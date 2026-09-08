import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const DEFAULT_MODEL = 'yanami3/agri-plant-disease-resnet50';
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const LOW_CONFIDENCE = 0.70;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function parseLabel(label: string) {
  const parts = label.split('___');
  const crop = (parts[0] ?? 'Unknown').replaceAll('_', ' ').replaceAll(',', ', ');
  const disease = (parts[1] ?? 'Unknown').replaceAll('_', ' ').trim();
  return { crop, disease };
}

function adviceFor(disease: string): string[] {
  const normalized = disease.toLowerCase();
  if (normalized === 'healthy') {
    return [
      'No disease class was detected in the submitted image.',
      'Continue monitoring the crop and keep a regular scouting record.',
    ];
  }
  if (normalized.includes('spider mite')) {
    return [
      'Inspect nearby leaves and the underside of leaves for mites or webbing.',
      'Remove heavily affected plant material where practical and improve field monitoring.',
      'Use an integrated pest-management recommendation from a local agronomist before applying any pesticide.',
    ];
  }
  if (normalized.includes('virus') || normalized.includes('mosaic') || normalized.includes('yellow leaf curl')) {
    return [
      'Isolate and inspect affected plants to reduce possible spread.',
      'Check for insect vectors and remove severely affected plants according to local guidance.',
      'Confirm the diagnosis with a local agricultural expert before treatment decisions.',
    ];
  }
  return [
    'Inspect surrounding plants for the same symptoms and record affected areas.',
    'Remove or isolate severely affected leaves where practical and avoid spreading contaminated plant material.',
    'Use an integrated pest-management recommendation from a local agronomist before applying any pesticide.',
  ];
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const hfToken = Deno.env.get('HF_TOKEN') ?? '';
  const model = Deno.env.get('HF_MODEL') || DEFAULT_MODEL;

  if (!supabaseUrl || !supabaseAnonKey || !hfToken) {
    return json({ error: 'AI service is not configured on the server.' }, 500);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'Authentication required.' }, 401);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) return json({ error: 'Invalid or expired session.' }, 401);

  let payload: { image_base64?: string };
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'Request body must be JSON.' }, 400);
  }

  const imageBase64 = payload.image_base64 ?? '';
  if (!imageBase64) return json({ error: 'image_base64 is required.' }, 400);

  const estimatedBytes = Math.floor((imageBase64.length * 3) / 4);
  if (estimatedBytes > MAX_IMAGE_BYTES) {
    return json({ error: 'Image is too large. Maximum size is 8 MB.' }, 413);
  }

  const hfUrl = `https://router.huggingface.co/hf-inference/models/${model}`;
  let hfResponse: Response;
  try {
    hfResponse = await fetch(hfUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${hfToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: imageBase64,
        parameters: { top_k: 5 },
      }),
    });
  } catch {
    return json({ error: 'Unable to reach the AI inference provider.' }, 502);
  }

  const raw = await hfResponse.text();
  if (!hfResponse.ok) {
    return json({ error: 'AI inference failed.', provider_status: hfResponse.status }, 502);
  }

  let output: unknown;
  try {
    output = JSON.parse(raw);
  } catch {
    return json({ error: 'AI provider returned an invalid response.' }, 502);
  }

  if (!Array.isArray(output) || output.length === 0) {
    return json({ error: 'AI provider returned no prediction.' }, 502);
  }

  const top = output[0] as { label?: string; score?: number };
  const label = top.label ?? 'Unknown';
  const confidence = Number(top.score ?? 0);
  const { crop, disease } = parseLabel(label);
  const lowConfidence = confidence < LOW_CONFIDENCE;

  const warning = lowConfidence
    ? 'Low confidence result. Retake the photo in good daylight and confirm with an agricultural expert before treatment.'
    : 'AI screening result only. Confirm important treatment decisions with a qualified agricultural expert.';

  const advice = adviceFor(disease);
  const { error: insertError } = await supabase.from('disease_diagnoses').insert({
    user_id: user.id,
    crop,
    disease,
    confidence,
    advice,
    model_name: model,
  });

  if (insertError) {
    console.error('diagnosis history insert failed', insertError);
  }

  return json({
    crop,
    disease,
    confidence,
    advice,
    warning,
    model_name: model,
    top_predictions: output.slice(0, 5),
  });
});
