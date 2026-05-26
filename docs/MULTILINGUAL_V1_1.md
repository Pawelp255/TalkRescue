# TalkRescue v1.1 — Multilingual Foundation

## Overview

v1.1 adds a **language profile** layer so TalkRescue can translate Polish speech into more than one target language without duplicating rescue workflow code. Polish → English remains the default; Polish → Swedish is the second profile.

Speech recognition stays **pl-PL** for all profiles. Translation, TTS, quick phrases, and on-device phrase cache are profile-driven.

## Language profiles

| Profile ID | Source | Target | UI label | TTS |
|------------|--------|--------|----------|-----|
| `pl-en` | pl-PL | en-US | Angielski | en-US |
| `pl-sv` | pl-PL | sv-SE | Szwedzki | sv-SE |

Defined in `TalkRescue/Models/LanguageProfile.swift`.

Each profile carries:

- Locale identifiers (speech source fixed to Polish today)
- `openAISystemPrompt` — short, one-line spoken output instruction
- `cacheNamespace` — key for `RescuePhraseCache`
- `quickPhrases` — tap-to-speak shortcuts on the main screen
- Polish UI strings (`shortLabel`, `autoSpeakToggleLabel`, `processingStatusLabel`)

## Persistence

`LanguageProfileStore` (`TalkRescue/Storage/LanguageProfileStore.swift`) saves `selectedLanguageProfileID` in **UserDefaults**. Default: `pl-en`. The same store instance is injected at app launch and shared by Main mode and Rescue Mode via `RescueSession.profileStore`.

## Services

### TranslationService

- `translate(_:profile:)` uses `profile.openAISystemPrompt`.
- `translatePolishToEnglish(_:)` kept for compatibility; delegates to PL→EN profile.
- Timeout, retry path, logging (no private text), and OpenAI warmup unchanged.

### TTSService

- `prepare(voiceLanguage:)` selects `AVSpeechSynthesisVoice` for the profile.
- Falls back to base language code (e.g. `sv` if `sv-SE` unavailable).

### RescuePhraseCache

- Lookups namespaced by `profile.cacheNamespace`.
- PL→EN entries preserved; basic PL→SV entries added for common phrases.

## UI

- **Main:** segmented picker (`LanguageProfilePicker`) above the result card; result header uses `profile.shortLabel`.
- **Rescue Mode:** compact segmented picker under the status banner; target label on the result card.
- Auto Speak toggle label follows profile (`Mów po angielsku` / `Mów po szwedzku`).

Action Button / shortcut flow is unchanged: coordinator opens Rescue Mode → auto-listen → translate with **currently selected profile**.

## History and favorites

`Phrase` still stores `polishText` + `englishText` (target output). No schema migration in v1.1; mixed-language history is acceptable for this release.

## Testing checklist

- [ ] Main: PL→EN hold-to-speak, OpenAI + cache
- [ ] Main: PL→SV hold-to-speak
- [ ] Main: quick phrases per profile
- [ ] Rescue Mode: PL→EN and PL→SV with auto-listen
- [ ] Action Button → Rescue Mode auto-listens
- [ ] TTS speaks English / Swedish per profile
- [ ] Kill app, relaunch — profile selection persists
- [ ] Switch profile mid-session — next translation uses new target

## Files touched (v1.1)

| Area | Files |
|------|--------|
| Model | `Models/LanguageProfile.swift` |
| Storage | `Storage/LanguageProfileStore.swift` |
| Services | `TranslationService.swift`, `TTSService.swift`, `RescuePhraseCache.swift` |
| Session | `Managers/RescueSession.swift` |
| UI | `ContentView.swift`, `Views/RescueModeView.swift`, `Views/LanguageProfilePicker.swift` |
| App shell | `TalkRescueApp.swift`, `Views/RootView.swift` |
| Copy | `Utilities/L10n.swift` (picker accessibility string) |

See `LOCAL_TRANSLATION_ROADMAP.md` for Apple on-device Translation integration plans.
