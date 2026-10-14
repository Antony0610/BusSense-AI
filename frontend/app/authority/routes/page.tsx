"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  getRoutes,
  getBuses,
  getAlerts,
  getCommandOverview,
  RouteData,
  Bus,
  Alert,
  CommandOverview,
} from "@/lib/api";

// Kerala network stop registries for known transit corridors
const ROUTE_STOPS_MAP: Record<
  string,
  Array<{ name: string; time: string; distance: string; isMetro: boolean }>
> = {
  "12": [
    { name: "Kaloor Metro Stand", time: "+0 min", distance: "0.0 km", isMetro: true },
    { name: "Palarivattom Junction", time: "+12 min", distance: "4.2 km", isMetro: false },
    { name: "Kakkanad Civil Station", time: "+22 min", distance: "9.8 km", isMetro: false },
    { name: "Infopark Phase 1 Express Bay", time: "+30 min", distance: "14.2 km", isMetro: false },
    { name: "Infopark Phase 2 Terminal", time: "+36 min", distance: "16.8 km", isMetro: false },
  ],
  "14A": [
    { name: "Fort Kochi Boat Jetty", time: "+0 min", distance: "0.0 km", isMetro: false },
    { name: "MG Road Metro Station", time: "+18 min", distance: "8.5 km", isMetro: true },
    { name: "South Railway Overbridge", time: "+26 min", distance: "11.2 km", isMetro: false },
    { name: "Kadavanthra Metro Junction", time: "+34 min", distance: "14.8 km", isMetro: true },
    { name: "Vyttila Mobility Hub", time: "+48 min", distance: "21.0 km", isMetro: true },
    { name: "Infopark Phase 1 Express Bay", time: "+62 min", distance: "26.5 km", isMetro: false },
  ],
  "205": [
    { name: "Aluva Regional Metro Terminal", time: "+0 min", distance: "0.0 km", isMetro: true },
    { name: "Kalamassery Premier Jn", time: "+14 min", distance: "6.8 km", isMetro: true },
    { name: "Edappally Toll / Metro", time: "+24 min", distance: "12.2 km", isMetro: true },
    { name: "Palarivattom Bypass", time: "+35 min", distance: "16.5 km", isMetro: false },
    { name: "Vyttila Mobility Hub", time: "+48 min", distance: "22.4 km", isMetro: true },
  ],
};

