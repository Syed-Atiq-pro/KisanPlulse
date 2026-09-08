import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-device-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const db = async (path: string, init: RequestInit = {}) => {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
      Prefer: "return=representation",
      ...(init.headers ?? {}),
    },
  });
  const text = await response.text();
  let data: unknown = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!response.ok) throw new Error(`Supabase REST ${response.status}: ${text}`);
  return data;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const body = await req.json();
    const deviceKey = String(body.device_key ?? req.headers.get("x-device-key") ?? "").trim();
    if (!deviceKey) return json({ error: "device_key is required" }, 400);

    const devices = await db(
      `iot_devices?select=id,is_online&device_key=eq.${encodeURIComponent(deviceKey)}&limit=1`,
    );
    if (!Array.isArray(devices) || devices.length !== 1) {
      return json({ error: "Invalid device key" }, 401);
    }

    const device = devices[0] as { id: string; is_online: boolean };
    const bounded = (value: unknown, min: number, max: number) => {
      if (value === null || value === undefined || value === "") return null;
      const number = Number(value);
      if (!Number.isFinite(number) || number < min || number > max) {
        throw new Error(`Invalid sensor value: ${value}`);
      }
      return number;
    };

    const recordedAt = body.recorded_at
      ? new Date(String(body.recorded_at)).toISOString()
      : new Date().toISOString();

    const reading = {
      device_id: device.id,
      soil_moisture: bounded(body.soil_moisture, 0, 100),
      temperature: bounded(body.temperature, -40, 85),
      humidity: bounded(body.humidity, 0, 100),
      water_level: bounded(body.water_level, 0, 100),
      pump_on:
        body.pump_on === undefined || body.pump_on === null
          ? null
          : Boolean(body.pump_on),
      recorded_at: recordedAt,
    };

    await db("iot_readings", {
      method: "POST",
      body: JSON.stringify(reading),
    });

    await db(`iot_devices?id=eq.${encodeURIComponent(device.id)}`, {
      method: "PATCH",
      body: JSON.stringify({
        is_online: true,
        last_seen: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }),
    });

    return json({ ok: true, device_id: device.id, recorded_at: recordedAt });
  } catch (error) {
    console.error(error);
    return json(
      { error: error instanceof Error ? error.message : "Invalid request" },
      400,
    );
  }
});
