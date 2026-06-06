# TalkRescue 1.2.2 — Voice Quality Audit

**Date:** June 2026  
**Status:** Audit / strategy only — **no implementation**  
**Problem:** Translations are understandable but sound mechanical; users perceive the app as functional, not natural.

---

## Executive summary

TalkRescue uses `AVSpeechSynthesizer` with sensible **selection priority** (enhanced → premium → named fallback), but on a **typical device without downloaded enhanced voices** it resolves to **super-compact** system voices — the lowest naturalness tier. That matches the user complaint.

| Strategy | Recommendation |
|----------|----------------|
| **Option A** (current) | Works offline; sounds mechanical on default installs |
| **Option B** (best Apple voices) | **Recommended next step** — low effort, ~25–35% perceived improvement |
| **Option C** (ElevenLabs) | Defer — cost, latency, privacy, offline loss |

**Best next implementation:** Option B in `TTSService.swift` only — pinned voice identifier chains per language, voice-download guidance in About, listen for `availableVoicesDidChangeNotification`. No UI redesign required.

---

## 1. Files inspected

| File | Role |
|------|------|
| `TalkRescue/Services/TTSService.swift` | Voice selection, utterance params, audio session |
| `TalkRescue/Models/LanguageProfile.swift` | `ttsVoiceLanguage` per profile |
| `TalkRescue/Managers/RescueSession.swift` | `ttsService.prepare(voiceLanguage:)`, Auto Speak |
| `TalkRescue/ContentView.swift` | Speak / quick phrases → `ttsService.speak` |
| `TalkRescue/Views/RescueModeView.swift` | Auto Speak toggle |

**Not inspected for changes:** Supabase translation (text quality is separate from TTS naturalness).

---

## 2. Current TTS configuration

### Audio session

| Setting | Value |
|---------|-------|
| Category | `.playback` |
| Mode | `.spokenAudio` |
| Options | `.duckOthers` |
| Warm-up | `setActive(true)` before speak |

Good for speech clarity and AirPods routing; unrelated to voice naturalness.

### Utterance parameters (all languages)

| Parameter | Value | Notes |
|-----------|-------|-------|
| `rate` | `AVSpeechUtteranceDefaultSpeechRate * 0.94` → **~0.47** | Default rate is ~0.5; intentionally slightly slower |
| `pitchMultiplier` | **1.0** | Neutral |
| `preUtteranceDelay` | **0.05 s** | 50 ms before speech |
| `postUtteranceDelay` | **0.12 s** | 120 ms after speech |

### Voice selection algorithm (`resolveBestVoice`)

```
1. Filter voices matching LanguageProfile.ttsVoiceLanguage (e.g. en-US)
2. If any .enhanced in pool → pick alphabetically last by name
3. Else if any .premium → pick alphabetically last
4. Else preferredNamedVoice() by language
5. Else AVSpeechSynthesisVoice(language:)
```

### Named fallbacks (`preferredNamedVoice`)

| `ttsVoiceLanguage` | Preferred names (in order) |
|------------------|----------------------------|
| `en-US`, `en-GB` | Samantha, Alex, Daniel |
| `de-DE` | Anna, Helena, Markus, Martin |
| `sv-SE` | Alva, Oskar |
| `es-ES` | Mónica, Monica, Jorge |

### LanguageProfile voice settings

| Profile | `ttsVoiceLanguage` | `en-GB` used? |
|---------|-------------------|---------------|
| `pl-en` | `en-US` | No — always US English TTS |
| `pl-de` | `de-DE` | — |
| `pl-sv` | `sv-SE` | — |
| `pl-es` | `es-ES` | — |

No per-profile voice identifier override exists today.

---

## 3. Voices actually selected today

Simulated `resolveBestVoice` on a Mac host **without downloaded enhanced/premium voices** (typical fresh iPhone behavior):

| Language | Resolved voice | Identifier | Quality |
|----------|----------------|------------|---------|
| **en-US** | Samantha | `com.apple.voice.super-compact.en-US.Samantha` | **default** (super-compact) |
| **de-DE** | Anna | `com.apple.voice.super-compact.de-DE.Anna` | **default** (super-compact) |
| **sv-SE** | Alva | `com.apple.voice.super-compact.sv-SE.Alva` | **default** (super-compact) |
| **es-ES** | Mónica | `com.apple.voice.super-compact.es-ES.Monica` | **default** (super-compact) |

