-- BusSense AI - Migration 20261103000000: Supabase-Native Backend Infrastructure & RPCs
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
-- Date: November 2026 (Phase H22)

-- ============================================================
-- 1. PROVIDERS & INGESTION LOGS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id VARCHAR(64) UNIQUE NOT NULL,
    name VARCHAR(128) NOT NULL,
    organization VARCHAR(128) NOT NULL,
    api_key_hash VARCHAR(128) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    allowed_feed_types TEXT[] DEFAULT ARRAY['AVL_GPS', 'CCTV_OCCUPANCY', 'SCHEDULE_TIMETABLE', 'DISRUPTION_INCIDENT']::TEXT[],
    rate_limit_per_minute INT DEFAULT 60 NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.ingestion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id VARCHAR(64) REFERENCES public.providers(provider_id) ON DELETE SET NULL,
    feed_type VARCHAR(64) NOT NULL,
    record_count INT DEFAULT 1 NOT NULL,
    accepted_count INT DEFAULT 1 NOT NULL,
    rejected_count INT DEFAULT 0 NOT NULL,
    data_origin VARCHAR(32) DEFAULT 'LIVE DATA' NOT NULL,
    status VARCHAR(32) DEFAULT 'PROCESSED' NOT NULL,
    details JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.pilot_authorizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    corridor_id VARCHAR(64) NOT NULL,
    corridor_name VARCHAR(128) NOT NULL,
    stage VARCHAR(32) DEFAULT 'PROPOSED PILOT' NOT NULL,
    status VARCHAR(32) DEFAULT 'ACTIVE' NOT NULL,
    advisory_mode BOOLEAN DEFAULT TRUE NOT NULL,
    approved_by VARCHAR(128),
    approved_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- 2. ROW LEVEL SECURITY (RLS) FOR NEW TABLES
-- ============================================================

ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingestion_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pilot_authorizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authority manage providers" ON public.providers;
CREATE POLICY "Authority manage providers" ON public.providers
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.role IN ('AUTHORITY', 'ADMIN')
    ));

DROP POLICY IF EXISTS "Authority view ingestion logs" ON public.ingestion_logs;
CREATE POLICY "Authority view ingestion logs" ON public.ingestion_logs
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.role IN ('AUTHORITY', 'ADMIN')
    ));

DROP POLICY IF EXISTS "Public read pilot authorizations" ON public.pilot_authorizations;
CREATE POLICY "Public read pilot authorizations" ON public.pilot_authorizations
    FOR SELECT TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS "Authority manage pilot authorizations" ON public.pilot_authorizations;
CREATE POLICY "Authority manage pilot authorizations" ON public.pilot_authorizations
    FOR ALL TO authenticated
    USING (EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.role IN ('AUTHORITY', 'ADMIN')
    ));

