# BusSense AI — Computer Vision & Edge Occupancy

This document specifies the computer vision architecture utilized by BusSense AI for real-time passenger occupancy estimation.

---

## 1. Core Principles & Privacy Safeguards

1. **Strictly Zero Biometrics:**
   The vision subsystem operates purely as an **anonymous object detector**. No facial detection, facial recognition, gender classification, age estimation, or individual re-identification algorithms are loaded or permitted.
2. **Edge Volatility:**
   Frames extracted from the onboard CCTV stream are processed entirely in transient volatile memory (RAM) and immediately discarded. No video frames, still images, or bounding box crops are stored to disk or transmitted to the cloud.
3. **Aggregated Count Transmission:**
   The only payload transmitted from the bus edge computer to the Supabase cloud backend is an integer tuple:
   `(bus_id, passenger_count, seated_count, standing_count, occupancy_pct, crowd_level, timestamp)`.

---

## 2. Detection Pipeline

```
┌─────────────────────────────────┐
│ Wide-Angle Ceiling CCTV Camera  │ (Mounted above cabin center aisle)
└───────────────┬─────────────────┘
                │ RTSP Stream / 1080p @ 15 FPS
                ▼
┌─────────────────────────────────┐
│ OpenCV Video Frame Sampler      │ (Downsamples to 640x360 resolution;
│                                 │  skips 12 frames -> 3 FPS processing)
└───────────────┬─────────────────┘
                │ Volatile RAM Tensor
                ▼
┌─────────────────────────────────┐
│ YOLOv8n (Nano) Object Detector  │ (Model: yolov8n.pt, PyTorch/ONNX runtime)
│ Class 0: 'person' (COCO)        │ (Confidence threshold: >= 0.45)
└───────────────┬─────────────────┘
                │ Bounding Box Detections [xmin, ymin, xmax, ymax]
                ▼
┌─────────────────────────────────┐
│ Spatial Cabin Centroid Tracker  │ (Discriminates Seated vs Standing zones
│                                 │  based on camera focal geometry)
└───────────────┬─────────────────┘
                │ passenger_count = len(detections)
                ▼
┌─────────────────────────────────┐
│ Density Classifier              │ (<50% LOW, 50-80% MODERATE, >80% CROWDED)
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│ PostgREST / Supabase Sync       │ (Stored in `occupancy_readings`)
└─────────────────────────────────┘
```

---

## 3. Crowd Classification Thresholds

The system strictly adheres to three global capacity tiers:

| Tier | Occupancy Range | Color Token | Commuter Guidance |
|---|---|---|---|
| **LOW** | `< 50.0%` | `#006c49` (Forest Green) | Seats abundant; highly comfortable travel. |
| **MODERATE**| `50.0% – 80.0%` | `#d97706` (Warm Amber) | Limited window/aisle seating; standing room available. |
| **CROWDED** | `> 80.0%` | `#ba1a1a` (Crimson) | Standing room only; boarding delays likely. |

---

## 4. Hardware Sizing & Edge Performance

- **Target On-Bus Compute:** Raspberry Pi 5 (8GB) paired with Hailo-8 M.2 AI acceleration module (26 TOPS).
- **Inference Latency:** ~18ms per frame using YOLOv8n ONNX quantised model.
- **Power Envelope:** Under 15 Watts DC via vehicle auxiliary battery line.

---

## 5. Development & Simulation Mode

When running in local development or test environments where physical CCTV hardware is absent (`CV_MODE=SIMULATION`):
1. `backend/app/services/cv_occupancy.py` activates an automated passenger flux simulator.
2. At every corridor stop arrival, a stochastic Poisson delta computes realistic commuter boardings and alightings:
   ```python
   # Example: Infopark morning shift influx
   boardings = np.random.poisson(lam=8)
   alightings = np.random.poisson(lam=3)
   current_count = max(0, min(total_capacity, current_count + boardings - alightings))
   ```
3. All telemetry generated in this mode is tagged with `data_origin = 'SIMULATED'`.
