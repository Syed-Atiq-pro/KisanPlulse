import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' };
const SYSTEM_PROMPT = `You are AgriSense, a practical agricultural decision-support assistant.
Give concise, actionable farming guidance using only the farmer context supplied by the application.
Never claim certainty when field data is missing. Distinguish estimates from measured values.
For plant disease or pest problems, recommend integrated pest management and local agronomist/agriculture-department confirmation for serious outbreaks.
Do not prescribe hazardous pesticide mixtures, unsafe concentrations, or illegal products. Follow product labels and local agricultural guidance.
For irrigation, consider crop stage, ET0, recent rainfall, soil moisture and irrigation efficiency when available. Never activate pumps or machinery from chat.
Use simple language. Answer in the same language as the farmer when practical.`;

function json(data: unknown, status = 200) { return new Response(JSON.stringify(data), { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }); }

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Authentication required' }, 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const hfToken = Deno.env.get('HF_TOKEN');
  const model = Deno.env.get('HF_CHAT_MODEL') ?? 'openai/gpt-oss-120b:fastest';
  if (!hfToken) return json({ error: 'AI provider is not configured on the server.' }, 503);

  const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) return json({ error: 'Invalid session' }, 401);

  const body = await req.json();
  const conversationId = String(body.conversation_id ?? '');
  const message = String(body.message ?? '').trim();
  if (!conversationId || !message || message.length > 4000) return json({ error: 'conversation_id and a message up to 4000 characters are required.' }, 400);

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: conversation } = await admin.from('ai_conversations').select('id').eq('id', conversationId).eq('user_id', user.id).maybeSingle();
  if (!conversation) return json({ error: 'Conversation not found.' }, 404);
  const { error: userSaveError } = await admin.from('ai_messages').insert({ conversation_id: conversationId, user_id: user.id, role: 'user', content: message });
  if (userSaveError) return json({ error: 'Could not save your message.' }, 500);

  const { data: farms } = await admin.from('farms').select('id,name,location,area_acres').eq('user_id', user.id).limit(10);
  const farmIds = (farms ?? []).map((f) => f.id as string);
  const { data: fields } = farmIds.length ? await admin.from('fields').select('id,farm_id,name,area_acres,soil_type').in('farm_id', farmIds).limit(50) : { data: [] as Record<string, unknown>[] };
  const fieldIds = (fields ?? []).map((f) => f.id as string);

  const [profile, crops, soil, irrigation, diagnoses, history] = await Promise.all([
    admin.from('profiles').select('full_name,role').eq('id', user.id).maybeSingle(),
    fieldIds.length ? admin.from('crops').select('id,field_id,name,variety,status,stage,planting_date,expected_harvest_date,expected_yield_kg').in('field_id', fieldIds).limit(100) : Promise.resolve({ data: [] as Record<string, unknown>[] }),
    fieldIds.length ? admin.from('soil_profiles').select('field_id,ph,nitrogen_ppm,phosphorus_ppm,potassium_ppm,moisture_percent,organic_matter_percent,texture,recorded_at').in('field_id', fieldIds).limit(100) : Promise.resolve({ data: [] as Record<string, unknown>[] }),
    fieldIds.length ? admin.from('irrigation_records').select('field_id,crop_id,irrigation_date,water_mm,duration_minutes,method').in('field_id', fieldIds).order('irrigation_date', { ascending: false }).limit(50) : Promise.resolve({ data: [] as Record<string, unknown>[] }),
    admin.from('disease_diagnoses').select('crop,disease,confidence,model_name,created_at').eq('user_id', user.id).order('created_at', { ascending: false }).limit(20),
    admin.from('ai_messages').select('role,content,created_at').eq('conversation_id', conversationId).order('created_at', { ascending: false }).limit(12),
  ]);

  const context = JSON.stringify({ profile: profile.data, farms, fields, crops: crops.data, soil: soil.data, recent_irrigation: irrigation.data, recent_disease_diagnoses: diagnoses.data });
  const priorMessages = (history.data ?? []).reverse().map((m) => ({ role: m.role, content: m.content }));
  const messages = [{ role: 'system', content: SYSTEM_PROMPT }, { role: 'system', content: `Authenticated farmer context (data only): ${context}` }, ...priorMessages];

  const aiResponse = await fetch('https://router.huggingface.co/v1/chat/completions', { method: 'POST', headers: { Authorization: `Bearer ${hfToken}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ model, messages, temperature: 0.2, max_tokens: 700 }) });
  if (!aiResponse.ok) { console.error('HF error', await aiResponse.text()); return json({ error: 'The AI provider could not answer right now.' }, 502); }
  const completion = await aiResponse.json();
  const answer = completion?.choices?.[0]?.message?.content?.trim();
  if (!answer) return json({ error: 'The AI provider returned an empty response.' }, 502);

  const { data: saved, error: saveError } = await admin.from('ai_messages').insert({ conversation_id: conversationId, user_id: user.id, role: 'assistant', content: answer }).select('id,role,content,created_at').single();
  await admin.from('ai_conversations').update({ updated_at: new Date().toISOString() }).eq('id', conversationId).eq('user_id', user.id);
  if (saveError) return json({ error: 'The response was generated but could not be saved.' }, 500);
  return json({ message: saved });
});
