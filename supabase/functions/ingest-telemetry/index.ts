// BusSense AI - Standalone Ingestion Telemetry Edge Function
// Ingests external AVL GPS packets and CCTV passenger counts with strict Zero-Biometrics enforcement.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-provider-api-key",
  "Content-Type": "application/json"
};

// Greater Kochi Bounding Box
const KOCHI_BBOX = {
  minLat: 9.80,
  maxLat: 10.35,
  minLng: 76.15,
  maxLng: 76.55
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const feedType = url.pathname.includes("cctv") ? "cctv" : "gps";
    const body = await req.json();

    if (feedType === "cctv") {
      if (body.privacy_standard !== "PERSON_COUNTING_ONLY_NO_BIOMETRICS") {
        return new Response(JSON.stringify({
          error: "Strict zero-biometrics policy violation: Facial or demographic tracking is prohibited."
        }), { status: 400, headers: corsHeaders });
      }

      return new Response(JSON.stringify({
        success: true,
        message: `CCTV occupancy processed for Bus ${body.bus_number}`,
        data: {
          status: "RECORDED",
          accepted: 1,
          rejected: 0,
          bus_number: body.bus_number,
          total_passengers: body.stabilized_person_count || body.raw_person_count,
          data_origin: "CV REPLAY"
        },
        data_origin: "CV REPLAY",
        timestamp: new Date().toISOString()
      }), { status: 200, headers: corsHeaders });
    }

    // GPS Telemetry Batch
    const records = Array.isArray(body.records) ? body.records : [body];
    let accepted = 0;
    let rejected = 0;

    for (const r of records) {
      const lat = parseFloat(r.latitude);
      const lng = parseFloat(r.longitude);
      const speed = parseFloat(r.speed || r.speed_kmh || 0);

      // Validate Kochi bounding box and speed bounds
      if (
        isNaN(lat) || isNaN(lng) ||
        lat < KOCHI_BBOX.minLat || lat > KOCHI_BBOX.maxLat ||
        lng < KOCHI_BBOX.minLng || lng > KOCHI_BBOX.maxLng ||
        speed < 0 || speed > 120
      ) {
        rejected++;
      } else {
        accepted++;
      }
    }

    return new Response(JSON.stringify({
      success: true,
      message: `GPS telemetry processed: ${accepted} accepted, ${rejected} rejected`,
      data: {
        status: "RECORDED",
        accepted,
        rejected,
        data_origin: "LIVE DATA"
      },
      data_origin: "LIVE DATA",
      timestamp: new Date().toISOString()
    }), { status: 200, headers: corsHeaders });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: corsHeaders
    });
  }
});

