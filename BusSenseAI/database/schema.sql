-- BusSense AI SQLite schema
CREATE TABLE IF NOT EXISTS buses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bus_id TEXT UNIQUE NOT NULL,
    operator_type TEXT NOT NULL CHECK (operator_type IN ('KSRTC', 'PRIVATE')),
    route_number TEXT NOT NULL,
    capacity INTEGER NOT NULL,
    registration_number TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS occupancy_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bus_id TEXT NOT NULL,
    route_number TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    passenger_count INTEGER NOT NULL,
    occupancy_percentage REAL NOT NULL,
    seat_availability INTEGER NOT NULL,
    source TEXT NOT NULL DEFAULT 'demo',
    FOREIGN KEY (bus_id) REFERENCES buses(bus_id)
);

CREATE INDEX IF NOT EXISTS idx_occupancy_bus_time ON occupancy_records(bus_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_occupancy_route_time ON occupancy_records(route_number, timestamp);

CREATE TABLE IF NOT EXISTS favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    favorite_type TEXT NOT NULL CHECK (favorite_type IN ('route', 'bus', 'destination')),
    favorite_value TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS passenger_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bus_id TEXT,
    report_type TEXT NOT NULL,
    message TEXT,
    latitude REAL,
    longitude REAL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

