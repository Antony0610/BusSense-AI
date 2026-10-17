/**
 * BusSense AI - Realtime WebSocket Client & Freshness Utilities
 * Phase H12: Provides WebSocket streaming with seamless polling fallback and data freshness tracking.
 */

export interface RealtimeEvent {
  event_id: string;
  event_type: string;
  entity_id: string;
  occurred_at: string;
  published_at: string;
  data_origin: string;
  schema_version: string;
  payload: Record<string, any>;
}

export interface FreshnessState {
  data_age_seconds: number;
  is_stale: boolean;
  freshness_label: string;
  data_origin: string;
}

export function calculateDataFreshness(
  timestampIso: string,
  dataOrigin: string = "SIMULATED TELEMETRY",
  thresholdSeconds: number = 15
): FreshnessState {
  if (!timestampIso) {
    return {
      data_age_seconds: 999,
      is_stale: true,
      freshness_label: "NO DATA",
      data_origin: dataOrigin,
    };
  }
  const dt = new Date(timestampIso).getTime();
  const now = Date.now();
  const ageSeconds = Math.max(0, Math.floor((now - dt) / 1000));
  const isStale = ageSeconds > thresholdSeconds;

  return {
    data_age_seconds: ageSeconds,
    is_stale: isStale,
    freshness_label: isStale ? `STALE • ${ageSeconds}s ago` : `FRESH • ${ageSeconds}s ago`,
    data_origin: dataOrigin,
  };
}

export type ConnectionStatus = "CONNECTED" | "RECONNECTING" | "POLLING" | "OFFLINE";

export function createRealtimeStream(
  onEvent: (event: RealtimeEvent) => void,
  onStatusChange?: (status: ConnectionStatus) => void,
  wsUrl: string = process.env.NEXT_PUBLIC_WS_URL || "ws://localhost:8000/ws/telemetry"
): () => void {
  if (typeof window === "undefined") {
    return () => {};
  }

  let ws: WebSocket | null = null;
  let pollingInterval: NodeJS.Timeout | null = null;
  let reconnectTimeout: NodeJS.Timeout | null = null;
  let isClosed = false;

  const setStatus = (status: ConnectionStatus) => {
    if (onStatusChange) onStatusChange(status);
  };

  const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api";

  const startPolling = () => {
    if (isClosed || pollingInterval) return;
    setStatus("POLLING");
    pollingInterval = setInterval(async () => {
      try {
        const res = await fetch(`${apiBase}/realtime/events?limit=10`);
        if (res.ok) {
          const json = await res.json();
          const items: RealtimeEvent[] = json.data || [];
          items.forEach((item) => onEvent(item));
        }
      } catch {
        // Polling failed, status remains POLLING
      }
    }, 5000);
  };

  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval);
      pollingInterval = null;
    }
  };

  const connect = () => {
    if (isClosed) return;
    setStatus("RECONNECTING");

    try {
      ws = new WebSocket(wsUrl);

      ws.onopen = () => {
        stopPolling();
        setStatus("CONNECTED");
      };

      ws.onmessage = (e) => {
        try {
          const data = JSON.parse(e.data);
          onEvent(data);
        } catch {
          // ignore malformed frame
        }
      };

      ws.onerror = () => {
        startPolling();
      };

      ws.onclose = () => {
        ws = null;
        startPolling();
        if (!isClosed) {
          reconnectTimeout = setTimeout(connect, 5000);
        }
      };
    } catch {
      startPolling();
    }
  };

  connect();

  return () => {
    isClosed = true;
    stopPolling();
    if (reconnectTimeout) clearTimeout(reconnectTimeout);
    if (ws) ws.close();
  };
}
