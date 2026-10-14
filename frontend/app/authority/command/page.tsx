"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import {
  getBuses,
  getCommandOverview,
  getAlerts,
  BusTelemetry,
  CommandOverview,
  AlertData,
} from "@/lib/api";

export default function AuthorityCommandPage() {
  const [buses, setBuses] = useState<BusTelemetry[]>([]);
  const [overview, setOverview] = useState<CommandOverview | null>(null);
  const [alerts, setAlerts] = useState<AlertData[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedBusCode, setSelectedBusCode] = useState<string>("Bus 205");
  const [corridorFilter, setCorridorFilter] = useState<string>("all");

  const loadData = async () => {
    try {
      const [busesData, overviewData, alertsData] = await Promise.all([
        getBuses(),
        getCommandOverview().catch((err) => {
          console.warn("Command overview endpoint fallback:", err);
          return null;
        }),
        getAlerts().catch((err) => {
          console.warn("Alerts endpoint fallback:", err);
          return [];
        }),
      ]);
      setBuses(busesData);
      if (overviewData) setOverview(overviewData);
      setAlerts(alertsData);
      setError(null);
    } catch (err: any) {
      console.error("Failed to load command telemetry:", err);
      setError(err?.message || "Failed to synchronize operational telemetry");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  const selectedBus =
    buses.find((b) => b.bus_code === selectedBusCode || b.bus_number === selectedBusCode.replace("Bus ", "")) ||
    buses[0] || {
      bus_id: "bus-205",
      bus_code: "Bus 205",
      bus_number: "205",
      registration_number: "KL-07-CE-8821",
      operator_type: "KSRTC",
      route_number: "12",
      route_name: "Kaloor - Infopark",
      occupancy_pct: 41.8,
      occupancy_percentage: 41.8,
      crowd_level: "LOW" as const,
      speed_kmh: 34.2,
      current_stop: "Palarivattom Jn",
      next_stop: "Kaloor Central Stand",
      eta_next_stop_mins: 4,
    };

  // Derived metrics
  const avgSpeed =
    buses.length > 0
      ? buses.reduce((acc, b) => acc + (b.speed_kmh || 30), 0) / buses.length
      : overview?.active_corridors?.[0]?.avg_speed || 28.6;

  const avgOccupancy =
    buses.length > 0
      ? buses.reduce((acc, b) => acc + (b.occupancy_percentage || b.occupancy_pct || 40), 0) / buses.length
      : overview?.average_network_occupancy_pct || 58.4;

  const crowdedCount = buses.filter((b) => b.crowd_level === "CROWDED").length;

  if (isLoading && buses.length === 0) {
    return (
      <div className="flex flex-col gap-4 w-full">
        <div className="h-14 bg-white rounded-2xl animate-pulse" />
        <div className="grid grid-cols-12 gap-5 w-full">
          <div className="col-span-12 xl:col-span-8 h-[580px] bg-white rounded-2xl animate-pulse" />
          <div className="col-span-12 xl:col-span-4 h-[580px] bg-white rounded-2xl animate-pulse" />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 w-full">
      {/* Error state if telemetry failed completely */}
      {error && buses.length === 0 && (
        <div className="bg-[#ffdad6] text-[#93000a] p-4 rounded-2xl border border-[#ba1a1a]/30 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[20px]">error</span>
            <span className="text-xs font-bold">{error}</span>
          </div>
          <button
            onClick={() => {
              setIsLoading(true);
              loadData();
            }}
            className="px-3 py-1 bg-white text-[#ba1a1a] rounded-xl text-xs font-bold hover:bg-[#fff1f0]"
          >
            Retry Connection
          </button>
        </div>
      )}

      {/* Top Filter Bar */}
      <div className="flex flex-wrap items-center justify-between bg-white rounded-2xl p-3 shadow-sm border border-[#c0c8c5]/20 gap-3">
        <div className="flex items-center gap-2 overflow-x-auto">
          <button
            onClick={() => setCorridorFilter("all")}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-2 transition-colors ${
              corridorFilter === "all"
                ? "bg-[#123c35] text-white"
                : "text-[#414846] hover:bg-[#eef5f1]"
            }`}
          >
            <span>All Corridors</span>
            <span className="bg-[#006c49] px-1.5 py-0.5 rounded text-[10px] font-bold text-white">
              {buses.length || 5}
            </span>
          </button>
          <button
            onClick={() => setCorridorFilter("kaloor")}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-2 transition-colors ${
              corridorFilter === "kaloor"
                ? "bg-[#123c35] text-white"
                : "text-[#414846] hover:bg-[#eef5f1]"
            }`}
          >
            <span>Kaloor – Kakkanad (Route 12)</span>
            <span className="bg-[#e8f0ec] px-1.5 py-0.5 rounded text-[10px] font-bold text-[#414846]">
              {buses.filter((b) => b.route_number === "12").length || 2}
            </span>
          </button>
          <button
            onClick={() => setCorridorFilter("mg")}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-2 transition-colors ${
              corridorFilter === "mg"
                ? "bg-[#123c35] text-white"
                : "text-[#414846] hover:bg-[#eef5f1]"
            }`}
          >
            <span>MG Road – Vyttila (Route 14A)</span>
            <span className="bg-[#e8f0ec] px-1.5 py-0.5 rounded text-[10px] font-bold text-[#414846]">
              {buses.filter((b) => b.route_number === "14A").length || 1}
            </span>
          </button>
          <button
            onClick={() => setCorridorFilter("aluva")}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-2 transition-colors ${
              corridorFilter === "aluva"
                ? "bg-[#123c35] text-white"
                : "text-[#414846] hover:bg-[#eef5f1]"
            }`}
          >
            <span>Aluva – Vyttila (Route 205)</span>
            <span className="bg-[#e8f0ec] px-1.5 py-0.5 rounded text-[10px] font-bold text-[#414846]">
              {buses.filter((b) => b.route_number === "205").length || 2}
            </span>
          </button>
        </div>

        <div className="flex items-center gap-4 text-xs">
          <div className="flex items-center gap-1.5 text-[#414846]">
            <span className="w-2.5 h-2.5 rounded-full bg-[#006c49]" />
            <span>&lt;50% Normal</span>
          </div>
          <div className="flex items-center gap-1.5 text-[#414846]">
            <span className="w-2.5 h-2.5 rounded-full bg-[#d97706]" />
            <span>50–80% Mod</span>
          </div>
          <div className="flex items-center gap-1.5 text-[#414846]">
            <span className="w-2.5 h-2.5 rounded-full bg-[#ba1a1a]" />
            <span>&gt;80% High</span>
          </div>
        </div>
      </div>

      {/* Main Command Workspace: 70% Map / 30% Live Operations Drawer */}
      <div className="grid grid-cols-12 gap-5 w-full items-start">
        {/* Primary Map Section (col-span-8) */}
        <div className="col-span-12 xl:col-span-8 flex flex-col gap-4">
          <div className="relative w-full h-[580px] rounded-2xl bg-[#eef5f1] overflow-hidden border border-[#c0c8c5]/30 shadow-sm">
            {/* Map Vector Graphic Lines representing Kochi Corridors */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 800 580" preserveAspectRatio="none">
              {/* Corridor 1: Aluva to Vyttila */}
              <path
                d="M 680,40 Q 560,140 430,220 T 360,370 T 340,540"
                fill="none"
                stroke="#123c35"
                strokeWidth="6"
                strokeLinecap="round"
                opacity="0.7"
              />
              <path
                d="M 680,40 Q 560,140 430,220 T 360,370 T 340,540"
                fill="none"
                stroke="#c0ebe1"
                strokeWidth="2"
                strokeDasharray="6,4"
              />
              {/* Corridor 2: Kaloor to Kakkanad Infopark */}
              <path
                d="M 220,380 L 360,370 Q 480,360 620,390 L 730,420"
                fill="none"
                stroke="#006c49"
                strokeWidth="6"
                strokeLinecap="round"
                opacity="0.8"
              />
              {/* Corridor 3: MG Road to Vyttila */}
              <path
                d="M 170,490 Q 240,510 340,540"
                fill="none"
                stroke="#d97706"
                strokeWidth="5"
                strokeLinecap="round"
                opacity="0.75"
              />
              {/* Water Metro Port Channel */}
              <path
                d="M 120,300 C 140,360 160,430 180,570"
                fill="none"
                stroke="#779aff"
                strokeWidth="3"
                strokeDasharray="4,4"
                opacity="0.5"
              />
            </svg>

            {/* Interactive Transit Hub Nodes */}
            <div className="absolute top-[48px] right-[110px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="w-2.5 h-2.5 rounded bg-[#002620]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-[#161d1b]">Aluva Terminal</span>
                <span className="text-[10px] text-[#717976]">Hub #01 • Metro Feeder</span>
              </div>
            </div>

            <div className="absolute top-[215px] left-[430px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-1.5 bg-white/90 backdrop-blur px-2.5 py-1 rounded-lg shadow-sm border border-[#c0c8c5]/30">
              <span className="w-2 h-2 rounded-full bg-[#717976]" />
              <span className="text-xs font-bold text-[#161d1b]">Edappally Jn</span>
            </div>

            <div className="absolute top-[365px] left-[360px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="w-2.5 h-2.5 rounded bg-[#002620]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-[#161d1b]">Palarivattom Jn</span>
                <span className="text-[10px] text-[#ba1a1a] font-semibold">Active Detour (+8m)</span>
              </div>
            </div>

            <div className="absolute top-[380px] left-[215px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="w-2.5 h-2.5 rounded bg-[#002620]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-[#161d1b]">Kaloor Central Stand</span>
                <span className="text-[10px] text-[#717976]">Bay A/B/C Active</span>
              </div>
            </div>

            <div className="absolute top-[418px] right-[55px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="w-2.5 h-2.5 rounded bg-[#002620]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-[#161d1b]">Infopark Gate 1</span>
                <span className="text-[10px] text-[#006c49] font-semibold">Smart Clearance</span>
              </div>
            </div>

            <div className="absolute top-[535px] left-[340px] -translate-x-1/2 -translate-y-1/2 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="w-3 h-3 rounded bg-[#006c49]" />
              <div className="flex flex-col">
                <span className="text-xs font-bold text-[#161d1b]">Vyttila Mobility Hub</span>
                <span className="text-[10px] text-[#414846]">Intermodal Metro / Water Metro</span>
              </div>
            </div>

            {/* Dynamic Bus Pins on Map */}
            {buses.map((bus, idx) => {
              // Calculate deterministic positions on SVG map based on route and index
              const positions: Record<string, { top: string; left: string }> = {
                "205": { top: "320px", left: "270px" },
                "14A": { top: "140px", left: "550px" },
                "FP-102": { top: "505px", left: "245px" },
                "12": { top: "400px", left: "520px" },
              };
              const defaultPos = {
                top: `${200 + ((idx * 80) % 280)}px`,
                left: `${200 + ((idx * 120) % 400)}px`,
              };
              const pos = positions[bus.bus_number] || positions[bus.bus_code] || defaultPos;
              const isSelected =
                selectedBus.bus_code === bus.bus_code || selectedBus.bus_number === bus.bus_number;

              const crowdColor =
                bus.crowd_level === "LOW"
                  ? "#006c49"
                  : bus.crowd_level === "MODERATE"
                  ? "#d97706"
                  : "#ba1a1a";

              return (
                <div
                  key={bus.bus_id || idx}
                  style={{ top: pos.top, left: pos.left }}
                  onClick={() => setSelectedBusCode(bus.bus_code)}
                  className="absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer transition-transform hover:scale-110 z-10"
                >
                  <div className="relative flex items-center justify-center">
                    {isSelected && (
                      <span className="absolute w-8 h-8 rounded-full bg-[#6cf8bb]/50 animate-ping pointer-events-none" />
                    )}
                    <div
                      className={`px-2 py-1 rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-md border ${
                        isSelected
                          ? "bg-[#123c35] text-white border-[#6cf8bb]"
                          : "bg-white text-[#161d1b] border-[#c0c8c5]/40"
                      }`}
                    >
                      <span
                        className="w-2 h-2 rounded-full"
                        style={{ backgroundColor: crowdColor }}
                      />
                      <span>{bus.bus_number || bus.bus_code.replace("Bus ", "")}</span>
                      <span className="material-symbols-outlined text-[13px]">
                        {bus.crowd_level === "CROWDED" ? "warning" : "navigation"}
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Pinned Detail Floating Card for Selected Bus */}
            <div className="absolute bottom-16 left-6 w-72 bg-white rounded-2xl p-3.5 shadow-xl z-20 border border-[#c0c8c5]/30">
              <div className="flex items-center justify-between pb-2 mb-2 border-b border-[#eef5f1]">
                <div className="flex items-center gap-1.5">
                  <span className="px-2 py-0.5 rounded bg-[#123c35] text-white text-[11px] font-bold">
                    {selectedBus.bus_code}
                  </span>
                  <span className="text-xs font-semibold text-[#161d1b] truncate">
                    Route {selectedBus.route_number}
                  </span>
                </div>
                <div className="flex items-center gap-1 bg-[#6cf8bb] px-1.5 py-0.5 rounded text-[10px] font-bold text-[#005236]">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#006c49]" />
                  <span>SIMULATED</span>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-1.5 text-center py-1">
                <div className="bg-[#eef5f1] p-1.5 rounded-xl">
                  <span className="text-[10px] uppercase text-[#717976] block">Speed</span>
                  <span className="text-xs font-bold text-[#161d1b] tnum">
                    {selectedBus.speed_kmh ? `${selectedBus.speed_kmh.toFixed(0)} km/h` : "32 km/h"}
                  </span>
                </div>
                <div className="bg-[#eef5f1] p-1.5 rounded-xl">
                  <span className="text-[10px] uppercase text-[#717976] block">Load</span>
                  <span
                    className={`text-xs font-bold tnum ${
                      selectedBus.crowd_level === "CROWDED"
                        ? "text-[#ba1a1a]"
                        : selectedBus.crowd_level === "MODERATE"
                        ? "text-[#d97706]"
                        : "text-[#006c49]"
                    }`}
                  >
                    {(selectedBus.occupancy_percentage || selectedBus.occupancy_pct || 42).toFixed(1)}%
                  </span>
                </div>
                <div className="bg-[#eef5f1] p-1.5 rounded-xl">
                  <span className="text-[10px] uppercase text-[#717976] block">Next Bay</span>
                  <span className="text-xs font-bold text-[#161d1b] tnum">
                    {selectedBus.eta_next_stop_mins || 4} min
                  </span>
                </div>
              </div>

              <div className="mt-2 text-[11px] text-[#414846] flex items-center justify-between">
                <span>
                  Approaching: <strong>{selectedBus.next_stop || "Kaloor Stand"}</strong>
                </span>
              </div>
            </div>

            {/* Bottom Floating Map Controls */}
            <div className="absolute bottom-4 left-4 flex items-center gap-2 bg-white/90 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30">
              <span className="material-symbols-outlined text-[18px] text-[#006c49]">my_location</span>
              <span className="text-[11px] font-bold uppercase tracking-wider text-[#414846]">
                SIMULATED LIVE DATA • 5.0s SYNC • KOCHI ARTERY
              </span>
            </div>

            <div className="absolute bottom-4 right-4 bg-white/90 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm border border-[#c0c8c5]/30 flex items-center gap-2">
              <span className="material-symbols-outlined text-[#006c49] text-[18px]">routine</span>
              <span className="text-xs font-semibold text-[#161d1b]">
                Network Status: {overview?.network_status || "OPTIMAL_FLOW"}
              </span>
            </div>
          </div>

          {/* Lower Corridor Micro-Telemetry Bar */}
          <div className="grid grid-cols-3 gap-4">
            <div className="bg-white p-3.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-[#eef5f1] flex items-center justify-center text-[#002620]">
                  <span className="material-symbols-outlined text-[20px]">route</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] font-bold uppercase text-[#717976]">Corridor Avg Speed</span>
                  <span className="text-base font-bold text-[#161d1b] tnum">{avgSpeed.toFixed(1)} km/h</span>
                </div>
              </div>
              <span className="text-xs font-bold text-[#006c49]">Nominal</span>
            </div>

            <div className="bg-white p-3.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-[#eef5f1] flex items-center justify-center text-[#002620]">
                  <span className="material-symbols-outlined text-[20px]">group</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] font-bold uppercase text-[#717976]">Avg Passenger Load</span>
                  <span className="text-base font-bold text-[#161d1b] tnum">{avgOccupancy.toFixed(1)}%</span>
                </div>
              </div>
              <span className="text-xs font-semibold text-[#414846]">Safe</span>
            </div>

            <div className="bg-white p-3.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-[#eef5f1] flex items-center justify-center text-[#002620]">
                  <span className="material-symbols-outlined text-[20px]">directions_bus</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] font-bold uppercase text-[#717976]">Active Fleet Count</span>
                  <span className="text-base font-bold text-[#161d1b] tnum">
                    {buses.length || 5} Active
                  </span>
                </div>
              </div>
              <span className="text-xs font-bold text-[#006c49]">100% Sync</span>
            </div>
          </div>
        </div>

        {/* Right Operational Drawer (col-span-4) */}
        <div className="col-span-12 xl:col-span-4 flex flex-col gap-4">
          {/* Executive Snapshot Card */}
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#eef5f1]">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-[#002620] text-[20px]">equalizer</span>
                <h2 className="font-bold text-base text-[#161d1b]">Executive Snapshot</h2>
              </div>
              <span className="text-[10px] font-bold uppercase text-[#006c49]">DYNAMIC TELEMETRY</span>
            </div>

            <div className="flex flex-col divide-y divide-[#eef5f1]">
              <div className="flex items-center justify-between py-2.5">
                <span className="text-sm text-[#414846]">Active Fleet in Service</span>
                <div className="flex items-baseline gap-1">
                  <span className="text-lg font-bold text-[#161d1b] tnum">{buses.length || 5}</span>
                  <span className="text-xs text-[#717976]">buses</span>
                </div>
              </div>

              <div className="flex items-center justify-between py-2.5">
                <span className="text-sm text-[#414846]">On-Time Performance</span>
                <div className="flex items-center gap-1 text-[#006c49]">
                  <span className="text-lg font-bold tnum">
                    {overview?.on_time_reliability_pct || 94.2}%
                  </span>
                  <span className="material-symbols-outlined text-[16px]">trending_up</span>
                </div>
              </div>

              <div className="flex items-center justify-between py-2.5">
                <span className="text-sm text-[#414846]">High Crowd Vehicles</span>
                <div className="flex items-center gap-1.5">
                  <span
                    className={`w-2 h-2 rounded-full ${
                      crowdedCount > 0 ? "bg-[#ba1a1a]" : "bg-[#006c49]"
                    }`}
                  />
                  <span className="text-sm font-bold text-[#161d1b]">
                    {crowdedCount} {crowdedCount === 1 ? "Vehicle" : "Vehicles"}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between py-2.5">
                <span className="text-sm text-[#414846]">Active Advisories & Incidents</span>
                <div className="flex items-center gap-1.5">
                  <span
                    className={`w-2 h-2 rounded-full ${
                      alerts.length > 0 ? "bg-[#d97706]" : "bg-[#006c49]"
                    }`}
                  />
                  <span className="text-sm font-bold text-[#161d1b]">
                    {alerts.length || overview?.service_incidents_count || 1} Active
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Attention Required Queue */}
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#eef5f1]">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-[#ba1a1a] text-[20px]">notifications_active</span>
                <h2 className="font-bold text-base text-[#161d1b]">Attention Required</h2>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ffdad6] text-[#93000a] text-[10px] font-bold">
                {alerts.length} Active
              </span>
            </div>

            <div className="flex flex-col gap-2.5">
              {alerts.length === 0 ? (
                <div className="p-4 rounded-xl bg-[#eef5f1] text-center text-xs text-[#717976]">
                  Zero active corridor advisories or urgent hazards logged.
                </div>
              ) : (
                alerts.slice(0, 3).map((alert) => (
                  <div
                    key={alert.id}
                    className="bg-[#eef5f1] p-3 rounded-xl flex flex-col gap-1.5 border border-[#c0c8c5]/20"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <span
                          className={`w-2 h-2 rounded-full ${
                            alert.severity === "CRITICAL"
                              ? "bg-[#ba1a1a]"
                              : alert.severity === "WARNING"
                              ? "bg-[#d97706]"
                              : "bg-[#006c49]"
                          }`}
                        />
                        <span className="text-xs font-bold text-[#161d1b]">{alert.title}</span>
                      </div>
                      <span
                        className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                          alert.severity === "CRITICAL"
                            ? "bg-[#ffdad6] text-[#93000a]"
                            : "bg-[#fed7aa] text-[#9a3412]"
                        }`}
                      >
                        {alert.severity}
                      </span>
                    </div>
                    <p className="text-xs text-[#414846] leading-relaxed line-clamp-2">
                      {alert.message}
                    </p>
                    <div className="flex items-center justify-between pt-1">
                      <span className="text-[11px] text-[#717976]">
                        {alert.affected_route || "All Corridors"}
                      </span>
                      <Link
                        href="/authority/alerts"
                        className="text-xs font-bold text-[#006c49] hover:underline flex items-center gap-0.5"
                      >
                        <span>View Alert</span>
                        <span className="material-symbols-outlined text-[14px]">arrow_forward</span>
                      </Link>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
