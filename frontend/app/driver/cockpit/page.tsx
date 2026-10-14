"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, BusTelemetry } from "@/lib/api";

export default function DriverCockpitPage() {
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
    <div className="bg-[#101817] text-white min-h-screen flex flex-col pb-24 font-body-md select-none">
      {/* High-Contrast Crew Top Bar */}
      <header className="fixed top-0 w-full z-50 bg-[#16201e] border-b border-white/10 px-gutter py-space-sm">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <div className="flex items-center gap-space-xs">
            <span className="w-3 h-3 rounded-full bg-emerald-400 animate-pulse"></span>
            <span className="font-bold text-xs uppercase text-emerald-400 font-mono tracking-wider">
              Shift Active · Bus 205
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[11px] text-white/60">Suresh Kumar (#402)</span>
            <Link
              href="/"
              className="text-[11px] px-2 py-0.5 rounded bg-white/10 text-white/80 hover:text-white"
            >
              Exit
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {/* Next Stop Hero Display - Extra Large for Safety */}
        <div className="bg-[#1a2825] p-space-base rounded-2xl border border-emerald-500/20 shadow-xl">
          <span className="text-xs uppercase text-emerald-400 font-bold tracking-wider block">
            Approaching Stop
          </span>
          <h1 className="text-3xl font-black text-white mt-1">
            {telemetry ? telemetry.next_stop : "Kaloor Metro Station"}
          </h1>
          <div className="flex items-center justify-between mt-space-base pt-space-sm border-t border-white/10">
            <div>
              <span className="text-xs text-white/60 block">Speed</span>
              <span className="text-2xl font-black font-mono text-emerald-400 tnum">
                {telemetry ? telemetry.speed_kmh : "34.5"} <span className="text-xs">km/h</span>
              </span>
            </div>
            <div className="text-right">
              <span className="text-xs text-white/60 block">Stop ETA</span>
              <span className="text-3xl font-black font-mono text-white tnum">
                {telemetry ? telemetry.eta_next_stop_mins : "3"} <span className="text-sm">min</span>
              </span>
            </div>
          </div>
        </div>

        {/* Live Passenger Count & Occupancy Status */}
        <div className="bg-[#16201e] p-space-base rounded-2xl border border-white/10 flex items-center justify-between">
          <div>
            <span className="text-xs uppercase text-white/60 font-semibold block">Cabin Density</span>
            <div className="flex items-baseline gap-2 mt-1">
              <span className="text-4xl font-black text-white font-mono tnum">
                {telemetry ? telemetry.passenger_count : "23"}
              </span>
              <span className="text-sm text-white/60 font-mono">/ 55 seats</span>
            </div>
            <span className="inline-block mt-1 px-2 py-0.5 rounded text-[11px] font-bold bg-emerald-500/20 text-emerald-300">
              {telemetry ? telemetry.crowd_level : "LOW"} · Seats Available
            </span>
          </div>

          <div className="w-20 h-20 rounded-full border-4 border-emerald-500 flex flex-col items-center justify-center">
            <span className="text-lg font-black font-mono text-white tnum">
              {telemetry ? telemetry.occupancy_pct : "41.8"}%
            </span>
            <span className="text-[9px] text-white/60 font-semibold uppercase">Capacity</span>
          </div>
        </div>

        {/* Rapid Action Buttons (Extra Large Touch Targets) */}
        <div className="grid grid-cols-2 gap-space-sm pt-space-xs">
          <Link
            href="/driver/validator"
            className="p-space-base bg-emerald-700 hover:bg-emerald-600 rounded-2xl flex flex-col items-center justify-center gap-2 shadow-lg transition-transform active:scale-95"
          >
            <span className="material-symbols-outlined text-[36px]">qr_code_scanner</span>
            <span className="font-bold text-sm">Validate Tickets</span>
          </Link>

          <Link
            href="/driver/incident"
            className="p-space-base bg-amber-700/80 hover:bg-amber-600 rounded-2xl flex flex-col items-center justify-center gap-2 shadow-lg transition-transform active:scale-95"
          >
            <span className="material-symbols-outlined text-[36px]">report_problem</span>
            <span className="font-bold text-sm">Report Incident</span>
          </Link>
        </div>

        {/* Layover & Shift Info */}
        <div className="p-space-base bg-[#16201e] rounded-xl border border-white/10 flex items-center justify-between text-xs text-white/70">
          <div>
            <span className="font-bold text-white block">Next Layover: Vyttila Hub</span>
            <span>Scheduled at 09:15 AM (15 min break)</span>
          </div>
          <Link
            href="/driver/layover"
            className="px-3 py-1.5 rounded-lg bg-white/10 text-white font-semibold hover:bg-white/20 transition-colors"
          >
            Complete Trip
          </Link>
        </div>
      </main>

      {/* Driver Bottom Bar */}
      <nav className="fixed bottom-0 w-full z-50 bg-[#16201e] border-t border-white/10 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link href="/driver/cockpit" className="flex flex-col items-center gap-1 text-emerald-400 font-bold">
            <span className="material-symbols-outlined text-[24px]">speed</span>
            <span className="text-[11px]">Cockpit</span>
          </Link>
          <Link href="/driver/validator" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">qr_code_scanner</span>
            <span className="text-[11px]">Scanner</span>
          </Link>
          <Link href="/driver/incident" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">warning</span>
            <span className="text-[11px]">Incident</span>
          </Link>
          <Link href="/driver/layover" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">flag</span>
            <span className="text-[11px]">End Trip</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
