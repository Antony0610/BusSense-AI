-- BusSense AI - Seed Data (Kerala Transport Network)
-- Target: Supabase PostgreSQL (Project: Bus_Sense_AI / lqegmqgkymstycpzplld)

-- 1. Demo Users
INSERT INTO users (id, email, hashed_password, full_name, phone_number, role) VALUES
    ('11111111-1111-1111-1111-111111111111', 'rahul.nair@bussense.kerala.gov.in', '$2b$12$y1wXJ8t2dIqkFjYgM9vH4eO0n7qDqXpS6FjRzC5wKx.hZ.vQ1L9rG', 'Rahul Nair', '+91 98470 12345', 'PASSENGER'),
    ('22222222-2222-2222-2222-222222222222', 'suresh.kumar@bussense.kerala.gov.in', '$2b$12$y1wXJ8t2dIqkFjYgM9vH4eO0n7qDqXpS6FjRzC5wKx.hZ.vQ1L9rG', 'Suresh Kumar (Driver #402)', '+91 94471 67890', 'DRIVER_CONDUCTOR'),
    ('33333333-3333-3333-3333-333333333333', 'controller.vyttila@bussense.kerala.gov.in', '$2b$12$y1wXJ8t2dIqkFjYgM9vH4eO0n7qDqXpS6FjRzC5wKx.hZ.vQ1L9rG', 'Anjali Menon (Traffic Controller)', '+91 484 2381200', 'AUTHORITY')
ON CONFLICT (email) DO NOTHING;

