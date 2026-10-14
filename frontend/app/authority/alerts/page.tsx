"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  getIncidents,
  getAlerts,
  resolveIncident,
  IncidentData,
  Alert,
} from "@/lib/api";

export default function AuthorityAlertsPage() {
  const [incidents, setIncidents] = useState<IncidentData[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [selectedIncidentId, setSelectedIncidentId] = useState<string>("");
  const [resolutionNote, setResolutionNote] = useState("");
  const [resolvedIds, setResolvedIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [resolving, setResolving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date());

  const loadData = useCallback(async () => {
    try {
      setError(null);
      const [incidentsData, alertsData] = await Promise.all([
        getIncidents().catch(() => []),
        getAlerts().catch(() => []),
      ]);

      setIncidents(incidentsData);
      setAlerts(alertsData);
      setLastRefreshed(new Date());

      // Track server-side resolved incidents
      const serverResolved = incidentsData
        .filter((i) => i.status === "RESOLVED")
        .map((i) => i.id);
      setResolvedIds((prev) => Array.from(new Set([...prev, ...serverResolved])));

      if (incidentsData.length > 0 && !selectedIncidentId) {
        setSelectedIncidentId(incidentsData[0].id);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load operational incidents";
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [selectedIncidentId]);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, [loadData]);

  // Current selected incident
  const currentIncident =
    incidents.find((i) => i.id === selectedIncidentId) ||
    incidents[0] || {
      id: "INC-FALLBACK",
      title: "No active incidents in queue",
      description: "Corridor telemetry confirms normal operating parameters across all sectors.",
      category: "DISPATCH",
      severity: "INFO",
      status: "RESOLVED",
      bus_number: "205",
      created_at: new Date().toISOString(),
      reporter_id: "System Monitor",
    };

  const isCurrentResolved =
    resolvedIds.includes(currentIncident.id) || currentIncident.status === "RESOLVED";

  const handleResolve = async () => {
    if (!currentIncident.id || isCurrentResolved) return;
    setResolving(true);
    setSuccessMsg(null);
    try {
      await resolveIncident(
        currentIncident.id,
        resolutionNote || "Resolved by Duty Officer via Command Console."
      );
      setResolvedIds((prev) => [...prev, currentIncident.id]);
      setSuccessMsg(`Incident ${currentIncident.id} successfully marked RESOLVED in Supabase ledger.`);
      setResolutionNote("");
      // Update local state
      setIncidents((prev) =>
        prev.map((inc) =>
          inc.id === currentIncident.id ? { ...inc, status: "RESOLVED" } : inc
        )
      );
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to resolve incident";
      setError(msg);
    } finally {
      setResolving(false);
    }
  };

  // Metrics calculation
  const warningCount = incidents.filter(
    (i) => i.severity === "WARNING" && !resolvedIds.includes(i.id) && i.status !== "RESOLVED"
  ).length;

  const investigatingCount = incidents.filter(
    (i) =>
      (i.status === "REPORTED" || i.status === "INVESTIGATING") &&
      !resolvedIds.includes(i.id)
  ).length;

  const totalResolvedCount = resolvedIds.length;

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header and Triage Counters */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-bold uppercase text-[#006c49] tracking-wider">
              Operational Incident Queue
            </span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="text-xs text-[#717976]">Real-time Duty Officer Triage</span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-[#e8f0ec] text-[#006c49] border border-[#006c49]/30">
              LIVE DATA
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#161d1b] tracking-tight">Alerts & Operational Incidents</h1>
        </div>

        {/* Counters */}
        <div className="flex items-center gap-3">
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white px-4 py-2.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col">
              <span className="text-[10px] font-bold uppercase text-[#ba1a1a]">Warnings</span>
              <span className="text-xl font-bold text-[#161d1b] tnum">{warningCount}</span>
            </div>
            <div className="bg-white px-4 py-2.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col">
              <span className="text-[10px] font-bold uppercase text-[#d97706]">Investigating</span>
              <span className="text-xl font-bold text-[#161d1b] tnum">{investigatingCount}</span>
            </div>
            <div className="bg-white px-4 py-2.5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col">
              <span className="text-[10px] font-bold uppercase text-[#006c49]">Resolved</span>
              <span className="text-xl font-bold text-[#161d1b] tnum">{totalResolvedCount}</span>
            </div>
          </div>
          <button
            type="button"
            onClick={() => loadData()}
            className="p-3 rounded-2xl bg-white text-[#161d1b] border border-[#c0c8c5]/30 hover:bg-[#eef5f1] transition-colors shadow-sm"
            title="Refresh incident ledger"
          >
            <span className="material-symbols-outlined text-[18px] text-[#006c49]">refresh</span>
          </button>
        </div>
      </div>

      {/* Notifications / Alerts Banner */}
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

      {successMsg && (
        <div className="p-4 rounded-2xl bg-[#e8f0ec] text-[#005236] text-xs flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">check_circle</span>
            <span>{successMsg}</span>
          </div>
          <button
            type="button"
            onClick={() => setSuccessMsg(null)}
            className="text-xs font-bold underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Public Service Advisories Strip */}
      {alerts.length > 0 && (
        <div className="p-3 bg-[#eef5f1] rounded-2xl border border-[#c0c8c5]/30 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px] text-[#006c49]">campaign</span>
            <span className="font-bold text-[#002620]">Public Service Advisories:</span>
            <span className="text-[#414846]">{alerts[0].title} — {alerts[0].message}</span>
          </div>
          <span className="text-[10px] text-[#717976] shrink-0">
            {alerts.length} active network broadcast{alerts.length > 1 ? "s" : ""}
          </span>
        </div>
      )}

      {/* Split Triage Workspace */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-5 items-start">
        {/* Left: Incident Queue (5 cols) */}
        <div className="xl:col-span-5 flex flex-col gap-3">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold uppercase text-[#717976]">Active Incident Queue</span>
            <span className="text-[11px] text-[#717976]">
              {loading ? "Loading..." : `${incidents.length} Records in Ledger`}
            </span>
          </div>

          {loading && incidents.length === 0 ? (
            <div className="flex flex-col gap-2.5">
              {[1, 2, 3].map((n) => (
                <div key={n} className="p-4 bg-white rounded-2xl border border-[#c0c8c5]/30 animate-pulse h-24" />
              ))}
            </div>
          ) : incidents.length === 0 ? (
            <div className="bg-white p-8 rounded-2xl border border-[#c0c8c5]/30 text-center flex flex-col items-center gap-2">
              <span className="material-symbols-outlined text-[32px] text-[#006c49]">check_circle</span>
              <span className="font-bold text-sm text-[#161d1b]">Zero Unresolved Incidents</span>
              <p className="text-xs text-[#717976]">
                All corridor routes operating with standard clearance. No pending driver incident tickets.
              </p>
            </div>
          ) : (
            <div className="flex flex-col gap-2.5">
              {incidents.map((incident) => {
                const isSelected = selectedIncidentId === incident.id;
                const isResolved =
                  resolvedIds.includes(incident.id) || incident.status === "RESOLVED";

                return (
                  <div
                    key={incident.id}
                    onClick={() => setSelectedIncidentId(incident.id)}
                    className={`p-4 bg-white rounded-2xl border transition-all cursor-pointer shadow-sm relative overflow-hidden ${
                      isSelected
                        ? "border-[#002620] ring-2 ring-[#002620]/15"
                        : "border-[#c0c8c5]/30 hover:border-[#002620]/30"
                    }`}
                  >
                    <div
                      className={`absolute left-0 top-0 bottom-0 w-1.5 ${
                        isResolved
                          ? "bg-[#006c49]"
                          : incident.severity === "WARNING"
                          ? "bg-[#ba1a1a]"
                          : "bg-[#d97706]"
                      }`}
                    />
                    <div className="flex items-start justify-between gap-2 pl-2">
                      <div className="flex flex-col">
                        <div className="flex items-center gap-1.5">
                          <span
                            className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase ${
                              isResolved
                                ? "bg-[#e8f0ec] text-[#006c49]"
                                : incident.severity === "WARNING"
                                ? "bg-[#ffdad6] text-[#93000a]"
                                : "bg-[#fed7aa] text-[#9a3412]"
                            }`}
                          >
                            {isResolved ? "RESOLVED" : incident.severity}
                          </span>
                          <span className="font-bold text-xs text-[#161d1b]">
                            Bus {incident.bus_number || "205"}
                          </span>
                          <span className="text-[10px] text-[#717976]">
                            [{incident.category || "GENERAL"}]
                          </span>
                        </div>
                        <h4 className="font-bold text-sm text-[#161d1b] mt-1">{incident.title}</h4>
                        <span className="text-[11px] text-[#717976] mt-0.5 line-clamp-1">
                          {incident.description}
                        </span>
                      </div>
                      <span className="text-[10px] text-[#717976] shrink-0 tnum">
                        {incident.created_at ? new Date(incident.created_at).toLocaleTimeString() : "Recent"}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right: Incident Inspector & Resolution Controls (7 cols) */}
        <div className="xl:col-span-7 flex flex-col gap-4">
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-[#c0c8c5]/20 flex flex-col gap-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#eef5f1]">
              <div className="flex flex-col">
                <span className="text-[10px] font-bold uppercase text-[#717976]">Incident Details</span>
                <h3 className="font-bold text-lg text-[#161d1b]">{currentIncident.title}</h3>
              </div>
              <span
                className={`px-2.5 py-1 rounded text-xs font-bold uppercase ${
                  isCurrentResolved
                    ? "bg-[#6cf8bb] text-[#005236]"
                    : "bg-[#ffdad6] text-[#93000a]"
                }`}
              >
                {isCurrentResolved ? "RESOLVED" : currentIncident.status || "INVESTIGATING"}
              </span>
            </div>

            {/* Context Fields */}
            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                <span className="text-[#717976] uppercase text-[10px] font-bold">Vehicle ID & Sector</span>
                <span className="font-bold text-[#161d1b] mt-1">Bus {currentIncident.bus_number || "205"}</span>
                <span className="text-[11px] text-[#414846]">Category: {currentIncident.category}</span>
              </div>
              <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col">
                <span className="text-[#717976] uppercase text-[10px] font-bold">Logged Source & Time</span>
                <span className="font-bold text-[#161d1b] mt-1">
                  {currentIncident.reporter_id ? `Crew Ref: ${currentIncident.reporter_id.slice(0, 8)}` : "Crew Console"}
                </span>
                <span className="text-[11px] text-[#414846] tnum">
                  {currentIncident.created_at ? new Date(currentIncident.created_at).toLocaleString() : "Live Telemetry"}
                </span>
              </div>
            </div>

            {/* Narrative Description */}
            <div className="p-3.5 rounded-xl bg-[#f3fbf7] border border-[#c0c8c5]/20 text-xs text-[#414846] leading-relaxed">
              <span className="font-bold text-[#161d1b] block mb-1">Crew Report Narrative:</span>
              {currentIncident.description}
            </div>

            {/* Resolution Form */}
            <div className="flex flex-col gap-2 pt-2 border-t border-[#eef5f1]">
              <label className="text-xs font-bold text-[#161d1b]">Duty Officer Action Notes:</label>
              <textarea
                value={resolutionNote}
                onChange={(e) => setResolutionNote(e.target.value)}
                disabled={isCurrentResolved}
                placeholder="Log resolution actions (e.g. Police detour coordination verified, recovery unit dispatched)..."
                rows={2}
                className="w-full p-3 rounded-xl bg-[#eef5f1] text-xs text-[#161d1b] focus:outline-none focus:ring-2 focus:ring-[#123c35] disabled:opacity-60"
              />

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={handleResolve}
                  disabled={isCurrentResolved || resolving || !currentIncident.id}
                  className={`flex-1 py-2.5 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 ${
                    isCurrentResolved
                      ? "bg-[#6cf8bb] text-[#005236]"
                      : "bg-[#123c35] text-white hover:bg-[#002620]"
                  }`}
                >
                  {resolving && (
                    <span className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  )}
                  <span>
                    {isCurrentResolved
                      ? "✓ Marked Resolved in Operations Ledger"
                      : resolving
                      ? "Persisting Resolution to Ledger..."
                      : "Authorize Resolution & Close Incident"}
                  </span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