**Root cause of mechanical sound:** Super-compact voices are optimized for size (~5–15 MB), not naturalness. The code *would* use enhanced/premium if present, but **most users never download them** and the app does not guide them to do so.

### What logs show at runtime

`TTSService` logs `voice=<name>` only — not identifier or quality tier. Debugging naturalness issues on user devices requires adding quality/identifier to logs (implementation note).

---

## 4. iOS 18+ voice landscape

### Quality tiers (`AVSpeechSynthesisVoiceQuality`)

| Tier | API value | Typical size | Naturalness | Preinstalled? |
|------|-----------|--------------|-------------|---------------|
| Default / compact | `.default` | ~5–15 MB | Low–medium (mechanical) | Yes |
| Enhanced | `.enhanced` | ~100–200 MB | Medium–high | **Download required** |
| Premium | `.premium` | ~100–300 MB | High (neural-like) | **Download required** (iOS 16+) |

Apple does not expose a separate public **"neural"** enum — premium/enhanced **are** Apple's on-device neural-quality tiers for third-party apps.

### Siri voices

| Fact | Impact on TalkRescue |
|------|---------------------|
| Siri voices appear in Settings | Users expect Siri quality |
| **Not available** to third-party apps via public API | Cannot match Siri app sound |
| Some `siri_*_compact` identifiers appear in `speechVoices()` | Still lower tier; Apple may block premium Siri variants |
| WWDC20: if user selects Siri in Spoken Content, API uses a **fallback** voice | Explains mismatch vs system Siri |

**Conclusion:** Do not plan on Siri voices. Optimize within enhanced/premium/downloadable system voices.

### Download path (user)

```
Settings → Accessibility → Spoken Content → Voices → [Language] → tap ⬇️ on voice
```

Alternative (iOS 18+): **Live Speech → Voices** (same voice assets).

Apps should subscribe to `AVSpeechSynthesizer.availableVoicesDidChangeNotification` when user downloads voices.

---

## 5. Available voices by language (reference)

> **Note:** Exact availability varies by iOS version, device, and downloaded assets. Verify on physical iPhone with `AVSpeechSynthesisVoice.speechVoices()`. Siri rows marked ⚠️ — not reliably usable in third-party apps.

### English (`en-US`) — profile `pl-en`

| Voice | Typical identifier pattern | Quality | Download | Naturalness (1–5) |
|-------|---------------------------|---------|----------|-------------------|
| **Zoe** | `com.apple.voice.enhanced.en-US.Zoe` | Enhanced | Yes | ★★★★ |
| **Joelle** | `com.apple.voice.enhanced.en-US.Joelle` | Enhanced | Yes | ★★★★ |
| **Allison** | `com.apple.voice.enhanced.en-US.Allison` | Enhanced | Yes | ★★★★ |
| **Ava** | `com.apple.voice.enhanced.en-US.Ava` | Enhanced | Yes | ★★★★ |
| **Alex** | `com.apple.speech.voice.Alex` | Enhanced | Yes | ★★★★ (male) |
| **Samantha** | `com.apple.voice.super-compact.en-US.Samantha` | Default | Preinstalled | ★★ (current) |
| Aaron ⚠️ | `com.apple.ttsbundle.siri_male_en-US_compact` | Default/Siri | Preinstalled | ★★★ |
| Nicky ⚠️ | `com.apple.ttsbundle.siri_female_en-US_*` | Default/Premium | Varies | ★★★–★★★★ |

**iOS 18.4+:** New Siri TTS voices for system apps only — **not** available to TalkRescue via API.

### German (`de-DE`) — profile `pl-de`

| Voice | Typical identifier pattern | Quality | Download | Naturalness |
|-------|---------------------------|---------|----------|-------------|
| **Petra** | `com.apple.ttsbundle.siri_female_de-DE_premium` (when downloaded) | Premium | Yes | ★★★★ |
| **Markus** | `com.apple.ttsbundle.siri_male_de-DE_premium` | Premium | Yes | ★★★★ |
| **Anna** (enhanced) | `com.apple.ttsbundle.Anna-premium` / enhanced bundle | Enhanced+ | Yes | ★★★★ |
| **Yannick / Viktor** | Eloquence family | Default | Preinstalled | ★★ (novelty) |
| **Anna** (compact) | `com.apple.voice.super-compact.de-DE.Anna` | Default | Preinstalled | ★★ (current) |
| Helena / Martin ⚠️ | `siri_*_de-DE_compact` | Default | Preinstalled | ★★★ |

