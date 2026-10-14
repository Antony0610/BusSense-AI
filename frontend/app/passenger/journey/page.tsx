"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, BusTelemetry } from "@/lib/api";

export default function ActiveJourneyHud() {
  const [telemetry, setTelemetry] = useState<BusTelemetry | null>(null);

  useEffect(() => {
    const load = () => {
      fetchApi<BusTelemetry>("/buses/205")
        .then((data) => setTelemetry(data))
        .catch(() => {});
    };
    load();
    const interval = setInterval(load, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="bg-surface font-body-md text-on-surface min-h-screen flex flex-col pb-24 selection:bg-secondary-fixed selection:text-on-secondary-fixed">
      {/* Top HUD Header */}
      <header className="fixed top-0 w-full z-50 bg-primary-container text-white py-space-sm px-gutter border-b border-secondary/20 shadow-md">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-secondary animate-pulse"></span>
            <span className="font-label-caps uppercase text-secondary-container tracking-wider text-xs">
              Active Onboard Journey
            </span>
          </div>
          <span className="text-[10px] px-2 py-0.5 rounded bg-white/10 font-mono">SIMULATED GPS</span>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {/* Prime HUD Card */}
        <section className="bg-primary-container text-white p-space-base rounded-2xl shadow-lg border border-secondary/30">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="bg-secondary text-white font-mono font-bold text-xl px-3 py-1 rounded-lg">
                205
              </span>
              <div>
                <span className="font-title-card text-title-card font-bold text-white block">
                  KSRTC Fast Passenger
                </span>
                <span className="text-xs text-secondary-container font-medium">
                  Priority Transit Lane Active
                </span>
              </div>
            </div>
            <div className="text-right">
              <span className="text-xs text-surface-bright/70 uppercase">Speed</span>
              <div className="text-xl font-bold font-mono text-secondary-container tnum">
                {telemetry ? telemetry.speed_kmh : "34.5"} <span className="text-xs">km/h</span>
              </div>
            </div>
          </div>

          <div className="my-space-base p-space-base bg-black/20 rounded-xl flex items-center justify-between">
            <div>
              <span className="text-xs text-secondary-container uppercase font-semibold">Next Approaching Stop</span>
              <h2 className="text-2xl font-black text-white mt-0.5">
                {telemetry ? telemetry.next_stop : "Kaloor Metro Station"}
              </h2>
            </div>
            <div className="text-right">
              <span className="text-xs text-surface-bright/70 block">Arriving In</span>
              <span className="text-3xl font-black text-secondary-container font-mono tnum">
                {telemetry ? telemetry.eta_next_stop_mins : "3"} <span className="text-sm">min</span>
              </span>
            </div>
          </div>

          {/* Occupancy telemetry row */}
          <div className="flex items-center justify-between pt-space-xs text-xs text-surface-bright/90">
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[18px] text-secondary">airline_seat_recline_normal</span>
              <span>
                Cabin Occupancy: <strong className="text-white">{telemetry ? telemetry.passenger_count : "23"}/55</strong> (42%)
              </span>
            </div>
            <span className="px-2 py-0.5 rounded-full bg-secondary text-white font-bold text-[10px]">
              LOW CROWD
            </span>
          </div>
        </section>

        {/* Route Progress Visual Line */}
        <section className="bg-surface-container-lowest p-space-base rounded-2xl border border-outline-variant/40 shadow-sm">
          <h3 className="font-title-card text-title-card text-primary font-bold mb-space-base">
            Corridor Progress
          </h3>

          <div className="space-y-space-base pl-2">
            {[
              { name: "Aluva Metro Station", passed: true, time: "08:15" },
              { name: "Kalamassery Premier Jn", passed: true, time: "08:27" },
              { name: "Edappally Toll & Lulu Hub", passed: true, time: "08:36" },
              { name: "Palarivattom Bypass", passed: true, time: "08:43" },
              { name: "Kaloor Metro Station", current: true, time: "08:49" },
              { name: "Vyttila Mobility Hub", terminal: true, time: "09:03" }
            ].map((st, i) => (
              <div key={i} className="flex items-start gap-space-base relative">
                <div className="flex flex-col items-center">
                  <div
                    className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                      st.current
                        ? "bg-secondary border-primary-container scale-125 ring-4 ring-secondary/20"
                        : st.passed
                        ? "bg-primary border-primary"
                        : "bg-surface border-outline-variant"
                    }`}
                  >
                    {st.passed && <span className="material-symbols-outlined text-white text-[10px]">check</span>}
                  </div>
                  {i < 5 && <div className={`w-0.5 h-8 ${st.passed ? "bg-primary" : "bg-outline-variant"}`}></div>}
                </div>

                <div className="flex-1 flex items-center justify-between -mt-0.5">
                  <div>
                    <span className={`text-sm ${st.current ? "font-bold text-primary" : st.passed ? "text-on-surface-variant" : "text-outline"}`}>
                      {st.name}
                    </span>
                    {st.current && (
                      <span className="block text-[11px] text-secondary font-bold">● Vehicle approaching platform</span>
                    )}
                  </div>
                  <span className="text-xs font-mono text-on-surface-variant">{st.time}</span>
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Bottom Nav */}
      <nav className="fixed bottom-0 w-full z-50 bg-surface/90 backdrop-blur-xl border-t border-outline-variant/40 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link href="/passenger/home" className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
            <span className="material-symbols-outlined text-[24px]">departure_board</span>
            <span className="font-caption text-[11px]">Departures</span>
          </Link>
          <Link href="/passenger/explore" className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
            <span className="material-symbols-outlined text-[24px]">explore</span>
            <span className="font-caption text-[11px]">Explore</span>
          </Link>
          <Link href="/passenger/assistant" className="flex flex-col items-center gap-1 text-secondary hover:opacity-80 transition-opacity">
            <div className="w-10 h-10 -mt-5 rounded-full bg-primary-container text-secondary-container flex items-center justify-center shadow-md">
              <span className="material-symbols-outlined text-[22px]">smart_toy</span>
            </div>
            <span className="font-caption text-[11px] font-semibold">AI Assistant</span>
          </Link>
          <Link href="/passenger/tickets" className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
            <span className="material-symbols-outlined text-[24px]">confirmation_number</span>
            <span className="font-caption text-[11px]">Tickets</span>
          </Link>
          <Link href="/passenger/journey" className="flex flex-col items-center gap-1 text-primary font-bold">
            <span className="material-symbols-outlined text-[24px]">navigation</span>
            <span className="font-caption text-[11px]">HUD</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
