# Local Translation Roadmap (Apple Translation Framework)

## Current state (v1.1)

| Layer | Implementation | Notes |
|-------|----------------|-------|
| Speech | `SFSpeechRecognizer` pl-PL | On-device |
| Translation | OpenAI `gpt-4o-mini` via `TranslationService` | Network, profile-aware prompts |
| TTS | `AVSpeechSynthesizer` | On-device, profile `ttsVoiceLanguage` |
| Deployment target | **iOS 17.0** | App Store minimum today |

## Apple Translation framework (iOS 18+)

Apple shipped the **Translation** framework at WWDC 2024 ([Meet the Translation API](https://developer.apple.com/videos/play/wwdc2024/10117/)).

### Capabilities

- **On-device** translation after language models are downloaded (user may be prompted once per language pair).
- **SwiftUI-first API:**
  - `translationPresentation` — system overlay (quick win, less control).
  - `translationTask(_:action:)` + `TranslationSession` — programmatic async `translate(_:)` inside a view lifecycle.
- `TranslationSession.Configuration(source:target:)` defines the pair; `prepareTranslation()` can prefetch models.
- `LanguageAvailability` can check whether a pair is supported before offering UI.

### Constraints relevant to TalkRescue

1. **Minimum OS:** Translation requires **iOS 18.0+** (iPadOS 18, macOS 15). TalkRescue currently targets **iOS 17** — adopting Translation implies either raising the deployment target or gating features with `@available(iOS 18, *)`.
2. **SwiftUI coupling:** Sessions are obtained through SwiftUI view modifiers (`translationTask`). UIKit-only paths need a small `UIViewControllerRepresentable` / hosting controller wrapper.
3. **Language pairs:** Not every combination is available; must handle unsupported pairs and model download failures gracefully.
4. **Polish → English / Swedish:** Verify availability on device via `LanguageAvailability` before enabling local-first for each profile.

### Recommended integration shape (future)

Do **not** replace OpenAI in v1.1. Later sprint:

```
RescueSession.translateRecognizedSpeech
    │
    ├─► RescuePhraseCache (instant, unchanged)
    │
    ├─► LocalTranslationService (iOS 18+, Translation framework)
    │       success → return
    │       unsupported / model missing / error → fall through
    │
    └─► TranslationService (OpenAI, current)
```

#### Proposed `LocalTranslationService` (sketch)

- Lives in `TalkRescue/Services/LocalTranslationService.swift`.
- Holds a `@MainActor` bridge that runs translation inside a hidden SwiftUI host view attached from `RootView` (or a dedicated `TranslationHostView` in the hierarchy).
- API: `func translate(_ text: String, profile: LanguageProfile) async throws -> String`
- Maps `profile.sourceLocaleIdentifier` / `profile.targetLocaleIdentifier` to `Locale.Language` components.
- Uses `TranslationSession.Configuration(source:target:)` matching `LanguageProfile`.
- Surfaces errors: model not downloaded, unsupported pair, `unableToIdentifyLanguage` (fallback: keep Polish source locale fixed).

#### UX for model download

- First use of PL→SV local path may show Apple’s download consent UI — acceptable in settings or a one-time “Pobierz języki do tłumaczenia offline” screen, **not** on the Action Button cold path.
- Pre-download in About / Settings when user selects a profile (call `prepareTranslation()` while idle).

#### Privacy and billing

- Local translation removes per-request OpenAI cost for supported pairs.
- Privacy story improves: recognized Polish text need not leave the device when local path succeeds.
- Keep OpenAI as fallback for iOS 17 devices, unsupported pairs, and quality edge cases until metrics prove local quality is sufficient.

## Migration phases

### Phase A — Research spike (1–2 days)

- Raise a **branch-only** deployment target to iOS 18 in a scratch target or `#if` prototype.
- Test `pl` → `en` and `pl` → `sv` with `LanguageAvailability` on physical devices.
- Compare latency and conversational quality vs OpenAI for short spoken lines.

### Phase B — Infrastructure (no user-visible change)

- Add `LocalTranslationService` + `TranslationHostView`.
- Feature flag: `UserDefaults` / xcconfig `USE_LOCAL_TRANSLATION=0`.
- Unit-free; manual test matrix on iOS 18+.

### Phase C — Profile flag

- Extend `LanguageProfile` with `prefersLocalTranslation: Bool`.
- Enable local-first only for pairs that pass availability checks.

### Phase D — Optional deployment bump

- If local translation is core to product positioning, consider **iOS 18** as minimum after adoption metrics.
- Maintain OpenAI fallback for failures regardless.

## What we are not doing in v1.1

- No `import Translation` in the shipping target (deployment 17).
- No change to App Store metadata or docs-site copy.
- No ML Kit or third-party on-device SDK (Apple path preferred for maintenance and privacy narrative).

## References

- [Translating text within your app](https://developer.apple.com/documentation/translation/translating-text-within-your-app)
- [translationTask(_:action:)](https://developer.apple.com/documentation/swiftui/view/translationtask(_:action:))
- [TranslationSession](https://developer.apple.com/documentation/translation/translationsession)
- WWDC24 Session 10117 — Meet the Translation API