-- 2. Kerala Buses
INSERT INTO buses (id, bus_number, registration_number, operator_type, capacity, is_ac, model_name, status, safety_score) VALUES
    ('a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '205', 'KL-15-A-2051', 'KSRTC', 55, FALSE, 'Ashok Leyland Viking FP', 'ACTIVE', 99.2),
    ('b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '14A', 'KL-07-CF-1402', 'PRIVATE', 45, FALSE, 'Tata Starbus Urban', 'ACTIVE', 96.5),
    ('c3333333-cccc-cccc-cccc-cccccccccccc', 'FP-102', 'KL-15-A-1024', 'KSRTC', 50, FALSE, 'Tata LPO 1618 Super Fast', 'ACTIVE', 98.7),
    ('d4444444-dddd-dddd-dddd-dddddddddddd', 'AC-501', 'KL-01-BV-5011', 'KURTC', 42, TRUE, 'Volvo 8400 Low Floor AC', 'ACTIVE', 99.8),
    ('e5555555-eeee-eeee-eeee-eeeeeeeeeeee', '12', 'KL-07-BW-1209', 'KSRTC', 55, FALSE, 'Tata Marcopolo Feeder', 'ACTIVE', 97.4)
ON CONFLICT (bus_number) DO NOTHING;

-- 3. Realistic Kerala Transit Stops (Valid Hex UUIDs)
INSERT INTO stops (id, stop_code, stop_name, locality, latitude, longitude, landmark) VALUES
    ('00000000-0000-0000-0000-000000000001', 'ALV-METRO', 'Aluva Metro Station', 'Aluva', 10.1076, 76.3533, 'Kochi Metro Terminal & Flyover'),
    ('00000000-0000-0000-0000-000000000002', 'KLM-JN', 'Kalamassery Premier Junction', 'Kalamassery', 10.0544, 76.3197, 'CUSAT Metro & HMT Jn'),
    ('00000000-0000-0000-0000-000000000003', 'EDP-TOLL', 'Edappally Toll & Lulu Terminal', 'Edappally', 10.0261, 76.3086, 'Lulu Mall & Metro Hub'),
    ('00000000-0000-0000-0000-000000000004', 'PLV-BYPASS', 'Palarivattom Bypass Junction', 'Palarivattom', 10.0075, 76.3115, 'Pipeline Junction & Civil Line Rd'),
    ('00000000-0000-0000-0000-000000000005', 'KLR-METRO', 'Kaloor Metro Station & Bus Stand', 'Kaloor', 9.9922, 76.2974, 'JLN Stadium & Banerji Road'),
    ('00000000-0000-0000-0000-000000000006', 'MGR-NORTH', 'MG Road North (Ernakulam Town)', 'Ernakulam North', 9.9865, 76.2842, 'North Railway Overbridge'),
    ('00000000-0000-0000-0000-000000000007', 'VYT-HUB', 'Vyttila Mobility Hub', 'Vyttila', 9.9678, 76.3182, 'Inter-Modal Terminal, KSRTC & Water Metro'),
    ('00000000-0000-0000-0000-000000000008', 'KKD-CIVIL', 'Kakkanad Civil Station', 'Kakkanad', 10.0159, 76.3456, 'District Collectorate'),
    ('00000000-0000-0000-0000-000000000009', 'IFO-PH1', 'Infopark Phase 1 Express Bay', 'Kakkanad', 10.0102, 76.3618, 'Athulya Building & TCS Gate'),
    ('00000000-0000-0000-0000-00000000000a', 'FTK-JETTY', 'Fort Kochi Boat Jetty', 'Fort Kochi', 9.9675, 76.2425, 'Ro-Ro Terminal & Coastal Promenade')
ON CONFLICT (stop_code) DO NOTHING;

-- 4. Routes
INSERT INTO routes (id, route_number, route_name, corridor_type, start_stop, end_stop, distance_km, estimated_duration_mins, color_code) VALUES
    ('00000000-0000-0000-0000-000000000101', '205', 'Aluva Metro ➔ Vyttila Mobility Hub via Kaloor', 'Fast Passenger Corridor', 'Aluva Metro Station', 'Vyttila Mobility Hub', 22.40, 48, '#123C35'),
    ('00000000-0000-0000-0000-000000000102', '14A', 'Fort Kochi ➔ Infopark Phase 1 via Kaloor', 'City Metro Feeder', 'Fort Kochi Boat Jetty', 'Infopark Phase 1 Express Bay', 26.50, 62, '#006C49'),
    ('00000000-0000-0000-0000-000000000103', '12', 'Kaloor Metro ➔ Infopark Phase 1 Corridor', 'Direct Tech Corridor', 'Kaloor Metro Station', 'Infopark Phase 1 Express Bay', 14.80, 32, '#2563EB')
ON CONFLICT (route_number) DO NOTHING;

-- 5. Route Stops Mapping
INSERT INTO route_stops (route_id, stop_id, stop_order, distance_from_start_km, scheduled_travel_mins) VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 1, 0.0, 0),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000002', 2, 6.2, 12),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000003', 3, 10.5, 21),
    ('00000000-0000-0000-0000-00000000000101', '00000000-0000-0000-0000-000000000004', 4, 13.8, 28),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000005', 5, 16.5, 34),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000007', 6, 22.4, 48),

    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000005', 1, 0.0, 0),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000004', 2, 2.8, 6),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000008', 3, 9.5, 20),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000009', 4, 14.8, 32)
ON CONFLICT (route_id, stop_order) DO NOTHING;

