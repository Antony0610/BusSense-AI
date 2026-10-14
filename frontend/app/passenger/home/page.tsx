"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, BusTelemetry } from "@/lib/api";

export default function PassengerHomePage() {
  const [buses, setBuses] = useState<BusTelemetry[]>([]);
  const [showWhyDrawer, setShowWhyDrawer] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLiveSync, setIsLiveSync] = useState(true);

  useEffect(() => {
    // Load live telemetry from backend
    const loadBuses = () => {
      fetchApi<BusTelemetry[]>("/buses")
        .then((data) => setBuses(data))
        .catch(() => {
          // Fallback static state if backend not running
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
    };

    loadBuses();
    const interval = setInterval(loadBuses, 4000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="bg-surface font-body-md text-on-surface min-h-screen flex flex-col pb-24 selection:bg-secondary-fixed selection:text-on-secondary-fixed">
      {/* Fixed Sticky Header */}
      <header className="fixed top-0 w-full z-50 bg-surface/85 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)] border-b border-outline-variant/30">
        <div className="h-16 px-gutter max-w-md mx-auto flex items-center justify-between">
          <div className="flex items-center gap-space-sm">
            <Link href="/" className="w-8 h-8 rounded-lg bg-primary-container flex items-center justify-center text-secondary-container">
              <span className="material-symbols-outlined text-[20px]">directions_bus</span>
            </Link>
            <div className="flex flex-col">
              <div className="flex items-center gap-space-2xs">
                <span className="w-2 h-2 rounded-full bg-secondary animate-pulse"></span>
                <span className="font-label-caps text-label-caps uppercase text-secondary tracking-wider">Kochi, Kerala</span>
              </div>
              <span className="font-title-card text-title-card text-primary font-bold leading-tight">BusSense AI</span>
            </div>
          </div>

          <div className="flex items-center gap-space-sm">
            <div className="px-space-sm py-space-2xs rounded-full bg-surface-container flex items-center gap-space-2xs text-on-surface-variant font-caption text-caption">
              <span className="material-symbols-outlined text-[14px] text-secondary">sensors</span>
              <span>Live Sync</span>
            </div>
            <Link href="/passenger/profile" className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-on-primary">
              <span className="material-symbols-outlined text-[18px]">person</span>
            </Link>
          </div>
        </div>
      </header>

      {/* Main Passenger Mobile Content */}
      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-16 px-gutter">
        {/* Passenger Header & Live Location */}
        <section className="pt-space-md pb-space-sm">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-space-xs text-on-surface-variant mb-space-2xs">
                <span className="material-symbols-outlined text-[16px] text-secondary">near_me</span>
                <span className="font-caption text-caption tracking-tight">Near Kaloor Metro Station, Kochi</span>
              </div>
              <h1 className="font-headline-lg-mobile text-headline-lg-mobile text-primary tracking-tight font-bold">
                Good Morning, Rahul
              </h1>
            </div>
            <div className="w-10 h-10 rounded-full bg-surface-container-high flex items-center justify-center shadow-sm">
              <span className="material-symbols-outlined text-primary text-[20px]">notifications_none</span>
            </div>
          </div>
        </section>

        {/* Hero Transit Search & Voice Interface */}
        <section className="py-space-xs">
          <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/40 p-space-sm flex items-center gap-space-sm">
            <span className="material-symbols-outlined text-outline text-[22px] ml-space-xs">search</span>
            <input
              type="text"
              id="transit-search-input"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-transparent font-title-card text-title-card text-on-surface placeholder:text-outline focus:outline-none py-space-xs"
              placeholder="Where are you going?"
            />
            <button
              aria-label="Search by voice"
              className="w-9 h-9 rounded-lg bg-surface-container-low flex items-center justify-center text-primary active:scale-95 transition-transform"
            >
              <span className="material-symbols-outlined text-[20px]">mic</span>
            </button>
          </div>

          {/* Quick Destinations Pills */}
          <div className="flex items-center gap-space-xs overflow-x-auto py-space-sm no-scrollbar">
            <Link
              href="/passenger/explore?dest=Infopark"
              className="shrink-0 flex items-center gap-space-2xs px-space-sm py-space-2xs bg-surface-container rounded-full text-on-surface font-caption text-caption hover:bg-surface-container-high transition-colors"
            >
              <span className="material-symbols-outlined text-[14px] text-secondary">history</span>
              <span>Infopark Phase 1</span>
            </Link>
            <Link
              href="/passenger/explore?dest=ErnakulamSouth"
              className="shrink-0 flex items-center gap-space-2xs px-space-sm py-space-2xs bg-surface-container rounded-full text-on-surface font-caption text-caption hover:bg-surface-container-high transition-colors"
            >
              <span className="material-symbols-outlined text-[14px] text-secondary">history</span>
              <span>Ernakulam South Station</span>
            </Link>
            <Link
              href="/passenger/explore?dest=Aluva"
              className="shrink-0 flex items-center gap-space-2xs px-space-sm py-space-2xs bg-surface-container rounded-full text-on-surface font-caption text-caption hover:bg-surface-container-high transition-colors"
            >
              <span className="material-symbols-outlined text-[14px] text-secondary">train</span>
              <span>Aluva Metro</span>
            </Link>
            <Link
              href="/passenger/explore?dest=FortKochi"
              className="shrink-0 flex items-center gap-space-2xs px-space-sm py-space-2xs bg-surface-container rounded-full text-on-surface font-caption text-caption hover:bg-surface-container-high transition-colors"
            >
              <span className="material-symbols-outlined text-[14px] text-secondary">directions_boat</span>
              <span>Fort Kochi Boat Jetty</span>
            </Link>
          </div>
        </section>

        {/* Route Map View Integration */}
        <section className="pt-space-xs pb-space-sm">
          <div
            className="w-full h-36 rounded-xl bg-primary-container relative overflow-hidden shadow-sm flex flex-col justify-end p-space-sm border border-outline-variant/30"
            style={{
              backgroundImage: "linear-gradient(to top, rgba(18, 60, 53, 0.95), rgba(18, 60, 53, 0.4)), url('https://lh3.googleusercontent.com/aida-public/AB6AXuA8oyZDuQWKU8soDjrJJ9cTAbMu5ZyYQ6BelIePzGb5VYtYPbtqivqnIA7lxqugYcXeaM7kxjZG6NKyYWd1gIld0OM7ojZJ8QEQF2O55bIaUWmtbP5FUk5E-U6l529an4zmVnEt4R1NNrOX8r1FJ-c3jQNQ1HgUH8t3NmqrZrbVpl9pHmbKcmn9rq-C-aHEM13nTZ5-0Q8jcGQLy5RSCbTuXDfH6llMzf-JqXCz-yMHSJpfsCKDAypGvQ')",
              backgroundSize: "cover",
              backgroundPosition: "center"
            }}
          >
            <div className="relative z-10 flex items-center justify-between">
              <div className="flex items-center gap-space-2xs bg-surface-container-lowest/90 backdrop-blur-md px-space-sm py-space-2xs rounded-full">
                <span className="w-2 h-2 rounded-full bg-secondary animate-ping"></span>
                <span className="font-caption text-caption font-semibold text-primary">Live Kerala Telemetry</span>
              </div>
              <span className="font-caption text-caption text-surface-bright bg-primary/70 backdrop-blur-sm px-space-sm py-space-2xs rounded-full">
                {buses.length} Vehicles Nearby
              </span>
            </div>
          </div>
        </section>

        {/* AI Predictive Recommendation Banner (Stitch Design Spotlight) */}
        <section className="py-space-xs">
          <div className="bg-primary-container text-on-primary rounded-xl p-space-base shadow-md">
            <div className="flex items-start justify-between gap-space-sm">
              <div className="flex items-center gap-space-xs">
                <div className="w-6 h-6 rounded-md bg-secondary-container text-on-secondary-container flex items-center justify-center">
                  <span className="material-symbols-outlined text-[16px]">bolt</span>
                </div>
                <span className="font-label-caps text-label-caps uppercase text-secondary-container tracking-wider">
                  Predictive Transit Insight
                </span>
              </div>
              <button
                onClick={() => setShowWhyDrawer(!showWhyDrawer)}
                className="flex items-center gap-space-2xs px-space-xs py-space-2xs rounded bg-surface-bright/10 text-surface-bright hover:bg-surface-bright/20 transition-colors font-caption text-caption"
              >
                <span>Why?</span>
                <span className="material-symbols-outlined text-[14px]">
                  {showWhyDrawer ? "expand_less" : "expand_more"}
                </span>
              </button>
            </div>

            <p className="font-title-card text-title-card text-surface-bright mt-space-sm leading-snug">
              Bus <span className="font-bold text-secondary-container">205</span> departs shortly after 14A, offers{" "}
              <span className="font-bold text-secondary-container">40% lower crowd</span>, and saves 12 min.
            </p>

            {/* Expandable rationalization panel */}
            {showWhyDrawer && (
              <div className="mt-space-sm pt-space-xs bg-black/20 rounded-lg p-space-sm text-surface-bright/90 animate-fadeIn">
                <div className="flex items-start gap-space-xs">
                  <span className="material-symbols-outlined text-secondary-container text-[18px]">alt_route</span>
                  <div>
                    <div className="font-caption text-caption font-semibold text-secondary-container">
                      Fewer stops on Banerji Rd corridor
                    </div>
                    <div className="font-body-sm text-body-sm text-surface-bright/80 mt-0.5">
                      Bypasses Kaloor market signal congestion with dedicated priority lane timing.
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </section>

        {/* Live Departures Nearby */}
        <section className="pt-space-md">
          <div className="flex items-center justify-between mb-space-sm">
            <div className="flex items-center gap-space-xs">
              <h2 className="font-headline-sm text-headline-sm text-primary font-bold">Live Departures</h2>
              <span className="w-1.5 h-1.5 rounded-full bg-secondary"></span>
            </div>
            <span className="font-caption text-caption text-on-surface-variant">Real-time sync active</span>
          </div>

          {/* Departures Module List */}
          <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-outline-variant/40 divide-y divide-outline-variant/30 overflow-hidden">
            {buses.map((bus) => (
              <Link
                key={bus.bus_number}
                href={`/passenger/explore?bus=${bus.bus_number}`}
                className="p-space-base block hover:bg-surface-container-low transition-colors"
              >
                <div className="flex items-start justify-between">
                  {/* Left: Route Info */}
                  <div className="flex flex-col">
                    <div className="flex items-center gap-space-xs mb-space-2xs">
                      <span className="bg-primary text-on-primary font-headline-sm text-headline-sm px-space-sm py-0.5 rounded-md leading-none font-bold">
                        {bus.bus_number}
                      </span>
                      <span className="font-label-caps text-label-caps uppercase bg-primary-fixed text-on-primary-fixed px-space-xs py-0.5 rounded">
                        {bus.operator_type} {bus.bus_number === "205" ? "Fast Passenger" : "City Feeder"}
                      </span>
                    </div>
                    <div className="font-title-card text-title-card text-primary font-semibold">
                      {bus.next_stop}
                    </div>
                    <div className="font-caption text-caption text-on-surface-variant mt-0.5">
                      via {bus.route_name.split("via")[1] || "Kaloor Corridors"}
                    </div>
                  </div>

                  {/* Right: Telemetry Countdown & Crowd */}
                  <div className="flex flex-col items-end">
                    <div className="flex items-baseline gap-1 text-primary">
                      <span className="font-eta-display text-eta-display font-extrabold tnum">
                        {bus.eta_next_stop_mins}
                      </span>
                      <span className="font-caption text-caption text-on-surface-variant font-medium">min</span>
                    </div>

                    {/* Crowd Density & Occupancy Bar */}
                    <div className="flex items-center gap-1.5 mt-space-2xs">
                      <div className="flex gap-1">
                        <span
                          className={`w-3 h-1.5 rounded-full ${
                            bus.occupancy_pct >= 0 ? (bus.crowd_level === "LOW" ? "bg-secondary" : "bg-secondary") : "bg-outline-variant"
                          }`}
                        ></span>
                        <span
                          className={`w-3 h-1.5 rounded-full ${
                            bus.occupancy_pct >= 50 ? (bus.crowd_level === "MODERATE" ? "bg-amber-500" : "bg-outline-variant") : "bg-outline-variant"
                          }`}
                        ></span>
                        <span
                          className={`w-3 h-1.5 rounded-full ${
                            bus.occupancy_pct > 80 ? "bg-red-500" : "bg-outline-variant"
                          }`}
                        ></span>
                      </div>
                      <span className="font-caption text-caption font-mono font-bold text-on-surface-variant tnum">
                        {bus.occupancy_pct}%
                      </span>
                    </div>

                    <span
                      className={`text-[11px] font-semibold mt-1 ${
                        bus.crowd_level === "LOW"
                          ? "text-secondary"
                          : bus.crowd_level === "MODERATE"
                          ? "text-amber-600"
                          : "text-red-600"
                      }`}
                    >
                      {bus.crowd_level === "LOW"
                        ? "Seats Available"
                        : bus.crowd_level === "MODERATE"
                        ? "Standing Room"
                        : "At Capacity"}
                    </span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </section>
      </main>

      {/* Persistent Bottom Mobile Navigation Bar */}
      <nav className="fixed bottom-0 w-full z-50 bg-surface/90 backdrop-blur-xl border-t border-outline-variant/40 pb-safe">
        <div className="max-w-md mx-auto h-16 flex items-center justify-around px-gutter">
          <Link
            href="/passenger/home"
            className="flex flex-col items-center gap-1 text-primary font-bold"
          >
            <span className="material-symbols-outlined text-[24px]">departure_board</span>
            <span className="font-caption text-[11px]">Departures</span>
          </Link>
          <Link
            href="/passenger/explore"
            className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors"
          >
            <span className="material-symbols-outlined text-[24px]">explore</span>
            <span className="font-caption text-[11px]">Explore</span>
          </Link>
          <Link
            href="/passenger/assistant"
            className="flex flex-col items-center gap-1 text-secondary hover:opacity-80 transition-opacity"
          >
            <div className="w-10 h-10 -mt-5 rounded-full bg-primary-container text-secondary-container flex items-center justify-center shadow-md">
              <span className="material-symbols-outlined text-[22px]">smart_toy</span>
            </div>
            <span className="font-caption text-[11px] font-semibold">AI Assistant</span>
          </Link>
          <Link
            href="/passenger/tickets"
            className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors"
          >
            <span className="material-symbols-outlined text-[24px]">confirmation_number</span>
            <span className="font-caption text-[11px]">Tickets</span>
          </Link>
          <Link
            href="/passenger/journey"
            className="flex flex-col items-center gap-1 text-on-surface-variant hover:text-primary transition-colors"
          >
            <span className="material-symbols-outlined text-[24px]">navigation</span>
            <span className="font-caption text-[11px]">HUD</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
