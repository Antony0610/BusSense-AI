"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { getCurrentAuthUser, switchDemoRole, clearAuthSession, AuthUser } from "@/lib/api";

export default function AuthorityLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [currentTime, setCurrentTime] = useState("14:32:08 IST");
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(null);
  const [authStatus, setAuthStatus] = useState<"checking" | "authorized" | "unauthorized" | "forbidden">("checking");
  const [isAuthenticating, setIsAuthenticating] = useState(false);

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString("en-IN", { hour12: false, hour: "2-digit", minute: "2-digit", second: "2-digit" }) +
          " IST"
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    function verifyAuth() {
      const user = getCurrentAuthUser();
      if (!user) {
        setAuthStatus("unauthorized");
      } else if (user.role !== "AUTHORITY" && user.role !== "ADMIN") {
        setCurrentUser(user);
        setAuthStatus("forbidden");
      } else {
        setCurrentUser(user);
        setAuthStatus("authorized");
      }
    }
    verifyAuth();
  }, [pathname]);

  const handleAuthorizeDemo = async () => {
    setIsAuthenticating(true);
    try {
      const res = await switchDemoRole("authority");
      setCurrentUser(res.user);
      setAuthStatus("authorized");
    } catch (err) {
      console.error("Failed to authorize as authority:", err);
    } finally {
      setIsAuthenticating(false);
    }
  };

  const handleSignOut = () => {
    clearAuthSession();
    router.push("/roles");
  };

  const navItems = [
    { label: "Overview", path: "/authority/command", icon: "grid_view" },
    { label: "Live Fleet", path: "/authority/fleet", icon: "fmd_good" },
    { label: "Routes & Network", path: "/authority/routes", icon: "alt_route" },
    { label: "Alerts & Incidents", path: "/authority/alerts", icon: "warning" },
  ];

  const operationalModules = [
    { label: "Crowd Forecast", path: "/authority/forecast", icon: "bar_chart" },
    { label: "AI Operations", path: "/authority/ai-ops", icon: "psychology" },
    { label: "Reports Archive", path: "/authority/reports", icon: "description" },
  ];

  if (authStatus === "checking") {
    return (
      <div className="bg-[#f3fbf7] min-h-screen flex items-center justify-center p-4">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 rounded-full border-2 border-[#006c49] border-t-transparent animate-spin" />
          <span className="text-xs font-bold uppercase tracking-wider text-[#414846]">Verifying Authority Clearance...</span>
        </div>
      </div>
    );
  }

  if (authStatus === "unauthorized") {
    return (
      <div className="bg-[#f3fbf7] min-h-screen flex items-center justify-center p-4 font-sans">
        <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-lg border border-[#c0c8c5]/30 flex flex-col gap-4 text-center">
          <div className="w-14 h-14 rounded-2xl bg-[#ffdad6] text-[#ba1a1a] flex items-center justify-center mx-auto">
            <span className="material-symbols-outlined text-[32px]">lock</span>
          </div>
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#ba1a1a]">HTTP 401 Unauthorized</span>
            <h2 className="text-xl font-bold text-[#161d1b] mt-1">Authority Clearance Required</h2>
            <p className="text-xs text-[#414846] mt-2 leading-relaxed">
              The Transit Command Center is restricted to authorized operations controllers and transport agency personnel.
            </p>
          </div>
          <div className="flex flex-col gap-2 pt-2">
            <button
              onClick={handleAuthorizeDemo}
              disabled={isAuthenticating}
              className="w-full py-3 rounded-xl bg-[#123c35] text-white text-xs font-bold hover:bg-[#002620] transition-colors flex items-center justify-center gap-2 shadow-sm"
            >
              {isAuthenticating ? (
                <span>Authenticating...</span>
              ) : (
                <>
                  <span className="material-symbols-outlined text-[18px]">badge</span>
                  <span>Authorize as Duty Controller (Demo)</span>
                </>
              )}
            </button>
            <Link
              href="/roles"
              className="w-full py-2.5 rounded-xl bg-[#eef5f1] text-[#161d1b] text-xs font-bold hover:bg-[#e8f0ec] transition-colors"
            >
              Back to Role Selection
            </Link>
          </div>
        </div>
      </div>
    );
  }

  if (authStatus === "forbidden") {
    return (
      <div className="bg-[#f3fbf7] min-h-screen flex items-center justify-center p-4 font-sans">
        <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-lg border border-[#ffdad6] flex flex-col gap-4 text-center">
          <div className="w-14 h-14 rounded-2xl bg-[#ffdad6] text-[#93000a] flex items-center justify-center mx-auto">
            <span className="material-symbols-outlined text-[32px]">no_accounts</span>
          </div>
          <div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#ba1a1a]">HTTP 403 Forbidden</span>
            <h2 className="text-xl font-bold text-[#161d1b] mt-1">Role Permission Mismatch</h2>
            <p className="text-xs text-[#414846] mt-2 leading-relaxed">
              Your active session is authenticated as <strong>{currentUser?.role || "PASSENGER"}</strong>. You must be authenticated as <strong>AUTHORITY</strong> to access regional transit operations.
            </p>
          </div>
          <div className="flex flex-col gap-2 pt-2">
            <button
              onClick={handleAuthorizeDemo}
              disabled={isAuthenticating}
              className="w-full py-3 rounded-xl bg-[#006c49] text-white text-xs font-bold hover:bg-[#005236] transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">swap_horiz</span>
              <span>Switch to Authority Role</span>
            </button>
            <Link
              href="/roles"
              className="w-full py-2.5 rounded-xl bg-[#eef5f1] text-[#161d1b] text-xs font-bold hover:bg-[#e8f0ec] transition-colors"
            >
              Return to Role Selector
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-[#f3fbf7] text-[#161d1b] min-h-screen flex antialiased font-sans">
      {/* Fixed Left Navigation Sidebar */}
      <aside className="fixed left-0 top-0 h-full w-64 lg:w-72 bg-white border-r border-[#c0c8c5]/30 z-50 flex flex-col justify-between shadow-sm">
        <div className="flex flex-col">
          {/* Brand Header */}
          <div className="h-16 px-6 flex items-center gap-3 bg-[#123c35] text-white">
            <div className="w-8 h-8 rounded-lg bg-[#006c49] flex items-center justify-center text-white shrink-0">
              <span className="material-symbols-outlined text-[20px]">directions_bus</span>
            </div>
            <div className="flex flex-col min-w-0">
              <span className="font-bold text-base tracking-tight truncate">BusSense AI</span>
              <span className="text-[10px] font-bold uppercase tracking-wider text-[#7da79d]">
                Transit Operations
              </span>
            </div>
          </div>

          {/* Section: Active Consoles */}
          <div className="px-6 pt-5 pb-2">
            <span className="text-[10px] font-bold uppercase text-[#717976] tracking-wider">Active Consoles</span>
          </div>
          <nav className="px-3 flex flex-col gap-1">
            {navItems.map((item) => {
              const isActive = pathname === item.path;
              return (
                <Link
                  key={item.path}
                  href={item.path}
                  className={`flex items-center px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors ${
                    isActive
                      ? "bg-[#123c35] text-white shadow-sm"
                      : "text-[#414846] hover:bg-[#eef5f1] hover:text-[#161d1b]"
                  }`}
                >
                  <span
                    className={`material-symbols-outlined mr-3 text-[20px] ${
                      isActive ? "text-[#6cf8bb]" : "text-[#717976]"
                    }`}
                  >
                    {item.icon}
                  </span>
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          {/* Section: Operational Modules */}
          <div className="px-6 pt-6 pb-2">
            <span className="text-[10px] font-bold uppercase text-[#717976] tracking-wider">Operational Modules</span>
          </div>
          <nav className="px-3 flex flex-col gap-1">
            {operationalModules.map((item) => {
              const isActive = pathname === item.path;
              return (
                <Link
                  key={item.path}
                  href={item.path}
                  className={`flex items-center px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors ${
                    isActive
                      ? "bg-[#123c35] text-white shadow-sm"
                      : "text-[#414846] hover:bg-[#eef5f1] hover:text-[#161d1b]"
                  }`}
                >
                  <span
                    className={`material-symbols-outlined mr-3 text-[20px] ${
                      isActive ? "text-[#6cf8bb]" : "text-[#717976]"
                    }`}
                  >
                    {item.icon}
                  </span>
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        {/* Footer Station Node Pill & Role Switcher */}
        <div className="p-4 mx-3 mb-4 bg-[#eef5f1] rounded-2xl flex flex-col gap-2 border border-[#c0c8c5]/20">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-bold uppercase text-[#414846]">Terminal Node</span>
            <span className="text-[10px] font-bold text-[#006c49]">SECURE L3</span>
          </div>
          <div className="text-xs text-[#717976] leading-tight">
            Station node #KR-COK-01 • Standby sync auto-engaged
          </div>
          <div className="flex items-center gap-1.5 mt-1">
            <Link
              href="/roles"
              className="flex-1 py-1.5 rounded-xl bg-white text-[#002620] text-xs font-bold text-center border border-[#c0c8c5]/30 hover:bg-[#e8f0ec] transition-colors"
            >
              Switch Role
            </Link>
            <button
              onClick={handleSignOut}
              title="Sign Out Session"
              className="p-1.5 rounded-xl bg-white text-[#ba1a1a] border border-[#c0c8c5]/30 hover:bg-[#ffdad6] transition-colors flex items-center justify-center"
            >
              <span className="material-symbols-outlined text-[18px]">logout</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Main Workspace Frame */}
      <div className="pl-64 lg:pl-72 flex-1 flex flex-col min-w-0">
        {/* Fixed Top Status Header */}
        <header className="fixed top-0 left-64 lg:left-72 right-0 h-16 bg-white/95 backdrop-blur-md border-b border-[#c0c8c5]/30 z-40 flex items-center justify-between px-6">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[#006c49] animate-pulse" />
              <span className="text-xs font-bold uppercase tracking-wider text-[#161d1b]">
                Greater Kochi Region • Live Fleet Simulation
              </span>
            </div>
            <div className="h-4 w-px bg-[#dce4e0] hidden sm:block" />
            <div className="hidden sm:flex items-center gap-1.5 text-[#414846] text-xs">
              <span className="material-symbols-outlined text-[16px] text-[#006c49]">sync</span>
              <span className="font-semibold text-[#161d1b] tnum">98.4% On-Time Sync</span>
            </div>
          </div>

          <div className="flex items-center gap-6">
            <div className="flex items-center gap-1.5 text-[#414846] text-xs">
              <span className="material-symbols-outlined text-[16px]">schedule</span>
              <span className="font-semibold text-[#161d1b] tnum">{currentTime}</span>
            </div>
            <div className="h-4 w-px bg-[#dce4e0]" />
            <div className="flex items-center gap-3">
              <div className="flex flex-col text-right">
                <span className="text-xs font-bold text-[#161d1b]">
                  {currentUser?.full_name || "Anjali Menon (Traffic Controller)"}
                </span>
                <span className="text-[10px] font-bold uppercase text-[#006c49]">
                  {currentUser?.role || "AUTHORITY"} • Clear L3
                </span>
              </div>
              <div className="w-8 h-8 rounded-full bg-[#002620] text-white flex items-center justify-center font-bold text-xs">
                {currentUser?.full_name ? currentUser.full_name[0].toUpperCase() : "A"}
              </div>
            </div>
          </div>
        </header>

        {/* Child Pages Content Canvas */}
        <main className="w-full pt-16 bg-[#f3fbf7] px-6 py-6 min-h-screen">{children}</main>
      </div>
    </div>
  );
}

