"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, RecommendationResponse } from "@/lib/api";

export default function ExplorePage() {
  const [origin, setOrigin] = useState("Kaloor Metro Station, Kochi");
  const [destination, setDestination] = useState("Vyttila Mobility Hub");
  const [recommendation, setRecommendation] = useState<RecommendationResponse | null>(null);
  const [forecast, setForecast] = useState<any[]>([]);

  useEffect(() => {
    // Load recommendations from backend
    fetchApi<RecommendationResponse>("/recommendations/plan?origin=" + encodeURIComponent(origin) + "&destination=" + encodeURIComponent(destination))
      .then((data) => setRecommendation(data))
      .catch(() => {});

    // Load crowd forecast for Bus 205
    fetchApi<any[]>("/occupancy/forecast/205")
      .then((data) => setForecast(data))
      .catch(() => {});
  }, [origin, destination]);

  return (
    <div className="bg-surface font-body-md text-on-surface min-h-screen flex flex-col pb-24 selection:bg-secondary-fixed selection:text-on-secondary-fixed">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-surface/85 backdrop-blur-xl border-b border-outline-variant/30">
        <div className="h-16 px-gutter max-w-md mx-auto flex items-center justify-between">
          <Link href="/passenger/home" className="flex items-center gap-space-xs text-primary font-semibold text-sm">
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span>Back</span>
          </Link>
          <span className="font-title-card text-title-card text-primary font-bold">Route Planning & Comparison</span>
          <div className="w-8"></div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter">
        {/* Origin / Destination Input Box */}
        <section className="bg-surface-container-lowest p-space-base rounded-xl border border-outline-variant/40 shadow-sm">
          <div className="flex flex-col gap-space-sm">
            <div className="flex items-center gap-space-sm">
              <span className="w-3 h-3 rounded-full bg-secondary shrink-0"></span>
              <div className="flex-1">
                <span className="font-caption text-[11px] text-on-surface-variant block uppercase font-semibold">Origin</span>
                <input
                  type="text"
                  value={origin}
                  onChange={(e) => setOrigin(e.target.value)}
                  className="w-full font-title-card text-title-card font-semibold text-primary bg-transparent focus:outline-none"
                />
              </div>
            </div>

            <div className="border-t border-outline-variant/30 my-0.5"></div>

            <div className="flex items-center gap-space-sm">
              <span className="w-3 h-3 rounded-full bg-primary shrink-0"></span>
              <div className="flex-1">
                <span className="font-caption text-[11px] text-on-surface-variant block uppercase font-semibold">Destination</span>
                <input
                  type="text"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                  className="w-full font-title-card text-title-card font-semibold text-primary bg-transparent focus:outline-none"
                />
              </div>
            </div>
          </div>
        </section>

        {/* 60-Min Crowd Forecast Trajectory (Section 6 Requirement: NOW, +15 MIN, +30 MIN, +60 MIN) */}
        <section className="mt-space-base">
          <div className="flex items-center justify-between mb-space-xs">
            <div className="flex items-center gap-space-xs">
              <span className="font-title-card text-title-card text-primary font-bold">Crowd Forecast Horizon</span>
              <span className="text-[10px] px-1.5 py-0.5 rounded bg-surface-container text-on-surface-variant font-mono">PREDICTION</span>
            </div>
            <span className="font-caption text-caption text-secondary font-semibold">Bus 205 Corridor</span>
          </div>

          <div className="grid grid-cols-4 gap-2 bg-surface-container-lowest p-space-sm rounded-xl border border-outline-variant/40">
            {forecast.length > 0 ? (
              forecast.map((pt) => (
                <div key={pt.time_offset} className="flex flex-col items-center p-2 rounded-lg bg-surface-container-low text-center">
                  <span className="font-label-caps text-[10px] uppercase font-bold text-on-surface-variant">{pt.time_offset}</span>
                  <span className="font-headline-sm text-headline-sm font-extrabold text-primary tnum my-0.5">
                    {pt.predicted_occupancy_pct}%
                  </span>
                  <span
                    className={`text-[10px] font-semibold px-1.5 py-0.5 rounded ${
                      pt.crowd_level === "LOW"
                        ? "bg-secondary-fixed/50 text-on-secondary-fixed"
                        : pt.crowd_level === "MODERATE"
                        ? "bg-amber-100 text-amber-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {pt.crowd_level}
                  </span>
                </div>
              ))
            ) : (
              [
                { label: "NOW", val: "42%", tier: "LOW" },
                { label: "+15 MIN", val: "45%", tier: "LOW" },
                { label: "+30 MIN", val: "52%", tier: "MODERATE" },
                { label: "+60 MIN", val: "65%", tier: "MODERATE" },
              ].map((f) => (
                <div key={f.label} className="flex flex-col items-center p-2 rounded-lg bg-surface-container-low text-center">
                  <span className="font-label-caps text-[10px] uppercase font-bold text-on-surface-variant">{f.label}</span>
                  <span className="font-headline-sm text-headline-sm font-extrabold text-primary tnum my-0.5">{f.val}</span>
                  <span className="text-[10px] font-semibold text-secondary">{f.tier}</span>
                </div>
              ))
            )}
          </div>
        </section>

        {/* Recommended Bus Card with AI Journey Score */}
        {recommendation && (
          <section className="mt-space-base">
            <div className="flex items-center justify-between mb-space-xs">
              <span className="font-title-card text-title-card text-primary font-bold">Recommended Journey</span>
              <span className="font-caption text-caption text-secondary font-bold">
                AI Journey Score: {recommendation.recommended_bus.journey_score}/100
              </span>
            </div>

            <div className="bg-primary-container text-white p-space-base rounded-xl shadow-md border border-secondary/30">
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="px-2.5 py-1 rounded bg-secondary text-white font-bold text-lg font-mono">
                      {recommendation.recommended_bus.bus_number}
                    </span>
                    <span className="font-label-caps uppercase text-secondary-container text-xs tracking-wider">
                      {recommendation.recommended_bus.operator_type} Fast Passenger
                    </span>
                  </div>
                  <div className="font-title-card text-base font-semibold text-surface-bright mt-1">
                    {recommendation.recommended_bus.route_name}
                  </div>
                </div>

                <div className="text-right">
                  <div className="text-2xl font-extrabold text-secondary-container tnum font-mono">
                    ₹{recommendation.recommended_bus.fare_inr}
                  </div>
                  <span className="text-xs text-surface-bright/80">Direct Route</span>
                </div>
              </div>

              {/* Rationale */}
              <div className="mt-space-base p-space-sm bg-black/20 rounded-lg text-sm text-surface-bright/90">
                <div className="flex items-start gap-2">
                  <span className="material-symbols-outlined text-secondary-container text-[18px]">verified</span>
                  <div>
                    <span className="font-bold text-secondary-container">Why Recommended: </span>
                    <span>{recommendation.recommended_bus.why_recommended}</span>
                  </div>
                </div>
              </div>

              {/* Action */}
              <div className="mt-space-base pt-space-sm border-t border-white/10 flex items-center justify-between">
                <div className="text-xs text-surface-bright/80">
                  Arrives in <span className="font-bold text-white tnum">{recommendation.recommended_bus.eta_mins} min</span> · 42% Occupied
                </div>
                <Link
                  href="/passenger/tickets"
                  className="px-space-base py-space-xs rounded-lg bg-secondary text-white font-semibold text-sm hover:opacity-95 transition-opacity"
                >
                  Book Boarding Pass
                </Link>
              </div>
            </div>
          </section>
        )}

        {/* Alternative Buses Comparison */}
        {recommendation && recommendation.alternative_buses && (
          <section className="mt-space-base">
            <h3 className="font-title-card text-title-card text-primary font-bold mb-space-xs">
              Alternative Options
            </h3>
            <div className="space-y-space-sm">
              {recommendation.alternative_buses.map((bus) => (
                <div key={bus.bus_number} className="bg-surface-container-lowest p-space-base rounded-xl border border-outline-variant/40 shadow-sm">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="px-2 py-0.5 rounded bg-surface-container-high font-bold text-primary text-sm font-mono">
                          {bus.bus_number}
                        </span>
                        <span className="font-label-caps uppercase text-xs text-on-surface-variant">
                          {bus.operator_type}
                        </span>
                      </div>
                      <div className="font-title-card text-sm font-semibold text-primary mt-1">
                        {bus.route_name}
                      </div>
                      <p className="text-xs text-red-600 font-medium mt-1">
                        {bus.why_recommended}
                      </p>
                    </div>

                    <div className="text-right">
                      <div className="font-bold text-primary tnum font-mono">₹{bus.fare_inr}</div>
                      <div className="text-xs text-on-surface-variant mt-1">
                        ETA: <span className="font-semibold">{bus.eta_mins}m</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}
      </main>

      {/* Persistent Bottom Mobile Navigation Bar */}
      <nav className="fixed bottom-0 w-full z-50 bg-surface/90 backdrop-blur-xl border-t border-outline-variant/40 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link href="/passenger/home" className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors">
            <span className="material-symbols-outlined text-[24px]">departure_board</span>
            <span className="font-caption text-[11px]">Departures</span>
          </Link>
          <Link href="/passenger/explore" className="flex flex-col items-center gap-1 text-primary font-bold">
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