-- 6. Active Trips
INSERT INTO trips (id, bus_id, route_id, driver_id, trip_code, status, scheduled_departure, scheduled_arrival, current_stop_id, next_stop_id) VALUES
    ('00000000-0000-0000-0000-000000000201', 'a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000101', '22222222-2222-2222-2222-222222222222', 'TRIP-205-0830', 'IN_TRANSIT', NOW() - INTERVAL '20 MIN', NOW() + INTERVAL '28 MIN', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000005'),
    ('00000000-0000-0000-0000-000000000202', 'b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000102', NULL, 'TRIP-14A-0840', 'IN_TRANSIT', NOW() - INTERVAL '15 MIN', NOW() + INTERVAL '45 MIN', '00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000005')
ON CONFLICT (trip_code) DO NOTHING;

-- 7. Live Occupancy Telemetry
INSERT INTO occupancy_readings (bus_id, trip_id, passenger_count, capacity, occupancy_pct, crowd_level, detection_source, data_origin, recorded_at) VALUES
    ('a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000201', 23, 55, 41.8, 'LOW', 'YOLOv8_CCTV', 'SIMULATED', NOW()),
    ('b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000202', 39, 45, 86.7, 'CROWDED', 'YOLOv8_CCTV', 'SIMULATED', NOW()),
    ('e5555555-eeee-eeee-eeee-eeeeeeeeeeee', NULL, 34, 55, 61.8, 'MODERATE', 'YOLOv8_CCTV', 'SIMULATED', NOW());

-- 8. GPS Positions
INSERT INTO gps_positions (bus_id, trip_id, latitude, longitude, speed_kmh, heading_deg, next_stop_id, eta_next_stop_mins, data_origin, recorded_at) VALUES
    ('a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000201', 10.0012, 76.3045, 34.5, 195.0, '00000000-0000-0000-0000-000000000005', 3, 'SIMULATED', NOW()),
    ('b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '00000000-0000-0000-0000-000000000202', 9.9890, 76.2910, 22.0, 85.0, '00000000-0000-0000-0000-000000000005', 6, 'SIMULATED', NOW());

-- 9. Smart AI Recommendation (Exact Stitch Copy: Bus 205 recommended over 14A)
INSERT INTO bus_recommendations (user_id, origin_stop_id, destination_stop_id, recommended_bus_id, alternative_bus_id, journey_score, why_recommended, crowd_saving_pct, time_saving_mins, data_origin) VALUES
    ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000007', 'a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'b2222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 94.5, 'Bus 205 departs shortly after 14A, offers 40% lower crowd (42% occupied vs 87%), and saves 12 min by utilizing the dedicated priority lane timing.', 40.0, 12, 'RECOMMENDATION');

-- 10. Digital Boarding Ticket
INSERT INTO tickets (id, ticket_number, user_id, trip_id, bus_id, route_id, origin_stop, destination_stop, fare_amount, discount_pct, final_fare, qr_code_hash, status, valid_until) VALUES
    ('99999999-9999-9999-9999-999999999999', 'BS-KL-2026-9042', '11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000201', 'a1111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '00000000-0000-0000-0000-000000000101', 'Kaloor Metro Station', 'Vyttila Mobility Hub', 25.00, 0.0, 25.00, 'bussense://ticket/BS-KL-2026-9042?salt=kerala_secure_token', 'VALID', NOW() + INTERVAL '3 HOURS')
ON CONFLICT (ticket_number) DO NOTHING;

-- 11. Alerts
INSERT INTO alerts (title, message, severity, affected_route_id, is_active) VALUES
    ('Priority Corridor Active', 'Banerji Road priority transit lane operational. Expect 8-12 min faster transit on Route 205.', 'INFO', '00000000-0000-0000-0000-000000000101', TRUE),
    ('Rain Advisory — Kakkanad Corridor', 'Intermittent showers near Infopark. Fleet speeds adjusted for wet road conditions.', 'LOW', '00000000-0000-0000-0000-000000000103', TRUE);

-- 12. RAG Knowledge Documents
INSERT INTO knowledge_documents (id, title, category, content) VALUES
    ('00000000-0000-0000-0000-000000000301', 'BusSense AI Occupancy Calculation Methodology', 'CROWD_FAQ', 'BusSense AI computes real-time passenger occupancy by analyzing onboard CCTV video feeds with a privacy-preserving YOLOv8 neural network. The system detects passenger bounding boxes without facial recognition, facial biometric capture, or passenger identity tracking. Crowd tiers are defined as: LOW (< 50% capacity), MODERATE (50% to 80% capacity), and CROWDED (> 80% capacity).'),
    ('00000000-0000-0000-0000-000000000302', 'Route 205 Service Profile and Corridors', 'SCHEDULE', 'Bus 205 is a KSRTC Fast Passenger service connecting Aluva Metro Station to Vyttila Mobility Hub via Kalamassery, Edappally Toll, Palarivattom Bypass, and Kaloor Metro Station. Operating frequency is every 10 minutes during peak hours (08:00–11:00 and 16:30–20:00). Standard fare from Kaloor to Vyttila is INR 25.00.'),
    ('00000000-0000-0000-0000-000000000303', 'Digital Ticket Boarding and QR Validation Policy', 'FARE_POLICY', 'Digital boarding passes purchased in BusSense AI are cryptographically signed with unique QR tokens. Conductors validate tickets using the onboard crew app. Ticket states include: BOOKED (confirmed payment), VALID (ready for boarding), USED (validated by conductor), EXPIRED (passed departure window), and CANCELLED. QR tokens cannot be reused once validated.')
ON CONFLICT (id) DO NOTHING;
