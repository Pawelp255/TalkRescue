# TalkRescue — Security Audit

**Date:** May 2026  
**Scope:** Repository `~/Projects/iOS/TalkRescue` (post–history-clean `main`, commit `3e809c3` area)  
**Method:** Static code review, repo grep, config trace. **No runtime pentest. No code changes.**

---

## Executive summary

| Area | Verdict |
|------|---------|
| Secret exposure in git | **LOW** — no `sk-` keys in tracked files; `Secrets.xcconfig` gitignored |
| Secret exposure in shipped app | **HIGH** — OpenAI key embedded in app bundle `Info.plist` |
| Client-side AI calls | **HIGH** — iPhone calls `api.openai.com` directly with Bearer token |
| Backend / proxy | **NONE** — no Supabase, no Edge Functions, no custom server |
| Abuse protection | **HIGH risk gap** — no rate limits, no auth beyond static API key |
| Privacy disclosures vs code | **LOW–MEDIUM** — aligned; minor UX copy leaks build setup |
| Public App Store launch (current arch) | **NOT SAFE** without proxy + key removal |

---

## 1. Current architecture (exact)

```
┌─────────────────────────────────────────────────────────────────┐
│                         iPhone (TalkRescue)                      │
├─────────────────────────────────────────────────────────────────┤
│  Microphone ──► Apple Speech (on-device, pl-PL)                 │
│       │              SFSpeechRecognizer / Speech framework       │
│       ▼                                                          │
│  Recognized Polish text                                          │
│       │                                                          │
│       ├──► RescuePhraseCache (19 exact phrases, local dict)       │
│       │         miss ───────────────────────────────┐            │
│       │         hit  ──► UI + optional TTS         │            │
│       │                                            ▼            │
│       └──► TranslationService                      │            │
│              POST https://api.openai.com/v1/chat/completions    │
│              Authorization: Bearer <OPENAI_API_KEY from plist>  │
│              model: gpt-4o-mini, max_tokens: 64, temperature: 0   │
│              user content = recognized Polish (no server filter)  │
│       ▼                                                          │
│  English text ──► UI, UserDefaults history (max 10), favorites   │
│       └──► AVSpeechSynthesizer (on-device TTS, en-US)            │
└─────────────────────────────────────────────────────────────────┘

External services:
  • Apple — Speech, microphone, iOS, TTS
  • OpenAI — Chat Completions API only

NOT used:
  • Supabase (no references in repo)
  • Custom backend / Edge Functions
  • Apple Translation framework
  • Firebase / analytics SDKs
```

### API key path (build → runtime)

1. Developer sets `OPENAI_API_KEY` in `TalkRescue/Config/Secrets.xcconfig` (gitignored).
2. `TalkRescue/Config/Config.xcconfig` includes Secrets via `#include? "Secrets.xcconfig"`.
3. Xcode substitutes `$(OPENAI_API_KEY)` into `TalkRescue/Info.plist` at build time.
4. `TranslationService` reads `Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY")`.
5. Every translation request sends `Authorization: Bearer <key>` from the device.

**Implication:** Anyone with the App Store IPA, TestFlight build, or a jailbroken install can extract the key (e.g. `strings`, `plutil`, class-dump of plist).

---

## 2. Findings by checklist

### OpenAI API usage

| Item | Status | Detail |
|------|--------|--------|
| Endpoint | Present | `https://api.openai.com/v1/chat/completions` |
| Model | `gpt-4o-mini` | Cost-efficient but still billable per token |
| Warmup | Present | `HEAD https://api.openai.com` on launch (`TranslationService.warmConnection`) |
| Output cap | Yes | `max_tokens: 64` limits **output** cost |
| Input cap | **No** | Full recognized transcript sent; long speech → large input |
| System prompt | Minimal | `"PL→EN. One spoken English line only. No quotes."` |
| Temperature | `0` | Good for determinism |

### Secret exposure

