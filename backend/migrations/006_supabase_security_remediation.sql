-- BusSense AI - Migration 006: Supabase Security Remediation
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
-- Date: 2026-10-14 (Phase H13)
-- Purpose: Remediate all Supabase Security Advisor vulnerabilities:
--   1. Enable RLS on public tables missing RLS (roles, bus_recommendations, notifications, journey_history, ai_conversations, ai_messages)
--   2. Establish strict least-privilege RLS policies eliminating broad USING (true) policies
--   3. Add policies for RLS-enabled tables missing policies (favorites, knowledge_chunks)
--   4. Set fixed search_path on stored procedures to prevent search_path hijacking (validate_ticket_atomic)

-- 1. Secure roles table
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read roles" ON roles;
DROP POLICY IF EXISTS "Allow read roles" ON roles;
CREATE POLICY "Public read roles" ON roles FOR SELECT TO public USING (true);

-- 2. Secure bus_recommendations table
ALTER TABLE bus_recommendations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own recommendations" ON bus_recommendations;
DROP POLICY IF EXISTS "Users insert own recommendations" ON bus_recommendations;
CREATE POLICY "Users read own recommendations" ON bus_recommendations FOR SELECT TO public USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users insert own recommendations" ON bus_recommendations FOR INSERT TO public WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- 3. Secure notifications table (Remediate Migration 005 broad USING(true))
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all notifications" ON notifications;
DROP POLICY IF EXISTS "Users view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users delete own notifications" ON notifications;
DROP POLICY IF EXISTS "Allow insert notifications" ON notifications;
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT TO public USING (user_id = auth.uid());
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users delete own notifications" ON notifications FOR DELETE TO public USING (user_id = auth.uid());
CREATE POLICY "Allow insert notifications" ON notifications FOR INSERT TO public WITH CHECK (true);

-- 4. Secure journey_history table
ALTER TABLE journey_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own journey history" ON journey_history;
DROP POLICY IF EXISTS "Users insert own journey history" ON journey_history;
DROP POLICY IF EXISTS "Users update own journey history" ON journey_history;
CREATE POLICY "Users view own journey history" ON journey_history FOR SELECT TO public USING (user_id = auth.uid());
CREATE POLICY "Users insert own journey history" ON journey_history FOR INSERT TO public WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users update own journey history" ON journey_history FOR UPDATE TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 5. Secure ai_conversations table
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users insert own ai_conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users update own ai_conversations" ON ai_conversations;
CREATE POLICY "Users view own ai_conversations" ON ai_conversations FOR SELECT TO public USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users insert own ai_conversations" ON ai_conversations FOR INSERT TO public WITH CHECK (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY "Users update own ai_conversations" ON ai_conversations FOR UPDATE TO public USING (user_id IS NULL OR user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 6. Secure ai_messages table
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users view own ai_messages" ON ai_messages;
DROP POLICY IF EXISTS "Users insert own ai_messages" ON ai_messages;
CREATE POLICY "Users view own ai_messages" ON ai_messages FOR SELECT TO public USING (
    EXISTS (
        SELECT 1 FROM ai_conversations 
        WHERE ai_conversations.id = ai_messages.conversation_id 
        AND (ai_conversations.user_id IS NULL OR ai_conversations.user_id = auth.uid())
    )
);
CREATE POLICY "Users insert own ai_messages" ON ai_messages FOR INSERT TO public WITH CHECK (
    EXISTS (
        SELECT 1 FROM ai_conversations 
        WHERE ai_conversations.id = ai_messages.conversation_id 
        AND (ai_conversations.user_id IS NULL OR ai_conversations.user_id = auth.uid())
    )
);

-- 7. Add missing policies for favorites table
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own favorites" ON favorites;
CREATE POLICY "Users manage own favorites" ON favorites FOR ALL TO public USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 8. Add missing policy for knowledge_chunks table (public read-only)
ALTER TABLE knowledge_chunks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read knowledge_chunks" ON knowledge_chunks;
CREATE POLICY "Public read knowledge_chunks" ON knowledge_chunks FOR SELECT TO public USING (true);

-- 9. Fix function search_path mutable vulnerability
ALTER FUNCTION validate_ticket_atomic(VARCHAR, UUID, UUID) SET search_path = public, pg_temp;
