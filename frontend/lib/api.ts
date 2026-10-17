/**
 * BusSense AI - Client SDK & API Service
 * Connects to FastAPI Backend at http://localhost:8000/api
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api";

export async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_BASE}${endpoint.startsWith("/") ? endpoint : `/${endpoint}`}`;
  const authHeader: Record<string, string> = {};
  if (typeof window !== "undefined") {
    const token = localStorage.getItem("bussense_token");
    if (token) {
      authHeader["Authorization"] = `Bearer ${token}`;
    }
  }
  try {
    const res = await fetch(url, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        ...authHeader,
        ...(options.headers || {}),
      },
    });
    if (!res.ok) {
      throw new Error(`API error ${res.status}: ${await res.text()}`);
    }
    const json = await res.json();
    return json.data !== undefined ? json.data : json;
  } catch (err) {
    console.warn(`[BusSense API fallback] ${endpoint}:`, err);
    throw err;
  }
}

// Telemetry Types
export interface BusTelemetry {
  bus_id: string;
  bus_number: string;
  bus_code?: string;
  registration_number: string;
  operator_type: string;
  route_number: string;
  route?: string;
  route_name: string;
  capacity?: number;
  total_capacity?: number;
  passenger_count?: number;
  occupancy_pct?: number;
  occupancy_percentage?: number;
  crowd_level: "LOW" | "MODERATE" | "CROWDED";
  speed_kmh?: number;
  heading_deg?: number;
  heading?: number;
  latitude?: number;
  longitude?: number;
  current_stop?: string;
  next_stop?: string;
  eta_next_stop_mins?: number;
  is_ac?: boolean;
  safety_score?: number;
  status?: string;
  is_active?: boolean;
  data_origin?: string;
}

export type Bus = BusTelemetry;

export interface PredictionHorizon {
  now?: { occupancy_pct: number; crowd_level: string; confidence: number };
  plus_15m?: { occupancy_pct: number; crowd_level: string; confidence: number };
  plus_30m?: { occupancy_pct: number; crowd_level: string; confidence: number };
  plus_60m?: { occupancy_pct: number; crowd_level: string; confidence: number };
}

export interface RecommendationResponse {
  origin_stop: string;
  destination_stop: string;
  preference?: string;
  data_quality?: "HIGH" | "MEDIUM" | "LOW";
  recommended_bus: {
    bus_number: string;
    route_number: string;
    route_name: string;
    operator_type: string;
    eta_mins: number;
    occupancy_pct: number;
    crowd_level: "LOW" | "MODERATE" | "CROWDED";
    is_recommended: boolean;
    journey_score: number;
    why_recommended: string;
    crowd_saving_vs_alternative_pct?: number;
    time_saving_mins?: number;
    fare_inr: number;
    predicted_occupancy_pct?: number;
    predicted_crowd_level?: "LOW" | "MODERATE" | "CROWDED";
    prediction_confidence?: number;
    data_quality?: "HIGH" | "MEDIUM" | "LOW";
    score_breakdown?: Record<string, number>;
  };
  alternative_buses: Array<{
    bus_number: string;
    route_number: string;
    route_name: string;
    operator_type: string;
    eta_mins: number;
    occupancy_pct: number;
    crowd_level: "LOW" | "MODERATE" | "CROWDED";
    is_recommended: boolean;
    journey_score: number;
    why_recommended: string;
    fare_inr: number;
    predicted_occupancy_pct?: number;
    predicted_crowd_level?: "LOW" | "MODERATE" | "CROWDED";
    data_quality?: "HIGH" | "MEDIUM" | "LOW";
    score_breakdown?: Record<string, number>;
  }>;
  explanation: string;
  data_origin: string;
}

export interface TicketData {
  id: string;
  ticket_number: string;
  passenger_name: string;
  bus_number: string;
  route_number: string;
  origin_stop: string;
  destination_stop: string;
  fare_amount: number;
  final_fare: number;
  status: string;
  qr_code_hash: string;
  qr_code_data_uri: string;
  valid_from: string;
  valid_until: string;
  created_at: string;
  data_origin: string;
}

export interface ValidationResult {
  result: "VALID" | "INVALID" | "ALREADY_USED" | "EXPIRED";
  is_valid: boolean;
  ticket_number?: string;
  passenger_name?: string;
  origin_stop?: string;
  destination_stop?: string;
  message: string;
  validated_at: string;
}

export async function getBuses(): Promise<BusTelemetry[]> {
  try {
    const raw = await fetchApi<any[]>("/buses");
    return raw.map((b) => ({
      bus_id: b.bus_id || b.id || "00000000-0000-0000-0000-000000000011",
      bus_number: b.bus_number || b.bus_code?.replace("Bus ", "") || "205",
      bus_code: b.bus_code || `Bus ${b.bus_number || "205"}`,
      registration_number: b.registration_number || "KL-07-CE-8821",
      operator_type: b.operator_type || "KSRTC",
      route_number: b.route_number || "12",
      route_name: b.route_name || "Kaloor - Infopark",
      capacity: b.total_capacity || b.capacity || 55,
      total_capacity: b.total_capacity || b.capacity || 55,
      passenger_count: b.passenger_count || 23,
      occupancy_pct: b.occupancy_percentage || b.occupancy_pct || 41.8,
      occupancy_percentage: b.occupancy_percentage || b.occupancy_pct || 41.8,
      crowd_level: b.crowd_level || "LOW",
      speed_kmh: b.speed_kmh || 34.2,
      heading_deg: b.heading || b.heading_deg || 85.0,
      latitude: b.latitude || 9.9984,
      longitude: b.longitude || 76.3025,
      current_stop: b.current_stop || "Palarivattom Jn",
      next_stop: b.next_stop || "Kaloor Central Stand",
      eta_next_stop_mins: b.eta_next_stop_mins || 4,
      is_ac: b.is_ac ?? false,
      safety_score: b.safety_score || 4.8,
      status: b.status || "ACTIVE",
      data_origin: b.data_origin || "SIMULATED",
    }));
  } catch {
    return [
      {
        bus_id: "00000000-0000-0000-0000-000000000011",
        bus_number: "205",
        bus_code: "Bus 205",
        registration_number: "KL-07-CE-8821",
        operator_type: "KSRTC",
        route_number: "12",
        route_name: "Kaloor - Kakkanad Infopark",
        capacity: 55,
        total_capacity: 55,
        passenger_count: 23,
        occupancy_pct: 41.8,
        occupancy_percentage: 41.8,
        crowd_level: "LOW",
        speed_kmh: 34.2,
        heading_deg: 85.0,
        latitude: 9.9984,
        longitude: 76.3025,
        current_stop: "Palarivattom Jn",
        next_stop: "Kaloor Central Stand",
        eta_next_stop_mins: 4,
        is_ac: false,
        safety_score: 4.8,
        status: "ACTIVE",
        data_origin: "SIMULATED",
      },
      {
        bus_id: "00000000-0000-0000-0000-000000000012",
        bus_number: "14A",
        bus_code: "Bus 14A",
        registration_number: "KL-07-CE-9912",
        operator_type: "KSRTC",
        route_number: "14A",
        route_name: "MG Road - Vyttila Hub",
        capacity: 55,
        total_capacity: 55,
        passenger_count: 36,
        occupancy_pct: 65.5,
        occupancy_percentage: 65.5,
        crowd_level: "MODERATE",
        speed_kmh: 28.0,
        heading_deg: 120.0,
        latitude: 9.9674,
        longitude: 76.2985,
        current_stop: "South Overbridge",
        next_stop: "Kadavanthra Junction",
        eta_next_stop_mins: 2,
        is_ac: false,
        safety_score: 4.6,
        status: "ACTIVE",
        data_origin: "SIMULATED",
      },
      {
        bus_id: "00000000-0000-0000-0000-000000000013",
        bus_number: "FP-102",
        bus_code: "Bus FP-102",
        registration_number: "KL-07-CE-7740",
        operator_type: "KSRTC",
        route_number: "205",
        route_name: "Aluva - Vyttila Hub",
        capacity: 55,
        total_capacity: 55,
        passenger_count: 48,
        occupancy_pct: 87.2,
        occupancy_percentage: 87.2,
        crowd_level: "CROWDED",
        speed_kmh: 42.0,
        heading_deg: 200.0,
        latitude: 10.0245,
        longitude: 76.3082,
        current_stop: "Kalamassery Premier",
        next_stop: "Edappally Toll",
        eta_next_stop_mins: 6,
        is_ac: false,
        safety_score: 4.7,
        status: "ACTIVE",
        data_origin: "SIMULATED",
      },
    ];
  }
}

export async function getPredictions(): Promise<PredictionHorizon> {
  try {
    return await fetchApi<PredictionHorizon>("/occupancy/predictions");
  } catch {
    return {
      now: { occupancy_pct: 42, crowd_level: "LOW", confidence: 0.94 },
      plus_15m: { occupancy_pct: 58, crowd_level: "MODERATE", confidence: 0.88 },
      plus_30m: { occupancy_pct: 82, crowd_level: "CROWDED", confidence: 0.82 },
      plus_60m: { occupancy_pct: 49, crowd_level: "LOW", confidence: 0.79 },
    };
  }
}

export interface TripData {
  trip_id: string;
  trip_code: string;
  bus_id: string;
  bus_number: string;
  route_id: string;
  route_number: string;
  current_status: string;
  current_stop: string;
  next_stop: string;
  started_at: string;
  estimated_arrival: string;
  occupancy_pct: number;
  crowd_level: "LOW" | "MODERATE" | "CROWDED";
  data_origin: string;
}

export interface LocationData {
  bus_id: string;
  bus_number: string;
  registration_number: string;
  latitude: number;
  longitude: number;
  speed_kmh: number;
  heading_deg: number;
  current_stop: string;
  next_stop: string;
  eta_next_stop_mins: number;
  timestamp: string;
  data_origin: string;
}

export interface CrowdData {
  bus_id: string;
  bus_number: string;
  occupancy_pct: number;
  passenger_count: number;
  capacity: number;
  crowd_level: "LOW" | "MODERATE" | "CROWDED";
  detection_source: string;
  privacy_standard: string;
  timestamp: string;
  data_origin: string;
}

export interface AlertData {
  id: string;
  title: string;
  message: string;
  severity: "INFO" | "WARNING" | "CRITICAL";
  affected_route: string;
  is_active: boolean;
  created_at: string;
}

export type Alert = AlertData;

export interface PaymentData {
  id: string;
  ticket_id: string;
  amount: number;
  currency: string;
  provider: string;
  status: string;
  transaction_reference?: string;
  created_at: string;
  data_origin: string;
}

export async function getTrips(): Promise<TripData[]> {
  return await fetchApi<TripData[]>("/trips");
}

export async function getLocations(): Promise<LocationData[]> {
  return await fetchApi<LocationData[]>("/locations");
}

export async function getCrowd(): Promise<CrowdData[]> {
  return await fetchApi<CrowdData[]>("/crowd");
}

export async function getAlerts(): Promise<AlertData[]> {
  return await fetchApi<AlertData[]>("/alerts/active");
}

export async function getMyPayments(): Promise<PaymentData[]> {
  return await fetchApi<PaymentData[]>("/payments/my");
}

// ==========================================
// Phase H7 - Authority API Types & Functions
// ==========================================

export interface CommandOverview {
  network_status: string;
  active_buses_count: number;
  total_fleet_registered: number;
  average_network_occupancy_pct: number;
  on_time_reliability_pct: number;
  crowding_alerts_count: number;
  service_incidents_count: number;
  co2_saved_today_kg: number;
  active_corridors: Array<{
    name: string;
    code: string;
    status: string;
    avg_speed: number;
  }>;
}

export interface AIDecision {
  id: string;
  trigger: string;
  prediction: string;
  recommendation: string;
  expected_impact: string;
  status: string;
  data_origin: string;
}

export interface OperationalReport {
  id: string;
  title: string;
  period: string;
  trips_total: number;
  on_time_pct: number;
  avg_occupancy_pct: number;
  carbon_offset_kg: number;
  summary?: string;
}

export interface IncidentData {
  id: string;
  category: string;
  severity: "INFO" | "WARNING" | "CRITICAL";
  title: string;
  description: string;
  bus_number: string;
  status: "REPORTED" | "INVESTIGATING" | "RESOLVED";
  created_at: string;
  resolved_at?: string;
  reporter_id?: string;
}

export interface RouteData {
  id: string;
  route_number: string;
  route_name: string;
  corridor_type?: string;
  start_stop: string;
  end_stop: string;
  distance_km: number;
  estimated_duration_mins: number;
  color_code?: string;
}

export interface AuthUser {
  id: string;
  email: string;
  role: "PASSENGER" | "DRIVER_CONDUCTOR" | "AUTHORITY" | "ADMIN";
  full_name: string;
}

export async function getCommandOverview(): Promise<CommandOverview> {
  return await fetchApi<CommandOverview>("/analytics/command-overview");
}

export async function getAIDecisions(): Promise<AIDecision[]> {
  return await fetchApi<AIDecision[]>("/analytics/ai-decision-queue");
}

export async function getOperationalReports(): Promise<OperationalReport[]> {
  return await fetchApi<OperationalReport[]>("/analytics/reports");
}

export async function getIncidents(): Promise<IncidentData[]> {
  return await fetchApi<IncidentData[]>("/incidents");
}

export async function resolveIncident(incidentId: string, notes?: string): Promise<IncidentData> {
  return await fetchApi<IncidentData>(`/incidents/${incidentId}/resolve`, {
    method: "POST",
    body: JSON.stringify({ resolution_notes: notes || "Resolved by corridor dispatch officer." }),
  });
}

export async function getRoutes(): Promise<RouteData[]> {
  return await fetchApi<RouteData[]>("/routes");
}

export async function getBusByNumber(busNumber: string): Promise<BusTelemetry> {
  return await fetchApi<BusTelemetry>(`/buses/${busNumber}`);
}

export async function getBusPredictions(busNumber: string): Promise<PredictionHorizon> {
  return await fetchApi<PredictionHorizon>(`/predictions/${busNumber}`);
}

// Authentication Helpers
export function getCurrentAuthToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("bussense_token");
}

export function getCurrentAuthUser(): AuthUser | null {
  if (typeof window === "undefined") return null;
  const userJson = localStorage.getItem("bussense_user");
  if (userJson) {
    try {
      return JSON.parse(userJson);
    } catch {
      // Fallback to token decoding
    }
  }
  const token = getCurrentAuthToken();
  if (!token) return null;
  try {
    const parts = token.split(".");
    if (parts.length === 3) {
      const payload = JSON.parse(atob(parts[1]));
      return {
        id: payload.sub || "",
        email: payload.email || "",
        role: payload.role || "PASSENGER",
        full_name: payload.full_name || "Transit Operator",
      };
    }
  } catch {
    return null;
  }
  return null;
}

export function setAuthSession(token: string, user: AuthUser): void {
  if (typeof window === "undefined") return;
  localStorage.setItem("bussense_token", token);
  localStorage.setItem("bussense_user", JSON.stringify(user));
}

export function clearAuthSession(): void {
  if (typeof window === "undefined") return;
  localStorage.removeItem("bussense_token");
  localStorage.removeItem("bussense_user");
}

export async function switchDemoRole(role: string): Promise<{ access_token: string; user: AuthUser }> {
  const result = await fetchApi<{ access_token: string; user: AuthUser }>("/auth/switch-demo-role", {
    method: "POST",
    body: JSON.stringify({ role }),
  });
  if (result.access_token && result.user) {
    setAuthSession(result.access_token, result.user);
  }
  return result;
}

export async function planJourney(
  origin: string = "Kaloor",
  destination: string = "Infopark",
  preference: string = "balanced"
): Promise<RecommendationResponse | null> {
  return fetchApi<RecommendationResponse>(
    `/recommendations/plan?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&preference=${encodeURIComponent(preference)}`
  );
}


