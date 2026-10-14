-- BusSense AI - Migration 005: Realtime & Notifications Extension
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)
-- Applied: 2026-10-13 (Phase H12)

-- 1. Extend notifications table with deduplication and provenance metadata
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS dedup_key VARCHAR(100);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS severity alert_severity DEFAULT 'INFO';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS data_origin data_origin DEFAULT 'SIMULATED';

-- 2. Enable Row-Level Security on notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public all notifications" ON notifications;
CREATE POLICY "Allow public all notifications" ON notifications FOR ALL USING (true) WITH CHECK (true);

-- 3. Create performance indexes for user notifications and deduplication
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_dedup ON notifications(user_id, dedup_key);
