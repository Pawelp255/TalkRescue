# TalkRescue 1.2.3 — Local Analytics, Feedback, Rating Prompt

Privacy-friendly usage counters, in-app feedback, and App Store rating prompt. **No external analytics SDK. No server upload.**

---

## Design principles

| Rule | Implementation |
|------|----------------|
| No tracking users | No IDs, no fingerprinting, no network analytics |
| Local-only | All counters in `UserDefaults` on device |
| No backend changes | Counters never sent to Supabase or OpenAI |
| No translation changes | Translation service and prompts unchanged |
| No UI redesign | Two new sections in existing About tab |

---

## Counters (`LocalUsageAnalytics`)

| Counter | UserDefaults key | When incremented |
|---------|------------------|------------------|
| App launch count | `analytics.appLaunchCount` | App becomes active (foreground) |
| First launch date | `analytics.firstLaunchDate` | First foreground session |
| Translation total | `analytics.translationCountTotal` | Each successful translation |
| Translation by profile | `analytics.translationCountByProfile` (JSON) | Each successful translation |
| Rescue Mode uses | `analytics.rescueModeUsageCount` | `RescueLaunchCoordinator.requestRescueMode` |
| Shortcut/Action Button launches | `analytics.shortcutRescueLaunchCount` | Rescue request with `source == .shortcut` |
| Cache hits | `analytics.cacheHitCount` | `RescuePhraseCache` hit |
| Proxy translations | `analytics.proxyTranslationCount` | Supabase proxy success |
| Proxy duration total/samples | `analytics.proxyDurationTotalMs`, `analytics.proxyDurationSampleCount` | Proxy success (for average ms) |
| Successful translations (rating) | `analytics.successfulTranslationCount` | Same as translation success |
| Rating prompt requested | `analytics.ratingPromptRequested` | After `SKStoreReviewController.requestReview` |

### About screen (`Statystyki użycia`)

Shows subset:

- Tłumaczenia łącznie
- Najczęściej używany język (from profile counts)
- Użycia trybu ratunkowego
- Trafienia pamięci podręcznej

Footer: *Licznik lokalny na tym urządzeniu. Dane nie są wysyłane na serwer.*

Internal snapshot also exposes proxy count, shortcut launches, app launches, and average proxy duration (not shown in UI v1).

---

## Instrumentation hooks

```
RootView (scenePhase → .active)
  └─ LocalUsageAnalytics.recordAppLaunch()

RescueLaunchCoordinator.requestRescueMode
  ├─ recordRescueModeUse()
  └─ recordShortcutRescueLaunch()  [if source == .shortcut]

RescueSession.applyTranslationSuccess
  ├─ recordTranslationSuccess(profileId, cache|proxy, durationMs?)
  └─ AppRatingPrompt.considerAfterSuccessfulTranslation()
```

Shortcut detection covers:

- Siri / Shortcuts (`StartRescueModeIntent`)
- Action Button assignment to the shortcut
- Cold-start restore replays UI only — **not** double-counted (counts happen in `requestRescueMode` / intent)

---

## Feedback

**O aplikacji → Opinia → Wyślij opinię**

Opens `mailto:pawelp255@gmail.com` with subject `TalkRescue feedback`. Uses system Mail app; alert if unavailable.

---

## Rating prompt (`AppRatingPrompt`)

Uses `SKStoreReviewController.requestReview(in:)` — Apple controls whether the dialog appears.

**Eligibility** (either condition):

1. ≥ 20 successful translations, **or**
2. ≥ 7 days since first launch

**Guards:**

- `analytics.ratingPromptRequested` — set when we call `requestReview` (no repeat from app logic)
- System enforces Apple's ~3 prompts/year limit
- No custom rating UI

Triggered after each successful translation once eligible.

---

## Privacy impact

| Data stored locally | Sent off device? |
|---------------------|------------------|
| Integer counters | No |
| Profile ID → count map | No |
| First launch timestamp | No |
| Rating prompt flag | No |

Counters contain **no** speech text, translations, or personal identifiers. Uninstalling the app removes all analytics keys.

---

## Files

| File | Role |
|------|------|
| `TalkRescue/Utilities/LocalUsageAnalytics.swift` | Counters + snapshot |
| `TalkRescue/Utilities/AppRatingPrompt.swift` | StoreKit review prompt |
| `TalkRescue/Managers/RescueSession.swift` | Translation success hooks |
| `TalkRescue/Coordinators/RescueLaunchCoordinator.swift` | Rescue / shortcut hooks |
| `TalkRescue/Views/RootView.swift` | App launch hook |
| `TalkRescue/Views/AboutView.swift` | Stats + feedback UI |
| `TalkRescue/Utilities/L10n.swift` | Polish copy |

---

## Test checklist

- [ ] Fresh install: About → Statystyki show zeros
- [ ] Main mode translation (proxy): total +1, cache unchanged
- [ ] Phrase cache hit (e.g. „nie rozumiem"): cache hits +1
- [ ] Rescue Mode from toolbar: rescue uses +1, shortcut count unchanged
- [ ] Shortcut / Action Button: rescue uses +1, shortcut launches +1
- [ ] Switch language profiles: most-used language updates after several translations
- [ ] Wyślij opinię opens Mail with correct subject
- [ ] After 20 translations (debug: lower threshold temporarily): rating API called once; not called again on 21st
- [ ] After 7 days (debug: backdate `firstLaunchDate`): rating eligible without 20 translations
- [ ] Counters survive app restart; no network requests from analytics code

---

## Version

TalkRescue **1.2.3** — local analytics, feedback, rating prompt.
