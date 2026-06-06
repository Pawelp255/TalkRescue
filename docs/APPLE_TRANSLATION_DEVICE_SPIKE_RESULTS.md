# TalkRescue 1.3 — Apple Translation Device Spike Results

**Status:** Planning spike — fill after on-device run  
**Date:** June 2026  
**Prerequisite:** Debug build, physical iPhone **iOS 18+** (Simulator unsupported)  
**Related:** `docs/APPLE_TRANSLATION_V1_3.md`

---

## How to run

1. Build **Debug** to a physical iPhone (iOS 18+).
2. Open **O aplikacji** → **Dev tools** → **Apple Translation Spike**.
3. Tap **Uruchom test**.
4. Copy results from the screen into the tables below.

**Guarantees (spike only):**

- Does **not** replace Supabase translation.
- Does **not** change Rescue Mode or main app flow.
- Does **not** call `prepareTranslation()` — no model-download UI during spike unless Apple triggers on first `translate()` for an installed pair (should not occur when `status == .installed`).
- Release builds omit the Dev tools entry (`#if DEBUG`).

---

## Test environment

| Field | Value |
|-------|-------|
| Device model | _e.g. iPhone 15 Pro_ |
| iOS version | _e.g. 18.2_ |
| TalkRescue build | _e.g. Debug 1.3-spike_ |
| Translate app installed | _Yes / No_ |
| Network during test | _Wi‑Fi / Cellular / Offline_ |
| Tester | _name_ |
| Test date | _YYYY-MM-DD_ |

---

## Language-pair availability

Checked via `LanguageAvailability().status(from:to:)` — no network translation.

| Pair | Profile | Status | Notes |
|------|---------|--------|-------|
| pl → en | `pl-en` | _installed / needs download / unsupported_ | |
| pl → de | `pl-de` | _installed / needs download / unsupported_ | |
| pl → sv | `pl-sv` | _installed / needs download / unsupported_ | |
| pl → es | `pl-es` | _installed / needs download / unsupported_ | |

**Status meanings:**

| Status | Meaning | v1.3 local path |
|--------|---------|-----------------|
| **installed** | On-device models ready | Eligible for local-first |
| **needs download** | Pair supported, models missing | Supabase fallback; optional Settings prep |
| **unsupported** | Pair not available | Permanent Supabase fallback |

---

## Sample phrase translations (installed pairs only)

Phrases tested:

1. `nie rozumiem`
2. `potrzebuję pomocy`
3. `gdzie jest dworzec?`
4. `czy możesz mówić wolniej?`

### pl → en

| Phrase | Apple output | Latency (ms) | Quality note |
|--------|--------------|--------------|--------------|
| nie rozumiem | | | |
| potrzebuję pomocy | | | |
| gdzie jest dworzec? | | | |
| czy możesz mówić wolniej? | | | |

**Average latency:** _ms_

### pl → de

| Phrase | Apple output | Latency (ms) | Quality note |
|--------|--------------|--------------|--------------|
| nie rozumiem | | | |
| potrzebuję pomocy | | | |
| gdzie jest dworzec? | | | |
| czy możesz mówić wolniej? | | | |

**Average latency:** _ms_

### pl → sv

| Phrase | Apple output | Latency (ms) | Quality note |
|--------|--------------|--------------|--------------|
| nie rozumiem | | | |
| potrzebuję pomocy | | | |
| gdzie jest dworzec? | | | |
| czy możesz mówić wolniej? | | | |

**Average latency:** _ms_

### pl → es

| Phrase | Apple output | Latency (ms) | Quality note |
|--------|--------------|--------------|--------------|
| nie rozumiem | | | |
| potrzebuję pomocy | | | |
| gdzie jest dworzec? | | | |
| czy możesz mówić wolniej? | | | |

**Average latency:** _ms_

---

## Latency comparison (reference)

| Path | Typical range | This device |
|------|---------------|-------------|
| RescuePhraseCache | ~0 ms | N/A (not spike) |
| Apple Translation (installed) | ~50–300 ms | _fill from spike_ |
| Supabase proxy (v1.2) | ~800–2500 ms | _optional manual curl_ |

---

## Quality notes

_Compare Apple output to OpenAI/Supabase conversational style. Note literal vs natural spoken phrasing, punctuation, travel-context suitability._

| Pair | Acceptable for Rescue? | Issues observed |
|------|------------------------|-----------------|
| pl-en | _Yes / Marginal / No_ | |
| pl-de | _Yes / Marginal / No_ | |
| pl-sv | _Yes / Marginal / No_ | |
| pl-es | _Yes / Marginal / No_ | |

---

## Spike observations

- Download UI appeared during test? _Yes / No_
- Errors or empty responses? _describe_
- Simulator run attempted? _expected: availability only, no translations_

---

## Recommendation: local-first in v1.3?

**Decision (fill after device test):** _Proceed / Proceed with caveats / Defer_

### Proceed if

- [ ] All four pairs at least **supported** (installed or downloadable)
- [ ] Primary pair (pl-en) **installed** on test device without Rescue-time download
- [ ] Average latency **< 400 ms** per phrase on installed models
- [ ] Output quality **acceptable** for spoken travel phrases (understandable, not misleading)

### Architecture if proceeding

```
RescuePhraseCache → Apple Translation (iOS 18+, status == .installed) → Supabase proxy
```

- **Keep Supabase fallback** for iOS 17, `.supported` (not installed), errors, quality escape hatch.
- **Never** show model download UI on Rescue / Action Button path.
- Optional Settings prewarm for `.supported` pairs only.

### Defer if

- Multiple pairs **unsupported**
- Latency consistently **> 500 ms** on modern hardware
- Quality regressions on critical phrases (help, don't understand, directions)

---

## Files (spike implementation)

| File | Role |
|------|------|
| `TalkRescue/Utilities/AppleTranslationSpike.swift` | Spike types, runner, debug view (`#if DEBUG`, `@available(iOS 18, *)`) |
| `TalkRescue/Views/AboutView.swift` | Debug-only navigation link |
| `docs/APPLE_TRANSLATION_DEVICE_SPIKE_RESULTS.md` | This results template |

**Unchanged:** `TranslationService.swift`, `RescueSession` production path, Supabase backend.

---

## Pre-device expectation (planning)

Based on Apple's published language list and `docs/APPLE_TRANSLATION_V1_3.md`:

| Pair | Expected availability | Confidence |
|------|---------------------|------------|
| pl → en | supported / likely installed | High |
| pl → de | supported | Medium — verify on device |
| pl → sv | supported | Medium |
| pl → es | supported | Medium |

**Preliminary recommendation (pending device data):** Implement **local-first with Supabase fallback** in v1.3 for iOS 18+ when `status == .installed`, subject to device spike confirming latency and quality. Do **not** remove proxy.

---

*Last updated: spike scaffold — device results pending.*
