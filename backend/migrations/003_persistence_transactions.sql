-- BusSense AI - Migration 003: Persistence & Transactional RLS Policies
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
-- Applied: 2026-09-26

-- 1. Enable RLS and establish policies for payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all payments" ON payments;
CREATE POLICY "Allow public all payments" ON payments FOR ALL USING (true) WITH CHECK (true);

-- 2. Establish insert & update policies for alerts
DROP POLICY IF EXISTS "Public read alerts" ON alerts;
DROP POLICY IF EXISTS "Allow public all alerts" ON alerts;
CREATE POLICY "Allow public all alerts" ON alerts FOR ALL USING (true) WITH CHECK (true);

-- 3. Establish insert & update policies for reports
DROP POLICY IF EXISTS "Public read reports" ON reports;
DROP POLICY IF EXISTS "Allow public all reports" ON reports;
CREATE POLICY "Allow public all reports" ON reports FOR ALL USING (true) WITH CHECK (true);

-- 4. Enable RLS and establish policies for crowd_predictions
ALTER TABLE crowd_predictions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all crowd_predictions" ON crowd_predictions;
CREATE POLICY "Allow public all crowd_predictions" ON crowd_predictions FOR ALL USING (true) WITH CHECK (true);

-- 5. Atomic ticket validation function (prevents concurrent race conditions via row-level locking)
CREATE OR REPLACE FUNCTION validate_ticket_atomic(
    p_qr_hash VARCHAR,
    p_conductor_id UUID,
    p_bus_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_ticket RECORD;
    v_val_id UUID;
    v_passenger_name VARCHAR;
BEGIN
    -- Lock ticket row for update to prevent concurrent double-validation race conditions
    SELECT * INTO v_ticket
    FROM tickets
    WHERE qr_code_hash = p_qr_hash
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'result', 'INVALID',
            'failure_reason', 'Ticket not found for QR hash'
        );
    END IF;

    -- Check if already used
    IF v_ticket.status = 'USED' THEN
        INSERT INTO ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
        VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'ALREADY_USED', 'Ticket was already validated')
        RETURNING id INTO v_val_id;

        RETURN jsonb_build_object(
            'result', 'ALREADY_USED',
            'ticket_id', v_ticket.id,
            'ticket_number', v_ticket.ticket_number,
            'failure_reason', 'Ticket has already been used'
        );
    END IF;

    -- Check if expired
    IF v_ticket.valid_until < NOW() OR v_ticket.status = 'EXPIRED' THEN
        UPDATE tickets SET status = 'EXPIRED' WHERE id = v_ticket.id;
        
        INSERT INTO ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
        VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'EXPIRED', 'Ticket validity window lapsed')
        RETURNING id INTO v_val_id;

        RETURN jsonb_build_object(
            'result', 'EXPIRED',
            'ticket_id', v_ticket.id,
            'ticket_number', v_ticket.ticket_number,
            'failure_reason', 'Ticket validity window has lapsed'
        );
    END IF;

    -- Update ticket to USED
    UPDATE tickets 
    SET status = 'USED'
    WHERE id = v_ticket.id;

    -- Record validation audit
    INSERT INTO ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
    VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'VALID', NULL)
    RETURNING id INTO v_val_id;

    SELECT full_name INTO v_passenger_name FROM users WHERE id = v_ticket.user_id;

    RETURN jsonb_build_object(
        'result', 'VALID',
        'ticket_id', v_ticket.id,
        'ticket_number', v_ticket.ticket_number,
        'passenger_name', COALESCE(v_passenger_name, 'Commuter'),
        'origin_stop', v_ticket.origin_stop,
        'destination_stop', v_ticket.destination_stop,
        'fare_amount', v_ticket.fare_amount,
        'validation_id', v_val_id,
        'validated_at', NOW()
    );
END;
$$;
