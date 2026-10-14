"use client";

import React from "react";
import Link from "next/link";

export default function ProfilePage() {
  return (
    <div className="bg-surface font-body-md text-on-surface min-h-screen flex flex-col pb-24 selection:bg-secondary-fixed selection:text-on-secondary-fixed">
      <header className="fixed top-0 w-full z-50 bg-surface/85 backdrop-blur-xl border-b border-outline-variant/30">
        <div className="h-16 px-gutter max-w-md mx-auto flex items-center justify-between">
          <Link href="/passenger/home" className="flex items-center gap-space-xs text-primary font-semibold text-sm">
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span>Home</span>
          </Link>
          <span className="font-title-card text-title-card text-primary font-bold">Commuter Profile & Privacy</span>
          <div className="w-8"></div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {/* Profile Card */}
        <div className="bg-surface-container-lowest p-space-base rounded-2xl border border-outline-variant/40 shadow-sm flex items-center gap-space-base">
          <div className="w-14 h-14 rounded-full bg-primary-container text-white flex items-center justify-center font-bold text-xl">
            RN
          </div>
          <div>
            <h2 className="font-headline-sm text-headline-sm font-bold text-primary">Rahul Nair</h2>
            <p className="text-xs text-on-surface-variant font-mono">+91 98470 12345 · Daily Commuter</p>
            <span className="inline-block mt-1 px-2 py-0.5 rounded bg-secondary-fixed/50 text-on-secondary-fixed text-[10px] font-bold">
              Kochi Metro Corridors
            </span>
          </div>
        </div>

        {/* Privacy & Computer Vision Transparency (Section 19 Requirement) */}
        <div className="bg-surface-container-lowest p-space-base rounded-2xl border border-outline-variant/40 shadow-sm space-y-space-sm">
          <div className="flex items-center gap-2 text-primary font-bold text-sm">
            <span className="material-symbols-outlined text-secondary text-[20px]">verified_user</span>
            <span>Computer Vision & Privacy Safeguards</span>
          </div>
          <p className="text-xs text-on-surface-variant leading-relaxed">
            BusSense AI utilizes privacy-preserving person detection algorithms. Onboard CCTV feeds are processed in real-time solely to compute passenger count and cabin density.
          </p>
          <div className="space-y-1.5 pt-2 border-t border-outline-variant/30 text-xs">
            <div className="flex items-center justify-between text-secondary font-medium">
              <span>● No Facial Recognition</span>
              <span className="text-on-surface-variant font-mono text-[10px]">ENFORCED</span>
            </div>
            <div className="flex items-center justify-between text-secondary font-medium">
              <span>● No Biometric Storage</span>
              <span className="text-on-surface-variant font-mono text-[10px]">ENFORCED</span>
            </div>
            <div className="flex items-center justify-between text-secondary font-medium">
              <span>● Bounding Box Counting Only</span>
              <span className="text-on-surface-variant font-mono text-[10px]">ACTIVE</span>
            </div>
          </div>
        </div>

        {/* Switch Role Fast Launcher */}
        <div className="bg-surface-container-low p-space-base rounded-2xl border border-outline-variant/40">
          <span className="font-caption text-xs uppercase text-on-surface-variant font-bold block mb-2">
            Switch Prototype Role
          </span>
          <div className="grid grid-cols-2 gap-2">
            <Link
              href="/driver/cockpit"
              className="p-3 bg-white rounded-xl border border-outline-variant/40 text-center font-semibold text-xs text-primary hover:border-secondary transition-colors"
            >
              Driver Cockpit
            </Link>
            <Link
              href="/authority/command"
              className="p-3 bg-white rounded-xl border border-outline-variant/40 text-center font-semibold text-xs text-primary hover:border-secondary transition-colors"
            >
              Authority Console
            </Link>
          </div>
        </div>
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
          <Link href="/passenger/journey" className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
            <span className="material-symbols-outlined text-[24px]">navigation</span>
            <span className="font-caption text-[11px]">HUD</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
