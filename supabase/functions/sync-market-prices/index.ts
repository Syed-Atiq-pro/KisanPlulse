import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-sync-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type RecordMap = Record<string, unknown>

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null
  const result = String(value).trim()
  return result.length ? result : null
}

function numberValue(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null
  const cleaned = String(value).replace(/,/g, '').replace(/[^0-9.-]/g, '')
  const result = Number(cleaned)
  return Number.isFinite(result) ? result : null
}

function first(record: RecordMap, keys: string[]): unknown {
  for (const key of keys) {
    if (record[key] !== undefined && record[key] !== null && record[key] !== '') return record[key]
  }
  return null
}

function normalizeDate(value: unknown): string | null {
  const raw = text(value)
  if (!raw) return null
  const iso = new Date(raw)
  if (!Number.isNaN(iso.getTime())) return iso.toISOString().slice(0, 10)

  const parts = raw.split(/[/-]/).map((part) => part.trim())
  if (parts.length === 3) {
    const [a, b, c] = parts
    if (a.length === 4) return `${a.padStart(4, '0')}-${b.padStart(2, '0')}-${c.padStart(2, '0')}`
    if (c.length === 4) return `${c}-${b.padStart(2, '0')}-${a.padStart(2, '0')}`
  }
  return null
}

function recordsFromPayload(payload: unknown): RecordMap[] {
  if (Array.isArray(payload)) return payload.filter((x): x is RecordMap => !!x && typeof x === 'object')
  if (!payload || typeof payload !== 'object') return []
  const root = payload as RecordMap
  for (const key of ['records', 'data', 'results', 'result']) {
    if (Array.isArray(root[key])) return root[key].filter((x): x is RecordMap => !!x && typeof x === 'object')
  }
  return []
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return Response.json({ error: 'POST required' }, { status: 405, headers: corsHeaders })

  const syncSecret = Deno.env.get('MARKET_SYNC_SECRET')
  if (!syncSecret || req.headers.get('x-sync-secret') !== syncSecret) {
    return Response.json({ error: 'Unauthorized' }, { status: 401, headers: corsHeaders })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const apiUrl = Deno.env.get('DATA_GOV_API_URL')
  const apiKey = Deno.env.get('DATA_GOV_API_KEY')

  if (!supabaseUrl || !serviceRoleKey) {
    return Response.json({ error: 'Supabase server configuration is incomplete' }, { status: 500, headers: corsHeaders })
  }
  if (!apiUrl) {
    return Response.json({ error: 'DATA_GOV_API_URL is not configured' }, { status: 503, headers: corsHeaders })
  }

  const admin = createClient(supabaseUrl, serviceRoleKey)
  const { data: run, error: runError } = await admin
    .from('market_sync_runs')
    .insert({ status: 'running' })
    .select('id')
    .single()

  if (runError || !run) {
    return Response.json({ error: 'Unable to create sync run', details: runError?.message }, { status: 500, headers: corsHeaders })
  }

  try {
    const url = new URL(apiUrl)
    if (apiKey) url.searchParams.set('api-key', apiKey)
    if (!url.searchParams.has('format')) url.searchParams.set('format', 'json')

    const response = await fetch(url, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(30000),
    })
    if (!response.ok) throw new Error(`Government data request failed: HTTP ${response.status}`)

    const payload = await response.json()
    const records = recordsFromPayload(payload)
    if (!records.length) throw new Error('Government response contained no recognizable records')

    let recordsUpserted = 0
    let marketsUpserted = 0

    for (const record of records) {
      const name = text(first(record, ['market', 'market_name', 'Market', 'Market Name']))
      const state = text(first(record, ['state', 'State']))
      const district = text(first(record, ['district', 'District']))
      const commodity = text(first(record, ['commodity', 'Commodity']))
      const variety = text(first(record, ['variety', 'Variety']))
      const grade = text(first(record, ['grade', 'Grade']))
      const priceDate = normalizeDate(first(record, ['arrival_date', 'price_date', 'date', 'Arrival_Date', 'Price Date']))
      const modalPrice = numberValue(first(record, ['modal_price', 'modal_price_per_quintal', 'Modal_Price', 'Modal Price']))
      const minPrice = numberValue(first(record, ['min_price', 'min_price_per_quintal', 'Min_Price', 'Min Price']))
      const maxPrice = numberValue(first(record, ['max_price', 'max_price_per_quintal', 'Max_Price', 'Max Price']))
      const arrivals = numberValue(first(record, ['arrivals_tonnes', 'arrival_quantity', 'Arrivals', 'Arrival Quantity']))

      if (!name || !state || !commodity || !priceDate || modalPrice === null) continue

      const { data: market, error: marketError } = await admin
        .from('markets')
        .upsert({ name, state, district, market_type: 'mandi' }, { onConflict: 'name,district,state' })
        .select('id')
        .single()

      if (marketError || !market) continue
      marketsUpserted += 1

      const { error: priceError } = await admin
        .from('market_prices')
        .upsert({
          market_id: market.id,
          commodity,
          variety,
          grade,
          price_date: priceDate,
          min_price: minPrice,
          max_price: maxPrice,
          modal_price: modalPrice,
          arrivals_tonnes: arrivals,
          unit: 'quintal',
          source: 'data.gov.in',
          source_record_id: text(first(record, ['id', 'record_id', 'source_record_id'])),
        }, { onConflict: 'market_id,commodity,variety,grade,price_date' })

      if (!priceError) recordsUpserted += 1
    }

    const status = recordsUpserted === records.length ? 'success' : 'partial'
    await admin.from('market_sync_runs').update({
      status,
      records_seen: records.length,
      records_upserted: recordsUpserted,
      markets_upserted: marketsUpserted,
      finished_at: new Date().toISOString(),
    }).eq('id', run.id)

    return Response.json({
      ok: true,
      status,
      recordsSeen: records.length,
      recordsUpserted,
      marketsUpserted,
      runId: run.id,
    }, { headers: corsHeaders })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown sync error'
    await admin.from('market_sync_runs').update({
      status: 'failed',
      error_message: message.slice(0, 2000),
      finished_at: new Date().toISOString(),
    }).eq('id', run.id)

    return Response.json({ error: message, runId: run.id }, { status: 502, headers: corsHeaders })
  }
})
