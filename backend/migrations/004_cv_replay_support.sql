-- BusSense AI - Migration 004: Support for CV Replay Data Origin
-- Adds CV_REPLAY and ESTIMATE to data_origin enum

DO $$ BEGIN
    ALTER TYPE data_origin ADD VALUE IF NOT EXISTS 'CV_REPLAY';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TYPE data_origin ADD VALUE IF NOT EXISTS 'ESTIMATE';
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
