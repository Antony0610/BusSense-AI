"use client";

import React, { useState } from "react";
import Link from "next/link";
import { fetchApi } from "@/lib/api";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  sources?: string[];
  suggestedActions?: string[];
}

export default function AssistantPage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "m0",
      role: "assistant",
      content: "Namaskaram! I am your BusSense AI transit assistant. I provide real-time bus arrivals, crowding forecasts, and route recommendations across Kerala corridors.",
      sources: ["BusSense AI Verified Transit Knowledge"],
      suggestedActions: [
        "Which bus is less crowded?",
        "When will Bus 205 arrive?",
        "Why was Bus 205 recommended?",
        "How does BusSense AI estimate crowding?"
      ]
    }
  ]);
  const [inputQuery, setInputQuery] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSendMessage = async (queryText?: string) => {
    const textToSend = queryText || inputQuery;
    if (!textToSend.trim() || isLoading) return;

    const userMsg: Message = {
      id: `u-${Date.now()}`,
      role: "user",
      content: textToSend
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputQuery("");
    setIsLoading(true);

    try {
      const res = await fetchApi<{
        answer: string;
        sources: string[];
        suggested_actions?: string[];
      }>("/ai/chat", {
        method: "POST",
        body: JSON.stringify({
          question: textToSend,
          user_location: "Kaloor Metro Station, Kochi"
        })
      });

      const assistantMsg: Message = {
        id: `a-${Date.now()}`,
        role: "assistant",
        content: res.answer,
        sources: res.sources,
        suggestedActions: res.suggested_actions
      };

      setMessages((prev) => [...prev, assistantMsg]);
    } catch (e) {
      setMessages((prev) => [
        ...prev,
        {
          id: `err-${Date.now()}`,
          role: "assistant",
          content: "I don't have enough reliable information to answer that question right now.",
          sources: ["System Guardrail"]
        }
      ]);
    } finally {
      setIsLoading(false);
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
          <div className="flex flex-col items-center">
            <span className="font-title-card text-title-card text-primary font-bold">Transit Assistant</span>
            <span className="text-[10px] text-secondary font-semibold">Grounded RAG · Live Telemetry</span>
          </div>
          <div className="w-8"></div>
        </div>
      </header>

      {/* Chat Messages Stream */}
      <main className="flex-1 flex flex-col max-w-md mx-auto w-full pt-20 px-gutter space-y-space-base">
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex flex-col ${msg.role === "user" ? "items-end" : "items-start"}`}
          >
            <div
              className={`p-space-base rounded-2xl max-w-[88%] shadow-sm ${
                msg.role === "user"
                  ? "bg-primary text-white rounded-br-none"
                  : "bg-surface-container-lowest text-primary border border-outline-variant/40 rounded-bl-none"
              }`}
            >
              <p className="text-sm leading-relaxed whitespace-pre-line">{msg.content}</p>

              {/* Source citations */}
              {msg.sources && msg.sources.length > 0 && (
                <div className="mt-space-sm pt-space-xs border-t border-outline-variant/30 text-[11px] text-on-surface-variant flex flex-wrap items-center gap-1.5">
                  <span className="font-semibold text-secondary flex items-center gap-0.5">
                    <span className="material-symbols-outlined text-[13px]">verified</span>
                    <span>Sources:</span>
                  </span>
                  {msg.sources.map((s, idx) => (
                    <span key={idx} className="bg-surface-container px-1.5 py-0.5 rounded text-[10px]">
                      {s}
                    </span>
                  ))}
                </div>
              )}
            </div>

            {/* Suggested action chips for quick follow-up */}
            {msg.suggestedActions && msg.suggestedActions.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {msg.suggestedActions.map((act, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSendMessage(act)}
                    className="text-xs px-2.5 py-1 rounded-full bg-surface-container hover:bg-surface-container-high text-primary font-medium transition-colors"
                  >
                    {act}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}

        {isLoading && (
          <div className="flex items-center gap-2 p-3 bg-surface-container rounded-xl w-32 animate-pulse text-xs text-on-surface-variant">
            <span className="material-symbols-outlined text-[16px] text-secondary animate-spin">refresh</span>
            <span>Retrieving...</span>
          </div>
        )}
      </main>

      {/* Chat Input Floating Dock */}
      <div className="fixed bottom-16 w-full z-40 bg-surface/90 backdrop-blur-md border-t border-outline-variant/30 py-space-xs">
        <div className="max-w-md mx-auto px-gutter flex items-center gap-2">
          <input
            type="text"
            value={inputQuery}
            onChange={(e) => setInputQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
            placeholder="Ask about Bus 205, crowding, routes..."
            className="flex-1 bg-surface-container-lowest border border-outline-variant/50 rounded-xl px-space-base py-space-xs text-sm focus:outline-none focus:border-primary"
          />
          <button
            onClick={() => handleSendMessage()}
            disabled={!inputQuery.trim() || isLoading}
            className="w-10 h-10 rounded-xl bg-primary text-white flex items-center justify-center disabled:opacity-40 hover:opacity-90 transition-opacity"
          >
            <span className="material-symbols-outlined text-[20px]">send</span>
          </button>
        </div>
      </div>

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
          <Link href="/passenger/assistant" className="flex flex-col items-center gap-1 text-secondary font-bold">
            <div className="w-10 h-10 -mt-5 rounded-full bg-primary text-white flex items-center justify-center shadow-md">
              <span className="material-symbols-outlined text-[22px]">smart_toy</span>
            </div>
            <span className="font-caption text-[11px] font-bold">AI Assistant</span>
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