| Location | Risk | Notes |
|----------|------|-------|
| `Secrets.xcconfig` | LOW (local) | Gitignored; correct pattern for dev |
| `Secrets.xcconfig.example` | LOW | Placeholder only |
| `Info.plist` | **HIGH (shipped)** | Key name `OPENAI_API_KEY` in customer binary |
| Git history (current `main`) | LOW | Single clean commit; no `sk-` found in tree |
| Logs | LOW–MEDIUM | `os.Logger` does not log key or raw translation text; logs durations and errors |
| User-facing errors | LOW | `L10n.Errors.translationNotConfigured` mentions `Secrets.xcconfig` (build-time detail) |

### Hardcoded secrets scan

```
Pattern searched: OPENAI_API_KEY, sk-, api.openai.com, Bearer, Supabase
Result: No live API keys in tracked source. Only placeholders and documentation.
```

### Env / Supabase

- **No** `.env` files committed.
- **No** Supabase client, anon key, or service role anywhere in codebase.

### Client-side AI calls

**Yes — 100% client-side.** All OpenAI traffic originates from the app process via `URLSession`. No intermediary can revoke a per-user session without changing the app.

### Rate limits & abuse

| Control | Present? |
|---------|----------|
| Per-user server rate limit | No |
| Per-device throttle | No |
| Max requests per minute | No |
| Input length limit before API | No |
| Retry cooldown | No (`retryTranslation()` immediate) |
| OpenAI org budget / hard cap | **Developer responsibility** (outside repo) |
| Task cancellation on new recording | Yes (`translationGeneration`) — limits parallel calls only |

### Prompt injection

| Vector | Risk | Mitigation today |
|--------|------|------------------|
| User speaks adversarial Polish/English | MEDIUM | Short system prompt; `max_tokens: 64` caps reply size |
| Long dictated text | MEDIUM | No truncation; increases input tokens and cost |
| Jailbreak of model via speech | LOW–MEDIUM | Model may still leak odd outputs; not logged to analytics |

User content is passed as the **user** role message with no sanitization beyond trim/empty checks.

### Debug / logging

- Uses `os.Logger` with `privacy: .public` on **durations**, **error descriptions**, **transcript length** — not full transcript text in most paths.
- **No** `print()` / `NSLog` of API responses in production Swift sources reviewed.
- Launch metrics: timing only (`LaunchMetrics`).

### Analytics / privacy mismatch

| Claim (docs / site) | Code reality | Match? |
|---------------------|--------------|--------|
| No ads / no ad tracking | No ad SDKs | Yes |
| No analytics SDK | No Firebase etc. | Yes |
| Speech on-device | Apple Speech | Yes |
| Text may go to OpenAI | Direct HTTPS from app | Yes |
| No TalkRescue cloud account | No auth server | Yes |
| History local only | `UserDefaults` max 10 | Yes |
| API key “at build time, not in UI” | True; but **is in binary** | Disclose in privacy; security issue separate |

---

## 3. Risk classification

### HIGH

1. **Embedded OpenAI API key in App Store binary**  
   - Extractable → unlimited third-party usage billed to developer account.  
   - **Blocks safe public launch** at scale.

2. **No backend proxy or abuse controls**  
   - Stolen key + scripts = worst-case spend until OpenAI org limit.

3. **Unbounded input size to OpenAI**  
   - Long recognition results increase tokens per request.

### MEDIUM

1. **TestFlight / small-audience distribution with single org key**  
   - Acceptable only with OpenAI **monthly budget**, **usage alerts**, and key rotation plan.

2. **Prompt injection / off-brand outputs**  
   - Reputational / UX risk; limited by `max_tokens`.

3. **Error copy references `Secrets.xcconfig`**  
   - Informational leak to end users; not a credential leak.

4. **Retry + Rescue auto-finish loops**  
   - Legitimate user can trigger many billable calls per session; no cooldown.

### LOW

1. **Secrets in git (current `main`)**  
   - Properly gitignored; clean history after May 2026 rewrite.

2. **Privacy policy / App Privacy questionnaire alignment**  
   - Documentation matches behavior if OpenAI + Apple are declared.

3. **Local phrase cache**  
   - 19 phrases avoid API; quick English buttons in UI do not call OpenAI.

4. **Supabase exposure**  
   - N/A — not integrated.

---

## 4. Files where AI / network activity occurs

