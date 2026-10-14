"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { getBuses, getAlerts, BusTelemetry, AlertData } from "@/lib/api";

export default function AuthorityFleetPage() {
  const [buses, setBuses] = useState<BusTelemetry[]>([]);
  const [alerts, setAlerts] = useState<AlertData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [crowdFilter, setCrowdFilter] = useState("all");
  const [selectedBus, setSelectedBus] = useState<BusTelemetry | null>(null);
  const [pingFeedback, setPingFeedback] = useState<string | null>(null);

  const loadData = async () => {
    try {
      const [fleetData, alertsData] = await Promise.all([
        getBuses(),
        getAlerts().catch(() => []),
      ]);
      setBuses(fleetData);
      setAlerts(alertsData);
      if (fleetData.length > 0 && !selectedBus) {
        setSelectedBus(fleetData[0]);
      } else if (selectedBus) {
        const updated = fleetData.find(
          (b) => b.bus_id === selectedBus.bus_id || b.bus_number === selectedBus.bus_number
        );
        if (updated) setSelectedBus(updated);
      }
      setError(null);
    } catch (err: any) {
      console.error("Failed to load fleet:", err);
      setError(err?.message || "Failed to query fleet telemetry");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const filteredBuses = buses.filter((bus) => {
    const matchesSearch =
      (bus.bus_code || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (bus.bus_number || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (bus.route_number || "").toLowerCase().includes(searchQuery.toLowerCase()) ||
      (bus.route_name || "").toLowerCase().includes(searchQuery.toLowerCase());

    if (crowdFilter === "low") return matchesSearch && bus.crowd_level === "LOW";
    if (crowdFilter === "moderate") return matchesSearch && bus.crowd_level === "MODERATE";
    if (crowdFilter === "crowded") return matchesSearch && bus.crowd_level === "CROWDED";
    return matchesSearch;
  });

  const avgOccupancy =
    buses.length > 0
      ? buses.reduce((acc, b) => acc + (b.occupancy_percentage || b.occupancy_pct || 40), 0) / buses.length
      : 54.8;

  const handleCockpitPing = (busNumber: string) => {
    setPingFeedback(`Operational ping sent to Bus ${busNumber} onboard cockpit.`);
    setTimeout(() => setPingFeedback(null), 3500);
  };

  const getDriverForBus = (busNumber: string) => {
    switch (busNumber) {
      case "205":
        return { name: "Suresh Kumar", shift: "Shift #A-204" };
      case "14A":
        return { name: "Manoj K.", shift: "Shift #B-108" };
      case "FP-102":
        return { name: "Rajesh P.", shift: "Shift #C-301" };
      case "12":
        return { name: "Anil George", shift: "Shift #A-205" };
      default:
        return { name: "Duty Crew Assigned", shift: "Morning Shift" };
    }
  };

  if (isLoading && buses.length === 0) {
    return (
      <div className="flex flex-col gap-6 w-full">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white h-24 rounded-2xl animate-pulse" />
          ))}
        </div>
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-5 items-start">
          <div className="xl:col-span-7 h-96 bg-white rounded-2xl animate-pulse" />
          <div className="xl:col-span-5 h-96 bg-white rounded-2xl animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Error state */}
      {error && (
        <div className="bg-[#ffdad6] text-[#93000a] p-3.5 rounded-2xl border border-[#ba1a1a]/30 flex items-center justify-between text-xs font-bold">
          <span>{error}</span>
          <button
            onClick={() => {
              setIsLoading(true);
              loadData();
            }}
            className="px-3 py-1 bg-white text-[#ba1a1a] rounded-xl hover:bg-[#fff1f0]"
          >
            Retry
          </button>
        </div>
      )}

      {/* Operational Telemetry Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Active Vehicles</span>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-2xl font-bold text-[#161d1b] tnum">{buses.length || 5}</span>
              <span className="text-xs text-[#006c49] font-bold">/ {buses.length || 5} Assigned Buses</span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#e8f0ec] flex items-center justify-center text-[#123c35]">
            <span className="material-symbols-outlined text-[24px]">directions_bus</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">On-Time Index</span>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-2xl font-bold text-[#161d1b] tnum">94.2%</span>
              <span className="text-xs text-[#006c49] font-bold">Within 3m</span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#6cf8bb]/40 flex items-center justify-center text-[#006c49]">
            <span className="material-symbols-outlined text-[24px]">verified</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Avg Fleet Occupancy</span>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-2xl font-bold text-[#161d1b] tnum">{avgOccupancy.toFixed(1)}%</span>
              <span className="text-xs text-[#414846] font-medium">Safe Capacity</span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#e8f0ec] flex items-center justify-center text-[#414846]">
            <span className="material-symbols-outlined text-[24px]">groups</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Active Advisories</span>
            <div className="flex items-baseline gap-1 mt-1">
              <span className="text-2xl font-bold text-[#ba1a1a] tnum">{alerts.length}</span>
              <span className="text-xs text-[#ba1a1a] font-bold truncate max-w-[120px]">
                {alerts[0]?.title || "Zero Detours"}
              </span>
            </div>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#ffdad6] flex items-center justify-center text-[#ba1a1a]">
            <span className="material-symbols-outlined text-[24px]">warning</span>
          </div>
        </div>
      </div>

      {/* Main Split: Fleet Table (Left 7 Cols) & Selected Bus Inspector (Right 5 Cols) */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-5 items-start">
        {/* Left: Table and Filters */}
        <div className="xl:col-span-7 flex flex-col gap-4">
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-3">
            <div className="flex flex-col sm:flex-row gap-3 items-center">
              <div className="relative w-full flex-1">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-[#717976] text-[20px]">
                  search
                </span>
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Filter by Bus #, Corridor, or Route..."
                  className="w-full bg-[#eef5f1] text-[#161d1b] text-sm pl-10 pr-3 py-2 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#123c35]"
                />
              </div>

              <div className="flex items-center gap-1.5 overflow-x-auto w-full sm:w-auto">
                <button
                  onClick={() => setCrowdFilter("all")}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wider transition-colors ${
                    crowdFilter === "all" ? "bg-[#123c35] text-white" : "bg-[#e8f0ec] text-[#414846]"
                  }`}
                >
                  All ({buses.length})
                </button>
                <button
                  onClick={() => setCrowdFilter("low")}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wider transition-colors ${
                    crowdFilter === "low" ? "bg-[#006c49] text-white" : "bg-[#e8f0ec] text-[#414846]"
                  }`}
                >
                  Normal
                </button>
                <button
                  onClick={() => setCrowdFilter("moderate")}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wider transition-colors ${
                    crowdFilter === "moderate" ? "bg-[#d97706] text-white" : "bg-[#e8f0ec] text-[#414846]"
                  }`}
                >
                  Mod
                </button>
                <button
                  onClick={() => setCrowdFilter("crowded")}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-bold uppercase tracking-wider transition-colors ${
                    crowdFilter === "crowded" ? "bg-[#ba1a1a] text-white" : "bg-[#e8f0ec] text-[#414846]"
                  }`}
                >
                  Crowded
                </button>
              </div>
            </div>

            {/* Tabular Fleet Roster */}
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-[#eef5f1] text-[10px] font-bold uppercase text-[#717976]">
                    <th className="py-2.5 px-3">Vehicle</th>
                    <th className="py-2.5 px-3">Route</th>
                    <th className="py-2.5 px-3">Speed</th>
                    <th className="py-2.5 px-3">Occupancy</th>
                    <th className="py-2.5 px-3">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#eef5f1] text-xs">
                  {filteredBuses.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-8 text-center text-[#717976]">
                        No active vehicles match the current filter query.
                      </td>
                    </tr>
                  ) : (
                    filteredBuses.map((bus) => {
                      const isSelected =
                        selectedBus?.bus_id === bus.bus_id ||
                        selectedBus?.bus_code === bus.bus_code ||
                        selectedBus?.bus_number === bus.bus_number;
                      return (
                        <tr
                          key={bus.bus_id || bus.bus_number}
                          onClick={() => setSelectedBus(bus)}
                          className={`cursor-pointer transition-colors ${
                            isSelected ? "bg-[#eef5f1] font-semibold" : "hover:bg-[#f3fbf7]"
                          }`}
                        >
                          <td className="py-3 px-3">
                            <div className="flex items-center gap-2">
                              <span
                                className={`w-2 h-2 rounded-full ${
                                  bus.crowd_level === "LOW"
                                    ? "bg-[#006c49]"
                                    : bus.crowd_level === "MODERATE"
                                    ? "bg-[#d97706]"
                                    : "bg-[#ba1a1a]"
                                }`}
                              />
                              <span className="font-bold text-[#161d1b]">
                                {bus.bus_code || `Bus ${bus.bus_number}`}
                              </span>
                            </div>
                          </td>
                          <td className="py-3 px-3 text-[#414846]">Route {bus.route_number}</td>
                          <td className="py-3 px-3 font-semibold text-[#161d1b] tnum">
                            {bus.speed_kmh ? `${bus.speed_kmh.toFixed(0)} km/h` : "32 km/h"}
                          </td>
                          <td className="py-3 px-3">
                            <div className="flex items-center gap-1.5">
                              <span className="tnum font-bold text-[#161d1b]">
                                {(bus.occupancy_percentage || bus.occupancy_pct || 40).toFixed(1)}%
                              </span>
                              <span
                                className={`text-[10px] px-1.5 py-0.5 rounded font-bold uppercase ${
                                  bus.crowd_level === "LOW"
                                    ? "bg-[#6cf8bb] text-[#005236]"
                                    : bus.crowd_level === "MODERATE"
                                    ? "bg-[#fed7aa] text-[#9a3412]"
                                    : "bg-[#ffdad6] text-[#93000a]"
                                }`}
                              >
                                {bus.crowd_level}
                              </span>
                            </div>
                          </td>
                          <td className="py-3 px-3">
                            <span className="px-2 py-0.5 rounded bg-[#e8f0ec] text-[#006c49] font-bold text-[10px]">
                              {bus.status || "ACTIVE"}
                            </span>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right: Selected Bus Inspector Card */}
        <div className="xl:col-span-5 flex flex-col gap-4">
          {selectedBus ? (
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-4">
              <div className="flex items-center justify-between pb-3 border-b border-[#eef5f1]">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 rounded-xl bg-[#123c35] text-white flex items-center justify-center font-bold text-sm">
                    {selectedBus.bus_number || selectedBus.bus_code.replace("Bus ", "")}
                  </div>
                  <div className="flex flex-col">
                    <h3 className="font-bold text-base text-[#161d1b]">{selectedBus.bus_code}</h3>
                    <span className="text-xs text-[#414846]">
                      {selectedBus.operator_type || "KSRTC"} • Route {selectedBus.route_number}
                    </span>
                  </div>
                </div>
                <span className="px-2 py-1 rounded bg-[#6cf8bb] text-[#005236] text-[10px] font-bold uppercase">
                  SIMULATED TELEMETRY
                </span>
              </div>

              {/* Edge Computer Vision Mock Box */}
              <div className="relative w-full h-44 rounded-xl bg-[#161d1b] overflow-hidden flex flex-col justify-between p-3 text-white">
                <div className="flex items-center justify-between text-xs">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#ba1a1a] animate-ping" />
                    <span className="font-bold tracking-wider uppercase text-[10px]">YOLOv8 Edge Feed</span>
                  </span>
                  <span className="text-[10px] text-[#c0ebe1]">FPS: 15.2 • No Biometrics Stored</span>
                </div>

                <div className="flex items-center justify-center">
                  <div className="p-3 rounded-xl bg-white/10 backdrop-blur border border-white/20 text-center">
                    <span className="text-2xl font-bold tnum">
                      {selectedBus.passenger_count || Math.round(((selectedBus.occupancy_percentage || selectedBus.occupancy_pct || 42) / 100) * 55)}
                    </span>
                    <span className="text-xs text-[#a5cfc5] block">Detected Passengers (Silhouette Only)</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-[11px] text-[#a5cfc5]">
                  <span>
                    Seated: {Math.min(selectedBus.passenger_count || 23, 35)} / 35
                  </span>
                  <span>
                    Standing: {Math.max(0, (selectedBus.passenger_count || 23) - 35)}
                  </span>
                  <span className="text-white font-bold">
                    Capacity: {selectedBus.total_capacity || selectedBus.capacity || 55}
                  </span>
                </div>
              </div>

              {/* Sensor Readouts */}
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                  <span className="text-[#717976] uppercase text-[10px] font-bold">GPS Coordinates</span>
                  <span className="font-bold text-[#161d1b] mt-1 tnum">
                    {selectedBus.latitude?.toFixed(4) || "9.9984"}, {selectedBus.longitude?.toFixed(4) || "76.3025"}
                  </span>
                  <span className="text-[10px] text-[#006c49]">Fix: 0.8s Delta</span>
                </div>
                <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                  <span className="text-[#717976] uppercase text-[10px] font-bold">Driver Assigned</span>
                  <span className="font-bold text-[#161d1b] mt-1">
                    {getDriverForBus(selectedBus.bus_number || "205").name}
                  </span>
                  <span className="text-[10px] text-[#414846]">
                    {getDriverForBus(selectedBus.bus_number || "205").shift}
                  </span>
                </div>
              </div>

              {/* Feedback toast if ping sent */}
              {pingFeedback && (
                <div className="p-2.5 rounded-xl bg-[#6cf8bb]/30 text-[#005236] text-xs font-bold flex items-center gap-1.5 border border-[#6cf8bb]">
                  <span className="material-symbols-outlined text-[16px]">check_circle</span>
                  <span>{pingFeedback}</span>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-2 pt-2 border-t border-[#eef5f1]">
                <button
                  type="button"
                  onClick={() => handleCockpitPing(selectedBus.bus_number || "205")}
                  className="flex-1 py-2.5 rounded-xl bg-[#123c35] text-white text-xs font-bold hover:bg-[#002620] transition-colors"
                >
                  Direct Cockpit Ping
                </button>
                <Link
                  href="/authority/routes"
                  className="px-4 py-2.5 rounded-xl bg-[#eef5f1] text-[#161d1b] text-xs font-bold hover:bg-[#e8f0ec] transition-colors text-center"
                >
                  View Route Sequence
                </Link>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-2xl p-8 text-center text-[#717976] border border-[#c0c8c5]/20">
              Select a bus from the roster to view live telemetry.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
