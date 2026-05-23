# TalkRescue TestFlight Notes

## What to test

- Hold-to-speak flow: hold the main button, speak Polish, release, read English result
- Auto Speak toggle: when enabled, English should play automatically after translation
- Speak / Copy / Save / Clear actions on the main screen
- Quick Phrases (offline English + TTS)
- History tab (last 10 translations, local only)
- Favorites tab (save, reopen, delete)
- About tab (privacy note and app version)
- Retry after translation failure (bad network or missing API key)
- Permission denial recovery (Settings → TalkRescue → Microphone / Speech Recognition)

## Known limitations (MVP v1.0)

- Requires internet for Polish → English translation
- Translation uses a third-party API (OpenAI); latency is typically 1–3+ seconds
- Polish speech recognition quality depends on environment and device
- No account, sync, or cloud backup
- API key must be configured before building for translation to work
- Placeholder app icon (solid blue) — replace before public App Store release if desired

## Tester instructions

1. Install TalkRescue from TestFlight.
2. On first launch, allow **Microphone** and **Speech Recognition** when prompted.
3. Hold **HOLD TO SPEAK**, say a short Polish phrase clearly, then release.
4. Wait for **Translating...** to finish; read the large English text.
5. Try **Speak** or enable **Auto Speak** in settings on the main screen.
6. Try a **Quick Phrase** when you need English immediately without speaking.
7. If translation fails, tap **Retry** or check your network connection.

## Feedback questions

- Was the hold/release gesture easy to use under pressure?
- Was the English result large and readable enough?
- How long did translation feel? (Too slow / OK / Fast)
- Did Auto Speak help in real conversations?
- Any crashes, stuck recording, or permission issues?
- What one improvement would help most in an awkward conversation?
