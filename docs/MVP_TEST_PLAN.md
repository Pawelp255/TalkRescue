# TalkRescue MVP Test Plan

Use this checklist before each TestFlight build or after significant changes.

## Environment

- [ ] Physical iPhone (iOS 17+)
- [ ] `Secrets.xcconfig` configured with valid OpenAI API key
- [ ] Wi‑Fi or cellular data enabled for translation tests

## 1. Basic launch

- [ ] App launches to Main tab without crash
- [ ] Display name shows as **TalkRescue**
- [ ] About tab shows version **1.0** and build **1**

## 2. Permission test

- [ ] First launch prompts for Speech Recognition and Microphone
- [ ] Deny one permission → clear error message shown
- [ ] Enable in Settings → app recovers on next record attempt

## 3. Hold-to-speak test

- [ ] Hold button → status shows **Recording Polish...** (red)
- [ ] Release → status shows **Translating...** (orange)
- [ ] Recognized Polish section updates during/after speech
- [ ] Haptic feedback felt on start and stop (device only)

## 4. Translation test

- [ ] Short Polish phrase translates to sensible English
- [ ] English result is large and readable
- [ ] History entry appears after success
- [ ] Missing API key build shows friendly configuration error (no crash)

## 5. TTS test

- [ ] **Speak** plays English aloud
- [ ] **Auto Speak** plays automatically after successful translation
- [ ] Starting a new recording stops any playing TTS

## 6. Quick phrases test

- [ ] Each quick phrase fills English immediately
- [ ] TTS plays for quick phrase
- [ ] No translation API call made

## 7. History / favorites test

- [ ] History shows recent translations (max 10)
- [ ] Tapping history item restores text on Main tab
- [ ] Save adds to Favorites
- [ ] Swipe delete removes favorite

## 8. Network failure test

- [ ] Airplane mode → translation fails with useful message
- [ ] **Retry** button appears after failure
- [ ] Retry works after network restored

## 9. Fast repeated press test

- [ ] Rapid hold/release does not start duplicate recordings
- [ ] Rapid hold/release does not stack duplicate translations
- [ ] Release without speech does not call translation API

## 10. Clear / error UX

- [ ] **Clear** resets English, Polish, and status
- [ ] Translation timeout shows timeout message (if simulable)

## Sign-off

| Tester | Date | Build | Pass/Fail | Notes |
|--------|------|-------|-----------|-------|
|        |      |       |           |       |
