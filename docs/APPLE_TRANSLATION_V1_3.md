# TalkRescue 1.3 — Apple Translation Integration Plan

**Date:** June 2026  
**Status:** Planning only — **no implementation**  
**Prerequisite:** v1.2 Supabase proxy (`docs/IOS_SUPABASE_TRANSLATION_V1_2.md`)  
**Related:** `docs/LOCAL_TRANSLATION_ROADMAP.md` (earlier sketch, superseded for v1.3 detail)

---

## Executive summary

TalkRescue v1.2 routes all network translation through a Supabase Edge Function. v1.3 adds an **on-device first** path using Apple's **Translation** framework (iOS 18+) for supported Polish → target pairs, with **silent fallback** to the existing Supabase proxy when local translation is unavailable, models are not installed, or quality checks fail.

| Dimension | Assessment |
|-----------|------------|
| Migration complexity | **Medium** — new service + SwiftUI host + availability gating |
| UI impact | **Minimal** — optional offline prep screen; no Rescue flow redesign |
| Deployment target | Can remain **iOS 17** with `@available(iOS 18, *)` gating |
| Expected latency win | **~500–1500 ms** off typical Supabase path (after models installed) |
| Billing impact | **High** — eliminates most proxy/OpenAI calls on iOS 18+ with installed models |
| Privacy impact | **High** — recognized Polish text may never leave device on local path |

---

## 1. Current architecture (v1.2 baseline)

```
Recognized Polish text (Apple Speech, on-device)
    │
    ├─► RescuePhraseCache (exact match, ~20/7/7 phrases per profile)
    │       hit → instant UI + optional TTS
    │
    └─► TranslationService (Supabase proxy)
            POST /functions/v1/translate
            { text, profileId } → { translation, provider: "openai" }
    │
    ▼
Target-language text → UI, history, AVSpeechSynthesizer TTS
```

**Deployment target today:** iOS 17.0  
**Profiles:** `pl-en`, `pl-sv`, `pl-es` — all share Polish speech input (`pl-PL`)

---

## 2. Target architecture (v1.3)

```
Recognized Polish text
    │
    ├─► [1] RescuePhraseCache          ← unchanged, always first
    │
    ├─► [2] AppleTranslationService    ← NEW, iOS 18+ only
    │       LanguageAvailability check
    │       status == .installed → translate locally
    │       .supported / .unsupported / error → fall through (no blocking UI)
    │
    └─► [3] TranslationService         ← unchanged Supabase fallback
    │
    ▼
Target-language text → UI, history, TTS (unchanged)
```

### Design principles

1. **Cache before everything** — `RescuePhraseCache` stays synchronous and first; zero regression for common phrases.
2. **Silent fallback** — Rescue Mode and Action Button cold launch must never block on Apple's language-download sheet.
3. **No UI redesign** — chip, onboarding, hold-to-speak, Rescue layout unchanged.
4. **Proxy always available** — Supabase path remains for iOS 17, missing models, unsupported pairs, and quality escape hatch.
5. **Text-only translation** — Apple Translation processes strings; speech and TTS pipelines are untouched.

---

## 3. Apple Translation framework (iOS 18) — research

### API surface

| API | Role | TalkRescue relevance |
|-----|------|---------------------|
| `TranslationSession` | Performs `translate(_:)` async | Core local translator |
| `TranslationSession.Configuration` | `source` + `target` `Locale.Language` | Maps from `LanguageProfile` locale IDs |
| `LanguageAvailability` | `status(from:to:)` → `.installed` / `.supported` / `.unsupported` | Gate before local path |
| `LanguageAvailability.supportedLanguages` | Dynamic list from Apple | Validate profile pairs at runtime |
| `prepareTranslation()` | Prefetch models without translating | Settings / idle prewarm only |
| `.translationTask(source:target:action:)` | SwiftUI modifier; provides session | Required for download consent UI |
| `init(installedSource:target:)` | Direct session, **installed models only** | Rescue-safe fast path |

