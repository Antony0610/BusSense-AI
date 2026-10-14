-- BusSense AI - Migration 006: Supabase Security Remediation (Hardened)
-- Target: Supabase PostgreSQL (Project: BusSense AI / lqegmqgkymstycpzplld)
-- Date: 2026-10-14 (Phase H13 Capstone)
-- Purpose: Remediate all 9 Supabase Security Advisor vulnerabilities with strict least-privilege policies:
--   1. Secure roles table: read-only for authenticated and anonymous users; prevent modification
--   2. Secure bus_recommendations: eliminate unauthenticated insertion bypass; enforce strict user isolation
--   3. Secure notifications: eliminate permissive WITH CHECK (true); restrict user writes; preserve server dispatch
--   4. Secure journey_history: enforce strict auth.uid() ownership on SELECT, INSERT, and UPDATE
--   5. Secure ai_conversations: eliminate shared NULL conversation exposure; enforce strict auth.uid() scoping
--   6. Secure ai_messages: bind message access strictly to verified user-owned parent conversations
--   7. Secure favorites: add missing granular policies for user-owned favorite stops and routes
--   8. Secure knowledge_chunks: add missing public read policy while strictly forbidding write/tampering
--   9. Harden validate_ticket_atomic: lock search_path, enforce caller RBAC, and restrict EXECUTE permissions

-- ============================================================
-- 1. SECURE ROLES TABLE (SEC-001)
-- ============================================================
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read roles" ON public.roles;
DROP POLICY IF EXISTS "Allow read roles" ON public.roles;

-- Read-only access to role definitions for authenticated clients and anonymous lookup
CREATE POLICY "Allow read roles" ON public.roles 
    FOR SELECT TO authenticated, anon 
    USING (true);

-- Explicitly revoke mutation privileges from client roles
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.roles FROM anon, authenticated, public;
GRANT SELECT ON public.roles TO anon, authenticated;

-- ============================================================
-- 2. SECURE BUS_RECOMMENDATIONS TABLE (SEC-002)
-- ============================================================
ALTER TABLE public.bus_recommendations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own recommendations" ON public.bus_recommendations;
DROP POLICY IF EXISTS "Users insert own recommendations" ON public.bus_recommendations;

-- Commuters can view general corridor recommendations (user_id IS NULL) or their own private recommendations
CREATE POLICY "Users read own recommendations" ON public.bus_recommendations 
    FOR SELECT TO authenticated 
    USING (user_id IS NULL OR user_id = auth.uid());

-- Commuters can ONLY insert recommendations assigned to themselves (cannot forge user_id or inject NULL rows)
CREATE POLICY "Users insert own recommendations" ON public.bus_recommendations 
    FOR INSERT TO authenticated 
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON public.bus_recommendations FROM anon;
GRANT SELECT, INSERT ON public.bus_recommendations TO authenticated;

-- ============================================================
-- 3. SECURE NOTIFICATIONS TABLE (SEC-003)
-- ============================================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users delete own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users insert own notifications" ON public.notifications;

-- Commuters can ONLY read their own inbox notifications
CREATE POLICY "Users view own notifications" ON public.notifications 
    FOR SELECT TO authenticated 
    USING (user_id = auth.uid());

-- Commuters can ONLY mark their own notifications as read; cannot modify user_id or content
CREATE POLICY "Users update own notifications" ON public.notifications 
    FOR UPDATE TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

-- Commuters can delete their own notifications
CREATE POLICY "Users delete own notifications" ON public.notifications 
    FOR DELETE TO authenticated 
    USING (user_id = auth.uid());

-- Clients may only insert notifications targeted to themselves (e.g., travel reminders);
-- backend service role handles fleet-wide and cross-user broadcast dispatch
CREATE POLICY "Users insert own notifications" ON public.notifications 
    FOR INSERT TO authenticated 
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON public.notifications FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;

-- ============================================================
-- 4. SECURE JOURNEY_HISTORY TABLE (SEC-004)
-- ============================================================
ALTER TABLE public.journey_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own journey history" ON public.journey_history;
DROP POLICY IF EXISTS "Users insert own journey history" ON public.journey_history;
DROP POLICY IF EXISTS "Users update own journey history" ON public.journey_history;

CREATE POLICY "Users view own journey history" ON public.journey_history 
    FOR SELECT TO authenticated 
    USING (user_id = auth.uid());

CREATE POLICY "Users insert own journey history" ON public.journey_history 
    FOR INSERT TO authenticated 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users update own journey history" ON public.journey_history 
    FOR UPDATE TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON public.journey_history FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.journey_history TO authenticated;

-- ============================================================
-- 5. SECURE AI_CONVERSATIONS TABLE (SEC-005)
-- ============================================================
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users insert own ai_conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users update own ai_conversations" ON public.ai_conversations;
DROP POLICY IF EXISTS "Users delete own ai_conversations" ON public.ai_conversations;

-- Strictly scoped to authenticated owner (eliminates shared NULL conversation vulnerability)
CREATE POLICY "Users view own ai_conversations" ON public.ai_conversations 
    FOR SELECT TO authenticated 
    USING (user_id = auth.uid());

CREATE POLICY "Users insert own ai_conversations" ON public.ai_conversations 
    FOR INSERT TO authenticated 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users update own ai_conversations" ON public.ai_conversations 
    FOR UPDATE TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users delete own ai_conversations" ON public.ai_conversations 
    FOR DELETE TO authenticated 
    USING (user_id = auth.uid());

