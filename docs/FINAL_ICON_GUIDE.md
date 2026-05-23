# TalkRescue — Final App Store Icon Guide

**Status:** Documentation for App Store release prep  
**Scope:** Icon system, generation prompts, Xcode integration, validation — **no Swift or project settings changes in this pass**  
**Related:** `ICON_DIRECTION.md`, `APP_ICON_BRIEF.md`, `APP_STORE_METADATA_PL.md`, `SCREENSHOT_PLAN.md`

---

## Executive summary

| Item | Decision |
|------|----------|
| **Ship this concept** | **Concept B — Rescue Lightning + Mic** |
| **Master asset** | 1024×1024 PNG, sRGB, opaque |
| **Xcode slot** | `TalkRescue/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |
| **Brand story** | Voice (mic) + instant help (amber bolt) on calm dark premium ground |

---

## Design principles (non‑negotiable)

| Rule | Rationale |
|------|-----------|
| **No text** | Illegible at 60×60 pt; Apple Human Interface Guidelines discourage logotypes on icons |
| **No flags** | Avoids “translation app for one country” perception; TalkRescue is conversation rescue, not locale branding |
| **No globe / chat bubble** | Generic translator clutter; poor differentiation |
| **One hero glyph** | Mic + integrated bolt reads as **one** mark, not two icons |
| **Opaque square** | iOS rejects / downgrades transparent 1024 marketing icons |
| **Safe zone ~75%** | Corners are system-masked; keep detail in center |
| **Calm, not alarm** | Warm amber `#E8A84A`, not recording red `#FF0000` as dominant field |

---

## Master palette (lock for all concepts)

Aligned with `AppTheme.rescueBackgroundTop/Bottom` and in-app mic blue.

| Token | Hex | Usage |
|-------|-----|--------|
| Background top | `#0A0C10` | Gradient start (~RGB 10,12,16) |
| Background bottom | `#121820` | Gradient end |
| Symbol white | `#F5F7FA` | Microphone body |
| Blue glow | `#2B6CB8` @ 30–40% | Halo behind mic head |
| Blue highlight | `#4A9EE8` @ 15% | Inner bloom |
| Rescue accent | `#E8A84A` | Lightning bolt (warm amber/gold) |
| Soft shadow | `#000000` @ 25% | Under-glyph depth only |

**Avoid:** rainbow gradients, neon red fields, photographic textures, baked-in iOS corner radius.

---

## Three final App Store concepts

### Concept A — **Glass Halo Mic** (premium voice utility)

**Visual**

- Centered **rounded capsule microphone** (custom geometry, SF Symbol–inspired but not a literal SF glyph export).
- **Vertical graphite gradient** `#0A0C10` → `#121820`.
- **Soft blue circular glow** behind mic head; subtle top-left specular (glass lighting).
- **No lightning** — pure “voice / speak” signal.
- Grille: **2–3 dots max** or smooth cap — no fine mesh.

**When to choose:** Maximum Apple-native “utility” feel; lowest risk if bolt tests muddy in QA.

**Small-size risk:** Blends with dictation / voice memo apps without rescue differentiation.

---

### Concept B — **Rescue Lightning + Mic** (recommended for release)

**Visual**

- Same **white mic** family as A, **~65–70%** of visual mass, centered slightly above optical center.
- **Integrated amber bolt** `#E8A84A` at lower-right of capsule or crossing stem — **5–7 vertices max**, chunky, not thin zigzag.
- **Blue glow** `#2B6CB8` behind upper mic only; bolt sits on mic silhouette so it reads as **one icon**.
- **Soft glass**: faint inner highlight on mic head, very subtle ground shadow (not drop-shadow sticker look).
- Background: deep graphite gradient; optional **1–2%** vignette at edges.

**Composition rules**

```
        [ blue glow bloom ]
              (  )
             (mic)
              |\
              | ⚡  ← bolt attached, same plane as mic
              |
```

- Bolt width ≥ **8%** of canvas width at 1024 px.
- Mic stem width ≥ **10%** of canvas width at 1024 px.

**When to choose:** Default — encodes **Talk** + **Rescue**, matches Rescue Mode dark UI and in-app bolt affordances.

---

### Concept C — **Bold Accessibility Mic** (ultra-minimal fallback)

