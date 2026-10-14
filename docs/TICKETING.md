# BusSense AI — Ticketing, Fares & QR Validation

This document outlines the digital ticketing subsystem, dynamic QR code generation, anti-fraud validation state machines, and sandbox payment flows.

---

## 1. Ticket Lifecycle State Machine

A transit pass transitions through strict, non-reversible states:

```
┌──────────────────┐
│  PASSENGER BOOK  │ (Selects Origin, Destination, Route)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   PAYMENT HOLD   │ (Simulated Sandbox or Razorpay Test)
└────────┬─────────┘
         │ Payment Confirmed
         ▼
┌──────────────────┐
│  STATUS: VALID   │ ◄──────────────────────────────┐
└────────┬─────────┘                                │
         │                                          │ Valid Window Active
         ├──────────────────────────────────────────┤
         │                                          │
         ├────────────────────┬─────────────────────┤
         │ Conductor Scan     │ Timeout (120m)      │ User Action
         ▼                    ▼                     ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   STATUS: USED   │ │  STATUS: EXPIRED │ │ STATUS: CANCELLED│
│   (Single Use    │ │ (Pass Invalided) │ │  (Refund Logged) │
│    Confirmed)    │ └──────────────────┘ └──────────────────┘
└────────┬─────────┘
         │ Re-scan Attempt
         ▼
┌──────────────────┐
│  ALREADY USED    │ (Audited Fraud Warning)
└──────────────────┘
```

---

## 2. Fare Calculation Model

Fares strictly follow the Kerala Motor Vehicles Department stage carriage tariff structures:

- **Base Fare:** ₹10.00 (covers initial 2.5 km journey stage).
- **Per-Kilometer Rate:** ₹1.50 per additional kilometer.
- **Service Tier Multipliers:**
  - Ordinary Stage Carriage: `1.0x`
  - Fast Passenger / Limited Stop: `1.15x`
  - Super Fast / AC Low Floor: `1.30x`

$$\text{fare} = \max\left(10.0, \text{round}\left((10.0 + (\text{distance\_km} \times 1.50)) \times \text{multiplier}, 2\right)\right)$$

---

## 3. Cryptographic QR Pass Structure

Tickets do not encode raw, easily forgeable plain text. The payload embedded inside the QR code data URI consists of a structured verification envelope:

```
BUS_SENSE:v1:<ticket_id>:<ticket_number>:<timestamp>:<hmac_signature>
```

- **HMAC Signature:** Generated using `HMAC-SHA256(ticket_id + valid_until, SECRET_KEY)`.
- **Base64 Rendering:** Encoded directly into an in-memory PNG data URI using `qrcode` and `Pillow`, bypassing the need to store static image files on cloud storage buckets.
- **Visual Glare Defense:** High error-correction level (ECC Level M) ensures reliable scanning on cracked smartphone glass or in low-light night-time bus cabins.

---

## 4. Conductor Validation & Anti-Fraud Logic (Phase H2 Database Hardened)

The conductor terminal (`/driver/validator`) performs sub-second verification upon camera scan using the Supabase PostgreSQL stored procedure `validate_ticket_atomic`:

1. **Row-Level Locking Concurrency Protection:**
   The procedure executes `SELECT * FROM tickets WHERE qr_code_hash = p_qr_hash FOR UPDATE;`. Any concurrent scans of the same ticket are serialized at the database engine level, eliminating double-use race conditions.
2. **Database Audit (`ticket_validations` table):**
   - If ticket `status == 'USED'`, the terminal emits an immediate **Crimson Warning** (`ALREADY_USED`), logs the audit failure in `ticket_validations`, and rejects boarding.
   - If `status == 'EXPIRED'` or current time is past `valid_until`, the pass is marked `EXPIRED`, audited, and rejected.
   - If `status == 'VALID'`, the ticket is atomically updated to `USED`, and a validation receipt is appended to `ticket_validations`.
3. **Cross-Session Persistence:**
   All validations and ticket status changes survive backend restarts, eliminating prototype state wipes.

---

## 5. Payment Integrations & Persistence

- **Simulated Payment Gateway (`PAYMENT_GATEWAY_MODE=SIMULATED`):** Transactions are verified instantly, and a persistent `payments` record is written directly into Supabase PostgreSQL referencing the generated `ticket_id` with `status: 'COMPLETED'`.
- **Sandbox Mode:** Supports Razorpay Test Keys (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`) using Razorpay Standard Checkout modal.
- **Truth Transparency:** All payment receipts generated in prototype mode are clearly flagged as simulated sandbox transactions and do not claim live banking clearinghouse integration.