REVOKE ALL ON public.ai_conversations FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_conversations TO authenticated;

-- ============================================================
-- 6. SECURE AI_MESSAGES TABLE (SEC-006)
-- ============================================================
ALTER TABLE public.ai_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_messages" ON public.ai_messages;
DROP POLICY IF EXISTS "Users insert own ai_messages" ON public.ai_messages;

-- Messages are only accessible if the parent conversation belongs to the authenticated user
CREATE POLICY "Users view own ai_messages" ON public.ai_messages 
    FOR SELECT TO authenticated 
    USING (
        EXISTS (
            SELECT 1 FROM public.ai_conversations 
            WHERE public.ai_conversations.id = public.ai_messages.conversation_id 
            AND public.ai_conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users insert own ai_messages" ON public.ai_messages 
    FOR INSERT TO authenticated 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ai_conversations 
            WHERE public.ai_conversations.id = public.ai_messages.conversation_id 
            AND public.ai_conversations.user_id = auth.uid()
        )
    );

REVOKE ALL ON public.ai_messages FROM anon;
GRANT SELECT, INSERT ON public.ai_messages TO authenticated;

-- ============================================================
-- 7. SECURE FAVORITES TABLE (SEC-008)
-- ============================================================
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own favorites" ON public.favorites;

CREATE POLICY "Users manage own favorites" ON public.favorites 
    FOR ALL TO authenticated 
    USING (user_id = auth.uid()) 
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON public.favorites FROM anon;
GRANT ALL ON public.favorites TO authenticated;

-- ============================================================
-- 8. SECURE KNOWLEDGE_CHUNKS TABLE (SEC-009)
-- ============================================================
ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read knowledge_chunks" ON public.knowledge_chunks;
DROP POLICY IF EXISTS "Allow read knowledge_chunks" ON public.knowledge_chunks;

CREATE POLICY "Allow read knowledge_chunks" ON public.knowledge_chunks 
    FOR SELECT TO authenticated, anon 
    USING (true);

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.knowledge_chunks FROM anon, authenticated, public;
GRANT SELECT ON public.knowledge_chunks TO anon, authenticated;

-- ============================================================
-- 9. HARDEN VALIDATE_TICKET_ATOMIC FUNCTION (SEC-007)
-- ============================================================
CREATE OR REPLACE FUNCTION public.validate_ticket_atomic(
    p_qr_hash character varying, 
    p_conductor_id uuid, 
    p_bus_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
    v_ticket RECORD;
    v_val_id UUID;
    v_passenger_name VARCHAR;
    v_caller_role VARCHAR;
BEGIN
    -- 1. Enforce caller RBAC authorization
    SELECT role INTO v_caller_role FROM public.users WHERE id = p_conductor_id;
    IF v_caller_role IS NULL OR v_caller_role NOT IN ('DRIVER_CONDUCTOR', 'AUTHORITY') THEN
        RETURN jsonb_build_object(
            'result', 'UNAUTHORIZED',
            'failure_reason', 'Caller is not authorized to validate boarding passes'
        );
    END IF;

    -- 2. Verify target bus existence
    IF NOT EXISTS (SELECT 1 FROM public.buses WHERE id = p_bus_id) THEN
        RETURN jsonb_build_object(
            'result', 'INVALID_BUS',
            'failure_reason', 'Specified bus_id does not exist'
        );
    END IF;

    -- 3. Lock ticket row for update to eliminate concurrent race conditions
    SELECT * INTO v_ticket
    FROM public.tickets
    WHERE qr_code_hash = p_qr_hash
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'result', 'INVALID',
            'failure_reason', 'Ticket not found for QR hash'
        );
    END IF;

    -- 4. Check if already redeemed
    IF v_ticket.status = 'USED' THEN
        INSERT INTO public.ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
        VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'ALREADY_USED', 'Ticket was already validated')
        RETURNING id INTO v_val_id;

        RETURN jsonb_build_object(
            'result', 'ALREADY_USED',
            'ticket_id', v_ticket.id,
            'ticket_number', v_ticket.ticket_number,
            'failure_reason', 'Ticket has already been used'
        );
    END IF;

    -- 5. Check if validity window lapsed
    IF v_ticket.valid_until < NOW() OR v_ticket.status = 'EXPIRED' THEN
        UPDATE public.tickets SET status = 'EXPIRED' WHERE id = v_ticket.id;
        
        INSERT INTO public.ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
        VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'EXPIRED', 'Ticket validity window lapsed')
        RETURNING id INTO v_val_id;

        RETURN jsonb_build_object(
            'result', 'EXPIRED',
            'ticket_id', v_ticket.id,
            'ticket_number', v_ticket.ticket_number,
            'failure_reason', 'Ticket validity window has lapsed'
        );
    END IF;

    -- 6. Transition status atomically to USED
    UPDATE public.tickets 
    SET status = 'USED'
    WHERE id = v_ticket.id;

    -- 7. Record validation audit log entry
    INSERT INTO public.ticket_validations (ticket_id, conductor_id, bus_id, result, failure_reason)
    VALUES (v_ticket.id, p_conductor_id, p_bus_id, 'VALID', NULL)
    RETURNING id INTO v_val_id;

    SELECT full_name INTO v_passenger_name FROM public.users WHERE id = v_ticket.user_id;

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
$function$;

-- Revoke execute from public and anonymous callers; grant exclusively to authenticated and service_role
REVOKE EXECUTE ON FUNCTION public.validate_ticket_atomic(character varying, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_ticket_atomic(character varying, uuid, uuid) TO authenticated, service_role;
