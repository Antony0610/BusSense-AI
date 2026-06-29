# BusSense AI System Architecture

1. **CCTV input**: Bus camera stream is processed at the edge using OpenCV full-body detection.
2. **Privacy layer**: Frames are processed transiently; no facial recognition or identity records are stored.
3. **Backend API**: Flask receives occupancy events, stores them in SQLite, and exposes dashboard/mobile endpoints.
4. **Authority dashboard**: Browser dashboard displays live occupancy, historical trends, alerts, and sustainability metrics.
5. **Passenger prototype**: Lightweight mobile-friendly web app shows crowd levels, ETA mockups, alternatives, and seat predictions.
6. **Analytics**: Historical occupancy records are aggregated to identify peak hours, overcrowding, underutilization, and route recommendations.
