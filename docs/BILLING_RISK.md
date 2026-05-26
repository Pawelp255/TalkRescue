# TalkRescue — Billing & API Cost Risk

**Date:** May 2026  
**Model in production code:** `gpt-4o-mini` via Chat Completions  
**Billing owner today:** Developer’s OpenAI organization (key in every shipped build)

Pricing reference (verify current rates on [OpenAI pricing](https://openai.com/api/pricing/)):  
**gpt-4o-mini** ≈ **$0.15 / 1M input tokens**, **$0.60 / 1M output tokens** (typical published tiers; subject to change).

---

## 1. What triggers a billable event

| Action | Billable? | Notes |
|--------|-----------|-------|
| Hold-to-talk → translate (cache miss) | **Yes** | 1× Chat Completion |
| Rescue Mode auto-finish (cache miss) | **Yes** | 1× per completed utterance |
| Retry translation | **Yes** | New request, no cooldown |
| `TranslationService.warmConnection()` | **Minimal / none** | `HEAD` to `api.openai.com` only |
| RescuePhraseCache hit (19 phrases) | **No** | Local dictionary |
| Quick English buttons (main UI) | **No** | Pre-written English, TTS only |
| History / favorites tap | **No** | Displays stored text |
| Apple Speech recognition | **No** | On-device (Apple) |
| TTS playback | **No** | On-device |

---

## 2. Per-request cost model (estimate)

Assumptions per translation (cache miss):

| Component | Tokens (typical) | Cost @ mini rates |
|-----------|------------------|-------------------|
| System message | ~15 | ~$0.000002 |
| User (Polish transcript) | 15–80 (short phrase) | ~$0.000002–$0.000012 |
| Assistant output | 10–30 (`max_tokens: 64` cap) | ~$0.000006–$0.000018 |
| **Total per request** | ~40–125 | **~$0.00001–$0.00003** |

Long utterances (no client cap): 200+ input tokens → **~$0.00005+** per request still small **per call**, but abuse scales linearly with call volume.

---

## 3. Legitimate usage estimates

### Assumptions

- **Light user:** 8 translations / day (conversation helper)  
- **Active user:** 25 translations / day  
- **Rescue-heavy user:** 40 translations / day (auto-finish + retries)  
- **Cache hit rate:** 10% (19 static phrases vs open vocabulary) — adjust if you expand cache  

Effective billable calls = translations × (1 − cache hit rate).

### Per 100 users (30 days)

| Persona mix | Calculation | Est. monthly API cost |
|-------------|-------------|------------------------|
| All light (8/day) | 100 × 8 × 30 × 0.9 × $0.00002 | **~$4** |
| Mixed (avg 15/day) | 100 × 15 × 30 × 0.9 × $0.00002 | **~$8** |
| All active (25/day) | 100 × 25 × 30 × 0.9 × $0.00002 | **~$14** |

Round up for longer phrases and retries: **plan $10–25 / month per 100 MAU** at MVP intensity.

### Per 1,000 users (30 days)

| Persona mix | Est. monthly API cost |
|-------------|------------------------|
| Mixed (avg 15/day) | **~$80–120** |
| Active-heavy (avg 25/day) | **~$140–200** |

These assume **honest users** and a **non-extracted** API key.

---

## 4. Worst-case abuse scenario (stolen key)

### Attack path

1. Attacker downloads app from App Store or TestFlight.  
2. Extracts `OPENAI_API_KEY` from `Info.plist` inside IPA.  
3. Runs parallel scripts calling `https://api.openai.com/v1/chat/completions` with the same model (or heavier models if key permissions allow).

### App lacks

- Server-side rate limits  
- Per-user quotas  
- Key rotation without app update  
- Request signing / attestation  

### Exposure

| Scenario | Duration | Rough cost (order of magnitude) |
|----------|----------|----------------------------------|
| Casual scraper | 1 hour | $1–50 |
| Dedicated abuse (100 req/s attempted) | 24 hours | **$500–5,000+** if org limits allow |
| No OpenAI budget cap | Until noticed | **Unbounded** (account debt / suspension) |

**This is the dominant financial risk** — not normal user churn.

### Mitigations (required before public launch)

| Mitigation | Effect |
|------------|--------|
| Remove key from client | Stops passive extraction |
| Proxy + server-side rate limit | Caps QPS per device/IP |
| OpenAI org **hard** monthly budget | Ceiling on damage |
| Usage alerts at 50% / 80% | Early detection |
| Separate **restricted** API key (chat only, no fine-tuning) | Limits blast radius |
| Key rotation after TestFlight | Invalidates leaked betas |

---

## 5. Risk classification (billing)

| Risk | Level | Rationale |
|------|-------|-----------|
| Public App Store + embedded key | **HIGH** | Unbounded third-party spend potential |
| TestFlight (trusted testers) + budget cap | **MEDIUM** | Small leak surface; still extractable |
| Personal build (your device only) | **LOW** | You control usage |
| Post-proxy architecture | **LOW–MEDIUM** | Depends on limit tuning |
| Apple Translation primary + rare OpenAI fallback | **LOW** | Marginal API volume |

---

## 6. Non-OpenAI costs

| Item | Cost |
|------|------|
| Apple Developer Program | $99/year |
| GitHub Pages (docs-site) | $0 |
| Supabase (if added for proxy) | Free tier → paid by MAU |
| Speech / TTS | $0 marginal (on-device) |

---

## 7. Comparison: architecture options (monthly @ 1k MAU, mixed use)

| Architecture | Est. API $ | Abuse ceiling |
|--------------|------------|---------------|
| **Current (client key)** | $80–200 + **unlimited abuse** | None |
| **Edge proxy + rate limit (60 req/device/day)** | $80–200 | ~$extra bounded |
| **+ response cache (40% hit)** | $50–120 | Lower |
| **Apple Translation primary (80% on-device)** | $15–40 | Lower |
| **Apple only, no OpenAI** | **$0** | N/A |

---

## 8. OpenAI dashboard checklist (do today, no code)

- [ ] Set **monthly budget hard limit** (e.g. $25 for TestFlight, scale later)  
- [ ] Enable **email alerts** on usage thresholds  
- [ ] Review **API key permissions** (restrict to needed endpoints)  
- [ ] Create **separate keys** for dev / TestFlight / production proxy  
- [ ] Document **rotation procedure** if a build leaks  

---

## 9. Decision matrix: when is billing “safe enough”?

| Stage | OK to proceed? |
|-------|----------------|
| Local dev on your key | Yes |
| TestFlight &lt; 20 testers + $25 cap | Yes, with monitoring |
| Public App Store | **No** until proxy ships |
| Press / viral launch | **No** without cache + limits + budget |

---

## 10. Related files

| File | Billing relevance |
|------|-------------------|
| `TalkRescue/Services/TranslationService.swift` | Model, tokens, HTTP client |
| `TalkRescue/Managers/RescueSession.swift` | Call frequency, retry |
| `TalkRescue/Services/RescuePhraseCache.swift` | Free translations |
| `TalkRescue/Config/Secrets.xcconfig` | Key source (local) |

---

*Estimates are order-of-magnitude; monitor real usage in OpenAI Usage dashboard after first TestFlight wave.*
