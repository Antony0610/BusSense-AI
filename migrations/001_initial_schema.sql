-- ============================================================================
-- BusSense AI 2.0: Production Supabase PostgreSQL 16 + PostGIS Schema
-- ============================================================================
-- Features: PostGIS Spatials, Dual-Role Auth (passenger / authority_admin),
-- Row Level Security (RLS) Policies, Supabase Realtime CDC Publications,
-- Dynamic QR Ticketing, EcoPass Gamification, Autonomous Rebalancing, & SOS Alerts.
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. CUSTOM TYPES & ENUMS
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('passenger', 'authority_admin');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE operator_type AS ENUM ('KSRTC', 'PRIVATE');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE bus_status AS ENUM ('active', 'delayed', 'maintenance', 'dispatched_extra');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_status AS ENUM ('active', 'used', 'cancelled', 'expired');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE report_type AS ENUM ('overcrowding', 'delay', 'comfort_issue', 'emergency');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE rebalance_status AS ENUM ('pending', 'applied', 'dismissed');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE sos_status AS ENUM ('active', 'investigating', 'resolved');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 3. PROFILES TABLE (Linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'passenger',
    phone_number TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to automatically populate public.profiles on auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'passenger'::user_role)
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        full_name = EXCLUDED.full_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Helper function to fetch current authenticated user role
CREATE OR REPLACE FUNCTION public.get_current_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 4. BUS FLEET DIRECTORY
CREATE TABLE IF NOT EXISTS public.buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id TEXT UNIQUE NOT NULL,
    operator_type operator_type NOT NULL,
    route_number TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 50,
    registration_number TEXT NOT NULL,
    status bus_status NOT NULL DEFAULT 'active',
    safety_score NUMERIC(3, 1) NOT NULL DEFAULT 9.4,
    sprite_type TEXT NOT NULL DEFAULT 'ksrtc_standard',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. ROUTES TABLE WITH POSTGIS WAYPOINTS
