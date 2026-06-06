# TalkRescue 1.3 — Apple Translation Local-First

**Status:** Implemented  
**Deployment target:** iOS 17.0 (Apple path gated at iOS 18+)  
**Fallback:** Supabase Edge Function proxy (no direct OpenAI from iOS)

---

## Translation flow

```
Recognized Polish text
    │
    ├─► [1] RescuePhraseCache (exact match)
    │       log: Translation route: cache
    │
    ├─► [2] Apple Translation (iOS 18+, status == .installed)
    │       profiles: pl-en, pl-de, pl-es
    │       log: Translation route: apple
    │
    └─► [3] TranslationService → Supabase proxy
            log: Translation route: supabase fallback
            log: Translation route: supabase
```

---

## Routing by profile

| Profile | Apple eligible | Device spike | Expected path (iOS 18+, models installed) |
|---------|----------------|--------------|---------------------------------------------|
| `pl-en` | Yes | installed | Cache → **Apple** → Supabase |
| `pl-de` | Yes | installed | Cache → **Apple** → Supabase |
| `pl-es` | Yes | installed | Cache → **Apple** → Supabase |
| `pl-sv` | **No** | unsupported | Cache → **Supabase** only |

---

## Fallback behavior (silent)

| Condition | Action |
|-----------|--------|
| iOS 17.x | Skip Apple; Supabase only |
| Profile not eligible (`pl-sv`) | Skip Apple |
| `LanguageAvailability` ≠ `.installed` | Skip Apple (no download UI) |
| Apple `translate()` throws | Log error → Supabase |
| Supabase error | Existing error UX (unchanged) |

**Never** calls `prepareTranslation()` on Rescue or Action Button paths.

---

## iOS 17 behavior

- `AppleTranslationHostContainer` renders empty on iOS 17.
- `TranslationRouter` skips `#available(iOS 18, *)` block.
- All profiles use Cache → Supabase (same as v1.2 after cache miss).

---

## Files

| File | Role |
|------|------|
| `Services/AppleTranslationService.swift` | Eligibility, `LanguageAvailability`, installed-only translate |
| `Services/AppleTranslationBridge.swift` | `TranslationSession` host + `translationTask` bridge |
| `Services/TranslationRouter.swift` | Cache miss routing: Apple → Supabase |
| `Services/TranslationService.swift` | Unchanged Supabase client |
| `Managers/RescueSession.swift` | Integrated router + route logs |
| `Views/RootView.swift` | Hidden `AppleTranslationHostContainer` in hierarchy |

Debug tools (`Apple Translation Spike`, `Voice Inventory`) remain `#if DEBUG` only — not in Release.

---

## Logging

| Route | Log prefix |
|-------|------------|
| Cache hit | `Translation route: cache` |
| Apple success | `Translation route: apple` |
| Supabase used | `Translation route: supabase fallback` then `Translation route: supabase` |
| Success summary | `Translation succeeded route=cache\|apple\|supabase` |

---

## Device test checklist

### iOS 18+ device (models installed for en/de/es)

- [ ] `pl-en` cache miss → Console shows `route: apple`; no network required
- [ ] `pl-de` cache miss → `route: apple`
- [ ] `pl-es` cache miss → `route: apple`
- [ ] `pl-sv` cache miss → `route: supabase fallback` only
- [ ] Cache phrase (e.g. „nie rozumiem”) → `route: cache`
- [ ] Rescue Mode cold launch → no language download sheet
- [ ] Action Button shortcut → no download sheet
- [ ] Airplane mode + installed models → Apple path still works for pl-en

### iOS 17 device

- [ ] All profiles → Supabase after cache miss
- [ ] No crash; no Apple logs

### Regression

- [ ] Supabase errors still show Polish error strings
- [ ] Retry re-enters same routing tree
- [ ] No OpenAI URL/key in binary

---

## Privacy

- Apple path: Polish text stays on device (Apple may log language-pair metrics, not content).
- Supabase path: unchanged v1.2 proxy behavior.

---

*TalkRescue 1.3 — local-first Apple Translation with universal Supabase fallback.*
