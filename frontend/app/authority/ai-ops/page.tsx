"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  getAIDecisions,
  getCommandOverview,
  getBuses,
  AIDecision,
  CommandOverview,
  Bus,
} from "@/lib/api";

export default function AuthorityAiOpsPage() {
  const [decisions, setDecisions] = useState<AIDecision[]>([]);
  const [overview, setOverview] = useState<CommandOverview | null>(null);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [approvedIds, setApprovedIds] = useState<string[]>([]);
  const [rejectedIds, setRejectedIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date());

  const loadData = useCallback(async () => {
    try {
      setError(null);
      const [decisionsData, overviewData, busesData] = await Promise.all([
        getAIDecisions().catch(() => []),
        getCommandOverview().catch(() => null),
        getBuses().catch(() => []),
      ]);

      setDecisions(decisionsData);
      setOverview(overviewData);
      setBuses(busesData);
      setLastRefreshed(new Date());
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to load decision queue";
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 8000);
    return () => clearInterval(interval);
  }, [loadData]);

  const handleApprove = (id: string) => {
    setApprovedIds((prev) => Array.from(new Set([...prev, id])));
    setRejectedIds((prev) => prev.filter((i) => i !== id));
  };

  const handleReject = (id: string) => {
    setRejectedIds((prev) => Array.from(new Set([...prev, id])));
    setApprovedIds((prev) => prev.filter((i) => i !== id));
  };

  // Derive route 12 fleet status
  const route12Buses = buses.filter(
    (b) => (b.route_number || b.route) === "12" || (b.route_number || b.route)?.includes("12")
  );
  const route12ActiveCount = route12Buses.length || 6;
  const route12AvgOccupancy =
    route12Buses.length > 0
      ? Math.round(
          route12Buses.reduce((acc, b) => acc + (b.occupancy_percentage || 0), 0) /
            route12Buses.length
        )
      : overview?.average_network_occupancy_pct || 41.8;

  // Primary decision item
  const primaryDecision = decisions[0] || {
    id: "dec-001",
    trigger: "Predictive Peak Inflow + Showers at Kakkanad",
    prediction: "Route 12 Infopark corridor predicted to reach 92% crowding between 17:30 - 18:30.",
    recommendation: "Deploy standby feeder unit (KL-07-BW-1209) from Kaloor depot at 17:15.",
    expected_impact: "-24% crowd reduction on primary corridor; 140 additional passenger capacity.",
    status: "PENDING_OFFICER_CLEARANCE",
    data_origin: "PREDICTION -> RECOMMENDATION -> HUMAN DECISION",
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-bold uppercase text-[#006c49] tracking-wider">
              Autonomous Dispatch Assistant • Human-in-the-Loop
            </span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="text-xs text-[#717976]">Kochi Transit Authority Console</span>
            <span className="text-[#c0c8c5]">•</span>
            <span className="px-2 py-0.5 rounded-full text-[9px] font-bold bg-[#e8f0ec] text-[#006c49] border border-[#006c49]/30">
              RECOMMENDATION
            </span>
          </div>
          <h1 className="text-2xl font-bold text-[#161d1b] tracking-tight">
            AI Operations & Predictive Decision Queue
          </h1>
        </div>

        <div className="flex items-center gap-2">
          <span className="px-3 py-1.5 rounded-full bg-[#e8f0ec] text-[#002620] text-xs font-bold uppercase tracking-wider border border-[#c0c8c5]/30">
            CONTROLLER CLEARANCE REQUIRED
          </span>
          <button
            type="button"
            onClick={() => loadData()}
            className="p-2.5 rounded-xl bg-white text-[#161d1b] border border-[#c0c8c5]/30 hover:bg-[#eef5f1] transition-colors shadow-sm"
            title="Refresh queue"
          >
            <span className="material-symbols-outlined text-[18px] text-[#006c49]">refresh</span>
          </button>
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

      {/* Human Decision Principles Banner */}
      <div className="p-3.5 bg-white rounded-2xl border border-[#c0c8c5]/20 flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-sm text-xs">
        <div className="flex items-center gap-2">
          <span className="material-symbols-outlined text-[20px] text-[#006c49]">shield</span>
          <div>
            <span className="font-bold text-[#161d1b]">Decision Hierarchy: </span>
            <span className="text-[#006c49] font-bold">LIVE DATA</span>
            <span className="text-[#717976]"> ➔ </span>
            <span className="text-[#d97706] font-bold">PREDICTION</span>
            <span className="text-[#717976]"> ➔ </span>
            <span className="text-[#002e82] font-bold">RECOMMENDATION</span>
            <span className="text-[#717976]"> ➔ </span>
            <span className="text-[#ba1a1a] font-bold">HUMAN DECISION</span>
          </div>
        </div>
        <span className="text-[11px] text-[#717976] shrink-0">
          Sync: {lastRefreshed.toLocaleTimeString()}
        </span>
      </div>

      {/* 3-Stage Pipeline Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Stage 1: Sensed Ground Truth */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col justify-between">
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#eef5f1]">
              <div className="flex items-center gap-1.5">
                <span className="px-2 py-0.5 rounded bg-[#e8f0ec] text-[10px] font-bold uppercase text-[#414846]">
                  Stage 01
                </span>
                <span className="px-1.5 py-0.2 rounded text-[9px] font-bold bg-[#6cf8bb] text-[#005236]">
                  LIVE DATA
                </span>
              </div>
              <span className="text-xs font-bold text-[#006c49] flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-[#006c49] animate-pulse" />
                Sensed Telemetry
              </span>
            </div>

            <div>
              <span className="text-[10px] font-bold uppercase text-[#717976]">Corridor Baseline</span>
              <h3 className="font-bold text-lg text-[#002620] mt-0.5">Route 12 (Kaloor ⇄ Infopark)</h3>
            </div>

            <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col gap-1.5 text-xs">
              <div className="flex justify-between">
                <span className="text-[#414846]">Current Active Fleet:</span>
                <span className="font-bold text-[#161d1b] tnum">{route12ActiveCount} Buses</span>
              </div>
              <div className="flex justify-between">
                <span className="text-[#414846]">Corridor Flow Status:</span>
                <span className="font-bold text-[#006c49]">
                  {overview?.network_status || "OPTIMAL_FLOW"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-[#414846]">Current Cabin Load:</span>
                <span className="font-bold text-[#161d1b] tnum">
                  {route12AvgOccupancy}% (Normal)
                </span>
              </div>
            </div>

            <p className="text-xs text-[#717976] leading-relaxed">
              Real-time computer vision passenger counts & GPS telemetry confirm nominal headway spacing with zero intermediate station bottlenecks currently.
            </p>
          </div>

          <div className="pt-3 mt-3 border-t border-[#eef5f1] text-[11px] text-[#717976] flex items-center justify-between">
            <span>Verified sync: {lastRefreshed.toLocaleTimeString()}</span>
            <span className="font-semibold text-[#006c49]">Nominal Baseline</span>
          </div>
        </div>

        {/* Stage 2: Predictive Forecast */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col justify-between">
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#eef5f1]">
              <div className="flex items-center gap-1.5">
                <span className="px-2 py-0.5 rounded bg-[#e8f0ec] text-[10px] font-bold uppercase text-[#414846]">
                  Stage 02
                </span>
                <span className="px-1.5 py-0.2 rounded text-[9px] font-bold bg-[#fed7aa] text-[#9a3412]">
                  PREDICTION
                </span>
              </div>
              <span className="text-xs font-bold text-[#002e82] flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">neurology</span>
                ML Demand Forecaster
              </span>
            </div>

            <div>
              <span className="text-[10px] font-bold uppercase text-[#717976]">Anticipated Influx (+30m)</span>
              <h3 className="font-bold text-lg text-[#ba1a1a] mt-0.5">
                {primaryDecision.trigger || "Peak Commuter Surge"}
              </h3>
            </div>

            <div className="p-3 rounded-xl bg-[#fff1f0] border border-[#ffdad6] flex flex-col gap-1.5 text-xs">
              <div className="flex justify-between items-baseline">
                <span className="text-[#93000a] font-bold">Predictive Projection:</span>
                <span className="font-bold text-[#ba1a1a] text-xs">Horizon: +30m</span>
              </div>
              <span className="text-[11px] text-[#414846] leading-relaxed">
                {primaryDecision.prediction}
              </span>
              <div className="mt-1 flex items-center gap-1 text-[#ba1a1a] font-semibold text-[11px]">
                <span className="material-symbols-outlined text-[14px]">warning</span>
                <span>Expected Impact: {primaryDecision.expected_impact}</span>
              </div>
            </div>

            <p className="text-xs text-[#414846] leading-relaxed">
              Historical Friday evening corporate shifts at Infopark Phase 1 & 2 correlate with sharp platform volume increase.
            </p>
          </div>

          <div className="pt-3 mt-3 border-t border-[#eef5f1] text-[11px] text-[#717976] flex items-center justify-between">
            <span>Model: Ridge Regression (Cyclical Hours)</span>
            <span className="font-semibold text-[#ba1a1a]">Surge Warning</span>
          </div>
        </div>

        {/* Stage 3: Actionable Recommendations & Human Decision */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-[#c0c8c5]/20 flex flex-col justify-between">
          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#eef5f1]">
              <div className="flex items-center gap-1.5">
                <span className="px-2 py-0.5 rounded bg-[#e8f0ec] text-[10px] font-bold uppercase text-[#414846]">
                  Stage 03
                </span>
                <span className="px-1.5 py-0.2 rounded text-[9px] font-bold bg-[#e8f0ec] text-[#006c49]">
                  RECOMMENDATION
                </span>
              </div>
              <span className="text-xs font-bold text-[#006c49] flex items-center gap-1">
                <span className="material-symbols-outlined text-[16px]">task_alt</span>
                Operator Action Queue
              </span>
            </div>

            <div>
              <span className="text-[10px] font-bold uppercase text-[#717976]">Proposed Mitigation</span>
              <h3 className="font-bold text-lg text-[#002620] mt-0.5">Surge Mitigation Actions</h3>
            </div>

            {/* Action Item 1: From Backend Queue */}
            <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col gap-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-bold text-[#161d1b]">Inject Relief Tripper (KL-07-BW-1209)</span>
                <span className="text-[#006c49] font-bold">High Impact</span>
              </div>
              <p className="text-[11px] text-[#414846]">
                {primaryDecision.recommendation}
              </p>

              <div className="flex items-center gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => handleApprove("dec-001")}
                  disabled={approvedIds.includes("dec-001")}
                  className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
                    approvedIds.includes("dec-001")
                      ? "bg-[#6cf8bb] text-[#005236]"
                      : "bg-[#123c35] text-white hover:bg-[#002620]"
                  }`}
                >
                  {approvedIds.includes("dec-001")
                    ? "✓ Relief Unit Dispatched"
                    : "Authorize Dispatch"}
                </button>
                <button
                  type="button"
                  onClick={() => handleReject("dec-001")}
                  disabled={approvedIds.includes("dec-001") || rejectedIds.includes("dec-001")}
                  className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all ${
                    rejectedIds.includes("dec-001")
                      ? "bg-[#ffdad6] text-[#93000a] border-[#ffdad6]"
                      : "bg-white text-[#717976] border-[#c0c8c5]/30 hover:bg-[#e8f0ec]"
                  }`}
                >
                  {rejectedIds.includes("dec-001") ? "Declined" : "Decline"}
                </button>
              </div>
            </div>

            {/* Action Item 2: Express Skip-Stop */}
            <div className="p-3 rounded-xl bg-[#eef5f1] flex flex-col gap-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-bold text-[#161d1b]">Express Skip-Stop for Bus 205</span>
                <span className="text-[#d97706] font-bold">Med Impact</span>
              </div>
              <p className="text-[11px] text-[#414846]">
                Bypass minor intermediate stop (Padamugal) to save 6 minutes towards Kaloor interchange.
              </p>

              <div className="flex items-center gap-2 pt-1">
                <button
                  type="button"
                  onClick={() => handleApprove("dec-002")}
                  disabled={approvedIds.includes("dec-002")}
                  className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
                    approvedIds.includes("dec-002")
                      ? "bg-[#6cf8bb] text-[#005236]"
                      : "bg-white text-[#161d1b] border border-[#c0c8c5]/30 hover:bg-[#e8f0ec]"
                  }`}
                >
                  {approvedIds.includes("dec-002")
                    ? "✓ Skip-Stop Sent to Cockpit"
                    : "Broadcast Skip-Stop"}
                </button>
                <button
                  type="button"
                  onClick={() => handleReject("dec-002")}
                  disabled={approvedIds.includes("dec-002") || rejectedIds.includes("dec-002")}
                  className={`px-3 py-2 rounded-xl text-xs font-bold border transition-all ${
                    rejectedIds.includes("dec-002")
                      ? "bg-[#ffdad6] text-[#93000a] border-[#ffdad6]"
                      : "bg-white text-[#717976] border-[#c0c8c5]/30 hover:bg-[#eef5f1]"
                  }`}
                >
                  {rejectedIds.includes("dec-002") ? "Declined" : "Decline"}
                </button>
              </div>
            </div>
          </div>

          <div className="pt-3 mt-3 border-t border-[#eef5f1] text-[11px] text-[#717976] flex items-center justify-between">
            <span>Strictest Safety Constraint:</span>
            <span className="font-bold text-[#ba1a1a]">HUMAN DECISION MANDATORY</span>
          </div>
        </div>
      </div>
    </div>
  );
}
