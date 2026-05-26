# TalkRescue — Language UX (Pass B, v1.2)

## Summary

Pass B replaces the segmented language control with a **compact chip + sheet**, adds **first-launch language onboarding**, and introduces **Polish → Spanish** alongside existing English and Swedish profiles. Rescue / Action Button stay fast and do not gate on onboarding.

## Supported profiles

| ID | Target | Chip / header label | TTS voice | Cache namespace |
|----|--------|---------------------|-----------|----------------|
| `pl-en` | English (US) | Angielski | en-US | pl-en |
| `pl-sv` | Swedish | Szwedzki | sv-SE | pl-sv |
| `pl-es` | Spanish (Spain) | Hiszpański | es-ES | pl-es |

Speech input remains Polish (`pl-PL`) for every profile.

## Language chip & sheet

- **Main**: Next to the “Tłumaczenie” section header; chip shows `{shortLabel} ▾`.
- **Rescue Mode**: Top row next to close; same interaction, dark-themed styling.

Tapping the chip opens a **sheet** with:

- Polish explanatory copy (see `L10n.LanguageUX.sheetExplainer`)
- Large rows per language (tap to select **and dismiss** immediately)
- **Gotowe** in the navbar to dismiss without changing selection

Goals: fewer accidental switches, scalable list for more languages later.

## First-launch onboarding

- Shown **only** when `UserDefaults` key `languageOnboarding.completed` is false **and** Main UI is visible (not Rescue).
- Polish copy: title, subtitle, options **Angielski / Szwedzki / Hiszpański**, CTA **Zacznij**.
- **Zacznij** persists the chosen profile (`selectedLanguageProfileID`) and sets onboarding completed permanently.

### Upgrade installs (migration)

First run of Pass B runs a **one-time** migration marker `languageOnboarding.passB_migration_v1`. Users who already have:

- Saved phrase history bucket (`talkRescue.history`),
- Saved favorites bucket (`talkRescue.favorites`), **or**
- An explicit saved profile id (`selectedLanguageProfileID`),

receive `languageOnboarding.completed = true` so they are not blocked by onboarding.

### Action Button / cold Launch to Rescue

- Onboarding **never** covers Rescue Mode.
- If onboarding is not completed yet, the session still runs with the **in-memory default** profile (Polish → English until the user persists another choice via the chip sheet or onboarding).
- Using the Rescue **chip** (any explicit `select(profile)`) marks onboarding complete, so returning to Main is not blocked by the full-screen language screen afterward.
- If the user exits Rescue never having opened that sheet, opening Main afterward shows onboarding until **Zacznij** confirms a profile.

Keeps rescue instant—no picker gate on launch—while still letting stressed users optionally switch language from the compact chip mid-rescue.

## Auto Speak labels

Per profile (`LanguageProfile.autoSpeakToggleLabel`):

- `Czytaj po angielsku`
- `Czytaj po szwedzku`
- `Czytaj po hiszpańsku`

## History & favorites

Schema unchanged (`polishText` + output text). Cards do not add per-row language metadata in v1.2.

## Future: local translation (Apple Translation framework)

- Profiles already carry `sourceLocaleIdentifier`, `targetLocaleIdentifier`, and `cacheNamespace`.
- A future `LocalTranslationService` can map these to `TranslationSession.Configuration` (iOS 18+) as outlined in `LOCAL_TRANSLATION_ROADMAP.md`.
- Onboarding and chip UX stay the same; only the translation backend would gain a local-first path.

## Files of interest

| Area | Files |
|------|--------|
| Profiles | `Models/LanguageProfile.swift` |
| Persistence & onboarding | `Storage/LanguageProfileStore.swift` |
| Chip + sheet | `Views/LanguageProfilePicker.swift` (`LanguageChipControl`, `LanguageSelectionSheet`) |
| Onboarding UI | `Views/LanguageOnboardingView.swift` |
| Shell | `Views/RootView.swift` |
| Main / Rescue | `ContentView.swift`, `Views/RescueModeView.swift` |
| Copy | `Utilities/L10n.swift` (`LanguageUX`) |
| Phrase cache | `Services/RescuePhraseCache.swift` |
