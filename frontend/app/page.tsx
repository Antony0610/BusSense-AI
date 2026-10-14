"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, BusTelemetry } from "@/lib/api";

export default function UnifiedGateway() {
  const [buses, setBuses] = useState<BusTelemetry[]>([]);
  const [activeTab, setActiveTab] = useState<"passenger" | "driver" | "authority">("passenger");

  useEffect(() => {
    // Load live telemetry from backend
    fetchApi<BusTelemetry[]>("/buses")
      .then((data) => setBuses(data))
      .catch(() => {
        // Fallback default state
        setBuses([
          {
            bus_id: "1",
            bus_number: "205",
            registration_number: "KL-15-A-2051",
            operator_type: "KSRTC",
            route_number: "205",
            route_name: "Aluva ➔ Vyttila via Kaloor",
            capacity: 55,
            passenger_count: 23,
            occupancy_pct: 41.8,
            crowd_level: "LOW",
            speed_kmh: 34.5,
            heading_deg: 195,
            latitude: 10.0012,
            longitude: 76.3045,
            current_stop: "Palarivattom Bypass",
            next_stop: "Kaloor Metro Station",
            eta_next_stop_mins: 3,
            is_ac: false,
            safety_score: 99.2,
            data_origin: "SIMULATED DATA"
          },
          {
            bus_id: "2",
            bus_number: "14A",
            registration_number: "KL-07-CF-1402",
            operator_type: "PRIVATE",
            route_number: "14A",
            route_name: "Fort Kochi ➔ Infopark",
            capacity: 45,
            passenger_count: 39,
            occupancy_pct: 86.7,
            crowd_level: "CROWDED",
            speed_kmh: 22.0,
            heading_deg: 85,
            latitude: 9.9890,
            longitude: 76.2910,
            current_stop: "MG Road North",
            next_stop: "Kaloor Metro Station",
            eta_next_stop_mins: 6,
            is_ac: false,
            safety_score: 96.5,
            data_origin: "SIMULATED DATA"
          }
        ]);
      });
  }, []);

  return (
    <div className="min-h-screen flex flex-col bg-surface">
      {/* Top Utility Header */}
      <header className="fixed top-0 w-full z-50 bg-surface/85 backdrop-blur-xl border-b border-outline-variant/30">
        <div className="max-w-7xl mx-auto h-16 px-gutter flex items-center justify-between">
          <div className="flex items-center gap-space-sm">
            <div className="w-9 h-9 rounded-lg bg-primary-container flex items-center justify-center text-secondary-container shadow-sm">
              <span className="material-symbols-outlined text-[22px]">directions_bus</span>
            </div>
            <div className="flex flex-col">
              <div className="flex items-center gap-space-2xs">
                <span className="w-2 h-2 rounded-full bg-secondary animate-pulse"></span>
                <span className="font-label-caps text-label-caps uppercase text-secondary tracking-wider">Kochi Corridor Network</span>
              </div>
              <span className="font-title-card text-title-card text-primary font-bold leading-tight">BusSense AI</span>
            </div>
          </div>

          <div className="flex items-center gap-space-sm">
            <div className="hidden md:flex items-center gap-space-xs px-space-sm py-space-2xs rounded-full bg-surface-container text-on-surface-variant font-caption text-caption">
              <span className="material-symbols-outlined text-[15px] text-secondary">sensors</span>
              <span>YOLOv8 & GPS Live Telemetry</span>
            </div>
            <Link
              href="/roles"
              className="px-space-md py-space-xs rounded-lg bg-primary-container text-on-primary font-semibold text-sm hover:opacity-90 transition-opacity"
            >
              Select Role
            </Link>
          </div>
        </div>
      </header>

      {/* Main Hero & Role Launcher */}
      <main className="flex-1 pt-24 pb-16 px-gutter max-w-7xl mx-auto w-full flex flex-col">
        {/* Climate Intelligence Hero */}
        <section className="py-space-md border-b border-outline-variant/30">
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-space-base">
            <div>
              <div className="inline-flex items-center gap-space-2xs px-space-sm py-0.5 rounded-full bg-secondary-fixed/40 text-on-secondary-fixed font-label-caps text-label-caps uppercase mb-space-xs">
                <span>Climate-Smart Public Bus Intelligence</span>
              </div>
              <h1 className="font-headline-lg text-headline-lg md:text-[40px] md:leading-[48px] text-primary tracking-tight font-extrabold max-w-2xl">
                Quiet certainty for Kerala’s bus transit network.
              </h1>
              <p className="font-body-lg text-body-lg text-on-surface-variant mt-space-xs max-w-xl">
                Combines onboard CCTV YOLOv8 occupancy estimation, real-time GPS telemetry, and explainable recommendations.
              </p>
            </div>

            {/* Core Architectural Flow Badge */}
            <div className="bg-surface-container-low p-space-sm rounded-xl border border-outline-variant/40 flex flex-wrap items-center gap-1.5 font-label-caps text-label-caps text-on-surface-variant">
              <span className="px-2 py-1 rounded bg-white font-bold text-primary">SEE</span>
              <span>→</span>
              <span className="px-2 py-1 rounded bg-white font-bold text-primary">SENSE</span>
              <span>→</span>
              <span className="px-2 py-1 rounded bg-white font-bold text-primary">PREDICT</span>
              <span>→</span>
              <span className="px-2 py-1 rounded bg-white font-bold text-secondary">RECOMMEND</span>
              <span>→</span>
              <span className="px-2 py-1 rounded bg-white font-bold text-primary">OPTIMIZE</span>
            </div>
          </div>
        </section>

        {/* Live Corridor Snapshot Banner (Bus 205 Spotlight) */}
        <section className="my-space-base bg-primary-container text-on-primary rounded-xl p-space-base shadow-sm">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-space-sm">
            <div className="flex items-start gap-space-sm">
              <div className="w-10 h-10 rounded-lg bg-secondary-container text-on-secondary-container flex items-center justify-center shrink-0">
                <span className="material-symbols-outlined text-[24px]">alt_route</span>
              </div>
              <div>
                <div className="flex items-center gap-space-xs">
                  <span className="font-label-caps text-label-caps uppercase text-secondary-container tracking-wider">Active Recommendation</span>
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-white/10 text-white font-mono">SIMULATED DATA</span>
                </div>
                <h3 className="font-title-card text-title-card text-surface-bright mt-0.5">
                  Bus 205 (Fast Passenger) saves 12 min over Bus 14A with 40% lower crowd
                </h3>
                <p className="font-body-sm text-body-sm text-surface-bright/80 mt-0.5">
                  Currently 23/55 seats occupied (41.8% · LOW). Banerji Road dedicated priority lane operational.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-space-sm self-end md:self-center shrink-0">
              <Link
                href="/passenger/home"
                className="px-space-md py-space-xs rounded-lg bg-secondary text-white font-semibold text-sm hover:opacity-95 transition-opacity"
              >
                Launch Commuter View
              </Link>
            </div>
          </div>
        </section>

        {/* The 3 Applications Grid */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-space-base mt-space-xs">
          {/* 1. Passenger App */}
          <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/50 p-space-base flex flex-col justify-between hover:border-secondary transition-all hover:shadow-md">
            <div>
              <div className="flex items-center justify-between mb-space-sm">
                <div className="w-12 h-12 rounded-xl bg-surface-container flex items-center justify-center text-primary">
                  <span className="material-symbols-outlined text-[28px]">commute</span>
                </div>
                <span className="px-space-xs py-0.5 rounded bg-surface-container text-on-surface-variant font-label-caps text-label-caps uppercase">
                  Mobile-First
                </span>
              </div>
              <h2 className="font-headline-sm text-headline-sm text-primary font-bold">Passenger Application</h2>
              <p className="font-body-sm text-body-sm text-on-surface-variant mt-space-xs">
                Real-time departures near Kaloor Metro, predictive crowding forecast, digital QR boarding tickets, and RAG transit assistant.
              </p>
              <ul className="mt-space-sm space-y-1 font-caption text-caption text-on-surface">
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Live occupancy countdowns (tabular tnum)</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Explainable AI journey scoring</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Offline-ready QR ticket verification</span>
                </li>
              </ul>
            </div>
            <div className="mt-space-base pt-space-sm border-t border-outline-variant/30 flex items-center justify-between">
              <Link
                href="/passenger/home"
                className="w-full text-center py-space-xs rounded-lg bg-primary-container text-white font-semibold text-sm hover:opacity-90 transition-opacity"
              >
                Open Passenger App
              </Link>
            </div>
          </div>

          {/* 2. Driver / Conductor App */}
          <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/50 p-space-base flex flex-col justify-between hover:border-secondary transition-all hover:shadow-md">
            <div>
              <div className="flex items-center justify-between mb-space-sm">
                <div className="w-12 h-12 rounded-xl bg-surface-container flex items-center justify-center text-primary">
                  <span className="material-symbols-outlined text-[28px]">airline_seat_recline_normal</span>
                </div>
                <span className="px-space-xs py-0.5 rounded bg-surface-container text-on-surface-variant font-label-caps text-label-caps uppercase">
                  Mobile-First
                </span>
              </div>
              <h2 className="font-headline-sm text-headline-sm text-primary font-bold">Crew Operations Cockpit</h2>
              <p className="font-body-sm text-body-sm text-on-surface-variant mt-space-xs">
                High-contrast operational HUD for drivers and conductors. Bus 205 pairing, stop timer, camera occupancy, and ticket scanning.
              </p>
              <ul className="mt-space-sm space-y-1 font-caption text-caption text-on-surface">
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Active Trip HUD with large touch targets</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>QR validator (Valid/Used/Expired states)</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>1-tap rapid incident logging</span>
                </li>
              </ul>
            </div>
            <div className="mt-space-base pt-space-sm border-t border-outline-variant/30 flex items-center justify-between">
              <Link
                href="/driver/cockpit"
                className="w-full text-center py-space-xs rounded-lg bg-surface-container-high text-primary font-semibold text-sm hover:bg-surface-container transition-colors"
              >
                Open Driver Cockpit
              </Link>
            </div>
          </div>

          {/* 3. Authority Command Console */}
          <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/50 p-space-base flex flex-col justify-between hover:border-secondary transition-all hover:shadow-md">
            <div>
              <div className="flex items-center justify-between mb-space-sm">
                <div className="w-12 h-12 rounded-xl bg-surface-container flex items-center justify-center text-primary">
                  <span className="material-symbols-outlined text-[28px]">monitoring</span>
                </div>
                <span className="px-space-xs py-0.5 rounded bg-primary-fixed text-on-primary-fixed font-label-caps text-label-caps uppercase">
                  Desktop-First
                </span>
              </div>
              <h2 className="font-headline-sm text-headline-sm text-primary font-bold">Authority Command Center</h2>
              <p className="font-body-sm text-body-sm text-on-surface-variant mt-space-xs">
                Network-wide transit management console for transport regulators and depot officers.
              </p>
              <ul className="mt-space-sm space-y-1 font-caption text-caption text-on-surface">
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Live Fleet Tracking & Telemetry Map</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>60-Min Predictive Crowd Horizon</span>
                </li>
                <li className="flex items-center gap-space-2xs">
                  <span className="material-symbols-outlined text-secondary text-[16px]">check_circle</span>
                  <span>Human-in-the-loop AI operational queue</span>
                </li>
              </ul>
            </div>
            <div className="mt-space-base pt-space-sm border-t border-outline-variant/30 flex items-center justify-between">
              <Link
                href="/authority/command"
                className="w-full text-center py-space-xs rounded-lg bg-primary text-white font-semibold text-sm hover:opacity-90 transition-opacity"
              >
                Open Command Center
              </Link>
            </div>
          </div>
        </section>

        {/* Live Fleet Preview Table */}
        <section className="mt-space-xl">
          <div className="flex items-center justify-between mb-space-sm">
            <div>
              <h3 className="font-headline-sm text-headline-sm text-primary font-bold">Live Kerala Transit Network Status</h3>
              <p className="font-caption text-caption text-on-surface-variant">Real-time telemetry updated via WebSocket & simulated corridor engine</p>
            </div>
            <span className="px-space-sm py-space-2xs rounded-full bg-secondary-fixed/50 text-on-secondary-fixed text-caption font-semibold">
              {buses.length} Vehicles Monitored
            </span>
          </div>

          <div className="bg-surface-container-lowest rounded-xl border border-outline-variant/40 overflow-hidden shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left font-body-sm text-body-sm">
                <thead className="bg-surface-container text-on-surface-variant font-label-caps text-label-caps uppercase border-b border-outline-variant/30">
                  <tr>
                    <th className="px-space-base py-space-sm">Bus</th>
                    <th className="px-space-base py-space-sm">Operator</th>
                    <th className="px-space-base py-space-sm">Corridor</th>
                    <th className="px-space-base py-space-sm">Next Stop & ETA</th>
                    <th className="px-space-base py-space-sm">Occupancy (YOLOv8)</th>
                    <th className="px-space-base py-space-sm">Data Standard</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-outline-variant/20">
                  {buses.map((bus) => (
                    <tr key={bus.bus_number} className="hover:bg-surface-container-low transition-colors">
                      <td className="px-space-base py-space-sm font-bold text-primary">
                        <span className="inline-block px-2 py-0.5 rounded bg-primary text-white text-xs mr-2 font-mono">
                          {bus.bus_number}
                        </span>
                        {bus.registration_number}
                      </td>
                      <td className="px-space-base py-space-sm">
                        <span className="px-1.5 py-0.5 rounded text-[11px] font-semibold bg-surface-container-high text-on-surface">
                          {bus.operator_type}
                        </span>
                      </td>
                      <td className="px-space-base py-space-sm text-on-surface-variant">
                        {bus.route_name}
                      </td>
                      <td className="px-space-base py-space-sm">
                        <span className="font-semibold text-primary">{bus.next_stop}</span>
                        <span className="ml-2 font-mono text-secondary font-bold tnum">in {bus.eta_next_stop_mins}m</span>
                      </td>
                      <td className="px-space-base py-space-sm">
                        <div className="flex items-center gap-2">
                          <span
                            className={`w-2 h-2 rounded-full ${
                              bus.crowd_level === "LOW"
                                ? "bg-secondary"
                                : bus.crowd_level === "MODERATE"
                                ? "bg-amber-500"
                                : "bg-red-500"
                            }`}
                          ></span>
                          <span className="font-mono font-bold text-primary tnum">{bus.occupancy_pct}%</span>
                          <span className="text-caption text-on-surface-variant">({bus.passenger_count}/{bus.capacity})</span>
                        </div>
                      </td>
                      <td className="px-space-base py-space-sm">
                        <span className="text-[10px] px-1.5 py-0.5 rounded bg-surface-container text-on-surface-variant font-mono">
                          {bus.data_origin}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </main>

      {/* Footer with Transparency & Privacy Notice */}
      <footer className="mt-auto border-t border-outline-variant/30 py-space-base bg-surface-container-low text-on-surface-variant font-caption text-caption">
        <div className="max-w-7xl mx-auto px-gutter flex flex-col md:flex-row items-center justify-between gap-space-sm">
          <div className="flex items-center gap-space-sm">
            <span className="font-bold text-primary">BusSense AI</span>
            <span>·</span>
            <span>Kerala Transit Intelligence</span>
            <span>·</span>
            <span className="font-mono text-[11px]">Prototype Mode (Demo Data Labelled)</span>
          </div>
          <div className="flex items-center gap-space-base">
            <Link href="/architecture" className="hover:text-primary transition-colors">Architecture</Link>
            <Link href="/privacy" className="hover:text-primary transition-colors">Privacy & Vision Policy</Link>
            <span>Supabase: lqegmqgkymstycpzplld</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