| File | Role |
|------|------|
| `TalkRescue/Services/TranslationService.swift` | **Only** OpenAI HTTP client (POST completions, HEAD warmup, Bearer auth) |
| `TalkRescue/Managers/RescueSession.swift` | Orchestrates cache → OpenAI; prewarm; retry; rescue flow |
| `TalkRescue/Services/RescuePhraseCache.swift` | Local exact-match cache (no network) |
| `TalkRescue/Info.plist` | Declares `OPENAI_API_KEY` plist entry |
| `TalkRescue/Config/Config.xcconfig` | Build-time key injection chain |
| `TalkRescue/Config/Secrets.xcconfig` | Local secrets (gitignored, not in repo) |
| `TalkRescue/Managers/SpeechManager.swift` | Apple Speech only (on-device) |
| `TalkRescue/Services/TTSService.swift` | On-device TTS only |

**No other `URLSession` / remote AI usage found in Swift sources.**

---

## 5. Can the app safely launch publicly today?

| Audience | Safe? | Condition |
|----------|-------|-----------|
| **App Store (public)** | **No** | Move key off-device; add proxy + limits first |
| **TestFlight (≤ few dozen testers)** | **Caution** | OpenAI spend cap + monitoring; accept key extraction among testers |
| **Personal dev device** | **Yes** | Your key, your risk |
| **Open-source repo consumers** | **Yes** | Each builder supplies own `Secrets.xcconfig` (not your key in IPA) |

**Privacy / App Store compliance (disclosure):** Generally **acceptable** if Privacy Policy URL, Support URL, and App Privacy labels declare microphone, speech, and third-party translation. **Security/billing** is the blocker, not the privacy questionnaire alone.

---

## 6. Recommended production architecture

```
iPhone
  ├─ Apple Speech (unchanged)
  ├─ RescuePhraseCache + expanded offline phrases (unchanged / grow list)
  ├─ Apple Translation framework (iOS 17.4+ where PL↔EN packs available) — primary path, no marginal API cost
  └─ HTTPS → YOUR proxy (Supabase Edge Function / Cloudflare Worker / minimal VPS)
              ├─ Auth: short-lived app attestation OR signed anonymous session token
              ├─ Rate limit: per device / per IP / global
              ├─ Validate: max input length, language heuristic, block empty
              ├─ Cache: hash(polish_normalized) → english (Redis / Supabase KV / edge cache)
              └─ Fallback: OpenAI gpt-4o-mini (key ONLY on server)
```

**Do not** ship `OPENAI_API_KEY` in `Info.plist` for production.

---

## 7. Safe migration plan (minimal changes)

See `docs/PRODUCTION_HARDENING_PLAN.md` for phased steps. Summary:

| Phase | Effort | Change |
|-------|--------|--------|
| 0 | 5 min | OpenAI dashboard: hard monthly budget, email alerts, rotate key |
| 1 | 0 code | Delay public launch until Phase 2 |
| 2 | Small | Edge proxy + env secret; `TranslationService` → proxy URL + app token header |
| 3 | Small | Remove `OPENAI_API_KEY` from `Info.plist`; stop xcconfig injection for release |
| 4 | Medium | Client max input length + retry cooldown |
| 5 | Optional | Apple Translation primary; OpenAI fallback only |
| 6 | Optional | Expand `RescuePhraseCache` from analytics of common phrases |

**Swift app logic** (`RescueSession`, UI, Speech) can stay largely unchanged; swap `TranslationService` transport layer only.

---

## 8. Verification commands (repeat after changes)

```bash
cd ~/Projects/iOS/TalkRescue

# Tracked secrets / artifacts
git ls-files | grep -E 'derivedData|xcarchive|Secrets\.xcconfig$|sk-'

# Source scan
rg -n 'api\.openai|OPENAI_API_KEY|Bearer |sk-' TalkRescue --glob '*.swift'

# Shipped plist (after archive)
plutil -p path/to/TalkRescue.app/Info.plist | grep -i openai
```

---

## 9. Related documents

- `docs/BILLING_RISK.md` — cost models and abuse scenarios  
- `docs/PRODUCTION_HARDENING_PLAN.md` — implementation checklist  
- `docs/PRIVACY_POLICY_PL.md` / `docs-site/privacy.html` — user-facing disclosure  

---

*Audit only — no application code was modified.*
