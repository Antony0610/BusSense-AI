"use client";

import React, { useState } from "react";
import Link from "next/link";
import { fetchApi, ValidationResult } from "@/lib/api";

export default function ConductorValidatorPage() {
  const [tokenInput, setTokenInput] = useState("bussense://ticket/BS-KL-2026-9042?salt=kerala_secure_token");
  const [lastResult, setLastResult] = useState<ValidationResult | null>(null);
  const [isVerifying, setIsVerifying] = useState(false);

  const handleVerify = async (hashToVerify?: string) => {
    const hash = hashToVerify || tokenInput;
    if (!hash.trim() || isVerifying) return;

    setIsVerifying(true);
    try {
      const res = await fetchApi<ValidationResult>("/tickets/validate", {
        method: "POST",
        body: JSON.stringify({
          qr_code_hash: hash,
          bus_number: "205",
          conductor_id: "22222222-2222-2222-2222-222222222222"
        })
      });
      setLastResult(res);
    } catch (e: any) {
      setLastResult({
        result: "INVALID",
        is_valid: false,
        message: "Network or token decoding error.",
        validated_at: new Date().toISOString()
      });
    } finally {
      setIsVerifying(false);
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
          <span className="font-bold text-sm text-emerald-400 font-mono">
            Conductor Validator · Bus 205
          </span>
          <div className="w-8"></div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {/* Verification Status Card */}
        {lastResult && (
          <div
            className={`p-space-base rounded-2xl border flex flex-col items-center text-center animate-fadeIn ${
              lastResult.result === "VALID"
                ? "bg-emerald-950/80 border-emerald-500 text-emerald-100"
                : lastResult.result === "ALREADY_USED"
                ? "bg-amber-950/80 border-amber-500 text-amber-100"
                : "bg-red-950/80 border-red-500 text-red-100"
            }`}
          >
            <div
              className={`w-16 h-16 rounded-full flex items-center justify-center mb-space-sm ${
                lastResult.result === "VALID"
                  ? "bg-emerald-500 text-white"
                  : lastResult.result === "ALREADY_USED"
                  ? "bg-amber-500 text-white"
                  : "bg-red-500 text-white"
              }`}
            >
              <span className="material-symbols-outlined text-[36px]">
                {lastResult.result === "VALID"
                  ? "check"
                  : lastResult.result === "ALREADY_USED"
                  ? "history"
                  : "close"}
              </span>
            </div>

            <h2 className="text-2xl font-black uppercase tracking-wider">
              {lastResult.result.replace("_", " ")}
            </h2>

            <p className="text-sm mt-1 max-w-xs">{lastResult.message}</p>

            {lastResult.passenger_name && (
              <div className="mt-space-base pt-space-xs border-t border-white/20 w-full text-left text-xs space-y-1">
                <div className="flex justify-between">
                  <span className="text-white/60">Passenger:</span>
                  <strong className="text-white">{lastResult.passenger_name}</strong>
                </div>
                <div className="flex justify-between">
                  <span className="text-white/60">Ticket #:</span>
                  <span className="font-mono text-white">{lastResult.ticket_number}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-white/60">Corridor:</span>
                  <span className="text-white">{lastResult.origin_stop} ➔ {lastResult.destination_stop}</span>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Camera / Scanner Simulation Box */}
        <div className="bg-[#16201e] p-space-base rounded-2xl border border-white/10 flex flex-col items-center">
          <div className="w-full h-44 rounded-xl border-2 border-dashed border-emerald-500/40 bg-black/40 flex flex-col items-center justify-center p-space-base relative overflow-hidden">
            <span className="material-symbols-outlined text-[48px] text-emerald-400/60 mb-2">
              qr_code_scanner
            </span>
            <span className="text-xs text-white/60 text-center">
              Position digital boarding QR code within scanner frame
            </span>

            {/* Scanning line animation */}
            <div className="absolute top-0 left-0 w-full h-1 bg-emerald-400 animate-pulse"></div>
          </div>

          <div className="w-full mt-space-base">
            <label className="text-xs uppercase text-white/60 font-semibold block mb-1">
              QR Token Hash / Ticket ID
            </label>
            <input
              type="text"
              value={tokenInput}
              onChange={(e) => setTokenInput(e.target.value)}
              className="w-full bg-[#101817] border border-white/20 rounded-xl px-space-base py-space-sm text-sm text-white font-mono focus:outline-none focus:border-emerald-400"
            />
          </div>

          <button
            onClick={() => handleVerify()}
            disabled={isVerifying}
            className="w-full mt-space-base py-space-base rounded-xl bg-emerald-600 hover:bg-emerald-500 font-bold text-base shadow-lg transition-transform active:scale-95 disabled:opacity-50"
          >
            {isVerifying ? "Verifying Token..." : "Validate Ticket QR"}
          </button>
        </div>

        {/* Quick Test Token Scenarios (Section 8 Requirement) */}
        <div className="bg-[#16201e] p-space-base rounded-2xl border border-white/10">
          <span className="text-xs uppercase text-white/60 font-bold block mb-space-sm">
            Quick Scanner Simulation Scenarios
          </span>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => {
                setTokenInput("bussense://ticket/BS-KL-2026-9042?salt=kerala_secure_token");
                handleVerify("bussense://ticket/BS-KL-2026-9042?salt=kerala_secure_token");
              }}
              className="p-2.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-semibold text-left"
            >
              <strong className="block text-emerald-300">Valid Ticket</strong>
              <span className="text-[10px] text-white/60">Ticket BS-KL-2026-9042</span>
            </button>

            <button
              onClick={() => {
                setTokenInput("bussense://ticket/INVALID-TOKEN-9999");
                handleVerify("bussense://ticket/INVALID-TOKEN-9999");
              }}
              className="p-2.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-semibold text-left"
            >
              <strong className="block text-red-300">Invalid Token</strong>
              <span className="text-[10px] text-white/60">Unrecognized Hash</span>
            </button>
          </div>
        </div>
      </main>

      {/* Driver Bottom Bar */}
      <nav className="fixed bottom-0 w-full z-50 bg-[#16201e] border-t border-white/10 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link href="/driver/cockpit" className="flex flex-col items-center gap-1 text-white/60 hover:text-white transition-colors">
            <span className="material-symbols-outlined text-[24px]">speed</span>
            <span className="text-[11px]">Cockpit</span>
          </Link>
          <Link href="/driver/validator" className="flex flex-col items-center gap-1 text-emerald-400 font-bold">
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
