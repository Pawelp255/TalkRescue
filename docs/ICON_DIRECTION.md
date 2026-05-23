# TalkRescue — Icon & Brand Direction

Premium App Store icon system and lightweight global branding for **TalkRescue** — a Polish → English **conversation rescue** app (voice, accessibility, Action Button, dark iOS aesthetic).

**Scope:** Documentation only. No Swift or asset changes until design is approved.

**Related:** `APP_ICON_BRIEF.md`, `APP_STORE_METADATA_PL.md`, `SCREENSHOT_PLAN.md`

---

## Brand essence

| Pillar | Expression |
|--------|------------|
| **Rescue** | Fast help when conversation stalls — not a generic translator |
| **Voice** | Microphone-first; speak, don’t type |
| **Calm** | Premium dark UI; no alarm-red dominance on icon |
| **Trust** | Clear, large in-app text; honest privacy |
| **Global** | Brand name stays English; copy localizes per market |

**One-line positioning:** *When you need English mid-conversation, TalkRescue gets you there with your voice.*

---

## Master palette (icon + marketing)

Use these hex values across icon, screenshots, and web.

| Token | Hex | Use |
|-------|-----|-----|
| **Background top** | `#0A0C10` | Icon gradient start (near-black) |
| **Background bottom** | `#121820` | Icon gradient end (deep graphite) |
| **Blue glow** | `#2B6CB8` @ 25–40% opacity | Halo behind symbol; Rescue Mode accent |
| **Blue glow core** | `#4A9EE8` @ 15% | Inner highlight |
| **Symbol white** | `#F5F7FA` | Microphone body |
| **Symbol shadow** | `#0A0C10` @ 30% | Soft depth under glyph |
| **Rescue accent** | `#E8A84A` | Lightning / bolt (warm, not red alarm) |
| **Rescue accent alt** | `#5EB8F0` | Optional cool lightning variant |
| **Success (in-app)** | `#38A169` | “Gotowe” — not required on icon |

**Avoid on icon:** pure `#FF0000`, flags, globes, speech bubbles, “A→文”, text logotypes.

---

## Icon technical spec (all concepts)

| Requirement | Value |
|-------------|--------|
| Master size | **1024 × 1024 px** |
| Color space | sRGB |
| Background | **Opaque** full bleed (no transparency in final PNG) |
| Text | **None** |
| Safe zone | Keep symbol in center **~75%** of canvas (iOS masks corners) |
| Small-size test | Must read at **60×60 pt** (@3x = 180 px) |

---

## Concept A — Premium microphone

### Visual

- **Shape:** Rounded capsule microphone (SF Symbol–inspired but custom), centered, slight soft 3D bevel on head.
- **Background:** Vertical gradient `#0A0C10` → `#121820`.
- **Glow:** Soft circular **blue** bloom behind mic (`#2B6CB8`, feathered).
- **Accent:** None, or microscopic specular dot on grille — **no lightning**.
- **Style:** Apple-adjacent premium utility; feels like “voice tool” not “game.”

### Colors (summary)

| Element | Color |
|---------|--------|
| BG | Graphite gradient |
| Mic | `#F5F7FA` |
| Glow | Blue `#2B6CB8` |
| Accent | — |

### App Store readability

- **Strengths:** Instant “voice app” recognition; clean on home screen; ages well.
- **Risks:** Generic among dictation/translator icons; **TalkRescue** name not visually hinted.

### Accessibility / readability

- High contrast white-on-dark (WCAG-friendly at icon level).
- Single shape = clear at a glance for older users.
- No fine lines on grille (max 2–3 simple dots or lines).

---

## Concept B — Rescue lightning + mic

### Visual

- **Shape:** White microphone (same family as A), **smaller bolt** integrated at lower-right of capsule or crossing the stem — bolt in **warm amber** `#E8A84A`.
- **Background:** Same graphite gradient + **blue glow** behind upper mic head.
- **Composition:** Mic 70% visual weight, bolt 30%; bolt must survive 180 px width.
- **Style:** Distinct “rescue + voice”; aligns with in-app bolt toolbar and Action Button story.

### Colors (summary)

| Element | Color |
|---------|--------|
| BG | Graphite gradient |
| Mic | `#F5F7FA` |
| Glow | Blue `#2B6CB8` / `#4A9EE8` |
| Lightning | `#E8A84A` |

### App Store readability

- **Strengths:** Unique silhouette; encodes product name; premium dark + dual accent reads “pro” not “free clipart.”
- **Risks:** Bolt too detailed → mud at small size; must simplify to **5–7 points max**.

