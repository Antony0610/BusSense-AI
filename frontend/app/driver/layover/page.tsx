"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function DriverLayoverPage() {
  const router = useRouter();
  const [cabinChecked, setCabinChecked] = useState(true);
  const [ticketsChecked, setTicketsChecked] = useState(true);
  const [stagedChecked, setStagedChecked] = useState(true);
  const [restMinutes, setRestMinutes] = useState(17);

  return (
    <div className="bg-[#f3fbf7] min-h-screen text-[#161d1b] flex flex-col font-sans pb-12">
      {/* Top Header */}
      <header className="sticky top-0 w-full z-40 bg-[#f3fbf7]/90 backdrop-blur-xl border-b border-[#c0c8c5]/30">
        <div className="h-16 px-4 flex items-center justify-between gap-2 max-w-xl mx-auto">
          <div className="flex items-center gap-2">
            <button
              onClick={() => router.back()}
              aria-label="Navigate back"
              className="w-10 h-10 flex items-center justify-center rounded-xl text-[#161d1b] hover:bg-[#eef5f1] transition-colors"
            >
              <span className="material-symbols-outlined text-[24px]">arrow_back</span>
            </button>
            <div className="flex flex-col min-w-0">
              <span className="font-bold text-base text-[#161d1b] leading-tight">Trip Completion</span>
              <span className="text-xs text-[#414846]">BusSense Crew Operations</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Link
              href="/roles"
              className="px-2.5 py-1 text-xs rounded-full bg-[#e8f0ec] text-[#006c49] font-semibold border border-[#006c49]/20 hover:bg-[#dce4e0]"
            >
              Switch Role
            </Link>
            <div className="w-8 h-8 rounded-full bg-[#002620] flex items-center justify-center text-white">
              <span className="material-symbols-outlined text-[18px]">person</span>
            </div>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 flex flex-col max-w-xl mx-auto w-full p-4 gap-4">
        {/* Hero Celebration Banner */}
        <div className="relative overflow-hidden rounded-2xl bg-[#123c35] text-white p-5 shadow-sm">
          <div className="absolute -right-6 -bottom-6 w-36 h-36 rounded-full bg-[#006c49]/30 pointer-events-none blur-2xl" />
          <div className="flex items-center gap-3 mb-2">
            <div className="w-12 h-12 rounded-full bg-[#6cf8bb] text-[#00714d] flex items-center justify-center shrink-0 shadow-sm">
              <span className="material-symbols-outlined text-[28px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                check_circle
              </span>
            </div>
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="inline-block w-2 h-2 rounded-full bg-[#6ffbbe] animate-pulse" />
                <span className="text-[10px] font-bold text-[#6ffbbe] tracking-wider uppercase">
                  Trip Complete • SIMULATED DATA
                </span>
              </div>
              <h2 className="text-2xl font-bold tracking-tight">Trip Complete</h2>
            </div>
          </div>
          <div className="mt-1 flex flex-col gap-0.5">
            <p className="text-base text-[#6cf8bb] font-semibold">✓ Inbound Trip Finished</p>
            <p className="text-sm text-[#a5cfc5]">Bus 205 • Route 12 arrived safely at Kakkanad Infopark Phase 2</p>
          </div>
          <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between text-[#a5cfc5] text-xs">
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px] text-[#6ffbbe]">verified</span>
              Logged to Local Operations Session
            </span>
            <span className="font-semibold text-white tnum">15:03 IST</span>
          </div>
        </div>

        {/* Shift Trip Performance Bento */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold text-[#414846] uppercase tracking-wider">Trip Performance Summary</span>
            <span className="text-xs text-[#006c49] font-semibold">Service ID #8841-A</span>
          </div>
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-3">
            {/* Route Banner Line */}
            <div className="flex items-center justify-between gap-2 bg-[#eef5f1] p-3 rounded-xl">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-10 h-10 rounded-lg bg-[#002620] text-white flex items-center justify-center font-bold text-lg shrink-0">
                  12
                </div>
                <div className="flex flex-col min-w-0">
                  <span className="font-semibold text-[#161d1b] truncate text-sm">Kaloor ⇄ Infopark Phase 2</span>
                  <span className="text-xs text-[#414846]">Via Palarivattom Bypass</span>
                </div>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#e8f0ec] text-[#161d1b] text-[10px] font-bold uppercase tracking-wider shrink-0">
                EXPRESS
              </span>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-2 gap-2">
              <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                <span className="text-xs text-[#414846] flex items-center gap-1">
                  <span className="material-symbols-outlined text-[15px] text-[#006c49]">schedule</span> Elapsed Duration
                </span>
                <span className="text-lg font-bold text-[#161d1b] mt-1 tnum">48 min</span>
                <span className="text-[11px] text-[#414846]">14:15 – 15:03 IST</span>
              </div>
              <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                <span className="text-xs text-[#414846] flex items-center gap-1">
                  <span className="material-symbols-outlined text-[15px] text-[#006c49]">timelapse</span> Schedule Delta
                </span>
                <span className="text-lg font-bold text-[#006c49] mt-1 tnum">+2 min</span>
                <span className="text-[11px] text-[#005236]">Within on-time threshold</span>
              </div>
            </div>

            {/* Passenger & Crowding Telemetry */}
            <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <span className="material-symbols-outlined text-[18px] text-[#002620]">groups</span>
                  <span className="text-sm font-semibold text-[#161d1b]">Total Passengers</span>
                </div>
                <span className="text-sm font-bold text-[#002620] tnum">~68 (PREDICTION)</span>
              </div>
              {/* Visual Crowd Meter */}
              <div className="flex flex-col gap-1">
                <div className="flex items-center justify-between text-xs text-[#414846]">
                  <span>Peak: 84% at Palarivattom</span>
                  <span className="text-[#006c49] font-semibold">Capacity Safe</span>
                </div>
                <div className="w-full h-2 rounded-full bg-[#e8f0ec] flex gap-1 overflow-hidden p-0.5">
                  <div className="h-full rounded-full bg-[#006c49] flex-1" />
                  <div className="h-full rounded-full bg-[#006c49] flex-1" />
                  <div className="h-full rounded-full bg-[#4edea3] flex-1" />
                  <div className="h-full rounded-full bg-[#dce4e0] flex-1" />
                </div>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-[#dce4e0] text-xs">
                <span className="text-[#414846] flex items-center gap-1">
                  <span className="material-symbols-outlined text-[16px] text-[#006c49]">qr_code_scanner</span>
                  Validated Tickets
                </span>
                <span className="font-semibold text-[#161d1b]">52 Validated Passes</span>
              </div>
            </div>
          </div>
        </div>

        {/* Turnaround Staging Status */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold text-[#414846] uppercase tracking-wider">Turnaround Staging</span>
            <span className="inline-flex items-center gap-1 text-xs text-[#006c49] font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-[#006c49] animate-pulse" /> Gate Active
            </span>
          </div>
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-3">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-[#e8f0ec] flex items-center justify-center text-[#002620] shrink-0">
                  <span className="material-symbols-outlined text-[26px]">local_parking</span>
                </div>
                <div className="flex flex-col min-w-0">
                  <span className="text-[10px] font-bold text-[#414846] uppercase tracking-wider">Dock Location</span>
                  <span className="text-base font-bold text-[#161d1b] truncate">Bay 4 (Turnaround Deck)</span>
                  <span className="text-xs text-[#414846]">Infopark Phase 2 Transit Terminal</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#eef5f1]">
              <div className="flex flex-col">
                <span className="text-xs text-[#414846]">Next Outbound Run</span>
                <span className="text-2xl font-black text-[#002620] mt-1 tnum">15:20</span>
                <span className="text-xs text-[#414846]">To Kaloor Stand</span>
              </div>
              <div className="flex flex-col justify-center items-start pl-3 bg-[#eef5f1] rounded-xl p-2">
                <span className="text-xs text-[#005236] font-semibold flex items-center gap-1">
                  <span className="material-symbols-outlined text-[16px] text-[#006c49]">hourglass_top</span>
                  Rest Window
                </span>
                <span className="text-lg font-bold text-[#006c49] tnum">{restMinutes} mins</span>
                <span className="text-[11px] text-[#414846]">Crew layover active</span>
              </div>
            </div>
          </div>
        </div>

        {/* Crew Post-Trip Checklist */}
        <div className="flex flex-col gap-2">
          <span className="text-xs font-bold text-[#414846] uppercase tracking-wider px-1">
            Hand-Off & Inspection Confirmation
          </span>
          <div className="bg-white rounded-2xl p-4 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-2">
            <label className="flex items-center gap-3 p-3 rounded-xl bg-[#eef5f1] cursor-pointer hover:bg-[#e8f0ec] transition-colors">
              <input
                type="checkbox"
                checked={cabinChecked}
                onChange={(e) => setCabinChecked(e.target.checked)}
                className="w-5 h-5 rounded accent-[#002620] cursor-pointer shrink-0"
              />
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold text-[#161d1b]">Cabin sweep complete</span>
                <span className="text-xs text-[#414846]">Zero passenger belongings detected in overhead or seats</span>
              </div>
            </label>

            <label className="flex items-center gap-3 p-3 rounded-xl bg-[#eef5f1] cursor-pointer hover:bg-[#e8f0ec] transition-colors">
              <input
                type="checkbox"
                checked={ticketsChecked}
                onChange={(e) => setTicketsChecked(e.target.checked)}
                className="w-5 h-5 rounded accent-[#002620] cursor-pointer shrink-0"
              />
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold text-[#161d1b]">Ticket count reconciled</span>
                <span className="text-xs text-[#414846]">52 validations match corridor run record</span>
              </div>
            </label>

            <label className="flex items-center gap-3 p-3 rounded-xl bg-[#eef5f1] cursor-pointer hover:bg-[#e8f0ec] transition-colors">
              <input
                type="checkbox"
                checked={stagedChecked}
                onChange={(e) => setStagedChecked(e.target.checked)}
                className="w-5 h-5 rounded accent-[#002620] cursor-pointer shrink-0"
              />
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold text-[#161d1b]">Vehicle staged for outbound</span>
                <span className="text-xs text-[#414846]">Destination board set to Route 12: Kaloor Stand via Bypass</span>
              </div>
            </label>
          </div>
        </div>

        {/* Crew Actions */}
        <div className="flex flex-col gap-2 pt-2">
          <button
            onClick={() => router.push("/driver/cockpit")}
            className="w-full h-14 rounded-2xl bg-[#002620] text-white font-semibold text-base flex items-center justify-center gap-2 shadow-md active:scale-[0.985] hover:bg-[#123c35] transition-all"
            type="button"
          >
            <span>Prepare Next Trip (15:20 Departure)</span>
            <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
          </button>

          <Link
            href="/roles"
            className="w-full h-12 rounded-2xl bg-white text-[#161d1b] font-semibold text-sm flex items-center justify-center gap-2 shadow-sm border border-[#c0c8c5]/30 hover:bg-[#eef5f1] transition-colors"
          >
            <span className="material-symbols-outlined text-[20px] text-[#717976]">power_settings_new</span>
            <span>End Duty Shift & Check Out</span>
          </Link>
        </div>

        {/* Simulation Integrity Badge */}
        <div className="p-3 rounded-xl bg-[#e8f0ec] flex items-start gap-2 text-[#414846] mt-2">
          <span className="material-symbols-outlined text-[18px] text-[#717976] shrink-0 mt-0.5">terminal</span>
          <p className="text-xs leading-tight">
            <strong className="font-semibold text-[#161d1b]">SIMULATED TRIP LOG:</strong> Trip telemetry and passenger
            estimates stored for demonstration purposes. Connected to Supabase project lqegmqgkymstycpzplld.
          </p>
        </div>
      </main>
    </div>
  );
}