**Visual**

- **Filled** white mic silhouette only — thickest stem and head of the three concepts.
- Near-flat background `#0A0C10` with **minimal** glow.
- Optional: thin **blue arc** (120°) under mic suggesting “listening” — **no lightning**.
- Optional faint ring at 20% white opacity — must not compete with mic at 180 px.

**When to choose:** User testing shows bolt confusion with weather apps; or accessibility research prioritizes maximum contrast over brand story.

**Small-size strength:** Highest legibility; **weakest** “rescue” narrative.

---

## Recommendation: ship **Concept B**

### Why it works psychologically

| Factor | Effect |
|--------|--------|
| **Microphone** | Universal “speak now” — matches core loop (Polish voice in) without reading copy |
| **Warm amber bolt** | Signals *energy and help*, not danger — avoids alarm-red anxiety before opening the app |
| **Dark graphite field** | Premium, calm, “pro tool at night” — fits conversation stress contexts |
| **Blue glow** | Trust + technology (cool) balanced with warm bolt (human urgency) — dual emotional cue without clutter |
| **No text** | Brain processes shape in **~200 ms** on home screen; name “TalkRescue” is learned once from App Store listing |

Users scanning a folder of apps infer: *dark app + mic = voice*; *gold accent = something happens fast* — aligned with “rescue in conversation.”

### Why it works at small size

- **Two-value silhouette:** white mic + amber wedge on black — survives grayscale and “squint test.”
- **Bolt attached to mic** prevents parsing as two separate icons at 60×60 pt (@3x = 180 px).
- **Thick geometry** rules (8–10% stroke widths) keep bolt visible where thin lightning disappears.
- **No micro-detail:** grille dots ≤ 3; no inner outlines thinner than 2 px at 1024.

### Why it fits App Store trends (2024–2026)

- **Dark, single-glyph icons** dominate utilities, health, and focus apps (calm premium vs. skeuomorphic clutter).
- **One accent color** on neutral dark reads “paid quality” vs. rainbow free-tier clipart.
- **Language-neutral symbols** support global subtitle strategy (`TalkRescue` brand + localized subtitle).
- **Differentiated from translator category** — no globe, no “A→文”, no speech bubbles (Apple category positioning).

**Fallback path:** If bolt fails 180 px QA, ship **Concept A** (drop bolt, keep blue glow mic) — not Concept C as primary.

---

## Image generation prompts

**Always append to every prompt:**

> Square 1:1, 1024×1024 pixels, opaque background, sRGB, no text, no letters, no watermark, no pre-rounded corners, no transparency.

**Universal negative prompt:**

```
text, letters, words, logo, TalkRescue, TR, typography, flag, Poland, UK, globe, earth, speech bubble, chat bubble, headphones, translator, dictionary, realistic photo, 3D render chrome, cluttered, rainbow, bright red background, alarm, siren, medical cross, transparent background, rounded corners baked in, watermark, stock clipart
```

---

### Concept A — Glass Halo Mic

#### ChatGPT (GPT-4o / image generation)

```
Create a premium iOS app icon, exactly 1024x1024 pixels, square, opaque full-bleed background.

Design: one centered white rounded microphone icon with soft glass-like highlight on the capsule head, minimal geometry (no detailed grille, max 3 simple dots). Background is a smooth vertical gradient from deep graphite #0A0C10 at top to #121820 at bottom. Behind the microphone head, a soft circular blue glow halo (#2B6CB8, feathered, subtle). Subtle premium lighting, calm Apple-style utility app aesthetic. High contrast white on dark. No lightning, no text, no flags, no globe, no speech bubbles.

Style: modern minimal vector, slight soft depth, not photorealistic. Must remain clear when shrunk to app icon size on iPhone home screen.
```

#### Midjourney

```
iOS app icon, premium minimal white rounded microphone centered, soft blue glow halo behind mic head, deep graphite black gradient background #0A0C10 #121820, subtle glass lighting soft 3D, geometric vector, apple design award style, high contrast, calm utility app --ar 1:1 --v 6.1 --style raw --s 50 --no text letters words flag globe speech bubble headphones lightning bolt realistic photo clutter watermark
```

#### Leonardo (Phoenix / Alchemy)