### Accessibility / readability

- Two elements only; bolt attached to mic so it reads as **one icon**, not two icons.
- Warm bolt on dark avoids confusion with pure “weather” apps if shape is angular and small.
- Test with grayscale: mic and bolt must still separate by value.

---

## Concept C — Ultra minimal accessibility icon

### Visual

- **Shape:** Single **filled** microphone silhouette inside a soft circle (ring optional, 2 px stroke `#FFFFFF` @ 20% opacity).
- **Background:** Flat `#0A0C10` or very subtle gradient; **minimal** glow.
- **Accent:** Thin **blue arc** (120°) under mic suggesting “active listening” — no lightning.
- **Style:** Maximum legibility; accessibility-first; almost medical-calm.

### Colors (summary)

| Element | Color |
|---------|--------|
| BG | Near-black `#0A0C10` |
| Mic | `#FFFFFF` |
| Ring / arc | `#4A9EE8` @ 60% |
| Glow | Optional, very subtle |

### App Store readability

- **Strengths:** Best small-size clarity; friendly to older users; least visual noise.
- **Risks:** Weakest “rescue” story; may blend with simple voice memo apps.

### Accessibility / readability

- Highest contrast option; ideal for Dynamic Type–minded brand.
- No secondary warm color — color-blind safe.
- Prefer **bold** mic stem (min 8% canvas width at 1024).

---

## Recommendation for App Store launch

### **Winner: Concept B — Rescue lightning + mic**

| Criterion | Why B wins |
|-----------|------------|
| Brand fit | “Talk” + “Rescue” in one glyph |
| Differentiation | Not another generic translator globe |
| Product truth | Matches Rescue Mode, bolt affordance, Action Button |
| Premium dark iOS | Graphite + blue glow + white = on-brand with app UI |
| Global | No language on icon; lightning is universal “fast help” |
| Age range | Simple enough for older users; modern enough for younger |

**Ship B** with strict simplification rules: one mic, one bolt, no text, no extra rings.

**Fallback:** If bolt tests poorly at 180 px in user testing, **refine B → A** (drop bolt, keep blue glow mic).

**Do not launch C** as primary unless user research shows confusion with B; keep C as **accessibility alternate** for marketing “large type” slides only.

---

## Image generation prompts

Use these verbatim or merge. Always add: **no text, no letters, square 1024, opaque background.**

### Concept A — Premium microphone

**ChatGPT / DALL·E**
```
iOS app icon, 1024x1024, square, opaque. Premium minimal app icon: single white rounded microphone centered on deep graphite to black gradient background (#0A0C10 to #121820). Soft blue glow halo behind microphone (#2B6CB8). Subtle soft 3D lighting on mic, geometric simplified shape, no grille detail. Apple-style premium utility icon. No text, no letters, no flags, no globe, no headphones. High contrast, clean edges, sRGB.
```

**Midjourney**
```
iOS app icon design, premium minimal white microphone symbol, centered, soft blue glow, deep black graphite gradient background, apple design award style, flat plus subtle depth, geometric vector look, high contrast --ar 1:1 --v 6 --style raw --no text letters words flag globe headphones realistic photo
```

**Canva AI**
```
App icon 1024px: minimalist white microphone on dark charcoal gradient, soft blue light glow behind, premium iOS style, no text, simple shapes, high contrast
```

---

### Concept B — Rescue lightning + mic (recommended)

**ChatGPT / DALL·E**
```
iOS app icon, 1024x1024, square, opaque. Premium app icon: white simplified microphone with small warm amber lightning bolt accent (#E8A84A) attached to lower right of microphone, centered. Background deep graphite black gradient (#0A0C10 to #121820) with subtle blue glow (#2B6CB8) behind mic head. Minimal geometric shapes, Apple-style, calm not alarming. No text, no letters, no flags. Must read clearly at small size. sRGB.
```

**Midjourney**
```
iOS app icon, white minimal microphone plus small golden amber lightning bolt integrated, deep black graphite gradient background, subtle blue halo glow, premium apple ios style, geometric vector, conversation rescue app, high contrast small-size readable --ar 1:1 --v 6 --style raw --no text typography letters flag globe translator
```

**Canva AI**
```
Premium iOS app icon: white microphone with small orange-gold lightning bolt, dark black-blue gradient background, soft blue glow, minimal, no text, emergency voice helper style
```

---

### Concept C — Ultra minimal accessibility

