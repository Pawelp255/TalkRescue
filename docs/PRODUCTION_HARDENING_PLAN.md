# TalkRescue — Production Hardening Plan

**Date:** May 2026  
**Goal:** Ship publicly on the App Store without exposing OpenAI billing, while keeping **minimal** Swift/UI changes.  
**Prerequisite audits:** `docs/SECURITY_AUDIT.md`, `docs/BILLING_RISK.md`

**Constraint from product owner:** Do not change Swift app behavior in this document phase — this is the **implementation plan only**.

---

## Target end state

```
TalkRescue (iOS)
  → Apple Speech (unchanged)
  → Local phrase cache (expanded over time)
  → [NEW] Apple Translation when available offline / on-device
  → [NEW] POST https://api.<your-domain>/v1/translate
        Authorization: Bearer <short-lived app token | signed request>
        Body: { "text": "<polish>", "source": "pl", "target": "en" }
  → Edge function holds OPENAI_API_KEY
        rate limit · max length · cache · logging (no PII retention policy TBD)
```

**Remove from release builds:** `OPENAI_API_KEY` in `Info.plist` and xcconfig substitution into the customer binary.

---

## Phase 0 — Immediate (no code, &lt; 1 hour)

| # | Action | Owner |
|---|--------|-------|
| 0.1 | OpenAI: set **hard monthly budget** + usage alerts | Developer |
| 0.2 | Rotate API key if any TestFlight/IPA was shared widely | Developer |
| 0.3 | **Do not** submit App Store 1.0 with current client-embedded key | Developer |
| 0.4 | Confirm `Secrets.xcconfig` never committed (`git ls-files`) | Developer |

---

## Phase 1 — Backend proxy (minimal, highest ROI)

### Option A: Supabase Edge Function (fits “Supabase” plugin ecosystem)

1. Create Supabase project (if not exists).  
2. Edge Function `translate`:  
   - Read `OPENAI_API_KEY` from Supabase secrets.  
   - Accept JSON `{ "text": string }`.  
   - Reject if `text.length > 500` (or 300 for spoken phrases).  
   - Rate limit: e.g. **30 requests / minute / IP** and **200 / day / IP** (tune).  
   - Optional: cache `sha256(normalize(text))` → english for 7 days.  
   - Call OpenAI with same prompt/model as `TranslationService` today.  
3. Return `{ "english": string }` or structured error.

### Option B: Cloudflare Worker (similar, no database required)

Same logic; KV for cache + rate limit counters.

### App change (small — one file focus)

| File | Change |
|------|--------|
| `TranslationService.swift` | Replace `endpoint` with proxy URL; replace `Bearer` OpenAI key with app token or Supabase anon + RLS policy on function |
| `Info.plist` | Remove `OPENAI_API_KEY` key from **Release** configuration |
| `Config.xcconfig` | Add `TRANSLATE_PROXY_URL` for debug vs prod |

**Do not change:** `RescueSession`, `SpeechManager`, views (unless adding a feature flag).

### Estimated effort

- Backend: **2–4 hours** (experienced dev)  
- iOS: **1–2 hours**  
- Test: **1 hour**

---

## Phase 2 — Client-side guardrails (minimal Swift)

| # | Change | File | Purpose |
|---|--------|------|---------|
| 2.1 | Cap Polish text at **500 characters** before network | `TranslationService` or `RescueSession` | Cost + abuse |
| 2.2 | Retry cooldown **2 s** | `RescueSession.retryTranslation` | Prevent tap spam |
| 2.3 | Optional: max **1 in-flight** translation (already mostly true via `translationGeneration`) | — | — |
| 2.4 | Remove user-facing `Secrets.xcconfig` mention | `L10n.Errors` | Polish UX |

**Estimated effort:** **1–2 hours**

---

## Phase 3 — Reduce API dependency (recommended)

### 3a. Expand `RescuePhraseCache`

- Add top 50–100 phrases from real usage / `docs/SCREENSHOT_CAPTIONS` / support themes.  
- **Zero API cost** for matches.  
- File: `RescuePhraseCache.swift` only.

### 3b. Apple Translation framework (iOS 17.4+)