```
1024x1024 iOS app icon, opaque square. Minimal white rounded microphone, centered, soft blue glow bloom (#2B6CB8), deep black graphite gradient background, subtle glass specular highlight, premium calm utility, thick simple shapes, high contrast, vector-like, no text no flags no globe
```

**Negative:** `text, logo, flag, globe, chat bubble, lightning, realistic photo, transparent, rounded corners`

---

### Concept B — Rescue Lightning + Mic (recommended)

#### ChatGPT

```
Create a premium iOS app icon, exactly 1024x1024 pixels, square, opaque full-bleed background.

Design: one centered white simplified microphone (rounded capsule, thick stem, minimal grille) with a small warm amber-gold lightning bolt (#E8A84A) integrated at the lower-right of the microphone so they read as one symbol. Behind the microphone head, a subtle soft blue glow (#2B6CB8). Background: smooth vertical gradient deep graphite #0A0C10 to #121820. Soft premium glass lighting, gentle shadow under glyph, calm and trustworthy, not alarming.

The lightning bolt must be chunky and simple (5-7 points max), clearly visible at small size. No text, no flags, no globe, no speech bubbles, no headphones. High contrast. Modern minimal Apple-style app icon.

Style: geometric vector-like, not photorealistic. Must read clearly at iPhone home screen icon size.
```

#### Midjourney

```
iOS app icon, white minimal rounded microphone with small integrated warm amber gold lightning bolt attached lower right, single unified symbol, subtle blue glow halo behind mic, deep graphite black gradient background, premium apple ios style, soft glass lighting, geometric vector, conversation rescue voice app, high contrast, small-size readable, calm trustworthy --ar 1:1 --v 6.1 --style raw --s 75 --no text typography letters flag globe translator speech bubble headphones realistic photo alarm red watermark
```

#### Leonardo

```
1024x1024 iOS app icon opaque. White thick rounded microphone plus small integrated amber gold lightning bolt #E8A84A attached to mic lower right as one glyph, subtle blue glow #2B6CB8 behind mic head, deep graphite gradient #0A0C10 #121820, premium soft glass lighting, minimal geometry, high contrast, calm not alarming, vector style, no text no flags
```

**Negative:** `text, logo, flag, globe, chat bubble, thin lightning, realistic photo, transparent, red background, watermark`

---

### Concept C — Bold Accessibility Mic

#### ChatGPT

```
Create a premium iOS app icon, exactly 1024x1024 pixels, square, opaque full-bleed background.

Design: one bold filled white microphone silhouette, centered, extra-thick stem and head for maximum legibility at small size. Near-black background #0A0C10 with very subtle gradient. Optional: thin soft blue arc (#4A9EE8 at 60% opacity) under the microphone suggesting listening. Minimal or no glow. No lightning bolt. No text, no flags, no globe.

Style: ultra-minimal accessibility-first, WCAG high contrast, geometric vector, no fine details. Must read instantly at iPhone app icon size.
```

#### Midjourney

```
iOS app icon ultra minimal, bold thick white microphone silhouette centered, thin soft blue arc below, near-black graphite background #0A0C10, accessibility friendly, maximum simplicity, high contrast, no lightning --ar 1:1 --v 6.1 --style raw --no text letter flag globe speech bubble lightning realistic photo watermark
```

#### Leonardo

```
1024x1024 iOS app icon opaque. Bold filled white microphone silhouette, very thick simple shapes, centered, near-black background #0A0C10, optional thin blue arc under mic, minimal glow, ultra high contrast accessibility style, no text no lightning no flags
```

---

## Post-generation refinement (designer checklist)

AI output is a **starting point**. Before Xcode:

1. **Vector trace or Figma rebuild** — crisp edges, exact hex values from palette table.
2. **Remove baked corner radius** — export full square; iOS masks automatically.
3. **Flatten to opaque PNG** — no alpha channel in final 1024 file.
4. **Sharpen for small size** — slightly bolder bolt and stem than AI default.
5. **Export tests** — see validation section below.

Optional tools: Figma, Affinity Designer, Sketch, Icon Slate, App Icon Generator (for derivative sizes only).

---

## Final recommended asset — Concept B spec sheet

Use this brief if hiring a designer or polishing AI output:

| Property | Value |
|----------|--------|
| Canvas | 1024 × 1024 px |
| Color space | sRGB IEC61966-2.1 |
| Format | PNG, 24-bit RGB, **no alpha** |
| Mic color | `#F5F7FA` |
| Bolt color | `#E8A84A` |
| BG gradient | `#0A0C10` (top) → `#121820` (bottom) |
| Glow | `#2B6CB8`, Gaussian ~80–120 px radius at 1024 scale |
| Filename | `AppIcon-1024.png` |

---

## Xcode AppIcon integration

### Current project layout

```
TalkRescue/
  Assets.xcassets/
    AppIcon.appiconset/
      Contents.json          ← single-slot iOS 17+ universal 1024
      AppIcon-1024.png       ← replace this file
```

`Contents.json` already declares one **1024×1024** universal iOS image. Xcode generates all device sizes from this master at build time.

`ASSETCATALOG_COMPILER_APPICON_NAME` = **AppIcon** (do not rename without updating build settings — out of scope for this doc pass).

---

### Exact export sizes

#### Required for App Store Connect & Xcode (minimum)

| Asset | Size | Notes |
|-------|------|--------|
| **App Store Marketing** | **1024 × 1024** | Only file required in current `AppIcon.appiconset` |
| App Store Connect upload | **1024 × 1024** | Same PNG at submission (often same file) |

#### Optional manual slots (legacy / marketing)

If you expand `AppIcon.appiconset` or use external generators, common iOS phone sizes:

| Role | Pt | @2x px | @3x px |
|------|-----|--------|--------|
| iPhone Notification | 20 | 40 | 60 |
| iPhone Settings | 29 | 58 | 87 |
| iPhone Spotlight | 40 | 80 | 120 |
| iPhone App | 60 | 120 | 180 |
| iPad App (if ever) | 76 / 83.5 | 152 / 167 | — |
| App Store | 1024 | 1024 | — |

**TalkRescue (iPhone-only, iOS 17+):** supplying **1024×1024** alone is sufficient for modern Xcode asset catalogs.

#### App Store Connect

- **Large App Icon:** 1024×1024 PNG/JPEG, no transparency, no rounded corners in file.

---

### Step-by-step: replace `AppIcon`

1. **Produce final PNG** `AppIcon-1024.png` per Concept B spec (designer or refined AI).
2. **Backup** existing icon (optional):
   ```bash
   cp TalkRescue/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
      TalkRescue/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.backup.png
   ```
3. **Replace** the file **in place** (keep exact name `AppIcon-1024.png`):
   ```bash
   cp /path/to/your/final/AppIcon-1024.png \
      TalkRescue/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
   ```
4. **Verify** `Contents.json` still references the filename:
   ```json
   "filename" : "AppIcon-1024.png"
   ```
5. Open **TalkRescue.xcodeproj** in Xcode.
6. Select **TalkRescue** target → **General** → **App Icons and Launch Screen** → confirm **AppIcon** is selected.
7. In Project Navigator: **Assets.xcassets** → **AppIcon** — preview should show new art.
8. **Clean build folder:** Product → Clean Build Folder (⇧⌘K).
9. **Delete app from device/simulator** (iOS caches icons aggressively).
10. **Build and run** on a physical iPhone (preferred for true home-screen test).

**Do not** add pre-rounded corners in the PNG. **Do not** embed text.

---

### Validate icon quality on iPhone

| Test | How |
|------|-----|
| **Home Screen** | Install Release build; view on light and dark wallpaper |
| **App Library** | Smaller than home screen — bolt must still read |
| **Settings → TalkRescue** | ~29 pt icon — silhouette only, no detail dependency |
| **Spotlight search** | Type “Talk” — recognizable among results |
| **Squint test** | Arm’s length — mic + bolt one shape |
| **Grayscale** | iOS Accessibility → Display → Color Filters → Grayscale |
| **Neighbor grid** | Screenshot home screen next to Phone, Notes, Weather — not confused with Weather if bolt is **attached** to mic |
| **180 px preview** | In Preview/Figma, resize to 180×180 — pass/fail gate for bolt |

**Simulator:** acceptable for layout; **physical device** required for true gamma and wallpaper contrast.

**TestFlight:** icon on install confirmation sheet must match expectations before public release.

