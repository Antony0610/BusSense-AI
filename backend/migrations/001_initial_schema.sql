-- BusSense AI - Complete Relational Schema
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. ENUMS & DOMAINS
-- ============================================================

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('PASSENGER', 'DRIVER_CONDUCTOR', 'AUTHORITY', 'ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE bus_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'IDLE', 'OUT_OF_SERVICE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE operator_type AS ENUM ('KSRTC', 'PRIVATE', 'KURTC');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE crowd_level AS ENUM ('LOW', 'MODERATE', 'CROWDED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE trip_status AS ENUM ('SCHEDULED', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED', 'DELAYED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_status AS ENUM ('BOOKED', 'VALID', 'USED', 'EXPIRED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE validation_result AS ENUM ('VALID', 'INVALID', 'ALREADY_USED', 'EXPIRED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE incident_category AS ENUM (
        'VEHICLE_ISSUE', 
        'ROUTE_OBSTRUCTION', 
        'OVERCROWDING', 
        'DELAY', 
        'SAFETY_MEDICAL', 
        'OTHER'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE incident_status AS ENUM ('REPORTED', 'ACKNOWLEDGED', 'INVESTIGATING', 'RESOLVED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_severity AS ENUM ('INFO', 'LOW', 'WARNING', 'CRITICAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE data_origin AS ENUM ('LIVE', 'SIMULATED', 'PREDICTION', 'RECOMMENDATION', 'HUMAN_DECISION');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================
-- 2. USERS & ROLES
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO roles (role_name, description) VALUES
    ('PASSENGER', 'Public commuter accessing routes, ticketing, real-time occupancy and AI assistant'),
    ('DRIVER_CONDUCTOR', 'Crew member managing bus trip, passenger validation, and rapid incident reports'),
    ('AUTHORITY', 'Transit regulator/depot manager accessing command console, fleet metrics, and dispatch'),
    ('ADMIN', 'Full system administrator')
ON CONFLICT (role_name) DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role user_role DEFAULT 'PASSENGER',
    is_active BOOLEAN DEFAULT TRUE,
    preferred_language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. FLEET & NETWORK (BUSES, ROUTES, STOPS)
-- ============================================================

CREATE TABLE IF NOT EXISTS buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_number VARCHAR(20) UNIQUE NOT NULL, -- e.g. '205', '14A', 'FP-102'
    registration_number VARCHAR(30) UNIQUE NOT NULL, -- e.g. 'KL-07-CD-2051'
    operator_type operator_type DEFAULT 'KSRTC',
    capacity INT NOT NULL DEFAULT 55,
    is_ac BOOLEAN DEFAULT FALSE,
    model_name VARCHAR(50) DEFAULT 'Tata Marcopolo BS-VI',
    status bus_status DEFAULT 'ACTIVE',
    safety_score NUMERIC(3, 1) DEFAULT 98.4,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_number VARCHAR(20) UNIQUE NOT NULL, -- e.g. 'R12', '205', 'FP-1'
    route_name VARCHAR(150) NOT NULL,
    corridor_type VARCHAR(50) DEFAULT 'Metro Feeder Corridor',
    start_stop VARCHAR(100) NOT NULL,
    end_stop VARCHAR(100) NOT NULL,
    distance_km NUMERIC(5, 2) NOT NULL,
    estimated_duration_mins INT NOT NULL,
    color_code VARCHAR(10) DEFAULT '#123C35',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stop_code VARCHAR(20) UNIQUE NOT NULL,
    stop_name VARCHAR(100) NOT NULL,
    locality VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    landmark VARCHAR(150),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
    stop_order INT NOT NULL,
    distance_from_start_km NUMERIC(5, 2) DEFAULT 0.0,
    scheduled_travel_mins INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(route_id, stop_order)
);

-- ============================================================
-- 4. TRIPS & ACTIVE TELEMETRY
-- ============================================================

CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id),
    conductor_id UUID REFERENCES users(id),
    trip_code VARCHAR(50) UNIQUE NOT NULL,
    status trip_status DEFAULT 'SCHEDULED',
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival TIMESTAMPTZ NOT NULL,
    actual_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    current_stop_id UUID REFERENCES stops(id),
    next_stop_id UUID REFERENCES stops(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gps_positions (
    id BIGSERIAL PRIMARY KEY,
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed_kmh NUMERIC(5, 1) DEFAULT 0.0,
    heading_deg NUMERIC(5, 1) DEFAULT 0.0,
    next_stop_id UUID REFERENCES stops(id),
    eta_next_stop_mins INT DEFAULT 3,
    data_origin data_origin DEFAULT 'SIMULATED',
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_gps_bus_recorded ON gps_positions(bus_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS occupancy_readings (
    id BIGSERIAL PRIMARY KEY,
    bus_id UUID NOT NULL REFERENCES buses(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id),
    passenger_count INT NOT NULL,
    capacity INT NOT NULL DEFAULT 55,
    occupancy_pct NUMERIC(5, 2) NOT NULL,
    crowd_level crowd_level NOT NULL,
    detection_source VARCHAR(50) DEFAULT 'YOLOv8_CCTV',
    data_origin data_origin DEFAULT 'SIMULATED',
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_occupancy_bus_recorded ON occupancy_readings(bus_id, recorded_at DESC);

-- ============================================================
-- 5. AI PREDICTIONS & SMART RECOMMENDATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS crowd_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    stop_id UUID NOT NULL REFERENCES stops(id) ON DELETE CASCADE,
    time_horizon_mins INT NOT NULL, -- e.g. 15, 30, 60
    predicted_occupancy_pct NUMERIC(5, 2) NOT NULL,
    predicted_crowd_level crowd_level NOT NULL,
    confidence_score NUMERIC(4, 3) DEFAULT 0.880,
    contributing_factors JSONB DEFAULT '{"rain_factor": 0.15, "peak_inflow": 0.65, "historical_density": 0.70}'::jsonb,
    data_origin data_origin DEFAULT 'PREDICTION',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bus_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    origin_stop_id UUID NOT NULL REFERENCES stops(id),
    destination_stop_id UUID NOT NULL REFERENCES stops(id),
    recommended_bus_id UUID NOT NULL REFERENCES buses(id),
    alternative_bus_id UUID REFERENCES buses(id),
    journey_score NUMERIC(4, 1) DEFAULT 94.0,
    why_recommended TEXT NOT NULL,
    crowd_saving_pct NUMERIC(5, 2) DEFAULT 40.0,
    time_saving_mins INT DEFAULT 12,
    data_origin data_origin DEFAULT 'RECOMMENDATION',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. TICKETS, VALIDATIONS & PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id),
    bus_id UUID NOT NULL REFERENCES buses(id),
    route_id UUID NOT NULL REFERENCES routes(id),
    origin_stop VARCHAR(100) NOT NULL,
    destination_stop VARCHAR(100) NOT NULL,
    fare_amount NUMERIC(6, 2) NOT NULL,
    discount_pct NUMERIC(4, 2) DEFAULT 0.0,
    final_fare NUMERIC(6, 2) NOT NULL,
    qr_code_hash VARCHAR(128) UNIQUE NOT NULL,
    status ticket_status DEFAULT 'BOOKED',
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ticket_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    conductor_id UUID REFERENCES users(id),
    bus_id UUID NOT NULL REFERENCES buses(id),
    result validation_result NOT NULL,
    failure_reason TEXT,
    validated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    amount NUMERIC(6, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'INR',
    gateway VARCHAR(30) DEFAULT 'RAZORPAY_TEST',
    gateway_payment_id VARCHAR(100),
    status payment_status DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. INCIDENTS, ALERTS & NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES users(id),
    bus_id UUID REFERENCES buses(id),
    route_id UUID REFERENCES routes(id),
    category incident_category NOT NULL,
    severity alert_severity DEFAULT 'WARNING',
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status incident_status DEFAULT 'REPORTED',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    severity alert_severity DEFAULT 'INFO',
    affected_route_id UUID REFERENCES routes(id),
    affected_bus_id UUID REFERENCES buses(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50) DEFAULT 'BUS_ARRIVAL',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. USER HISTORY & FAVORITES
-- ============================================================

CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- 'ROUTE', 'STOP', 'DESTINATION'
    reference_id VARCHAR(100) NOT NULL,
    label VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, item_type, reference_id)
);

CREATE TABLE IF NOT EXISTS journey_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id),
    ticket_id UUID REFERENCES tickets(id),
    origin_stop VARCHAR(100) NOT NULL,
    destination_stop VARCHAR(100) NOT NULL,
    board_time TIMESTAMPTZ NOT NULL,
    alighting_time TIMESTAMPTZ,
    status VARCHAR(30) DEFAULT 'COMPLETED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. RAG ASSISTANT KNOWLEDGE BASE
-- ============================================================

CREATE TABLE IF NOT EXISTS knowledge_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'SCHEDULE', 'CROWD_FAQ', 'FARE_POLICY', 'SAFETY'
    source_url VARCHAR(255),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS knowledge_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES knowledge_documents(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    chunk_content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    session_title VARCHAR(150) DEFAULT 'Transit Query',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    sender_role VARCHAR(20) NOT NULL, -- 'user', 'assistant'
    content TEXT NOT NULL,
    sources JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. AUTHORITY REPORTS & AUDIT LOGS
-- ============================================================

CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type VARCHAR(50) NOT NULL, -- 'WEEKLY_OPERATIONS', 'CORRIDOR_EFFICIENCY', 'SAFETY_AUDIT'
    title VARCHAR(200) NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    summary_metrics JSONB NOT NULL,
    generated_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on core tables (with permissive prototype policies)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE occupancy_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Permissive prototype policies for anon/authenticated access in demo environment
CREATE POLICY "Public read buses" ON buses FOR SELECT USING (true);
CREATE POLICY "Public read routes" ON routes FOR SELECT USING (true);
CREATE POLICY "Public read stops" ON stops FOR SELECT USING (true);
CREATE POLICY "Public read route_stops" ON route_stops FOR SELECT USING (true);
CREATE POLICY "Public read trips" ON trips FOR SELECT USING (true);
CREATE POLICY "Public read gps" ON gps_positions FOR SELECT USING (true);
CREATE POLICY "Public read occupancy" ON occupancy_readings FOR SELECT USING (true);
CREATE POLICY "Public read alerts" ON alerts FOR SELECT USING (true);
CREATE POLICY "Public read knowledge" ON knowledge_documents FOR SELECT USING (true);
CREATE POLICY "Public read reports" ON reports FOR SELECT USING (true);
CREATE POLICY "Allow public insert tickets" ON tickets FOR ALL USING (true);
CREATE POLICY "Allow public insert validations" ON ticket_validations FOR ALL USING (true);
CREATE POLICY "Allow public insert incidents" ON incidents FOR ALL USING (true);
CREATE POLICY "Allow public users" ON users FOR ALL USING (true);
