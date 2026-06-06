# TalkRescue — Supabase Setup Guide (Phase 1)

Deploy the `translate` Edge Function that proxies Polish speech text to OpenAI.  
**Phase 1 is backend only** — the iOS app still calls OpenAI directly until Phase 2.

Reference: [`docs/SECURE_TRANSLATION_V1_2.md`](SECURE_TRANSLATION_V1_2.md)

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Supabase CLI](https://supabase.com/docs/guides/cli) | Deploy Edge Functions |
| [Docker Desktop](https://www.docker.com/) | Local `supabase start` / `functions serve` (optional) |
| OpenAI API key | Server secret only — never in the iOS app |

```bash
supabase --version   # v2.x recommended
```

---

## 1. Create a Supabase project

1. Open [database.new](https://database.new) (or Supabase Dashboard → New project).
2. Choose a name (e.g. `talkrescue-prod`).
3. Pick a region close to users (e.g. **EU (Frankfurt)** for Polish audience).
4. Set a strong database password (required even if you only use Edge Functions).
5. Wait for the project to finish provisioning.

Note your **Project URL**:

- Dashboard → **Project Settings** → **API**
- URL: `https://<project-ref>.supabase.co`

The translation proxy uses a **custom app key** (`TALKRESCUE_API_KEY`), not the Supabase anon key. The anon key is for Supabase client SDK access; the Edge Function validates `TALKRESCUE_API_KEY` instead.

---

## 2. Link this repository

From the TalkRescue repo root:

```bash
cd ~/Projects/iOS/TalkRescue

supabase login
supabase projects list
supabase link --project-ref <YOUR_PROJECT_REF>
```

`project-ref` is the subdomain in your project URL (e.g. `abcdefghijklmnop`).

---

## 3. Set secrets

The Edge Function reads two secrets from Supabase (CLI rejects names starting with `SUPABASE_`):

| Secret | Purpose |
|--------|---------|
| `OPENAI_API_KEY` | OpenAI Chat Completions — server only |
| `TALKRESCUE_API_KEY` | Public app proxy key — clients send `apikey: <value>` |

Generate a proxy key locally:

```bash
export TALKRESCUE_API_KEY="$(openssl rand -hex 32)"
```

Set both secrets:

```bash
supabase secrets set OPENAI_API_KEY=sk-proj-xxxxxxxx
supabase secrets set TALKRESCUE_API_KEY="$TALKRESCUE_API_KEY"
```

Verify (names only — values are hidden):

```bash
supabase secrets list
```

Expected:

```
OPENAI_API_KEY
TALKRESCUE_API_KEY
```

**Never** commit `sk-` or `TALKRESCUE_API_KEY` values to git. Store the proxy key in `Secrets.xcconfig` for Phase 2 iOS builds. Rotate the OpenAI key if it was ever embedded in a shipped IPA.

---

## 4. Deploy the function

```bash
cd ~/Projects/iOS/TalkRescue

supabase functions deploy translate
```

On success, the function is live at:

```
https://<project-ref>.supabase.co/functions/v1/translate
```

`supabase/config.toml` sets `[functions.translate] verify_jwt = false` because the iOS client authenticates with `TALKRESCUE_API_KEY` in the `apikey` header (not a user JWT). The function validates that key against the server secret.

Redeploy after any change:

```bash
supabase functions deploy translate
```

---

## 5. Local development (optional)

### Start Supabase stack

```bash
supabase start
```

### Serve the function with secrets

Create `supabase/.env.local` (gitignored):

```env
OPENAI_API_KEY=sk-proj-xxxxxxxx
TALKRESCUE_API_KEY=your_local_proxy_key_here
```

```bash
supabase functions serve translate --env-file supabase/.env.local --no-verify-jwt
```

Local URL:

```
http://127.0.0.1:54321/functions/v1/translate
```

---

## 6. curl tests

Replace placeholders:

- `<PROJECT_REF>` — your project reference
- `$TALKRESCUE_API_KEY` — the proxy key you set via `supabase secrets set`

### Success — Polish → English

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"nie rozumiem","profileId":"pl-en"}'
```

Expected `200`:

```json
{
  "translation": "I don't understand.",
  "provider": "openai"
}
```

### Success — Polish → Swedish

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"nie rozumiem","profileId":"pl-sv"}'
```

### Success — Polish → Spanish

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"dziękuję","profileId":"pl-es"}'
```

### Validation error — empty text

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"   ","profileId":"pl-en"}'
```

Expected `400`:

```json
{
  "error": "invalid_body",
  "message": "\"text\" must not be empty."
}
```

### Validation error — unknown profile

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"cześć","profileId":"pl-de"}'
```

Expected `400`:

```json
{
  "error": "invalid_body",
  "message": "Unsupported profileId. Allowed: pl-en, pl-sv, pl-es."
}
```

### Auth error — missing apikey

```bash
curl -sS -X POST \
  "https://<PROJECT_REF>.supabase.co/functions/v1/translate" \
  -H "Content-Type: application/json" \
  -d '{"text":"cześć","profileId":"pl-en"}'