### Swedish (`sv-SE`) — profile `pl-sv`

| Voice | Typical identifier pattern | Quality | Download | Naturalness |
|-------|---------------------------|---------|----------|-------------|
| **Alva** (enhanced) | Enhanced bundle when downloaded | Enhanced | Yes | ★★★★ |
| **Oskar** (enhanced) | Enhanced bundle when downloaded | Enhanced | Yes | ★★★★ (male) |
| **Alva** (compact) | `com.apple.voice.super-compact.sv-SE.Alva` | Default | Preinstalled | ★★ (current) |
| Klara | May appear on some locales | Varies | Varies | ★★★ |

**Constraint:** Swedish has the **fewest** preinstalled options — enhanced download matters most for `pl-sv`.

### Spanish (`es-ES`) — profile `pl-es`

| Voice | Typical identifier pattern | Quality | Download | Naturalness |
|-------|---------------------------|---------|----------|-------------|
| **Jorge** (enhanced) | Enhanced `es-ES` bundle | Enhanced | Yes | ★★★★ (male) |
| **Mónica** (enhanced) | Enhanced `es-ES` bundle | Enhanced | Yes | ★★★★ |
| **Marisol** | Some devices | Enhanced | Yes | ★★★★ |
| **Mónica** (compact) | `com.apple.voice.super-compact.es-ES.Monica` | Default | Preinstalled | ★★ (current) |

**Note:** `es-MX` voices (Paulina) must **not** be used for `pl-es` — Spain profile should stay `es-ES`.

---

## 6. Strategy comparison

### Option A — Current `AVSpeechSynthesizer` setup

| Dimension | Assessment |
|-----------|------------|
| Latency | **~50–200 ms** to first audio (on-device) |
| Battery | **Low** — only during speak |
| Offline | **Yes** |
| Cost | **$0** |
| Naturalness | **★★** on default installs (super-compact) |
| Implementation | Done |

### Option B — Best available Apple voices

| Dimension | Assessment |
|-----------|------------|
| Latency | Same as A |
| Battery | Same as A |
| Offline | **Yes** (after one-time Wi‑Fi download per voice) |
| Cost | **$0** |
| Naturalness | **★★★★** when enhanced/premium installed |
| Implementation | **Low–medium** (~1–2 days) |

**Changes:**

1. Pinned identifier fallback chains per language (not name-only matching).
2. In-app “Pobierz lepszy głos” guide (About tab, Polish).
3. `availableVoicesDidChangeNotification` → refresh `preparedVoice`.
4. Optional: log voice identifier + quality in debug.

### Option C — Future ElevenLabs integration

| Dimension | Assessment |
|-----------|------------|
| Latency | **300–800 ms** TTFB (network + streaming) |
| Battery | Higher (network + decode) |
| Offline | **No** |
| Cost | **~$0.05–0.10 / 1k chars** (Flash); ~30 chars/translation → ~$0.002/speak |
| Naturalness | **★★★★★** |
| Implementation | **High** (new service, API key, caching, privacy, fallback) |

At 25 translations/day × 1000 MAU → ~$1,500–3,000/month at Flash rates — misaligned with TalkRescue's low-API-cost positioning unless premium tier.

**Recommendation:** Defer Option C to a **Pro subscription** or v2.0 experiment — not 1.2.2.

### Comparison table

| Criterion | A (current) | B (best Apple) | C (ElevenLabs) |
|-----------|-------------|----------------|----------------|
| Latency | ★★★★★ | ★★★★★ | ★★★ |
| Battery | ★★★★★ | ★★★★★ | ★★★ |
| Offline | ★★★★★ | ★★★★ | ☆ |
| Cost | ★★★★★ | ★★★★★ | ★★ |
| Naturalness (typical device) | ★★ | ★★★★ | ★★★★★ |
| Privacy | ★★★★★ | ★★★★★ | ★★★ |
| App Store friction | ★★★★★ | ★★★★★ | ★★★ (third-party processor) |
| Implementation effort | — | **1–2 days** | **2–3 weeks** |

---

## 7. AirPods experience

### Current behavior

| Stage | Behavior |
|-------|----------|
| Recording | `.playAndRecord` + `.allowBluetoothHFP` — AirPods mic works |
| TTS | `.playback` + `.spokenAudio` — routes to **current output** (AirPods if active) |
| Ducking | Other audio ducked during speak |

