"""Flask API for BusSense AI prototype."""
from __future__ import annotations

import csv
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean

from flask import Flask, jsonify, request
from flask_cors import CORS

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "database" / "bussense.db"
SCHEMA_PATH = ROOT / "database" / "schema.sql"
DATASET_PATH = ROOT / "datasets" / "sample_occupancy.csv"

app = Flask(__name__, static_folder=str(ROOT / "dashboard"), static_url_path="/dashboard")
CORS(app)


def get_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def row_to_dict(row: sqlite3.Row) -> dict:
    return dict(zip(row.keys(), row))


def init_db(seed: bool = True) -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with get_db() as conn:
        conn.executescript(SCHEMA_PATH.read_text())
        if seed and conn.execute("SELECT COUNT(*) FROM buses").fetchone()[0] == 0:
            with DATASET_PATH.open(newline="") as fh:
                for item in csv.DictReader(fh):
                    conn.execute(
                        """INSERT OR IGNORE INTO buses
                        (bus_id, operator_type, route_number, capacity, registration_number)
                        VALUES (?, ?, ?, ?, ?)""",
                        (item["bus_id"], item["operator_type"], item["route_number"], int(item["capacity"]), item["registration_number"]),
                    )
                    conn.execute(
                        """INSERT INTO occupancy_records
                        (bus_id, route_number, timestamp, latitude, longitude, passenger_count,
                         occupancy_percentage, seat_availability, source)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'seed')""",
                        (
                            item["bus_id"], item["route_number"], item["timestamp"], float(item["latitude"]),
                            float(item["longitude"]), int(item["passenger_count"]), float(item["occupancy_percentage"]),
                            int(item["seat_availability"]),
                        ),
                    )


def crowd_level(occupancy: float) -> str:
    if occupancy >= 80:
        return "Red"
    if occupancy >= 55:
        return "Yellow"
    return "Green"


def savings(records: list[dict]) -> dict:
    underused = sum(1 for r in records if r["occupancy_percentage"] < 40)
    balanced = sum(1 for r in records if 55 <= r["occupancy_percentage"] <= 85)
    fuel_litres = round((underused * 1.8) + (balanced * 0.9), 2)
    return {"estimated_fuel_savings_litres": fuel_litres, "estimated_co2_reduction_kg": round(fuel_litres * 2.68, 2)}


@app.route("/")
def index():
    return jsonify({"name": "BusSense AI", "dashboard": "/dashboard/index.html", "health": "/api/health"})


@app.route("/api/health")
def health():
    return jsonify({"status": "ok", "database": str(DB_PATH)})


@app.route("/api/buses")
def buses():
    with get_db() as conn:
        rows = conn.execute(
            """SELECT b.*, r.timestamp, r.latitude, r.longitude, r.passenger_count,
                      r.occupancy_percentage, r.seat_availability
               FROM buses b
               LEFT JOIN occupancy_records r ON r.id = (
                   SELECT id FROM occupancy_records WHERE bus_id = b.bus_id ORDER BY timestamp DESC LIMIT 1
               ) ORDER BY b.route_number, b.bus_id"""
        ).fetchall()
    payload = [row_to_dict(r) | {"crowd_level": crowd_level(r["occupancy_percentage"] or 0)} for r in rows]
    return jsonify(payload)


@app.route("/api/occupancy", methods=["GET", "POST"])
def occupancy():
    if request.method == "POST":
        data = request.get_json(force=True)
        with get_db() as conn:
            bus = conn.execute("SELECT capacity, route_number FROM buses WHERE bus_id = ?", (data["bus_id"],)).fetchone()
            if not bus:
                return jsonify({"error": "unknown bus_id"}), 404
            passengers = int(data["passenger_count"])
            capacity = int(bus["capacity"])
            occupancy_pct = round((passengers / capacity) * 100, 2)
            conn.execute(
                """INSERT INTO occupancy_records
                (bus_id, route_number, timestamp, latitude, longitude, passenger_count,
                 occupancy_percentage, seat_availability, source)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    data["bus_id"], bus["route_number"], data.get("timestamp", datetime.now(timezone.utc).isoformat()),
                    float(data.get("latitude", 0)), float(data.get("longitude", 0)), passengers,
                    occupancy_pct, max(capacity - passengers, 0), data.get("source", "api"),
                ),
            )
        return jsonify({"message": "occupancy stored", "occupancy_percentage": occupancy_pct}), 201

    bus_id = request.args.get("bus_id")
    query = "SELECT * FROM occupancy_records"
    params: tuple = ()
    if bus_id:
        query += " WHERE bus_id = ?"
        params = (bus_id,)
    query += " ORDER BY timestamp DESC LIMIT 100"
    with get_db() as conn:
        rows = [row_to_dict(r) for r in conn.execute(query, params).fetchall()]
    return jsonify(rows)


@app.route("/api/stats")
def stats():
    with get_db() as conn:
        records = [row_to_dict(r) for r in conn.execute("SELECT * FROM occupancy_records").fetchall()]
        route_rows = conn.execute(
            """SELECT route_number, ROUND(AVG(occupancy_percentage), 2) avg_occupancy,
                      MAX(occupancy_percentage) max_occupancy, COUNT(*) samples
               FROM occupancy_records GROUP BY route_number ORDER BY route_number"""
        ).fetchall()
    overcrowded = [r for r in records if r["occupancy_percentage"] >= 85]
    underused = [r for r in records if r["occupancy_percentage"] <= 35]
    avg_occ = round(mean([r["occupancy_percentage"] for r in records]), 2) if records else 0
    return jsonify({
        "average_occupancy": avg_occ,
        "bus_utilization_score": round(min(avg_occ / 85 * 100, 100), 2),
        "route_statistics": [row_to_dict(r) for r in route_rows],
        "overcrowding_alerts": overcrowded,
        "underutilized_buses": underused,
        **savings(records),
    })


@app.route("/api/recommendations")
def recommendations():
    with get_db() as conn:
        routes = conn.execute(
            "SELECT route_number, AVG(occupancy_percentage) avg_occ FROM occupancy_records GROUP BY route_number"
        ).fetchall()
    recs = []
    for route in routes:
        avg_occ = route["avg_occ"]
        if avg_occ >= 80:
            recs.append({"route_number": route["route_number"], "action": "Add peak-hour services or larger buses", "priority": "High"})
        elif avg_occ <= 35:
            recs.append({"route_number": route["route_number"], "action": "Reduce frequency or shift buses to crowded routes", "priority": "Medium"})
        else:
            recs.append({"route_number": route["route_number"], "action": "Maintain current schedule", "priority": "Low"})
    return jsonify(recs)


if __name__ == "__main__":
    init_db(seed=True)
    app.run(debug=True, host="0.0.0.0", port=5000)