export default function AuthorityRoutesPage() {
  const [routes, setRoutes] = useState<RouteData[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [overview, setOverview] = useState<CommandOverview | null>(null);
  const [selectedRouteNumber, setSelectedRouteNumber] = useState<string>("12");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date());
  const [showDispatchNotice, setShowDispatchNotice] = useState(false);

  const loadData = useCallback(async () => {
    try {
      setError(null);
      const [routesData, busesData, alertsData, overviewData] = await Promise.all([
        getRoutes().catch(() => []),
        getBuses().catch(() => []),
        getAlerts().catch(() => []),
        getCommandOverview().catch(() => null),
      ]);

      setRoutes(routesData);
      setBuses(busesData);
      setAlerts(alertsData);
      setOverview(overviewData);
      setLastRefreshed(new Date());

      // If selected route not in list, pick first
      if (routesData.length > 0 && !routesData.some((r) => r.route_number === selectedRouteNumber)) {
        setSelectedRouteNumber(routesData[0].route_number);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load corridor route data";
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [selectedRouteNumber]);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, [loadData]);

  // Derived metrics
  const activeBusesCount = buses.filter((b) => b.is_active !== false).length;
  const corridorDetourCount = alerts.filter(
    (a) => a.severity === "WARNING" || a.title?.toLowerCase().includes("detour")
  ).length;

  const currentRoute =
    routes.find((r) => r.route_number === selectedRouteNumber) ||
    routes[0] || {
      id: "fallback-12",
      route_number: "12",
      route_name: "Kaloor Metro ➔ Infopark Phase 1 Corridor",
      corridor_type: "Direct Tech Corridor",
      start_stop: "Kaloor Metro Station",
      end_stop: "Infopark Phase 1 Express Bay",
      distance_km: 14.8,
      estimated_duration_mins: 32,
      color_code: "#123C35",
    };

  const currentStops =
    ROUTE_STOPS_MAP[currentRoute.route_number] || [
      { name: currentRoute.start_stop || "Origin Station", time: "+0 min", distance: "0.0 km", isMetro: true },
      { name: "Intermediate Transit Point", time: "+15 min", distance: `${(currentRoute.distance_km / 2).toFixed(1)} km`, isMetro: false },
      { name: currentRoute.end_stop || "Terminal Station", time: `+${currentRoute.estimated_duration_mins} min`, distance: `${currentRoute.distance_km} km`, isMetro: true },
    ];

  const busesOnCurrentRoute = buses.filter(
    (b) =>
      (b.route_number || b.route) === currentRoute.route_number ||
      (b.route_number || b.route)?.includes(currentRoute.route_number)
  );

  const avgRouteOccupancy =
    busesOnCurrentRoute.length > 0
      ? Math.round(
          busesOnCurrentRoute.reduce((acc, b) => acc + (b.occupancy_percentage || 0), 0) /
            busesOnCurrentRoute.length
        )
      : overview?.average_network_occupancy_pct || 56.4;

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header and Operational Band */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-bold uppercase text-[#006c49] tracking-wider">
              Network Corridor Monitoring
            </span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="text-xs text-[#717976]">Zone 04: Ernakulam - Kakkanad - Aluva</span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-[#e8f0ec] text-[#006c49] border border-[#006c49]/30">
              SIMULATED LIVE DATA
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#161d1b] tracking-tight">Routes & Network Operations</h1>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-[11px] text-[#717976] hidden sm:inline">
            Sync: {lastRefreshed.toLocaleTimeString()}
          </span>
          <button
            type="button"
            onClick={() => loadData()}
            className="px-3.5 py-2 rounded-xl bg-white text-[#161d1b] text-xs font-bold border border-[#c0c8c5]/30 hover:bg-[#eef5f1] transition-colors flex items-center gap-1.5 shadow-sm"
          >
            <span className="material-symbols-outlined text-[16px] text-[#006c49]">refresh</span>
            <span>Refresh</span>
          </button>
          <div className="relative">
            <button
              type="button"
              onClick={() => alert("GTFS Export engine deferred: live GTFS-RT feed generator scheduled for Phase H8.")}
              className="px-3.5 py-2 rounded-xl bg-white text-[#717976] text-xs font-bold border border-[#c0c8c5]/30 hover:bg-[#eef5f1] transition-colors flex items-center gap-1.5 shadow-sm"
            >
              <span className="material-symbols-outlined text-[16px] text-[#717976]">file_download</span>
              <span>Export GTFS</span>
              <span className="text-[9px] px-1 py-0.2 bg-[#eef5f1] rounded font-semibold text-[#717976]">DEFERRED</span>
            </button>
          </div>
        </div>
      </div>

      {/* Error state banner */}
      {error && (
        <div className="p-4 rounded-2xl bg-[#ffdad6] text-[#93000a] text-xs flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">error</span>
            <span>{error}</span>
          </div>
          <button
            type="button"
            onClick={() => loadData()}
            className="px-3 py-1 bg-[#ba1a1a] text-white rounded-lg font-bold text-[11px]"
          >
            Retry
          </button>
        </div>
      )}

      {/* Operational Summary Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Corridor On-Time</span>
            <span className="text-xl font-bold text-[#161d1b] mt-1 tnum">
              {overview?.on_time_reliability_pct ?? 94.2}%
            </span>
          </div>
          <span className="material-symbols-outlined text-[24px] text-[#006c49]">verified</span>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Active Vehicles</span>
            <span className="text-xl font-bold text-[#161d1b] mt-1 tnum">
              {activeBusesCount > 0 ? `${activeBusesCount} Buses` : "5 Buses"}
            </span>
          </div>
          <span className="material-symbols-outlined text-[24px] text-[#002620]">directions_bus</span>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Corridor Advisories</span>
            <span className="text-xl font-bold text-[#ba1a1a] mt-1 tnum">
              {corridorDetourCount > 0 ? `${corridorDetourCount} Detour` : "0 Detours"}
            </span>
          </div>
          <span className="material-symbols-outlined text-[24px] text-[#ba1a1a]">traffic</span>
        </div>

        <div className="bg-white p-4 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-[10px] font-bold uppercase text-[#717976]">Avg Occupancy</span>
            <span className="text-xl font-bold text-[#161d1b] mt-1 tnum">
              {avgRouteOccupancy}%
            </span>
          </div>
          <span className="material-symbols-outlined text-[24px] text-[#4edea3]">groups</span>
        </div>
      </div>

      {/* Main Split Console: Route Roster (5 cols) & Route Detail / Stops (7 cols) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        {/* Left: Route Roster */}
        <div className="lg:col-span-5 flex flex-col gap-3">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold uppercase text-[#717976]">Network Corridors</span>
            <span className="text-[11px] text-[#717976]">
              {loading ? "Loading..." : `${routes.length} Active Corridors`}
            </span>
          </div>

          {loading && routes.length === 0 ? (
            <div className="flex flex-col gap-2.5">
              {[1, 2, 3].map((n) => (
                <div key={n} className="p-4 bg-white rounded-2xl border border-[#c0c8c5]/30 animate-pulse h-28" />
              ))}
            </div>
          ) : routes.length === 0 ? (
            <div className="bg-white p-8 rounded-2xl border border-[#c0c8c5]/30 text-center text-xs text-[#717976]">
              No active transit routes discovered in Supabase database.
            </div>
          ) : (
            <div className="flex flex-col gap-2.5">
              {routes.map((route) => {
                const isSelected = selectedRouteNumber === route.route_number;
                const routeBuses = buses.filter(
                  (b) =>
                    (b.route_number || b.route) === route.route_number ||
                    (b.route_number || b.route)?.includes(route.route_number)
                );
                const busCount = routeBuses.length || (route.route_number === "12" ? 6 : route.route_number === "14A" ? 4 : 5);

                return (
                  <div
                    key={route.id || route.route_number}
                    onClick={() => setSelectedRouteNumber(route.route_number)}
                    className={`p-4 bg-white rounded-2xl border transition-all cursor-pointer shadow-sm ${
                      isSelected
                        ? "border-[#006c49] ring-2 ring-[#006c49]/15"
                        : "border-[#c0c8c5]/30 hover:border-[#006c49]/40"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div
                          className="w-10 h-10 rounded-xl text-white flex items-center justify-center font-bold text-sm shrink-0 shadow-sm"
                          style={{ backgroundColor: route.color_code || "#123c35" }}
                        >
                          {route.route_number}
                        </div>
                        <div className="flex flex-col min-w-0">
                          <span className="font-bold text-sm text-[#161d1b] truncate">
                            {route.start_stop} ⇄ {route.end_stop}
                          </span>
                          <span className="text-xs text-[#717976] truncate">{route.route_name}</span>
                        </div>
                      </div>
                    </div>

                    <div className="grid grid-cols-3 gap-2 mt-3 pt-3 border-t border-[#eef5f1] text-[11px] text-[#414846]">
                      <div>
                        <span className="text-[#717976] block text-[10px]">Distance</span>
                        <span className="font-semibold text-[#161d1b] tnum">
                          {route.distance_km ? `${route.distance_km} km` : "16.8 km"}
                        </span>
                      </div>
                      <div>
                        <span className="text-[#717976] block text-[10px]">Est. Duration</span>
                        <span className="font-semibold text-[#006c49] tnum">
                          {route.estimated_duration_mins ? `${route.estimated_duration_mins} min` : "35 min"}
                        </span>
                      </div>
                      <div>
                        <span className="text-[#717976] block text-[10px]">Active Fleet</span>
                        <span className="font-semibold text-[#161d1b] tnum">{busCount} buses</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right: Detailed Corridor Configuration & Stop Sequence */}
        <div className="lg:col-span-7 flex flex-col gap-4">
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#eef5f1]">
              <div className="flex flex-col">
                <span className="text-[10px] font-bold uppercase text-[#717976]">Corridor Milestone Sequence</span>
                <h3 className="font-bold text-lg text-[#161d1b]">Route {currentRoute.route_number} Stop Registry</h3>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2.5 py-1 rounded bg-[#e8f0ec] text-[#006c49] text-xs font-bold">
                  {currentStops.length} Managed Stops
                </span>
                <span className="px-2 py-0.5 rounded text-[9px] font-bold bg-[#eef5f1] text-[#717976] border border-[#c0c8c5]/30">
                  SIMULATED REGISTRY
                </span>
              </div>
            </div>

            {/* Corridor Metadata Bar */}
            <div className="p-3 bg-[#f3fbf7] rounded-xl border border-[#c0c8c5]/20 flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#002620]">Corridor Type:</span>
                <span className="text-[#414846]">{currentRoute.corridor_type || "Regional Priority Corridor"}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#002620]">Buses Assigned:</span>
                <span className="font-bold text-[#006c49] tnum">{busesOnCurrentRoute.length || 5} active</span>
              </div>
            </div>

            {/* Stop Sequence Timeline */}
            <div className="flex flex-col gap-3 relative before:absolute before:left-5 before:top-4 before:bottom-4 before:w-0.5 before:bg-[#dce4e0]">
              {currentStops.map((stop, idx) => (
                <div key={stop.name} className="flex items-start gap-4 relative z-10">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-xs shrink-0 shadow-sm ${
                      idx === 0 || idx === currentStops.length - 1
                        ? "bg-[#002620] text-white"
                        : "bg-white border-2 border-[#006c49] text-[#006c49]"
                    }`}
                  >
                    {idx + 1}
                  </div>
                  <div className="flex-1 bg-[#eef5f1] p-3 rounded-xl flex items-center justify-between">
                    <div className="flex flex-col">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs text-[#161d1b]">{stop.name}</span>
                        {stop.isMetro && (
                          <span className="px-1.5 py-0.5 rounded bg-[#6cf8bb] text-[#005236] text-[9px] font-bold">
                            METRO HUB
                          </span>
                        )}
                        {alerts.some(
                          (a) =>
                            a.title?.toLowerCase().includes("detour") &&
                            stop.name.toLowerCase().includes("palarivattom")
                        ) && (
                          <span className="px-1.5 py-0.5 rounded bg-[#ffdad6] text-[#93000a] text-[9px] font-bold">
                            DETOUR ADVISORY
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-[#717976]">{stop.distance} from origin</span>
                    </div>
                    <span className="text-xs font-bold text-[#006c49] tnum">{stop.time}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Prototype Notice Dialog */}
            {showDispatchNotice && (
              <div className="p-3 bg-[#fed7aa] text-[#9a3412] rounded-xl text-xs flex items-center justify-between">
                <span>
                  <strong>Prototype Simulation:</strong> Route corridor adjustments require physical in-vehicle MDT dispatch authorization. Operational mutations disabled in H7.
                </span>
                <button
                  type="button"
                  onClick={() => setShowDispatchNotice(false)}
                  className="text-xs font-bold underline ml-2"
                >
                  Dismiss
                </button>
              </div>
            )}

            {/* Corridor Control Actions */}
            <div className="pt-3 border-t border-[#eef5f1] flex items-center justify-between gap-3">
              <span className="text-xs text-[#717976]">
                Geofence sync: {lastRefreshed.toLocaleTimeString()}
              </span>
              <button
                type="button"
                onClick={() => setShowDispatchNotice(true)}
                className="px-4 py-2 rounded-xl bg-[#123c35] text-white text-xs font-bold hover:bg-[#002620] transition-colors flex items-center gap-1.5"
              >
                <span>Dispatch Corridor Adjustment</span>
                <span className="px-1.5 py-0.2 rounded bg-white/20 text-[9px] uppercase tracking-wider">PROTOTYPE</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