- Use `Translation` / `TranslationSession` for PL→EN when language pack available.  
- Fall back to proxy only on unsupported OS, missing pack, or error.  
- New thin wrapper: `AppleTranslationService.swift`; `RescueSession` tries Apple → proxy.

**Estimated effort:** **4–8 hours** (testing on device with language packs)

### 3c. Prompt hardening (server-side)

Move system prompt to Edge Function only; client sends raw text. Prevents prompt tampering via modified app (partial).

---

## Phase 4 — Release & operations

| # | Task |
|---|------|
| 4.1 | Archive Release scheme **without** `OPENAI_API_KEY` in plist |
| 4.2 | Verify: `plutil TalkRescue.app/Info.plist` has no OpenAI key |
| 4.3 | Pen-test: `strings` IPA for `sk-` |
| 4.4 | Load test proxy rate limits |
| 4.5 | Update `docs/PRIVACY_POLICY_PL.md` if proxy host named (e.g. Supabase region) |
| 4.6 | App Privacy: add “Data collected by third-party processors” → your proxy + OpenAI |

---

## Migration sequence (minimal disruption)

```
Week 1: Phase 0 + Phase 1 (proxy live, TestFlight build points to proxy)
Week 2: Phase 2 guardrails + expand cache (Phase 3a)
Week 3: Phase 3b Apple Translation (optional before 1.0 if time)
Week 4: App Store submit with Release plist clean
```

Rollback: point `TranslationService` back to direct OpenAI **only for internal debug builds** via `#if DEBUG` + xcconfig — never for App Store.

---

## Configuration matrix

| Build | OPENAI in plist | API target |
|-------|-----------------|------------|
| Debug (local) | Optional direct key | OpenAI or proxy |
| TestFlight | **No** | Proxy only |
| App Store | **No** | Proxy only |

---

## Abuse prevention checklist (proxy)

- [ ] Max body size (bytes + chars)  
- [ ] Rate limit per IP  
- [ ] Optional: rate limit per `device_id` header (random UUID in Keychain, not IDFA)  
- [ ] Reject non-PL heuristic (optional `Accept-Language` / simple charset check)  
- [ ] Structured 429 responses → app shows “Spróbuj za chwilę”  
- [ ] Server logs: timestamp + token count only (no long-term transcript storage unless policy updated)  
- [ ] CORS N/A (native app)  
- [ ] WAF / bot protection on custom domain (Cloudflare)

---

## App Store privacy compliance (unchanged architecture items)

Keep current disclosures; update when proxy added:

| Label | Value |
|-------|-------|
| Data collected | Audio, User Content (text) |
| Linked to user | No |
| Tracking | No |
| Third parties | Apple, OpenAI (via your proxy), optionally Supabase as processor |

`docs-site/privacy.html` already states OpenAI — add one sentence: *“Żądania mogą przechodzić przez zabezpieczony serwer pośredniczący należący do wydawcy.”* when proxy ships.

---

## Files touched by phase (reference)

| Phase | Files |
|-------|-------|
| 0 | OpenAI dashboard only |
| 1 | `TranslationService.swift`, `Info.plist`, `Config.xcconfig`, new Edge Function repo or `supabase/functions/` |
| 2 | `TranslationService.swift`, `RescueSession.swift`, `L10n.swift` |
| 3a | `RescuePhraseCache.swift` |
| 3b | New `AppleTranslationService.swift`, `RescueSession.swift` |
| 4 | Docs, App Store Connect metadata |

**Explicitly out of scope:** Xcode project structure changes unless needed for new Swift file; no UI redesign.

---

## Success criteria (go / no-go for App Store)

- [ ] `git ls-files` and IPA contain **no** `sk-` / `OPENAI_API_KEY` value  
- [ ] Proxy rate limits tested  
- [ ] OpenAI budget cap active  
- [ ] Privacy policy mentions translation path accurately  
- [ ] 24h TestFlight soak: no runaway usage in OpenAI dashboard  

---

## Related documents

- `docs/SECURITY_AUDIT.md` — threat model and file map  
- `docs/BILLING_RISK.md` — cost and abuse math  
- `TalkRescue/Config/README.md` — current dev key setup (dev only)  

---

*Plan only — implementation not started in codebase per audit scope.*
