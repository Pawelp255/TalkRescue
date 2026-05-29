# TalkRescue v1.1 — Quality Pass

Small post–TestFlight pass focused on **speech recognition**, **translation tone**, and **TTS** without UI or architecture changes.

## Speech recognition (`SpeechManager`)

| Change | Rationale |
|--------|-----------|
| `AVAudioSession` mode `.measurement` (was `.voiceChat`) | Less aggressive voice processing; often better STT in real environments |
| IO buffer duration `0.005` s (was `0.01`) | Slightly lower capture latency for first partials |
| `setPrefersNoInterruptionsFromSystemAlerts` (iOS 16+) | Fewer system alert interruptions during capture |
| **27 Polish contextual strings** (was 5) | Aligns with rescue phrase cache and common travel/social Polish |
| Tap buffer size **4096** (was 2048) | Slightly fuller buffers without noticeable startup delay |
| Relaxed `isLikelyGarbagePartial` | Allows short valid first words; only drops obvious noise collapse |
| Finalize wait **0.35 s** (was 0.25) | More time for last word after release |

Readiness timeout remains **1.0 s** (unchanged from mic regression fix).

## Rescue silence (`RescueSilenceMonitor`)

| Setting | Before | After |
|---------|--------|-------|
| Silence after speech | 1.35 s | 1.5 s |
| Short transcript silence | 1.8 s | 2.0 s |
| Minimum time after speech start | 0.8 s | 1.0 s |

Reduces premature auto-finish when background noise causes transcript flicker.

## Translation prompts (`LanguageProfile`)

Per-language system prompts now ask for:

- One **short spoken sentence**
- **Natural / conversational** tone (not formal)
- **Meaning preserved**
- No quotes or labels

Profiles: `pl-en`, `pl-sv`, `pl-es` (OpenAI path unchanged; cache still applies first).

## TTS (`TTSService`)

| Change | Rationale |
|--------|-----------|
| Rate **0.94× default** (was 1.12×) | Slightly slower, clearer Auto Speak |
| **Enhanced / premium** voice when available | Better quality per locale |
| Named fallbacks: Samantha/Alex (EN), Alva (SV), Mónica/Jorge (ES) | When enhanced tier missing on device |
| `preUtteranceDelay` / `postUtteranceDelay` | Small pauses for natural phrasing |
| `releasePlaybackForRecording()` | Stops TTS and deactivates playback session before mic capture |

`RescueSession.stopSpeaking()` uses release path so recording does not fight TTS audio session.

## Files changed

- `TalkRescue/Managers/SpeechManager.swift`
- `TalkRescue/Managers/RescueSilenceMonitor.swift`
- `TalkRescue/Managers/RescueSession.swift`
- `TalkRescue/Models/LanguageProfile.swift`
- `TalkRescue/Services/TTSService.swift`
- `docs/QUALITY_PASS_V1_1.md`

## Risks

- **`.measurement` mode** may behave differently on some Bluetooth headsets; monitor field feedback.
- **Slower TTS** adds ~5–10% duration per phrase; still faster than pre–quality-pass 1.12× boost.
- **Longer silence auto-finish** in Rescue Mode may require an extra ~0.2 s pause after speaking — acceptable tradeoff for fewer cut-offs.
- **Richer OpenAI prompts** may very slightly increase token use (negligible vs audio).

## Test checklist

### Speech (Main)

- [ ] Hold-to-speak in quiet room — full Polish sentence recognized
- [ ] First word not dropped (“Chcę…”, “Gdzie…”, “Nie rozumiem”)
- [ ] Short tap still cancels cleanly (no hang)
- [ ] Noisy café: hold longer; transcript stabilizes before release

### Speech (Rescue / Action Button)

- [ ] Auto-listen starts; silence auto-finish after natural pause (not mid-sentence)
- [ ] Background chatter does not instantly end session
- [ ] Manual Done still works

### Translation (EN / SV / ES)

- [ ] Output sounds conversational, one sentence, not stiff
- [ ] Meaning matches Polish intent
- [ ] Cache hits still instant

### TTS

- [ ] Auto Speak EN/SV/ES — clear, not rushed
- [ ] After Auto Speak, immediate new recording works (no stuck session)
- [ ] Manual “Odtwórz” after translation sounds natural

### Regression

- [ ] PL→EN, PL→SV, PL→ES profiles and chip unchanged
- [ ] Onboarding / Action Button / language persistence unchanged