CREATE TABLE IF NOT EXISTS public.routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_number TEXT UNIQUE NOT NULL,
    route_name TEXT NOT NULL,
    start_stop TEXT NOT NULL,
    end_stop TEXT NOT NULL,
    distance_km NUMERIC(5, 2) NOT NULL,
    estimated_duration_mins INTEGER NOT NULL DEFAULT 35,
    path GEOMETRY(LineString, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. BUS STOPS TABLE
CREATE TABLE IF NOT EXISTS public.bus_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stop_name TEXT NOT NULL,
    route_number TEXT NOT NULL,
    stop_order INTEGER NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bus_stops_spatial ON public.bus_stops USING GIST(location);

-- 7. REAL-TIME OCCUPANCY & TELEMETRY TABLE
CREATE TABLE IF NOT EXISTS public.occupancy_telemetry (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bus_id TEXT NOT NULL REFERENCES public.buses(bus_id) ON DELETE CASCADE,
    route_number TEXT NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    passenger_count INTEGER NOT NULL,
    occupancy_percentage NUMERIC(5, 2) NOT NULL,
    seat_availability INTEGER NOT NULL,
    speed_kmh NUMERIC(4, 1) NOT NULL DEFAULT 35.0,
    heading_deg NUMERIC(4, 1) NOT NULL DEFAULT 0.0,
    crowd_tier TEXT GENERATED ALWAYS AS (
        CASE
            WHEN occupancy_percentage >= 80 THEN 'RED'
            WHEN occupancy_percentage >= 50 THEN 'YELLOW'
            ELSE 'GREEN'
        END
    ) STORED,
    source TEXT NOT NULL DEFAULT 'edge_yolo',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_telemetry_bus_time ON public.occupancy_telemetry(bus_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_telemetry_spatial ON public.occupancy_telemetry USING GIST(location);

-- 8. DYNAMIC SMART QR TICKETS & SEAT RESERVATIONS
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    bus_id TEXT NOT NULL REFERENCES public.buses(bus_id),
    route_number TEXT NOT NULL,
    origin_stop TEXT NOT NULL,
    destination_stop TEXT NOT NULL,
    seat_number TEXT NOT NULL,
    base_fare NUMERIC(6, 2) NOT NULL,
    discount_pct NUMERIC(4, 2) NOT NULL DEFAULT 0.0,
    final_fare NUMERIC(6, 2) NOT NULL,
    qr_code_hash TEXT UNIQUE NOT NULL,
    status ticket_status NOT NULL DEFAULT 'active',
    valid_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tickets_user ON public.tickets(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_hash ON public.tickets(qr_code_hash);

-- 9. ECOPASS GAMIFICATION & GREEN COMMUTER REWARDS
CREATE TABLE IF NOT EXISTS public.eco_rewards (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_ecopoints INTEGER NOT NULL DEFAULT 50,
    total_co2_kg_saved NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    total_distance_km NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    tier TEXT NOT NULL DEFAULT 'Bronze Commuter',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. AUTONOMOUS FLEET REBALANCING RECOMMENDATIONS
CREATE TABLE IF NOT EXISTS public.rebalance_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_route TEXT NOT NULL,
    target_route TEXT NOT NULL,
    recommended_bus_ids TEXT[] NOT NULL,
    reason TEXT NOT NULL,
    predicted_congestion_reduction_pct NUMERIC(4, 1) NOT NULL,
    status rebalance_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. EMERGENCY SOS & PASSENGER SAFETY ALERTS
CREATE TABLE IF NOT EXISTS public.sos_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    bus_id TEXT,
    route_number TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    message TEXT NOT NULL DEFAULT 'Emergency SOS Triggered by Passenger',
    status sos_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. PASSENGER CROWDING & INCIDENT REPORTS
CREATE TABLE IF NOT EXISTS public.passenger_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    bus_id TEXT REFERENCES public.buses(bus_id),
    report_type report_type NOT NULL DEFAULT 'overcrowding',
    message TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. AUTHORITY RELIEF BUS DISPATCH LOGS
CREATE TABLE IF NOT EXISTS public.dispatch_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    bus_id TEXT NOT NULL,
    route_number TEXT NOT NULL,
    operator_type operator_type NOT NULL,
    reason TEXT NOT NULL,
    dispatched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.occupancy_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eco_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rebalance_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passenger_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispatch_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone authenticated can view profiles, users edit their own
CREATE POLICY "Public profiles are viewable by everyone" 
    ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Fleet & Routes: Read-only for all commuters; full write for authority admins
CREATE POLICY "Buses are viewable by everyone" 
    ON public.buses FOR SELECT USING (true);
CREATE POLICY "Authority admins can manage buses" 
    ON public.buses FOR ALL USING (public.get_current_role() = 'authority_admin');

CREATE POLICY "Routes are viewable by everyone" 
    ON public.routes FOR SELECT USING (true);
CREATE POLICY "Authority admins can manage routes" 
    ON public.routes FOR ALL USING (public.get_current_role() = 'authority_admin');

CREATE POLICY "Bus stops are viewable by everyone" 
    ON public.bus_stops FOR SELECT USING (true);
CREATE POLICY "Authority admins can manage bus stops" 
    ON public.bus_stops FOR ALL USING (public.get_current_role() = 'authority_admin');

-- Occupancy Telemetry: Viewable by everyone; inserter service role / authority
CREATE POLICY "Telemetry is viewable by everyone" 
    ON public.occupancy_telemetry FOR SELECT USING (true);
CREATE POLICY "Edge and authorities can insert telemetry" 
    ON public.occupancy_telemetry FOR INSERT WITH CHECK (true);

-- Tickets: Passengers view/insert their own; authorities can inspect all
CREATE POLICY "Passengers can view their own tickets" 
    ON public.tickets FOR SELECT USING (auth.uid() = user_id OR public.get_current_role() = 'authority_admin');
CREATE POLICY "Passengers can book tickets" 
    ON public.tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Authorities can update ticket status" 
    ON public.tickets FOR UPDATE USING (public.get_current_role() = 'authority_admin');

-- Eco Rewards: View own rewards
CREATE POLICY "Users can view their own eco rewards" 
    ON public.eco_rewards FOR SELECT USING (auth.uid() = user_id OR public.get_current_role() = 'authority_admin');
CREATE POLICY "System can update eco rewards" 
    ON public.eco_rewards FOR ALL USING (auth.uid() = user_id OR public.get_current_role() = 'authority_admin');

-- Rebalance Recommendations: Restricted to authority admins
CREATE POLICY "Authority admins can view rebalances" 
    ON public.rebalance_recommendations FOR SELECT USING (public.get_current_role() = 'authority_admin');
CREATE POLICY "Authority admins can update rebalances" 
    ON public.rebalance_recommendations FOR UPDATE USING (public.get_current_role() = 'authority_admin');
CREATE POLICY "System can insert rebalances" 
    ON public.rebalance_recommendations FOR INSERT WITH CHECK (true);

-- SOS Alerts: Anyone can insert SOS; authority admins can see all; passengers see own
CREATE POLICY "Authenticated users can trigger SOS" 
    ON public.sos_alerts FOR INSERT WITH CHECK (true);
CREATE POLICY "SOS viewable by owner or authority" 
    ON public.sos_alerts FOR SELECT USING (auth.uid() = user_id OR public.get_current_role() = 'authority_admin' OR auth.uid() IS NULL);
CREATE POLICY "Authorities can resolve SOS alerts" 
    ON public.sos_alerts FOR UPDATE USING (public.get_current_role() = 'authority_admin');

-- Passenger Reports: Commuters can insert; authority admins manage
CREATE POLICY "Reports viewable by author or authority" 
    ON public.passenger_reports FOR SELECT USING (auth.uid() = user_id OR public.get_current_role() = 'authority_admin');
CREATE POLICY "Authenticated users can submit reports" 
    ON public.passenger_reports FOR INSERT WITH CHECK (true);
CREATE POLICY "Authorities can update reports" 
    ON public.passenger_reports FOR UPDATE USING (public.get_current_role() = 'authority_admin');

-- Dispatch Logs: Restricted to authority admins
CREATE POLICY "Authority admins can view dispatch logs" 
    ON public.dispatch_logs FOR SELECT USING (public.get_current_role() = 'authority_admin');
CREATE POLICY "Authority admins can create dispatch logs" 
    ON public.dispatch_logs FOR INSERT WITH CHECK (public.get_current_role() = 'authority_admin');

-- ============================================================================
-- SUPABASE REALTIME CONFIGURATION
-- ============================================================================
-- Add active tables to Supabase Realtime CDC publication
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.occupancy_telemetry;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rebalance_recommendations;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.dispatch_logs;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.passenger_reports;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- ============================================================================
-- REALISTIC SEED DATA (KERALA TRANSIT CORRIDORS)
-- ============================================================================

-- 1. Routes (Thiruvananthapuram)
INSERT INTO public.routes (route_number, route_name, start_stop, end_stop, distance_km, estimated_duration_mins, path)
VALUES
(
    'R1',
    'Thampanoor Central ➔ Technopark Campus',
    'Thampanoor Central Stop',
    'Technopark Main Gate',
    16.5,
    38,
    ST_GeomFromText('LINESTRING(76.9366 8.5241, 76.9400 8.5300, 76.9450 8.5350, 76.9520 8.5410, 76.9600 8.5520, 76.8840 8.5580)', 4326)
),
(
    'R2',
    'East Fort Heritage ➔ Kovalam Beach',
    'East Fort Bus Terminal',
    'Kovalam Light House',
    14.2,
    32,
    ST_GeomFromText('LINESTRING(76.9440 8.4830, 76.9410 8.4720, 76.9600 8.4350, 76.9800 8.4000)', 4326)
),
(
    'R3',
    'Pattom Junction ➔ Kazhakkoottam Hub',
    'Pattom Junction',
    'Kazhakkoottam Junction',
    12.8,
    28,
    ST_GeomFromText('LINESTRING(76.9420 8.5280, 76.9380 8.5350, 76.9200 8.5500, 76.8710 8.5680)', 4326)
),
(
    'R4',
    'Central Railway Station ➔ Medical College',
    'Central Railway Station',
    'Government Medical College',
    8.4,
    22,
    ST_GeomFromText('LINESTRING(76.9370 8.5240, 76.9480 8.5150, 76.9320 8.5250, 76.9240 8.5260)', 4326)
)
ON CONFLICT (route_number) DO NOTHING;

-- 2. Bus Stops
INSERT INTO public.bus_stops (stop_name, route_number, stop_order, latitude, longitude, location)
VALUES
('Thampanoor Central Stop', 'R1', 1, 8.5241, 76.9366, ST_SetSRID(ST_MakePoint(76.9366, 8.5241), 4326)),
('Palayam Connemara Market', 'R1', 2, 8.5020, 76.9510, ST_SetSRID(ST_MakePoint(76.9510, 8.5020), 4326)),
('Pattom Junction Stop', 'R1', 3, 8.5280, 76.9420, ST_SetSRID(ST_MakePoint(76.9420, 8.5280), 4326)),
('Ulloor Bridge Stop', 'R1', 4, 8.5360, 76.9310, ST_SetSRID(ST_MakePoint(76.9310, 8.5360), 4326)),
('Sreekaryam Junction', 'R1', 5, 8.5480, 76.9180, ST_SetSRID(ST_MakePoint(76.9180, 8.5480), 4326)),
('Technopark Main Gate', 'R1', 6, 8.5580, 76.8840, ST_SetSRID(ST_MakePoint(76.8840, 8.5580), 4326)),

('East Fort Bus Terminal', 'R2', 1, 8.4830, 76.9440, ST_SetSRID(ST_MakePoint(76.9440, 8.4830), 4326)),
('Attukal Temple Junction', 'R2', 2, 8.4720, 76.9520, ST_SetSRID(ST_MakePoint(76.9520, 8.4720), 4326)),
('Thiruvallam Bridge', 'R2', 3, 8.4480, 76.9610, ST_SetSRID(ST_MakePoint(76.9610, 8.4480), 4326)),
('Kovalam Light House', 'R2', 4, 8.4000, 76.9800, ST_SetSRID(ST_MakePoint(76.9800, 8.4000), 4326))
ON CONFLICT DO NOTHING;

-- 3. Bus Fleet
INSERT INTO public.buses (bus_id, operator_type, route_number, capacity, registration_number, status, safety_score, sprite_type)
VALUES
('KSRTC-101', 'KSRTC', 'R1', 50, 'KL-15-A-1001', 'active', 9.6, 'ksrtc_standard'),
('KSRTC-102', 'KSRTC', 'R1', 50, 'KL-15-A-1002', 'active', 9.4, 'ksrtc_standard'),
('PVT-201', 'PRIVATE', 'R1', 40, 'KL-01-P-2201', 'active', 9.1, 'pvt_cruiser'),
('KSRTC-103', 'KSRTC', 'R2', 50, 'KL-15-A-1003', 'active', 9.5, 'ksrtc_standard'),
('PVT-202', 'PRIVATE', 'R2', 38, 'KL-01-P-2202', 'active', 8.9, 'pvt_cruiser'),
('KSRTC-104', 'KSRTC', 'R3', 50, 'KL-15-A-1004', 'active', 9.7, 'ksrtc_standard'),
('PVT-203', 'PRIVATE', 'R3', 42, 'KL-01-P-2203', 'active', 9.2, 'pvt_cruiser'),
('KSRTC-105', 'KSRTC', 'R4', 48, 'KL-15-A-1005', 'active', 9.5, 'ksrtc_standard'),
('PVT-204', 'PRIVATE', 'R4', 36, 'KL-01-P-2204', 'active', 9.0, 'pvt_cruiser')
ON CONFLICT (bus_id) DO UPDATE
SET status = EXCLUDED.status,
    route_number = EXCLUDED.route_number;

-- 4. Initial Telemetry & Occupancy Pings
INSERT INTO public.occupancy_telemetry (bus_id, route_number, latitude, longitude, location, passenger_count, occupancy_percentage, seat_availability, speed_kmh, heading_deg, source)
VALUES
('KSRTC-101', 'R1', 8.5241, 76.9366, ST_SetSRID(ST_MakePoint(76.9366, 8.5241), 4326), 22, 44.0, 28, 38.0, 45.0, 'edge_yolo'),
('KSRTC-102', 'R1', 8.5350, 76.9450, ST_SetSRID(ST_MakePoint(76.9450, 8.5350), 4326), 46, 92.0, 4, 25.0, 50.0, 'edge_yolo'),
('PVT-201', 'R1', 8.5410, 76.9520, ST_SetSRID(ST_MakePoint(76.9520, 8.5410), 4326), 24, 60.0, 16, 42.0, 48.0, 'edge_yolo'),
('KSRTC-103', 'R2', 8.4830, 76.9440, ST_SetSRID(ST_MakePoint(76.9440, 8.4830), 4326), 18, 36.0, 32, 40.0, 180.0, 'edge_yolo'),
('PVT-202', 'R2', 8.4720, 76.9520, ST_SetSRID(ST_MakePoint(76.9520, 8.4720), 4326), 14, 36.8, 24, 35.0, 175.0, 'edge_yolo'),
('KSRTC-104', 'R3', 8.5280, 76.9420, ST_SetSRID(ST_MakePoint(76.9420, 8.5280), 4326), 48, 96.0, 2, 20.0, 320.0, 'edge_yolo'),
('PVT-203', 'R3', 8.5350, 76.9380, ST_SetSRID(ST_MakePoint(76.9380, 8.5350), 4326), 20, 47.6, 22, 38.0, 315.0, 'edge_yolo'),
('KSRTC-105', 'R4', 8.5240, 76.9370, ST_SetSRID(ST_MakePoint(76.9370, 8.5240), 4326), 12, 25.0, 36, 30.0, 90.0, 'edge_yolo'),
('PVT-204', 'R4', 8.5150, 76.9480, ST_SetSRID(ST_MakePoint(76.9480, 8.5150), 4326), 10, 27.7, 26, 32.0, 85.0, 'edge_yolo');

-- 5. Autonomous Fleet Rebalancing Recommendation Seed
INSERT INTO public.rebalance_recommendations (source_route, target_route, recommended_bus_ids, reason, predicted_congestion_reduction_pct, status)
VALUES
('R4', 'R1', ARRAY['PVT-204'], 'Route R1 predicted peak demand surge of 92% at 17:30. Route R4 operating at 25% occupancy.', 18.5, 'pending')
ON CONFLICT DO NOTHING;
