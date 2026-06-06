# TalkRescue 1.2 — iOS Supabase Translation Integration (Phase 2)

**Date:** June 2026  
**Status:** Implemented  
**Backend:** `https://iexhwsiqwgoksucdzpok.supabase.co/functions/v1/translate`  
**Prerequisite:** Phase 1 deployed (`docs/SUPABASE_SETUP_GUIDE.md`)

---

## Summary

The iOS app no longer calls `api.openai.com` directly. `TranslationService` POSTs to the Supabase Edge Function with `text` and `profileId` only. OpenAI credentials remain server-side.

**Unchanged:** UI, speech, TTS, language profiles, cache, retry, Rescue Mode, Action Button.

---

## Architecture

```
iPhone
  RescueSession (unchanged orchestration)
    → RescuePhraseCache (local hit → no network)
    → TranslationService.translate(text, profile)
         POST TALKRESCUE_SUPABASE_URL
         Header: apikey: TALKRESCUE_API_KEY
         Body: { text, profileId }
    → UI + TTS

Supabase Edge Function → OpenAI (server only)
```

---

## Configuration keys

| Key | Source | Committed? | Purpose |
|-----|--------|------------|---------|
| `TALKRESCUE_SUPABASE_URL` | `Config.xcconfig` | Yes | Edge Function URL |
| `TALKRESCUE_API_KEY` | `Secrets.xcconfig` | **No** (gitignored) | App proxy auth |

### Setup (developer machine / CI)

```bash
cp TalkRescue/Config/Secrets.xcconfig.example TalkRescue/Config/Secrets.xcconfig
# Edit Secrets.xcconfig — set TALKRESCUE_API_KEY from supabase secrets set
```

Default URL in `Config.xcconfig` (note `$()` trick — `//` is a comment in xcconfig):

```
TALKRESCUE_SUPABASE_URL = https:/$()/iexhwsiqwgoksucdzpok.supabase.co/functions/v1/translate
```

Values are injected into `Info.plist` at build time and read via `Bundle.main`.

---

## Files changed (Phase 2)

| File | Change |
|------|--------|
| `TalkRescue/Services/TranslationService.swift` | Supabase proxy client |
| `TalkRescue/Info.plist` | `TALKRESCUE_*` keys; removed `OPENAI_API_KEY` |
| `TalkRescue/Config/Config.xcconfig` | Proxy URL + key placeholders |
| `TalkRescue/Config/Secrets.xcconfig.example` | Proxy key placeholder |
| `TalkRescue/Config/README.md` | Updated setup instructions |
| `TalkRescue/Utilities/L10n.swift` | Friendly Polish error strings |
| `TalkRescue/Managers/RescueSession.swift` | Log label only (`proxy`) |

---

## Error mapping

| HTTP | `TranslationError` | User message (PL) |
|------|-------------------|-------------------|
| — | `missingAPIKey` | Usługa tłumaczenia nie jest skonfigurowana. |
| 401 | `unauthorized` | Usługa tłumaczenia jest niedostępna. Spróbuj ponownie później. |
| 429 | `rateLimited` | Zbyt wiele prób. Spróbuj za chwilę. |
| 400 | `apiFailure` | Nie udało się przetłumaczyć tej wypowiedzi. Spróbuj krócej. |
| 502 | `networkFailure` | Brak połączenia. Sprawdź internet i spróbuj ponownie. |
| 504 | `timedOut` | Tłumaczenie trwało zbyt długo… |
| Timeout | `timedOut` | Same as 504 |

---

## Security validation

Run after every Release archive:

```bash
cd ~/Projects/iOS/TalkRescue

# 1. No live API keys in git
git ls-files | grep -E 'Secrets\.xcconfig$|sk-'
rg -n 'sk-proj|sk-' --glob '!*.md' --glob '!docs/**'

# 2. No OpenAI references in Swift
rg -n 'api\.openai|OPENAI_API_KEY' TalkRescue --glob '*.swift'

# 3. Info.plist has proxy keys only
rg -n 'OPENAI' TalkRescue/Info.plist TalkRescue/Config/Config.xcconfig

# 4. Shipped binary (after archive)
APP="path/to/TalkRescue.app"
plutil -p "$APP/Info.plist" | grep -iE 'openai|talkrescue'
strings "$APP/TalkRescue" | grep -E 'api\.openai\.com|sk-proj|OPENAI_API_KEY'
```

**Expected Release results:**

- `git ls-files` — no `Secrets.xcconfig`
- Swift grep — no matches
- `Info.plist` — `TALKRESCUE_SUPABASE_URL` + `TALKRESCUE_API_KEY`; no `OPENAI_API_KEY`
- `strings` — no `api.openai.com`, no `sk-`

---

## Manual test checklist

| # | Test | Expected |
|---|------|----------|
| 1 | Main hold-to-speak PL→EN | Translation appears; network hits Supabase |
| 2 | Language chip → PL→SV, speak | Swedish output |
| 3 | Language chip → PL→ES, speak | Spanish output |
| 4 | Rescue Mode auto-finish | Same proxy path |
| 5 | Action Button → Rescue | Same proxy path |
| 6 | Retry after airplane mode off | Retry works |
| 7 | Cache hit (`nie rozumiem`) | Instant; no network |
| 8 | Wrong `TALKRESCUE_API_KEY` in Secrets | Friendly “niedostępna” / not configured |
| 9 | Rate limit burst (optional) | “Zbyt wiele prób…” |
| 10 | Network proxy capture | No `api.openai.com` from device |

### Verify no direct OpenAI (macOS)

Use Proxyman, Charles, or log stream while translating:

```bash
log stream --predicate 'subsystem == "com.pawelp.talkrescue" AND category == "Translation"'
```

Look for `Translation proxy request started` — not `OpenAI request started`.

---

## Build commands

### Simulator

```bash
cd ~/Projects/iOS/TalkRescue/TalkRescue
xcodebuild -scheme TalkRescue -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Archive (requires signing + Secrets.xcconfig)

```bash
xcodebuild -scheme TalkRescue -destination 'generic/platform=iOS' archive \
  -archivePath build/TalkRescue.xcarchive
```

Post-archive security check:

```bash
plutil -p build/TalkRescue.xcarchive/Products/Applications/TalkRescue.app/Info.plist
strings build/TalkRescue.xcarchive/Products/Applications/TalkRescue.app/TalkRescue | \
  grep -E 'api\.openai|sk-proj|OPENAI_API_KEY' || echo "PASS: no OpenAI artifacts"
```

---

## Rollback

Point `TranslationService` back to direct OpenAI only for emergency internal debug — not for App Store. Production rollback = redeploy previous app version that still used embedded OpenAI key (not recommended).

---

## Related documents

- [`docs/SECURE_TRANSLATION_V1_2.md`](SECURE_TRANSLATION_V1_2.md) — architecture audit
- [`docs/SUPABASE_SETUP_GUIDE.md`](SUPABASE_SETUP_GUIDE.md) — backend deploy
- [`docs/PRODUCTION_HARDENING_PLAN.md`](PRODUCTION_HARDENING_PLAN.md) — full rollout