**ChatGPT / DALL·E**
```
iOS app icon, 1024x1024, square, opaque. Ultra minimal accessibility icon: bold white microphone silhouette centered inside faint circular ring, thin blue arc under microphone suggesting listening. Near-black background #0A0C10, very subtle gradient, almost no glow. Maximum simplicity, thick shapes, WCAG high contrast. No text, no lightning, no extra icons. sRGB.
```

**Midjourney**
```
iOS app icon ultra minimal, bold white mic silhouette, thin blue arc, dark near-black background, accessibility friendly, thick simple shapes, no details --ar 1:1 --v 6 --style raw --no text letter lightning globe
```

**Canva AI**
```
Minimal app icon: thick white microphone icon on pure dark background, thin blue curved line below, very simple, high contrast, no text, accessibility style
```

---

### Negative prompt (all tools)

```
text, letters, words, logo type, TalkRescue, TR, flag, Poland, UK, globe, earth, speech bubble, chat app, headphones, realistic photo, cluttered, gradient rainbow, bright red background, alarm, siren, medical cross, transparent background, rounded corners baked in, watermark
```

---

## Post-generation checklist

1. Export **1024×1024 PNG** (opaque).
2. Preview at **180×180** and **60×60** — bolt still visible on B.
3. Squint test / grayscale — silhouette unique on a page of apps.
4. Place on **light and dark** iOS wallpapers (screenshot).
5. Only then add to `Assets.xcassets` → AppIcon.

---

## App naming & subtitle strategy

### Display name (global)

| Market | App Store name | Notes |
|--------|----------------|-------|
| **All** | **TalkRescue** | One word, camel case in marketing; no space required in icon row |
| Limit | 30 characters | Fits |

**Do not translate the brand name** in the store listing title (builds recognition; subtitle carries meaning).

### Subtitle (localized, 30 chars)

| Locale | Subtitle | Rationale |
|--------|----------|-----------|
| **Polish (primary)** | `Polski głos → angielski` | Clear PL→EN; fits 30 chars |
| **English (US/UK)** | `Polish voice to English` | Global expansion |
| **English (short)** | `Voice rescue in English` | If char limit tight |

**Avoid in subtitle:** “translator”, “AI chat”, “dictionary” — positions as utility translator, not conversation rescue.

### Promotional naming (marketing, not on icon)

- PL: *„Ratunek w rozmowie”* / *„Mów po polsku — słysz po angielsku”*
- EN: *“Conversation rescue”* / *“Speak Polish. Show English.”*

---

## Lightweight branding direction

### Logo usage

- **Primary mark:** App icon (Concept B) — no separate wordmark required for v1.0.
- **Wordmark (optional web):** `TalkRescue` in **SF Pro Display Semibold**, letter-spacing −1%.
- **Never:** all-caps shouting logo on icon.

### UI alignment (existing app — do not change in this pass)

| Surface | Direction |
|---------|-----------|
| Rescue Mode | Black / graphite (`rescueBackgroundTop/Bottom`) |
| Main app | System grouped light + calm cards |
| Accent | Blue idle mic, soft coral listening, green ready |
| Icon → app | User sees blue glow + dark on home screen → opens to matching Rescue dark |

### Typography (marketing & store)

- **Headlines:** SF Pro / system stack — large, bold.
- **Body:** Regular, generous line height (accessibility).
- **Polish:** primary store copy; **English:** parallel listing when expanding.

### Photography / screenshots

- Dark gradient frames optional; keep **in-app UI** as hero (authentic).
- Polish UI strings on screenshots for PL storefront.

### Global scalability

| Principle | Action |
|-----------|--------|
| Icon | Language-neutral symbol only |
| Name | `TalkRescue` everywhere |
| Meaning | Localized **subtitle** + description |
| Feature names | “Rescue Mode” can stay English in UI or localize in v1.1 (`Tryb ratunkowy` already in PL copy) |
| Colors | Same palette worldwide |

---

## Concept comparison matrix

| | A Premium mic | **B Rescue + mic** | C Ultra minimal |
|---|:---:|:---:|:---:|
| Voice clarity | ●●● | ●●● | ●●● |
| Rescue story | ● | ●●● | ● |
| Small-size read | ●●● | ●●● | ●●●● |
| Differentiation | ●● | ●●● | ●● |
| Premium feel | ●●● | ●●● | ●● |
| Action Button fit | ●● | ●●● | ●● |

---

## Decision log

| Date | Decision |
|------|----------|
| 2026-05 | Launch icon: **Concept B** pending asset production |
| 2026-05 | Brand name locked: **TalkRescue** |
| 2026-05 | Primary storefront: **Polish**; English subtitle ready |

---

*Icon direction v1.0 — TalkRescue. Assets not modified in repo.*
