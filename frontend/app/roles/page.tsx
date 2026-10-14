"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { switchDemoRole } from "@/lib/api";

export default function RoleSelectionPage() {
  const router = useRouter();
  const [selectedRole, setSelectedRole] = useState<"passenger" | "authority" | "driver">("passenger");
  const [isLoading, setIsLoading] = useState(false);

  const roleMeta = {
    passenger: {
      name: "Passenger",
      buttonText: "Continue to Passenger Portal",
      path: "/passenger/home",
    },
    authority: {
      name: "Transport Authority & Ops",
      buttonText: "Open Authority Command Center",
      path: "/authority/command",
    },
    driver: {
      name: "Driver & Conductor",
      buttonText: "Launch Driver Cockpit HUD",
      path: "/driver/cockpit",
    },
  };

  const handleContinue = async () => {
    setIsLoading(true);
    try {
      await switchDemoRole(selectedRole);
    } catch (err) {
      console.warn("Demo role session switch fallback:", err);
    } finally {
      setIsLoading(false);
      router.push(roleMeta[selectedRole].path);
    }
  };

  return (
    <div className="bg-[#f3fbf7] text-[#161d1b] antialiased min-h-screen flex flex-col font-sans pb-10">
      {/* Header */}
      <header className="sticky top-0 w-full z-50 bg-[#f3fbf7]/80 backdrop-blur-xl border-b border-[#c0c8c5]/30">
        <div className="h-16 px-4 max-w-xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Link
              href="/"
              className="w-10 h-10 flex items-center justify-center rounded-xl text-[#002620] hover:bg-[#e8f0ec] active:scale-95 transition-all"
            >
              <span className="material-symbols-outlined text-[24px]">arrow_back</span>
            </Link>
            <div className="flex items-center gap-2">
              <span className="font-bold text-base text-[#002620] tracking-tight">BusSense AI</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[11px] font-bold text-[#414846] uppercase tracking-wider hidden sm:inline-block">
              Role Selection
            </span>
            <div className="w-8 h-8 rounded-full bg-[#002620] flex items-center justify-center shadow-sm text-white">
              <span className="material-symbols-outlined text-[18px]">person</span>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex flex-col max-w-xl mx-auto w-full px-4 pt-6 gap-6">
        {/* Editorial Header */}
        <div className="flex flex-col gap-1.5">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-[#006c49]" />
            <span className="text-[11px] font-bold text-[#006c49] tracking-wider uppercase">
              ACCESS PORTAL • KERALA TRANSIT
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#002620] tracking-tight">Select your transit workspace.</h1>
          <p className="text-sm text-[#414846] leading-relaxed">
            Choose your role to access personalized routing, cockpit telemetry, or network command tools.
          </p>
        </div>

        {/* Role Cards List */}
        <div className="flex flex-col gap-3" role="radiogroup">
          {/* Option 1: Passenger */}
          <div
            onClick={() => setSelectedRole("passenger")}
            className={`role-card relative cursor-pointer rounded-2xl bg-white p-4 shadow-sm border transition-all duration-200 select-none overflow-hidden ${
              selectedRole === "passenger" ? "border-[#006c49] ring-2 ring-[#006c49]/20" : "border-[#c0c8c5]/30 hover:border-[#006c49]/40"
            }`}
          >
            {selectedRole === "passenger" && (
              <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#006c49]" />
            )}
            <div className="flex items-start justify-between gap-2 pl-2">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center transition-colors ${
                    selectedRole === "passenger" ? "bg-[#e8f0ec] text-[#002620]" : "bg-[#eef5f1] text-[#414846]"
                  }`}
                >
                  <span className="material-symbols-outlined text-[22px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                    directions_bus
                  </span>
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-[#002620] text-base">Passenger</span>
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#6cf8bb] text-[#005236]">
                      Mobile First
                    </span>
                  </div>
                  <span className="text-xs text-[#414846]">Consumer Mobility</span>
                </div>
              </div>
              <div
                className={`w-5 h-5 rounded-full flex items-center justify-center text-white transition-all shadow-sm ${
                  selectedRole === "passenger" ? "bg-[#006c49]" : "bg-[#e8f0ec] text-transparent"
                }`}
              >
                <span className="material-symbols-outlined text-[14px] font-bold">check</span>
              </div>
            </div>
            <p className="text-xs text-[#161d1b] mt-3 pl-2">
              Real-time bus tracking, crowd forecasting, digital QR booking, and intelligent AI journey planning across Kerala.
            </p>
            <div className="mt-3 pl-2 pt-2 border-t border-[#eef5f1] flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-[#006c49]">bolt</span>
              <span className="text-xs font-semibold text-[#002620] truncate">Live ETAs • Seat Availability • Easy Booking</span>
            </div>
          </div>

          {/* Option 2: Transport Authority & Ops */}
          <div
            onClick={() => setSelectedRole("authority")}
            className={`role-card relative cursor-pointer rounded-2xl bg-white p-4 shadow-sm border transition-all duration-200 select-none overflow-hidden ${
              selectedRole === "authority" ? "border-[#006c49] ring-2 ring-[#006c49]/20" : "border-[#c0c8c5]/30 hover:border-[#006c49]/40"
            }`}
          >
            {selectedRole === "authority" && (
              <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#006c49]" />
            )}
            <div className="flex items-start justify-between gap-2 pl-2">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center transition-colors ${
                    selectedRole === "authority" ? "bg-[#e8f0ec] text-[#002620]" : "bg-[#eef5f1] text-[#414846]"
                  }`}
                >
                  <span className="material-symbols-outlined text-[22px]">radar</span>
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-[#002620] text-base">Transport Authority & Ops</span>
                  </div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-xs text-[#414846]">Regional Operations</span>
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#e8f0ec] text-[#414846]">
                      Command Center
                    </span>
                  </div>
                </div>
              </div>
              <div
                className={`w-5 h-5 rounded-full flex items-center justify-center text-white transition-all shadow-sm ${
                  selectedRole === "authority" ? "bg-[#006c49]" : "bg-[#e8f0ec] text-transparent"
                }`}
              >
                <span className="material-symbols-outlined text-[14px] font-bold">check</span>
              </div>
            </div>
            <p className="text-xs text-[#414846] mt-3 pl-2">
              Regional fleet orchestration, AI-driven surge dispatch, bottleneck mitigation, and human-in-the-loop decision queue.
            </p>
            <div className="mt-3 pl-2 pt-2 border-t border-[#eef5f1] flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-[#717976]">hub</span>
              <span className="text-xs font-semibold text-[#414846] truncate">
                Fleet monitoring • Congestion alerts • Operational decisions
              </span>
            </div>
          </div>

          {/* Option 3: Driver & Conductor */}
          <div
            onClick={() => setSelectedRole("driver")}
            className={`role-card relative cursor-pointer rounded-2xl bg-white p-4 shadow-sm border transition-all duration-200 select-none overflow-hidden ${
              selectedRole === "driver" ? "border-[#006c49] ring-2 ring-[#006c49]/20" : "border-[#c0c8c5]/30 hover:border-[#006c49]/40"
            }`}
          >
            {selectedRole === "driver" && (
              <div className="absolute left-0 top-0 bottom-0 w-1.5 bg-[#006c49]" />
            )}
            <div className="flex items-start justify-between gap-2 pl-2">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center transition-colors ${
                    selectedRole === "driver" ? "bg-[#e8f0ec] text-[#002620]" : "bg-[#eef5f1] text-[#414846]"
                  }`}
                >
                  <span className="material-symbols-outlined text-[22px]">sports_motorsports</span>
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-[#002620] text-base">Driver & Conductor</span>
                  </div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-xs text-[#414846]">Onboard Terminal</span>
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#e8f0ec] text-[#414846]">
                      Vehicle Cockpit
                    </span>
                  </div>
                </div>
              </div>
              <div
                className={`w-5 h-5 rounded-full flex items-center justify-center text-white transition-all shadow-sm ${
                  selectedRole === "driver" ? "bg-[#006c49]" : "bg-[#e8f0ec] text-transparent"
                }`}
              >
                <span className="material-symbols-outlined text-[14px] font-bold">check</span>
              </div>
            </div>
            <p className="text-xs text-[#414846] mt-3 pl-2">
              One-handed active trip HUD, automated stop progression, rapid hazard reporting, and high-speed QR ticket scanner.
            </p>
            <div className="mt-3 pl-2 pt-2 border-t border-[#eef5f1] flex items-center gap-2">
              <span className="material-symbols-outlined text-[16px] text-[#717976]">speed</span>
              <span className="text-xs font-semibold text-[#414846] truncate">
                Trip HUD • Stop progression • Fast QR scanner
              </span>
            </div>
          </div>
        </div>

        {/* Action Button */}
        <div className="flex flex-col gap-3 pt-2">
          <button
            onClick={handleContinue}
            className="w-full bg-[#123c35] text-white py-4 px-6 rounded-2xl font-bold text-base flex items-center justify-center gap-2 shadow-md active:scale-[0.985] hover:bg-[#002620] transition-all"
            type="button"
          >
            <span>{roleMeta[selectedRole].buttonText}</span>
            <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
          </button>
          <p className="text-xs text-center text-[#414846] flex items-center justify-center gap-1.5">
            <span className="material-symbols-outlined text-[14px]">info</span>
            <span>Switch roles anytime from the top bar or home screen.</span>
          </p>
        </div>
      </main>
    </div>
  );
}