---

## Optional launch screen (match icon, no code in this pass)

Project uses **`INFOPLIST_KEY_UILaunchScreen_Generation = YES`** (auto-generated launch screen). When you implement branding later (separate task):

| Approach | Spec |
|----------|------|
| **Background** | Solid or gradient `#0A0C10` → `#121820` (match icon) |
| **Center mark** | White mic only **or** mic+bolt at **40–50%** of icon size — no text |
| **Glow** | Very subtle blue bloom, 50% of icon intensity |
| **Duration** | Static; no animation required for v1.0 |
| **Avoid** | Full-screen marketing copy, loading spinners, different palette than icon |

**Psychological continuity:** user taps dark premium icon → brief same-dark frame → Rescue Mode / main UI feels intentional, not a flash of white.

Implementation options (future): Asset Catalog color set, `LaunchScreen.storyboard`, or SwiftUI launch asset — **not modified in this documentation pass**.

---

## App Store readiness checklist (icon & visual)

### Icon assets

- [ ] Final **1024×1024** PNG, opaque, sRGB
- [ ] Concept **B** approved after 180 px + device tests
- [ ] Replaced `AppIcon.appiconset/AppIcon-1024.png`
- [ ] Clean build + reinstall on device
- [ ] TestFlight build shows correct icon
- [ ] App Store Connect **Large App Icon** uploaded (matches build)

### Icon compliance

- [ ] No text, trademarks you don’t own, or Apple product mimicry
- [ ] No transparency in 1024 marketing PNG
- [ ] No misleading imagery (not a medical/emergency services impersonation)
- [ ] Distinct from Apple system apps

### Brand consistency

- [ ] Screenshots use same graphite + blue + amber language (`SCREENSHOT_PLAN.md`)
- [ ] Rescue Mode dark UI feels continuous with home screen icon
- [ ] Subtitle does not say “translator” (positioning)

### Broader release (cross-reference)

- [ ] Privacy policy URL live (`PRIVACY_POLICY_PL.md`)
- [ ] Metadata PL/EN (`APP_STORE_METADATA_PL.md`)
- [ ] MVP test plan executed (`MVP_TEST_PLAN.md`)
- [ ] Microphone / Speech Recognition usage strings accurate in Info.plist

---

## Concept comparison matrix

| Criterion | A Glass Halo | **B Rescue + Mic** | C Bold Minimal |
|-----------|:------------:|:------------------:|:--------------:|
| Voice clarity | ●●● | ●●● | ●●● |
| Rescue story | ● | ●●● | ● |
| Small-size bolt | — | ●●● (if simplified) | — |
| Differentiation | ●● | ●●● | ●● |
| Premium dark iOS | ●●● | ●●● | ●● |
| Accessibility contrast | ●●● | ●●● | ●●●● |
| App Store trend fit | ●●● | ●●● | ●● |

---

## Decision log

| Date | Decision |
|------|----------|
| 2026-05 | **Concept B** selected for App Store launch |
| 2026-05 | Master palette locked to `AppTheme` rescue graphite + mic blue |
| 2026-05 | Single 1024 `AppIcon.appiconset` confirmed in repo |
| 2026-05 | Documentation only — Swift / pbxproj unchanged |

---

## Quick reference — copy-paste winner prompt (Concept B)

**ChatGPT (final):**

```
Create a premium iOS app icon, exactly 1024x1024 pixels, square, opaque full-bleed background.

Design: one centered white simplified microphone (rounded capsule, thick stem, minimal grille) with a small warm amber-gold lightning bolt (#E8A84A) integrated at the lower-right of the microphone so they read as one symbol. Behind the microphone head, a subtle soft blue glow (#2B6CB8). Background: smooth vertical gradient deep graphite #0A0C10 to #121820. Soft premium glass lighting, gentle shadow under glyph, calm and trustworthy, not alarming.

The lightning bolt must be chunky and simple (5-7 points max), clearly visible at small size. No text, no flags, no globe, no speech bubbles, no headphones. High contrast. Modern minimal Apple-style app icon.

Style: geometric vector-like, not photorealistic. Must read clearly at iPhone home screen icon size.
```

---

*TalkRescue Final Icon Guide v1.0 — May 2026. Assets not modified in this pass.*