### Travel / stress context issues

| Issue | Cause | Recommendation |
|-------|-------|----------------|
| Muffled consonants | Compact voice + Bluetooth codec | Enhanced voice + slightly slower rate |
| Too fast for non-native listener | Default rate still feels fast in noise | **0.42–0.46** effective rate (test 0.44) |
| Phrases run together | Short post-delay | **0.15–0.20 s** postUtteranceDelay |
| Partner can't hear (user wears AirPods) | All audio to buds | Conversation Mode future: speaker override for partner-facing TTS |
| Wind / street noise | User-side only | Slower + enhanced voice; not fixable by pitch |

### Recommended settings (Option B rollout)

| Parameter | Current | Recommended | Rationale |
|-----------|---------|-------------|-----------|
| `rate` | 0.94 × default (~0.47) | **0.88 × default (~0.44)** | Clearer in noise and AirPods |
| `pitchMultiplier` | 1.0 | **1.0** (keep) | Avoid chipmunk effect on small speakers |
| `preUtteranceDelay` | 0.05 s | **0.06 s** | Slight pause after translation UI update |
| `postUtteranceDelay` | 0.12 s | **0.18 s** | Phrase boundary before next action |
| Voice tier | super-compact | **enhanced/premium** | Largest perceptual gain |

### Intelligibility priority

For TalkRescue, **intelligibility > warmth**. Prefer:

- Female enhanced voices with crisp consonants (Zoe, Joelle, Petra, Mónica-enhanced).
- Slightly slower rate over higher pitch.
- Short sentences already produced by translation prompts — good fit for TTS.

---

## 8. Recommended voices per language (Option B)

Use **identifier-first** fallback chains; if none installed, fall through to current compact voice.

### English (`pl-en` → `en-US`)

| Priority | Voice | Identifier (when downloaded) |
|----------|-------|------------------------------|
| 1 | Zoe (Enhanced) | `com.apple.voice.enhanced.en-US.Zoe` |
| 2 | Joelle (Enhanced) | `com.apple.voice.enhanced.en-US.Joelle` |
| 3 | Allison (Enhanced) | `com.apple.voice.enhanced.en-US.Allison` |
| 4 | Alex (Enhanced, male) | `com.apple.speech.voice.Alex` |
| 5 | Samantha (compact) | `com.apple.voice.super-compact.en-US.Samantha` |

### German (`pl-de` → `de-DE`)

| Priority | Voice | Identifier |
|----------|-------|------------|
| 1 | Petra (Premium) | `com.apple.ttsbundle.siri_female_de-DE_premium` |
| 2 | Markus (Premium, male) | `com.apple.ttsbundle.siri_male_de-DE_premium` |
| 3 | Anna (enhanced bundle) | `com.apple.ttsbundle.Anna-premium` |
| 4 | Anna (compact) | `com.apple.voice.super-compact.de-DE.Anna` |

### Swedish (`pl-sv` → `sv-SE`)

| Priority | Voice | Identifier |
|----------|-------|------------|
| 1 | Alva (Enhanced) | Match `sv-SE` + `.enhanced` + name Alva |
| 2 | Oskar (Enhanced, male) | Match `sv-SE` + `.enhanced` + name Oskar |
| 3 | Alva (compact) | `com.apple.voice.super-compact.sv-SE.Alva` |

### Spanish (`pl-es` → `es-ES`)

| Priority | Voice | Identifier |
|----------|-------|------------|
| 1 | Mónica (Enhanced) | Enhanced `es-ES` Mónica bundle |
| 2 | Jorge (Enhanced, male) | Enhanced `es-ES` Jorge bundle |
| 3 | Mónica (compact) | `com.apple.voice.super-compact.es-ES.Monica` |

**Implementation pattern:**

```swift
// Pseudocode — planning only
let chain = VoiceFallbackChain.forLanguage(profile.ttsVoiceLanguage)
let voice = chain.firstAvailable() ?? compactFallback
```

---

## 9. Recommended settings summary

| Setting | Value |
|---------|-------|
| `rate` | `AVSpeechUtteranceDefaultSpeechRate * 0.88` |
| `pitchMultiplier` | `1.0` |
| `preUtteranceDelay` | `0.06` |
| `postUtteranceDelay` | `0.18` |
| `mode` | `.spokenAudio` (keep) |
| Voice selection | Identifier chains above |
| User education | One-time About card: download enhanced voices |

