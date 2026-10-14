# BusSense AI — Digital Ticketing & Fare Collection Protocol
Document ID: KB-TICKETS
Category: FARE_POLICY_AND_TICKETS
Version: 1.1.0
Last Verified: October 2026

## 1. Digital Boarding Pass Architecture
- **Token Format:** Digital passes contain a cryptographically signed QR code hash (`bussense://ticket/{ticket_number}`).
- **Single Passenger Scope:** Each digital pass is valid for one commuter per single-trip corridor transit session.
- **Unassigned Seating:** Stage carriage transit buses in Kerala operate on an open-seating basis per Kerala Motor Vehicles Rules. All passenger seats are unreserved and unassigned; boarding passes provide authorized carriage transit rather than numbered seat reservations.

## 2. Ticket Lifecycle States
- **BOOKED:** Payment transaction processed and ticket record persisted to Supabase database.
- **VALID:** Departure window active; ticket is ready for conductor validation.
- **USED:** Successfully scanned and atomically validated by the conductor's mobile cockpit terminal. Cannot be re-scanned.
- **EXPIRED:** Validity departure window has elapsed without boarding.
- **CANCELLED:** Trip cancelled prior to departure window.

## 3. Booking Workflow & Payment Prototype Limitations
- **Workflow:**
  1. Commuter selects origin and destination stops in Explore or Smart Recommendation.
  2. System calculates distance-based Kerala transit fare.
  3. Commuter confirms booking via digital payment trigger.
  4. Instant Base64 PNG QR code boarding pass is issued.
- **Prototype Payment Sandbox:** Payments in the prototype utilize a local test payment simulator. Real bank debits, UPI auto-pay, and live production Razorpay gateways are NOT connected in this development phase.

## 4. Atomic Anti-Reuse Validation & QR Verification
- Conductor validation of the digital ticket QR code uses an atomic PostgreSQL stored procedure (`validate_ticket_atomic`) with row-level locks (`SELECT ... FOR UPDATE`).
- Anti-replay protection guarantees that two scans of the same digital boarding pass QR code cannot both succeed. Re-scanning yields `ALREADY_USED`.

## 5. Transit Tariff & Policy Boundaries
- **Distance-Based Fare Formula:** Standard minimum fare ₹10.00 base, with ₹1.50 per kilometer increment across Greater Kochi corridors.
- **Concessions & Pass Books:** Student concession cards, senior citizen passes, monthly physical season tickets, and depot cash refunds are handled exclusively at KSRTC and private bus depot counters. They cannot be processed or refunded via this application.