**Sources:** [WWDC24 — Meet the Translation API](https://developer.apple.com/videos/play/wwdc2024/10117/), [TranslationSession](https://developer.apple.com/documentation/translation/translationsession), [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability)

### Key behavioral facts

| Fact | Implication for TalkRescue |
|------|---------------------------|
| On-device ML after model download | No network needed for translation once `.installed` |
| Models shared system-wide (Translate app) | User may already have PL↔EN assets |
| First download requires network + user consent | **Never trigger on Rescue cold path** |
| `TranslationSession` anchored to a SwiftUI view | Need persistent `TranslationHostView` in hierarchy |
| `init(installedSource:target:)` throws if not installed | Use only when `status == .installed` |
| Simulator **not supported** | All Apple Translation QA on physical devices |
| Apple collects language-pair metrics, **not content** | Privacy improvement vs proxy path |
| No control over output style (no system prompt) | Quality may differ from OpenAI conversational tuning |

### Supported languages (Apple-published list)

Apple's Translation framework supports these language **codes** (list evolves over time):

> English, Arabic, Catalan, Czech, Danish, Dutch, Finnish, French, German, Greek, Hebrew, Hindi, Italian, Japanese, Korean, Malay, Norwegian Bokmål, **Polish**, Portuguese, Romanian, Russian, Simplified Chinese, Slovak, **Spanish**, **Swedish**, Thai, Traditional Chinese, Turkish, Ukrainian, Vietnamese

**TalkRescue profile mapping (expected):**

| Profile | Source | Target | Pair expectation |
|---------|--------|--------|------------------|
| `pl-en` | `pl` / `pl-PL` | `en` / `en-US` | **Likely supported** — verify on device |
| `pl-sv` | `pl` / `pl-PL` | `sv` / `sv-SE` | **Likely supported** — verify on device |
| `pl-es` | `pl` / `pl-PL` | `es` / `es-ES` | **Likely supported** — verify on device |

**Critical caveat:** Language *codes* being supported does not guarantee every *pairing* is available. Always check:

```swift
let status = await LanguageAvailability().status(
    from: Locale.Language(identifier: "pl"),
    to: Locale.Language(identifier: "en")
)
// Use local path only when status == .installed
```

Use `LanguageAvailability.supportedLanguages` (async) rather than hardcoding assumptions in production.

### Offline model downloads

| State | Meaning | TalkRescue action |
|-------|---------|-----------------|
| `.installed` | Models ready | Use `init(installedSource:target:)` or `translationTask` session |
| `.supported` | Pair OK but models not downloaded | **Fallback to Supabase** on Rescue; offer download in Settings |
| `.unsupported` | Pair not available | Permanent Supabase fallback for that profile |

**Download UX (Apple-owned):**

- System sheet asks permission to download language assets.
- Downloads continue in background if user dismisses.
- Managed in **Settings → Apps → Translate → Translation Languages** (Translate app must exist on device; installed by default since iOS 14).

**TalkRescue policy:**

| Context | Download UI |
|---------|-------------|
| Rescue Mode / Action Button cold launch | **Never** — fallback to proxy |
| Main app idle / Settings / About | **Optional** — `prepareTranslation()` with user tap |
| Profile switch in chip sheet | **Optional** — background check only; no modal |

---

## 4. Fallback architecture

### Decision tree (in `RescueSession.translateRecognizedSpeech`)

```
trimmed text
  → RescuePhraseCache hit? → applyTranslationSuccess(instant: true)
  → iOS 18+ AND feature enabled?
      → AppleTranslationService.canTranslate(profile)?
          → status == .installed?
              → try translate
              → success → applyTranslationSuccess(instant: false, source: .apple)
              → error → log, fall through
  → TranslationService (Supabase proxy)
      → success → applyTranslationSuccess(instant: false, source: .proxy)
      → error → existing error UX
```

### When fallback to Supabase is mandatory

| Condition | Reason |
|-----------|--------|
| iOS 17.x | Translation framework unavailable |
| `status != .installed` | Avoid download UI on critical path |
| `TranslationSession` view host missing | Session lifecycle failure |
| Local `translate()` throws | Model error, timeout, empty response |
| Feature flag off | Safe rollout |
| User opted out of local translation | Future setting |
| Quality regression detected (future) | A/B or manual flag per profile |

### Fallback must be invisible to user

- Same Polish error strings from `L10n.Errors` on total failure.
- No "switching to cloud" message — user sees one translation flow.
- Retry button re-enters the same decision tree.

---

## 5. Cache interaction

| Layer | Order | Latency | Network | Changes in v1.3 |
|-------|-------|---------|---------|-----------------|
| `RescuePhraseCache` | 1st | ~0 ms | None | **None** |
| Apple Translation | 2nd | ~50–300 ms | None* | **New** |
| Supabase proxy | 3rd | ~800–2500 ms | Yes | **None** |

\*First model download requires network but happens outside Rescue path.

### `lastTranslationWasInstant` flag

| Path | `instant` value | Rationale |
|------|-----------------|-----------|
| Phrase cache hit | `true` | Unchanged |
| Apple Translation | `false` | Not synchronous; still fast |
| Supabase proxy | `false` | Unchanged |

Optional v1.3.1: add `lastTranslationSource` enum (`cache`, `apple`, `proxy`) for diagnostics only — not user-visible.

### Cache expansion (orthogonal)

Expanding `RescuePhraseCache` (more phrases) remains valuable and **reduces pressure on both** Apple and Supabase paths. Not a v1.3 blocker.

---

## 6. AirPods impact

Apple Translation is **text-in / text-out** — it does not open audio streams.

| Subsystem | AirPods interaction | v1.3 impact |
|-----------|---------------------|-------------|
| **Speech input** | `SpeechManager` uses `.playAndRecord` + `.allowBluetoothHFP` — AirPods mic works | **None** |
| **Translation** | String processing only | **None** |
| **TTS output** | `TTSService` uses `.playback` + `.spokenAudio` — routes to active output (AirPods, speaker, car) | **None** |
| **Auto Speak** | Speak after translation completes | **None** — may benefit from faster local translation (shorter gap before TTS) |

**Net effect with AirPods:** Users may notice **shorter speak delay** (translation completes sooner → TTS starts sooner). No new pairing, routing, or HFP/A2DP changes required.

---

## 7. Rescue Mode compatibility

Rescue Mode constraints from v1.2 remain hard requirements:

| Requirement | v1.3 approach |
|-------------|---------------|
| Action Button cold launch — no gates | Local path only if `.installed`; else proxy |
| No onboarding on Rescue | Unchanged |
| Silence auto-finish | Same translation pipeline |
| Manual finish / retry | Same pipeline |
| `translationGeneration` cancellation | Unchanged |
| Status labels / error cards | Unchanged |

### Rescue-unsafe operations (forbidden on critical path)

- `prepareTranslation()` when status is `.supported` (triggers download UI)
- `.translationTask` first-use download on a view shown only during Rescue
- Blocking `await` on model download

### Rescue-safe pattern

```swift
// Pseudocode — planning only
guard #available(iOS 18, *) else { return try await proxy.translate(...) }

let status = await availability.status(from: pl, to: target)
guard status == .installed else {
    return try await proxy.translate(...)  // silent fallback
}

let session = TranslationSession(installedSource: pl, target: target)
let response = try await session.translate(text)
return response.targetText
```

**SwiftUI host:** Attach a zero-size persistent `TranslationHostView` from `RootView` (not `RescueModeView`) so session lifecycle survives Rescue presentation. Use host only for `prepareTranslation()` in Settings, not for Rescue translates.

---

## 8. Proposed implementation shape

### New files (v1.3 implementation sprint)

| File | Role |
|------|------|
| `Services/AppleTranslationService.swift` | Availability checks + `translate(_:profile:)` |
| `Views/TranslationHostView.swift` | Hidden SwiftUI anchor for `translationTask` / `prepareTranslation()` |
| `Storage/TranslationPreferences.swift` | Feature flag, per-profile local preference (optional) |

### Modified files (minimal)

| File | Change |
|------|--------|
| `Managers/RescueSession.swift` | Insert Apple path between cache and proxy |
| `Views/RootView.swift` | Host `TranslationHostView` |
| `Views/AboutView.swift` or new Settings row | Optional "Pobierz języki offline" |
| `Models/LanguageProfile.swift` | Optional `appleSourceLanguage` / `appleTargetLanguage` helpers |

### Unchanged

- All visible UI layouts (Main, Rescue, chip, onboarding)
- `SpeechManager`, `TTSService`, `RescuePhraseCache`
- `TranslationService` (Supabase)
- App Store metadata (until v1.3 ship + privacy copy review)
- Language profile list

---

## 9. Unsupported devices and environments

| Environment | Apple Translation | Behavior |
|-------------|-------------------|----------|
| iOS 17.x | Not available | Supabase proxy only |
| iOS 18+ simulator | **Not supported** by Apple | Proxy only; dev must use device |
| iOS 18+ device, models not installed | `.supported` | Proxy on Rescue; optional download in Settings |
| iOS 18+ device, unsupported pair | `.unsupported` | Proxy permanently for that profile |
| iPadOS 18+ | API available | Same rules as iPhone |
| macOS / watchOS | N/A | TalkRescue iOS only |
| Offline after models installed | Works | **Key advantage** — translate without cellular/Wi‑Fi |
| Offline, models missing | Fails local | Proxy also fails → existing network error UX |

### Deployment target options

| Strategy | Pros | Cons |
|----------|------|------|
| **Keep iOS 17** (recommended v1.3) | Maximum device reach; gradual adoption | Two code paths to test |
| **Raise to iOS 18** (v1.4+ consideration) | Simpler codebase | Drops iOS 17 users |

Recommendation: **stay on iOS 17** for v1.3; gate with `@available(iOS 18, *)`.

---

## 10. Expected latency improvements

### Baseline measurements (v1.2, approximate)

| Path | Typical latency | Notes |
|------|-----------------|-------|
| Cache hit | **< 5 ms** | Synchronous dictionary |
| Supabase proxy | **800–2500 ms** | TLS + edge + OpenAI; varies by network |
| Prewarm | Saves ~100–200 ms | First request only |

### Projected v1.3 (Apple Translation, `.installed`)

| Path | Typical latency | vs proxy |
|------|-----------------|----------|
| Cache hit | **< 5 ms** | Unchanged |
| Apple Translation | **50–300 ms** | **~500–1500 ms faster** |
| Supabase fallback | **800–2500 ms** | Unchanged |

### User-perceived impact

- **Hold-to-speak:** Noticeably snappier on iOS 18 with installed models.
- **Rescue auto-finish → Auto Speak:** Shorter gap between silence detection and TTS — especially valuable with AirPods.
- **Retry:** Faster if local path succeeds on second attempt.

### When latency does **not** improve

- Cache hits (already instant)
- iOS 17 devices
- iOS 18 without downloaded models (proxy fallback)
- First `prepareTranslation()` download (one-time, user-initiated only)

---

## 11. Rollout plan

### Phase 0 — Research spike (2–3 days, device-only)

| Task | Output |
|------|--------|
| Prototype branch with `import Translation` | Throwaway target, iOS 18 |
| Test `pl → en/sv/es` on iPhone 15/16 | Availability matrix spreadsheet |
| Compare 50 spoken phrases: Apple vs Supabase | Quality notes |
| Measure latency (10 samples per path) | p50/p95 table |
| Confirm simulator failure mode | Document dev workflow |

**Gate:** All three profiles `.installed` on at least one test device, or document permanent proxy fallback per profile.

### Phase 1 — Infrastructure (3–4 days)

| Task | Detail |
|------|--------|
| Add `AppleTranslationService` | No user-visible change |
| Add `TranslationHostView` to `RootView` | Hidden anchor |
| Feature flag `useLocalTranslation` default **off** | `UserDefaults` |
| Wire into `RescueSession` behind flag | Cache → Apple → proxy |

### Phase 2 — Offline prep UX (1–2 days, optional)

| Task | Detail |
|------|--------|
| About / Settings: "Tłumaczenie offline" | Explains Apple download |
| Button triggers `prepareTranslation()` per selected profile | Only when user taps |
| Show status: gotowe / wymaga pobrania / niedostępne | Polish copy |

**Not on Rescue path.**

### Phase 3 — Beta (TestFlight, 1–2 weeks)

| Task | Detail |
|------|--------|
| Enable flag for TestFlight builds | xcconfig `USE_LOCAL_TRANSLATION=1` |
| Monitor Supabase usage drop | OpenAI dashboard |
| Collect quality feedback | PL→EN/SV/ES |
| Verify Rescue + Action Button on iOS 18 | No download interruptions |

### Phase 4 — Production (v1.3.0)

| Task | Detail |
|------|--------|
| Enable local-first by default on iOS 18+ | Flag on |
| Keep proxy fallback | Always |
| Update privacy copy (optional) | "May use on-device Apple translation" |
| App Store release notes | Offline speed benefit |

### Phase 5 — Follow-up (v1.3.1+)

- Expand `RescuePhraseCache`
- Per-profile `prefersLocalTranslation` tuning
- Consider iOS 18 minimum after adoption metrics
- Edge cache reduction if Apple path dominates

---

## 12. Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Download UI appears during Rescue | **High** | Only use local path when `status == .installed` |
| Conversational quality worse than OpenAI | **Medium** | Proxy fallback; A/B on TestFlight; keep cache |
| Polish spoken colloquialisms mistranslated | **Medium** | Proxy fallback flag per profile if needed |
| `TranslationSession` lifecycle bugs | **Medium** | Persistent host view; thorough Rescue testing |
| Simulator-only dev workflow | **Low** | Document device requirement; proxy tests in Simulator |
| Apple changes supported languages | **Low** | Runtime `LanguageAvailability` checks |
| Two-path test matrix explosion | **Medium** | Device matrix doc; automated smoke tests on device |
| False sense of offline-ready | **Medium** | Clear Settings status; proxy handles gaps |
| Privacy label updates needed | **Low** | Defer metadata until ship; on-device is improvement |
| Supabase costs don't drop if few iOS 18 users | **Low** | Expected; monitor dashboard |

---

## 13. Migration complexity

| Area | Complexity | Effort estimate |
|------|------------|-----------------|
| `AppleTranslationService` + host view | Medium | 1–2 days |
| `RescueSession` pipeline insert | Low | 0.5 day |
| Availability + fallback logic | Medium | 1 day |
| Settings offline prep (optional) | Low | 0.5–1 day |
| Device QA matrix | Medium | 2–3 days |
| Privacy / docs | Low | 0.5 day |
| **Total** | **Medium** | **~5–8 days** |

**Lower than v1.2 Supabase migration** (new infra + secrets + deploy).  
**Higher than cache-only expansion** (SwiftUI lifecycle + device testing).

### What makes it medium, not low

1. SwiftUI session anchoring from non-View orchestrator (`RescueSession`).
2. Strict Rescue path rules — no download UI regressions.
3. Physical-device-only Apple Translation testing.
4. Three language pairs × two OS versions × online/offline states.

---

## 14. Privacy and billing impact

| Metric | v1.2 (proxy) | v1.3 (local-first) |
|--------|--------------|-------------------|
| Polish text leaves device | Yes (on cache miss) | **Often no** (iOS 18 + installed) |
| OpenAI cost per translation | ~$0.00002 | **$0** on local path |
| Supabase proxy calls | Every cache miss | **Reduced** — fallback only |
| Apple telemetry | Speech on-device | + language-pair metrics (no content) |

---

## 15. Verification plan (pre-ship)

### Device test matrix

| Device | OS | Profile | Models | Path expected |
|--------|-----|---------|--------|---------------|
| iPhone 15 | 18.x | pl-en | installed | Apple |
| iPhone 15 | 18.x | pl-en | not installed | Proxy (no download UI in Rescue) |
| iPhone 14 | 17.x | pl-en | n/a | Proxy |
| Any | 18.x | pl-es | installed | Apple |
| AirPods connected | 18.x | pl-en | installed | Apple + TTS to AirPods |

### Rescue-specific checks

- [ ] Action Button → Rescue → speak → translate (no system download sheet)
- [ ] Silence auto-finish works with local path
- [ ] Retry after local failure hits proxy
- [ ] Airplane mode + installed models → local works
- [ ] Airplane mode + no models → friendly network error

### Regression checks

- [ ] Cache hit still instant
- [ ] Quick phrases still skip translation
- [ ] No `api.openai.com` from device (unchanged from v1.2)

---

## 16. Open questions (resolve in Phase 0 spike)

1. Are all three pairs `.installed` by default on a fresh iOS 18 Polish user's device?
2. Does `Locale.Language(identifier: "pl-PL")` vs `"pl"` affect availability?
3. Is conversational quality acceptable for stressed rescue scenarios without OpenAI prompt tuning?
4. Should `processingStatusLabel` change when local path is active (e.g. "Tłumaczę…" vs "Pobieram angielski…")? *Default: no UI change.*
5. When to bump deployment target to iOS 18?

---

## 17. References

- [Meet the Translation API — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10117/)
- [Translating text within your app](https://developer.apple.com/documentation/translation/translating-text-within-your-app)
- [TranslationSession](https://developer.apple.com/documentation/translation/translationsession)
- [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability)
- [prepareTranslation()](https://developer.apple.com/documentation/translation/translationsession/preparetranslation())
- [`docs/LOCAL_TRANSLATION_ROADMAP.md`](LOCAL_TRANSLATION_ROADMAP.md)
- [`docs/IOS_SUPABASE_TRANSLATION_V1_2.md`](IOS_SUPABASE_TRANSLATION_V1_2.md)
- [`docs/LANGUAGE_UX_V1_2.md`](LANGUAGE_UX_V1_2.md)

---

## 18. Decision summary

| Decision | Recommendation |
|----------|----------------|
| Adopt Apple Translation in v1.3? | **Yes** — local-first with proxy fallback |
| Raise deployment target? | **No** — keep iOS 17, gate iOS 18 |
| Replace Supabase proxy? | **No** — permanent fallback |
| Replace phrase cache? | **No** — always first |
| Download UI in Rescue? | **Never** |
| Implementation in this sprint? | **No** — planning only |

---

*TalkRescue 1.3 — planning document. No Swift changes.*