-- ============================================================
-- 3. STORED FUNCTIONS (RPCs) FOR ATOMIC OPERATIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.book_ticket_atomic(
    p_user_id UUID,
    p_bus_number VARCHAR,
    p_route_number VARCHAR,
    p_origin_stop VARCHAR,
    p_destination_stop VARCHAR,
    p_passenger_name VARCHAR,
    p_fare_amount NUMERIC(10, 2),
    p_payment_method VARCHAR DEFAULT 'UPI'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_ticket_id UUID;
    v_ticket_number VARCHAR;
    v_qr_hash VARCHAR;
    v_valid_until TIMESTAMPTZ;
    v_payment_id UUID;
    v_bus_id UUID;
    v_route_id UUID;
    v_qr_data_uri TEXT;
BEGIN
    SELECT id INTO v_bus_id FROM public.buses WHERE bus_number = p_bus_number LIMIT 1;
    SELECT id INTO v_route_id FROM public.routes WHERE route_number = p_route_number LIMIT 1;

    v_ticket_id := gen_random_uuid();
    v_ticket_number := 'BS-KL-2026-' || LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    v_valid_until := NOW() + INTERVAL '2 hours';
    v_qr_hash := encode(digest(v_ticket_id::TEXT || v_ticket_number || NOW()::TEXT, 'sha256'), 'hex');
    v_qr_data_uri := 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    INSERT INTO public.tickets (
        id,
        user_id,
        bus_id,
        route_id,
        ticket_number,
        origin_stop,
        destination_stop,
        passenger_name,
        fare_amount,
        status,
        valid_until,
        qr_code_hash,
        qr_code_data_uri,
        data_origin,
        created_at
    ) VALUES (
        v_ticket_id,
        p_user_id,
        v_bus_id,
        v_route_id,
        v_ticket_number,
        p_origin_stop,
        p_destination_stop,
        p_passenger_name,
        p_fare_amount,
        'VALID',
        v_valid_until,
        v_qr_hash,
        v_qr_data_uri,
        'LIVE DATA',
        NOW()
    );

    v_payment_id := gen_random_uuid();
    INSERT INTO public.payments (
        id,
        user_id,
        ticket_id,
        amount,
        currency,
        payment_method,
        status,
        transaction_reference,
        created_at
    ) VALUES (
        v_payment_id,
        p_user_id,
        v_ticket_id,
        p_fare_amount,
        'INR',
        p_payment_method,
        'COMPLETED',
        'TXN-' || UPPER(SUBSTRING(v_qr_hash FROM 1 FOR 12)),
        NOW()
    );

    RETURN jsonb_build_object(
        'id', v_ticket_id,
        'ticket_id', v_ticket_id,
        'ticket_number', v_ticket_number,
        'bus_number', p_bus_number,
        'route_number', p_route_number,
        'origin_stop', p_origin_stop,
        'destination_stop', p_destination_stop,
        'passenger_name', p_passenger_name,
        'fare_amount', p_fare_amount,
        'status', 'VALID',
        'valid_until', v_valid_until,
        'qr_code_hash', v_qr_hash,
        'qr_code_data_uri', v_qr_data_uri,
        'payment_id', v_payment_id,
        'payment_status', 'COMPLETED'
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_nearby_stops(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 2.0
)
RETURNS TABLE (
    id UUID,
    stop_id VARCHAR,
    stop_name VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_km DOUBLE PRECISION
)
LANGUAGE sql
STABLE
AS $$
    SELECT 
        s.id,
        s.stop_id,
        s.stop_name,
        s.latitude,
        s.longitude,
        ROUND((
            6371 * acos(
                cos(radians(p_lat)) * cos(radians(s.latitude)) *
                cos(radians(s.longitude) - radians(p_lng)) +
                sin(radians(p_lat)) * sin(radians(s.latitude))
            )
        )::NUMERIC, 2)::DOUBLE PRECISION AS distance_km
    FROM public.stops s
    WHERE (
        6371 * acos(
            cos(radians(p_lat)) * cos(radians(s.latitude)) *
            cos(radians(s.longitude) - radians(p_lng)) +
            sin(radians(p_lat)) * sin(radians(s.latitude))
        )
    ) <= p_radius_km
    ORDER BY distance_km ASC;
$$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tickets;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.occupancy_readings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

INSERT INTO public.providers (provider_id, name, organization, api_key_hash, is_active, rate_limit_per_minute)
VALUES 
    ('KSRTC-SWIFT-01', 'KSRTC-SWIFT Automated Vehicle Location Feed', 'Kerala State Road Transport Corporation', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', true, 60),
    ('KMRL-FEEDER-01', 'Kochi Metro Feeder Bus GTFS-RT Telemetry', 'Kochi Metro Rail Limited', '4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a', true, 60),
    ('CCTV-GATEWAY-01', 'On-Bus CCTV Headcount Ingestion Gateway', 'BusSense Edge CCTV Integration Services', 'ef2d127de37b942baad06145e54b0c619a1f22327b2ebbcfbec78f5564afe39d', true, 120),
    ('KERALA-POLICE-01', 'Kerala Police Traffic Disruption Alerts', 'Kerala Police Traffic Department', '79054025255fb1a26e4bc422aef54eb4d08307c3be14b609c1598f654b9f2913', true, 30)
ON CONFLICT (provider_id) DO NOTHING;

INSERT INTO public.pilot_authorizations (corridor_id, corridor_name, stage, status, advisory_mode, approved_by, approved_at)
VALUES 
    ('corridor-205', 'Aluva Metro ➔ Vyttila Mobility Hub via Kaloor', 'PROPOSED PILOT', 'ACTIVE', true, 'Kerala Transport Commissionerate (Advisory)', NOW()),
    ('corridor-14a', 'Fort Kochi ➔ Infopark Phase 1 via Kaloor', 'PROPOSED PILOT', 'ACTIVE', true, 'Kerala Transport Commissionerate (Advisory)', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================
-- 6. SECURE STORAGE BUCKETS
-- ============================================================

DO $$
BEGIN
    INSERT INTO storage.buckets (id, name, public)
    VALUES 
        ('bussense-reports', 'bussense-reports', false),
        ('bussense-cctv-replays', 'bussense-cctv-replays', false),
        ('bussense-incidents', 'bussense-incidents', false)
    ON CONFLICT (id) DO NOTHING;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