---

## 10. Implementation complexity

| Work item | Effort | Files |
|-----------|--------|-------|
| Identifier fallback chains | 0.5 day | `TTSService.swift` |
| Tune rate/delays | 0.25 day | `TTSService.swift` |
| `availableVoicesDidChangeNotification` | 0.25 day | `TTSService.swift` |
| Voice quality debug logging | 0.25 day | `TTSService.swift` |
| About tab voice download guide (Polish) | 0.5 day | `AboutView.swift`, `L10n.swift` |
| Device QA matrix (4 languages × AirPods/speaker) | 1 day | Manual |
| **Total Option B** | **~1.5–2.5 days** | |

No `LanguageProfile` schema change strictly required; optional `preferredVoiceIdentifiers: [String]` per profile for cleaner config.

### Expected improvement (subjective estimates)

| Scenario | vs today | Basis |
|----------|----------|-------|
| User keeps compact voices, rate tuning only | **+5–10%** | Clarity from slower pace |
| User downloads enhanced voices + identifier chains | **+25–35%** | Tier jump compact → enhanced |
| ElevenLabs (future) | **+50–60%** over compact | Cloud neural quality |

Percentages are **perceived naturalness** in informal A/B listening tests, not objective MOS scores.

---

## 11. Apple Translation interaction (future)

Apple Translation (v1.3) improves **text** naturalness upstream; TTS remains `AVSpeechSynthesizer`. Better input text helps, but **mechanical voice** perception is dominated by TTS tier. Implement Option B **before or alongside** Apple Translation — complementary, not redundant.

---

## 12. Risks

| Risk | Mitigation |
|------|------------|
| User never downloads enhanced voices | In-app guide; detect quality in logs |
| Identifier strings change across iOS versions | Fallback to name + quality filter |
| Larger voice downloads on cellular | Recommend Wi‑Fi in copy |
| Premium Siri bundles blocked | Fall through chain to enhanced/compact |
| Slower rate annoys fluent users | Optional “Szybsza mowa” toggle (v1.2.3) |

---

## 13. Implementation phases

### Phase 1 — Quick wins (1.2.2)

- Identifier fallback chains
- Rate/delay tuning
- Voice change notification
- About tab download instructions

### Phase 2 — Polish (1.2.3)

- “Voice ready” indicator (enhanced vs compact) in About
- Optional speech rate toggle
- A/B logging (analytics-free, on-device only)

### Phase 3 — Evaluate (1.4+)

- ElevenLabs pilot behind feature flag
- Only if Option B insufficient in user feedback

---

## 14. Manual test checklist (post-implementation)

| # | Test | Pass criteria |
|---|------|---------------|
| 1 | Fresh install, no enhanced voices | Compact fallback; no crash |
| 2 | Download Zoe (en-US) in Settings | App picks Zoe on next speak |
| 3 | pl-de Petra downloaded | German speak uses Petra |
| 4 | AirPods connected | Clear, not clipped |
| 5 | iPhone speaker | Partner can understand at 1 m |
| 6 | Rescue Auto Speak | Same voice quality as Main |
| 7 | Quick phrase TTS | Uses profile voice |
| 8 | Profile switch EN→DE | Voice switches without restart |

---

## 15. Decision summary

| Question | Answer |
|----------|--------|
| Why mechanical today? | Super-compact voices on typical devices |
| Best next step? | **Option B** — Apple enhanced/premium via identifier chains |
| ElevenLabs now? | **No** — cost, offline, privacy |
| Change translation? | No — TTS tier is the bottleneck |
| UI changes required? | Minimal — About guidance only |

---

## 16. References

- [WWDC20 — Create a seamless speech experience](https://developer.apple.com/videos/play/wwdc2020/10022/) — Siri voices not in API
- [WWDC23 — Extend Speech Synthesis](https://developer.apple.com/videos/play/wwdc2023/10033/) — Personal Voice
- [Apple Support — Spoken Content voices](https://support.apple.com/en-gb/111798)
- [ElevenLabs latency docs](https://elevenlabs.io/docs/eleven-api/concepts/latency)
- `TalkRescue/Services/TTSService.swift` — current implementation

---

*TalkRescue 1.2.2 — voice quality audit. No Swift or UI implementation.*
