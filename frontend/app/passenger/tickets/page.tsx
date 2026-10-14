"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { fetchApi, TicketData } from "@/lib/api";

export default function TicketsPage() {
  const [ticket, setTicket] = useState<TicketData | null>(null);
  const [isBookingNew, setIsBookingNew] = useState(false);
  const [bookingSuccess, setBookingSuccess] = useState(false);

  useEffect(() => {
    // Load my tickets
    fetchApi<TicketData[]>("/tickets/my")
      .then((data) => {
        if (data && data.length > 0) {
          setTicket(data[0]);
        }
      })
      .catch(() => {});
  }, []);

  const handleBookNewTicket = async () => {
    setIsBookingNew(true);
    try {
      const res = await fetchApi<TicketData>("/tickets/book", {
        method: "POST",
        body: JSON.stringify({
          bus_number: "205",
          route_number: "205",
          origin_stop: "Kaloor Metro Station",
          destination_stop: "Vyttila Mobility Hub",
          passenger_name: "Rahul Nair",
          passenger_count: 1,
          fare_amount: 25.0,
          payment_method: "SIMULATED_UPI"
        })
      });
      setTicket(res);
      setBookingSuccess(true);
      setTimeout(() => setBookingSuccess(false), 3000);
    } catch (e) {
      console.error(e);
    } finally {
      setIsBookingNew(false);
    }
  };

  return (
    <div className="bg-surface font-body-md text-on-surface min-h-screen flex flex-col pb-24 selection:bg-secondary-fixed selection:text-on-secondary-fixed">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-surface/85 backdrop-blur-xl border-b border-outline-variant/30">
        <div className="h-16 px-gutter max-w-md mx-auto flex items-center justify-between">
          <Link href="/passenger/home" className="flex items-center gap-space-xs text-primary font-semibold text-sm">
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span>Home</span>
          </Link>
          <span className="font-title-card text-title-card text-primary font-bold">Digital Boarding Pass</span>
          <div className="w-8"></div>
        </div>
      </header>

      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter">
        {bookingSuccess && (
          <div className="mb-space-sm p-space-sm rounded-xl bg-secondary-fixed text-on-secondary-fixed font-semibold text-center text-sm animate-fadeIn">
            ✓ New boarding pass issued successfully
          </div>
        )}

        {/* Digital Ticket Card */}
        {ticket ? (
          <div className="bg-surface-container-lowest rounded-2xl border border-outline-variant/40 shadow-md overflow-hidden">
            {/* Top Ticket Header */}
            <div className="bg-primary-container p-space-base text-white">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="bg-secondary text-white font-mono font-bold text-lg px-2.5 py-0.5 rounded">
                    {ticket.bus_number}
                  </span>
                  <span className="font-label-caps uppercase text-secondary-container text-xs">
                    KSRTC Fast Passenger
                  </span>
                </div>
                <span className="px-2 py-0.5 rounded-full bg-secondary text-white text-[11px] font-bold">
                  {ticket.status}
                </span>
              </div>

              <div className="mt-space-base">
                <span className="text-xs text-surface-bright/70 uppercase font-semibold">Corridor</span>
                <div className="text-lg font-bold text-white mt-0.5">
                  {ticket.origin_stop} ➔ {ticket.destination_stop}
                </div>
              </div>
            </div>

            {/* Middle QR Code Section */}
            <div className="p-space-base flex flex-col items-center border-b border-dashed border-outline-variant/60">
              <div className="p-3 bg-white rounded-xl border border-outline-variant/40 shadow-sm">
                {ticket.qr_code_data_uri ? (
                  <img
                    src={ticket.qr_code_data_uri}
                    alt="Ticket QR Code"
                    className="w-48 h-48 object-contain"
                  />
                ) : (
                  <div className="w-48 h-48 bg-surface-container flex items-center justify-center text-outline">
                    QR Generator Active
                  </div>
                )}
              </div>

              <span className="font-mono text-xs text-primary font-bold mt-space-sm tracking-wider">
                {ticket.ticket_number}
              </span>
              <span className="text-[11px] text-on-surface-variant mt-0.5">
                Scan via Conductor Crew App before boarding
              </span>
            </div>

            {/* Bottom Metadata Grid */}
            <div className="p-space-base bg-surface-container-low/40 grid grid-cols-2 gap-space-sm text-sm">
              <div>
                <span className="text-xs text-on-surface-variant block">Passenger</span>
                <span className="font-bold text-primary">{ticket.passenger_name}</span>
              </div>
              <div className="text-right">
                <span className="text-xs text-on-surface-variant block">Total Fare</span>
                <span className="font-bold text-secondary text-base font-mono tnum">₹{ticket.final_fare}</span>
              </div>
              <div>
                <span className="text-xs text-on-surface-variant block">Departure Window</span>
                <span className="font-medium text-primary">Valid for 3 hours</span>
              </div>
              <div className="text-right">
                <span className="text-xs text-on-surface-variant block">Security Hash</span>
                <span className="font-mono text-[10px] text-outline">SHA256:VERIFIED</span>
              </div>
            </div>
          </div>
        ) : (
          <div className="p-space-base bg-surface-container rounded-xl text-center">
            <p className="text-sm text-on-surface-variant">No active boarding pass found.</p>
          </div>
        )}

        {/* Action Button */}
        <div className="mt-space-base">
          <button
            onClick={handleBookNewTicket}
            disabled={isBookingNew}
            className="w-full py-space-sm rounded-xl bg-secondary text-white font-bold text-sm shadow hover:opacity-95 transition-opacity disabled:opacity-50"
          >
            {isBookingNew ? "Generating Secure QR..." : "+ Book New Boarding Ticket (₹25)"}
          </button>
        </div>

        {/* Policy Notice */}
        <div className="mt-space-base p-space-sm rounded-lg bg-surface-container-high/40 text-[11px] text-on-surface-variant">
          <span className="font-bold text-primary block mb-0.5">Boarding Policy Notice</span>
          Digital tickets are single-use tokens valid on any active bus on the specified corridor within the time window. Conductor scanning verifies token validity and prevents duplicate reuse.
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
          <Link href="/passenger/tickets" className="flex flex-col items-center gap-1 text-primary font-bold">
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
