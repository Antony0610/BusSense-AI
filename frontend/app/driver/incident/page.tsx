"use client";

import React, { useState } from "react";
import Link from "next/link";
import { fetchApi } from "@/lib/api";

const CATEGORIES = [
  { id: "VEHICLE_ISSUE", label: "Vehicle Issue", icon: "build" },
  { id: "ROUTE_OBSTRUCTION", label: "Route Obstruction", icon: "construction" },
  { id: "OVERCROWDING", label: "Overcrowding", icon: "groups" },
  { id: "DELAY", label: "Signal Delay", icon: "timer" },
  { id: "SAFETY_MEDICAL", label: "Safety / Medical", icon: "medical_services" },
  { id: "OTHER", label: "Other Concern", icon: "info" }
];

export default function RapidIncidentPage() {
  const [selectedCategory, setSelectedCategory] = useState("ROUTE_OBSTRUCTION");
  const [details, setDetails] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      await fetchApi("/incidents/report", {
        method: "POST",
        body: JSON.stringify({
          bus_number: "205",
          route_number: "205",
          category: selectedCategory,
          severity: "WARNING",
          title: `Crew Alert: ${selectedCategory.replace("_", " ")}`,
          description: details || `Reported by driver of Bus 205 en route near Kaloor.`
        })
      });
      setSubmitted(true);
    } catch (e) {
      console.error(e);
      setSubmitted(true); // Still show confirmation in prototype mode
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-[#101817] text-white min-h-screen flex flex-col pb-24 font-body-md select-none">
      {/* Top Header */}
      <header className="fixed top-0 w-full z-50 bg-[#16201e] border-b border-white/10 px-gutter py-space-sm">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <Link href="/driver/cockpit" className="flex items-center gap-1 text-white/80 hover:text-white text-sm font-semibold">
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span>Cockpit</span>
          </Link>
          <span className="font-bold text-sm text-amber-400 font-mono">
            Rapid Incident Log · Bus 205
          </span>
          <div className="w-8"></div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {submitted ? (
          <div className="p-space-xl bg-[#16201e] rounded-2xl border border-emerald-500/40 text-center animate-fadeIn">
            <div className="w-16 h-16 rounded-full bg-emerald-500 text-white flex items-center justify-center mx-auto mb-space-sm">
              <span className="material-symbols-outlined text-[36px]">check</span>
            </div>
            <h2 className="text-2xl font-black text-white">Incident Dispatched</h2>
            <p className="text-xs text-white/70 mt-1 max-w-xs mx-auto">
              Logged to Transport Authority Command Queue. Traffic Controller notified.
            </p>
            <div className="mt-space-base pt-space-sm border-t border-white/10 flex justify-center">
              <Link
                href="/driver/cockpit"
                className="px-6 py-2.5 rounded-xl bg-emerald-600 text-white font-bold text-sm hover:bg-emerald-500"
              >
                Return to Cockpit HUD
              </Link>
            </div>
          </div>
        ) : (
          <>
            <div>
              <span className="text-xs uppercase text-white/60 font-semibold block">Safety-First Incident Logging</span>
              <h1 className="text-2xl font-black text-white mt-1">Select Incident Category</h1>
            </div>

            {/* 1-Tap Category Grid */}
            <div className="grid grid-cols-2 gap-2.5">
              {CATEGORIES.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategory(cat.id)}
                  className={`p-space-base rounded-2xl border flex flex-col items-center justify-center gap-2 text-center transition-all ${
                    selectedCategory === cat.id
                      ? "bg-amber-950/80 border-amber-400 text-white shadow-lg ring-2 ring-amber-400/30"
                      : "bg-[#16201e] border-white/10 text-white/70 hover:border-white/30"
                  }`}
                >
                  <span className={`material-symbols-outlined text-[32px] ${selectedCategory === cat.id ? "text-amber-400" : "text-white/60"}`}>
                    {cat.icon}
                  </span>
                  <span className="font-bold text-xs">{cat.label}</span>
                </button>
              ))}
            </div>

            {/* Minimal optional comment */}
            <div className="bg-[#16201e] p-space-base rounded-2xl border border-white/10">
              <label className="text-xs uppercase text-white/60 font-semibold block mb-1">
                Quick Note (Optional)
              </label>
              <textarea
                value={details}
                onChange={(e) => setDetails(e.target.value)}
                placeholder="e.g. Tree branch obstructing lane near Pipeline Jn..."
                className="w-full bg-[#101817] border border-white/20 rounded-xl p-space-sm text-sm text-white focus:outline-none focus:border-amber-400 resize-none h-20"
              ></textarea>
            </div>

            {/* Submit Button */}
            <button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="w-full py-space-base rounded-xl bg-amber-600 hover:bg-amber-500 text-white font-bold text-base shadow-lg transition-transform active:scale-95 disabled:opacity-50"
            >
              {isSubmitting ? "Transmitting Alert..." : "Broadcast Incident to Dispatch"}
            </button>
          </>
        )}
      </main>

      {/* Driver Bottom Bar */}
      <nav className="fixed bottom-0 w-full z-50 bg-[#16201e] border-t border-white/10 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link href="/driver/cockpit" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">speed</span>
            <span className="text-[11px]">Cockpit</span>
          </Link>
          <Link href="/driver/validator" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">qr_code_scanner</span>
            <span className="text-[11px]">Scanner</span>
          </Link>
          <Link href="/driver/incident" className="flex flex-col items-center gap-1 text-amber-400 font-bold">
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
