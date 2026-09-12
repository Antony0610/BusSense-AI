-- ============================================================================
-- BusSense AI 2.0: Stored Database RPC Functions (100% Supabase Cloud Backend)
-- Completely replaces local Python backend.
-- ============================================================================

-- 1. Function: Retrieve Live Fleet Telemetry with PostGIS & Crowding
CREATE OR REPLACE FUNCTION fn_get_live_fleet()
RETURNS TABLE (
    bus_id VARCHAR,
    operator_type VARCHAR,
    route_number VARCHAR,
    route_name VARCHAR,
    route_name_ml VARCHAR,
    capacity INT,
    passenger_count INT,
    occupancy_percentage FLOAT,
    seat_availability INT,
    latitude FLOAT,
    longitude FLOAT,
    speed_kmh FLOAT,
    eta_minutes INT,
    crowd_level VARCHAR,
    co2_reduction_kg FLOAT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH latest_telemetry AS (
        SELECT DISTINCT ON (t.bus_id)
            t.bus_id,
            t.latitude,
            t.longitude,
            t.passenger_count,
            t.occupancy_percentage::FLOAT,
            t.seat_availability,
            t.speed_kmh::FLOAT,
            t.crowd_tier
        FROM occupancy_telemetry t
        ORDER BY t.bus_id, t.timestamp DESC
    )
    SELECT 
        b.bus_id::VARCHAR,
        b.operator_type::VARCHAR,
        b.route_number::VARCHAR,
        COALESCE(r.route_name, 'Thampanoor ➔ Technopark')::VARCHAR AS route_name,
        CASE 
            WHEN b.route_number = 'R1' THEN 'തമ്പാനൂർ ➔ കഴക്കൂട്ടം'
            WHEN b.route_number = 'R2' THEN 'കിഴക്കേക്കോട്ട ➔ കോവളം'
            WHEN b.route_number = 'R3' THEN 'തമ്പാനൂർ ➔ ടെക്നോപാർക്ക്'
            WHEN b.route_number = 'R4' THEN 'പേരൂർക്കട ➔ മെഡിക്കൽ കോളേജ്'
            ELSE 'തമ്പാനൂർ ➔ ടെക്നോപാർക്ക്'
        END::VARCHAR AS route_name_ml,
        b.capacity::INT,
        COALESCE(lt.passenger_count, 20)::INT AS passenger_count,
        COALESCE(lt.occupancy_percentage, 40.0)::FLOAT AS occupancy_percentage,
        COALESCE(lt.seat_availability, b.capacity - 20)::INT AS seat_availability,
        COALESCE(lt.latitude, 8.5241)::FLOAT AS latitude,
        COALESCE(lt.longitude, 76.9366)::FLOAT AS longitude,
        COALESCE(lt.speed_kmh, 35.0)::FLOAT AS speed_kmh,
        CASE 
            WHEN COALESCE(lt.occupancy_percentage, 40.0) >= 80 THEN 10
            WHEN COALESCE(lt.occupancy_percentage, 40.0) >= 50 THEN 6
            ELSE 4
        END::INT AS eta_minutes,
        CASE 
            WHEN COALESCE(lt.occupancy_percentage, 40.0) >= 85 THEN 'Red'
            WHEN COALESCE(lt.occupancy_percentage, 40.0) >= 50 THEN 'Amber'
            ELSE 'Green'
        END::VARCHAR AS crowd_level,
        ROUND((COALESCE(lt.passenger_count, 20) * 1.4)::NUMERIC, 1)::FLOAT AS co2_reduction_kg
    FROM buses b
    LEFT JOIN latest_telemetry lt ON b.bus_id = lt.bus_id
    LEFT JOIN routes r ON b.route_number = r.route_number
    ORDER BY b.bus_id;
END;
$$;

-- 2. Function: Book Seat with 20% Green Off-Peak Discount & Cryptographic QR
CREATE OR REPLACE FUNCTION fn_book_ticket(
    p_user_id VARCHAR,
    p_bus_id VARCHAR,
    p_route_number VARCHAR,
    p_origin VARCHAR,
    p_destination VARCHAR,
    p_seat_number VARCHAR,
    p_fare_amount FLOAT,
    p_is_off_peak BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ticket_id UUID := gen_random_uuid();
    v_fare NUMERIC := p_fare_amount;
    v_discount NUMERIC := 0.0;
    v_qr_hash VARCHAR;
BEGIN
    IF p_is_off_peak THEN
        v_discount := 20.0;
        v_fare := ROUND((p_fare_amount * 0.80)::NUMERIC, 2);
    END IF;

    v_qr_hash := 'BUSSENSE|' || p_bus_id || '|SEAT:' || p_seat_number || '|HASH:' || SUBSTRING(MD5(v_ticket_id::TEXT) FROM 1 FOR 8);

    INSERT INTO tickets (
        id,
        bus_id,
        route_number,
        origin_stop,
        destination_stop,
        seat_number,
        base_fare,
        discount_pct,
        final_fare,
        qr_code_hash,
        status,
        valid_until
    ) VALUES (
        v_ticket_id,
        p_bus_id,
        p_route_number,
        p_origin,
        p_destination,
        p_seat_number,
        p_fare_amount,
        v_discount,
        v_fare,
        v_qr_hash,
        'active'::ticket_status,
        NOW() + INTERVAL '4 hours'
    );

    UPDATE occupancy_telemetry 
    SET passenger_count = passenger_count + 1,
        seat_availability = GREATEST(0, seat_availability - 1)
    WHERE bus_id = p_bus_id;

    RETURN jsonb_build_object(
        'ticket_id', v_ticket_id,
        'bus_id', p_bus_id,
        'route_number', p_route_number,
        'seat_number', p_seat_number,
        'origin_stop', p_origin,
        'destination_stop', p_destination,
        'fare_amount', v_fare,
        'discount_pct', v_discount,
        'qr_code_hash', v_qr_hash,
        'status', 'active',
        'valid_until', NOW() + INTERVAL '4 hours',
        'created_at', NOW()
    );
END;
$$;

-- 3. Function: Broadcast Emergency SOS Distress Beacon
CREATE OR REPLACE FUNCTION fn_broadcast_sos(
    p_user_id VARCHAR,
    p_bus_id VARCHAR,
    p_route_number VARCHAR,
    p_lat FLOAT,
    p_lng FLOAT,
    p_message VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_alert_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO sos_alerts (
        id,
        bus_id,
        route_number,
        latitude,
        longitude,
        message,
        status
    ) VALUES (
        v_alert_id,
        p_bus_id,
        p_route_number,
        p_lat,
        p_lng,
        p_message,
        'active'::sos_status
    );

    RETURN jsonb_build_object(
        'sos_id', v_alert_id,
        'bus_id', p_bus_id,
        'route_number', p_route_number,
        'latitude', p_lat,
        'longitude', p_lng,
        'message', p_message,
        'status', 'active',
        'created_at', NOW()
    );
END;
$$;

-- 4. Function: Autonomous Fleet Relief Bus Dispatch
CREATE OR REPLACE FUNCTION fn_dispatch_relief_bus(
    p_route_number VARCHAR,
    p_operator_type VARCHAR,
    p_reason VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_relief_id VARCHAR := 'RELIEF-EV-' || FLOOR(RANDOM() * 899 + 100)::INT;
    v_log_id UUID := gen_random_uuid();
BEGIN
    INSERT INTO dispatch_logs (
        id,
        bus_id,
        route_number,
        operator_type,
        reason,
        dispatched_at
    ) VALUES (
        v_log_id,
        v_relief_id,
        p_route_number,
        p_operator_type::operator_type,
        p_reason,
        NOW()
    );

    RETURN jsonb_build_object(
        'relief_bus_id', v_relief_id,
        'route_number', p_route_number,
        'operator_type', p_operator_type,
        'message', 'Dispatched extra electric relief bus ' || v_relief_id || ' to Route ' || p_route_number,
        'dispatched_at', NOW()
    );
END;
$$;

-- 5. Function: Conductor QR Ticket Verification
CREATE OR REPLACE FUNCTION fn_verify_ticket(p_qr_hash VARCHAR)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_ticket RECORD;
BEGIN
    SELECT * INTO v_ticket FROM tickets WHERE qr_code_hash = p_qr_hash LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'message', 'Invalid Ticket Hash: Not found');
    END IF;

    IF v_ticket.status = 'used' THEN
        RETURN jsonb_build_object('valid', false, 'message', 'Ticket Already Used');
    END IF;

    UPDATE tickets SET status = 'used', validated_at = NOW() WHERE id = v_ticket.id;

    RETURN jsonb_build_object(
        'valid', true,
        'ticket_id', v_ticket.id,
        'bus_id', v_ticket.bus_id,
        'route_number', v_ticket.route_number,
        'seat_number', v_ticket.seat_number,
        'origin_stop', v_ticket.origin_stop,
        'destination_stop', v_ticket.destination_stop,
        'fare', v_ticket.final_fare,
        'status', 'used',
        'verified_at', NOW()
    );
END;
$$;
