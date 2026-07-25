"""Flask API for BusSense AI prototype."""
from __future__ import annotations

import csv
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean

from analytics import predict_demand
from gps_simulator import simulate_location
from recommendation import crowd_level, recommend_less_crowded_buses
from sustainability import bus_utilization_score, estimate_savings

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

import os

ROOT = Path(__file__).resolve().parents[1]
if os.environ.get("VERCEL") or not os.access(str(ROOT / "database"), os.W_OK):
    DB_PATH = Path("/tmp/bussense.db")
else:
    DB_PATH = ROOT / "database" / "bussense.db"

SCHEMA_PATH = ROOT / "database" / "schema.sql"
DATASET_PATH = ROOT / "datasets" / "sample_occupancy.csv"

app = Flask(__name__, static_folder=str(ROOT / "dashboard"), static_url_path="/dashboard")
CORS(app)


@app.route("/dashboard/")
@app.route("/dashboard")
def serve_dashboard_index():
    return send_from_directory(ROOT / "dashboard", "index.html")


@app.route("/dashboard/<path:filename>")
def serve_dashboard_files(filename):
    return send_from_directory(ROOT / "dashboard", filename)


@app.route("/mobile_app/<path:filename>")
@app.route("/app/<path:filename>")
def serve_mobile_app(filename):
    return send_from_directory(ROOT / "mobile_app", filename)


@app.route("/mobile_app/")
@app.route("/mobile_app")
@app.route("/app/")
@app.route("/app")
def serve_mobile_app_index():
    return send_from_directory(ROOT / "mobile_app", "index.html")


def get_db() -> sqlite3.Connection:
    if not DB_PATH.exists():
        init_db(seed=True)
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
    payload = []
    for index, row in enumerate(rows):
        item = row_to_dict(row)
        item.update(simulate_location(item["route_number"], item["bus_id"]))
        item["eta_minutes"] = 6 + (index * 4)
        item["crowd_level"] = crowd_level(item["occupancy_percentage"] or 0)
        item["bus_utilization_score"] = bus_utilization_score(item["occupancy_percentage"] or 0)
        payload.append(item)
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
        "bus_utilization_score": bus_utilization_score(avg_occ),
        "route_statistics": [row_to_dict(r) for r in route_rows],
        "overcrowding_alerts": overcrowded,
        "underutilized_buses": underused,
        **estimate_savings(records),
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


@app.route("/api/demand")
def demand():
    with get_db() as conn:
        records = [row_to_dict(r) for r in conn.execute("SELECT * FROM occupancy_records ORDER BY timestamp").fetchall()]
    return jsonify([insight.to_dict() for insight in predict_demand(records)])


@app.route("/api/locations")
def locations():
    with get_db() as conn:
        buses_rows = [row_to_dict(r) for r in conn.execute("SELECT bus_id, route_number FROM buses ORDER BY route_number, bus_id").fetchall()]
    return jsonify([simulate_location(row["route_number"], row["bus_id"]) for row in buses_rows])


@app.route("/api/recommend-buses")
def recommend_buses():
    route_number = request.args.get("route_number")
    limit = int(request.args.get("limit", 3))
    with get_db() as conn:
        rows = conn.execute(
            """SELECT b.*, r.timestamp, r.latitude, r.longitude, r.passenger_count,
                      r.occupancy_percentage, r.seat_availability
               FROM buses b
               LEFT JOIN occupancy_records r ON r.id = (
                   SELECT id FROM occupancy_records WHERE bus_id = b.bus_id ORDER BY timestamp DESC LIMIT 1
               )"""
        ).fetchall()
    buses_payload = []
    for index, row in enumerate(rows):
        item = row_to_dict(row)
        item.update(simulate_location(item["route_number"], item["bus_id"]))
        item["eta_minutes"] = 6 + (index * 4)
        buses_payload.append(item)
    return jsonify(recommend_less_crowded_buses(buses_payload, route_number, limit))


@app.route("/api/favorites", methods=["GET", "POST"])
def favorites():
    if request.method == "POST":
        data = request.get_json(force=True)
        with get_db() as conn:
            conn.execute(
                "INSERT INTO favorites (favorite_type, favorite_value) VALUES (?, ?)",
                (data.get("favorite_type", "route"), data.get("favorite_value", "")),
            )
        return jsonify({"message": "favorite saved"}), 201
    with get_db() as conn:
        rows = [row_to_dict(r) for r in conn.execute("SELECT * FROM favorites ORDER BY created_at DESC LIMIT 50").fetchall()]
    return jsonify(rows)


@app.route("/api/report", methods=["POST", "GET"])
def report():
    if request.method == "GET":
        with get_db() as conn:
            rows = [row_to_dict(r) for r in conn.execute("SELECT * FROM passenger_reports ORDER BY created_at DESC LIMIT 50").fetchall()]
        return jsonify(rows)
    data = request.get_json(silent=True) or {}
    with get_db() as conn:
        conn.execute(
            """INSERT INTO passenger_reports (bus_id, report_type, message, latitude, longitude)
               VALUES (?, ?, ?, ?, ?)""",
            (
                data.get("bus_id"),
                data.get("report_type", "passenger_report"),
                data.get("message", "Submitted from passenger app"),
                data.get("latitude"),
                data.get("longitude"),
            ),
        )
    return jsonify({"message": "report submitted"}), 201

@app.route("/api/dispatch", methods=["POST"])
def dispatch():
    data = request.get_json(silent=True) or {}
    route_number = data.get("route_number", "R1")
    operator = data.get("operator_type", "KSRTC")
    
    with get_db() as conn:
        count = conn.execute("SELECT COUNT(*) FROM buses WHERE route_number = ?", (route_number,)).fetchone()[0]
        new_id = f"{operator}-EXTRA-{count+1}"
        conn.execute(
            """INSERT OR IGNORE INTO buses (bus_id, operator_type, route_number, capacity, registration_number)
               VALUES (?, ?, ?, 50, ?)""",
            (new_id, operator, route_number, f"KL-01-EX-{count+1:02d}")
        )
        conn.execute(
            """INSERT INTO occupancy_records (bus_id, route_number, timestamp, latitude, longitude, passenger_count, occupancy_percentage, seat_availability, source)
               VALUES (?, ?, ?, 8.5241, 76.9366, 10, 20.0, 40, 'authority_dispatch')""",
            (new_id, route_number, datetime.now(timezone.utc).isoformat())
        )
    return jsonify({
        "message": f"Dispatched extra {operator} bus {new_id} to Route {route_number}",
        "bus_id": new_id,
        "route_number": route_number
    }), 201


if __name__ == "__main__":
    init_db(seed=True)
    app.run(debug=False, use_reloader=False, host="0.0.0.0", port=5000)