```

Expected `401`:

```json
{
  "error": "unauthorized",
  "message": "Missing or invalid apikey."
}
```

### Rate limit (after burst testing)

Send >30 requests in one minute from the same IP. Expected `429`:

```json
{
  "error": "rate_limited",
  "message": "Too many translation requests. Try again later.",
  "retryAfter": 60
}
```

### Local curl

```bash
curl -sS -X POST \
  "http://127.0.0.1:54321/functions/v1/translate" \
  -H "apikey: $TALKRESCUE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"nie rozumiem","profileId":"pl-en"}'
```

---

## API contract

### Request

`POST /functions/v1/translate`

| Header | Required | Value |
|--------|----------|-------|
| `apikey` | Yes | `TALKRESCUE_API_KEY` (app proxy key — not Supabase anon) |
| `Content-Type` | Yes | `application/json` |
| `x-device-id` | No | UUID for per-device rate limits (Phase 2) |

Body (only these two fields):

```json
{
  "text": "recognized Polish speech",
  "profileId": "pl-en"
}
```

| Field | Rules |
|-------|-------|
| `text` | Trimmed; 1–500 characters |
| `profileId` | `pl-en`, `pl-sv`, or `pl-es` |

### Success response `200`

```json
{
  "translation": "I don't understand.",
  "provider": "openai"
}
```

### Error responses

| HTTP | `error` | When |
|------|---------|------|
| 400 | `invalid_body` | Bad JSON, extra fields, empty text, length, bad profile |
| 401 | `unauthorized` | Missing/wrong `apikey` |
| 405 | `method_not_allowed` | Not POST |
| 429 | `rate_limited` | Rate limit exceeded |
| 502 | `upstream_error` | OpenAI error |
| 504 | `upstream_timeout` | OpenAI timeout (12s) |

---

## Repository layout

```
supabase/
  config.toml                 # verify_jwt = false for translate
  .gitignore
  functions/
    translate/
      index.ts                # HTTP handler
      prompts.ts              # Server-owned system prompts
      validation.ts           # Input validation + length caps
      rate-limit.ts           # Rate-limit hooks (in-memory Phase 1)
      openai.ts               # OpenAI Chat Completions client
      errors.ts               # JSON error helpers + CORS
```

---

## Required secrets

| Secret | Set by | Purpose |
|--------|--------|---------|
| `OPENAI_API_KEY` | `supabase secrets set` | OpenAI Chat Completions (server only) |
| `TALKRESCUE_API_KEY` | `supabase secrets set` | App proxy auth — clients send in `apikey` header |

---

## OpenAI dashboard (do in parallel)

1. Set a **hard monthly budget** and email alerts.
2. Rotate the key if any TestFlight IPA contained the old embedded key.
3. Monitor usage after first curl tests and TestFlight soak.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `401` before function runs | Wrong deploy flags — ensure `verify_jwt = false` in `config.toml` and redeploy |
| `401` from function body | Wrong `apikey` — must match `TALKRESCUE_API_KEY` secret |
| `502` upstream_error | Check `OPENAI_API_KEY` secret; verify key is active in OpenAI dashboard |
| `504` upstream_timeout | OpenAI slow/down; retry; check OpenAI status |
| Function not found | Run `supabase functions deploy translate` after `supabase link` |
| Local serve fails | Start Docker; run `supabase start` |

---

## Phase 2 readiness

Phase 1 is complete when:

- [ ] Supabase project created and linked
- [ ] `OPENAI_API_KEY` and `TALKRESCUE_API_KEY` secrets set
- [ ] `translate` deployed to production URL
- [ ] curl tests pass for all three `profileId` values
- [ ] `401` / `400` / `429` error shapes verified

**Phase 2 (iOS)** will:

1. Change `TranslationService.swift` only — POST to `/functions/v1/translate`
2. Send `apikey: TALKRESCUE_API_KEY` header (not OpenAI Bearer token)
3. Body: `{ text, profileId: profile.id }` only
4. Parse `{ translation, provider }` response
5. Remove `OPENAI_API_KEY` from Release `Info.plist`
6. Add `SUPABASE_URL` + `TALKRESCUE_API_KEY` to xcconfig (Release)
7. Optional: `X-Device-ID` header for per-device rate limits

No Swift changes in Phase 1.

---

## Related documents

- [`docs/SECURE_TRANSLATION_V1_2.md`](SECURE_TRANSLATION_V1_2.md) — architecture audit
- [`docs/PRODUCTION_HARDENING_PLAN.md`](PRODUCTION_HARDENING_PLAN.md) — full rollout phases
- [`docs/BILLING_RISK.md`](BILLING_RISK.md) — cost and abuse model
