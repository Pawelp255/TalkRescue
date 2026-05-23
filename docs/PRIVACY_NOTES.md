# TalkRescue Privacy Notes (MVP v1.0)

## What data is processed

- **Voice audio** — captured from the microphone while you hold the record button
- **Speech recognition** — Polish speech is converted to text on the device using Apple’s speech recognition
- **Translation text** — recognized Polish text may be sent to the translation provider (OpenAI) to produce English

## What is stored locally

- **History** — last 10 Polish/English phrase pairs (UserDefaults on device)
- **Favorites** — saved phrases you choose to keep (UserDefaults on device)
- **Auto Speak preference** — on/off toggle (UserDefaults on device)

## What may be sent to the translation provider

- The recognized Polish text you spoke (or retry text)
- Standard API request metadata required for the HTTPS call

No TalkRescue account, login, or cloud database is used. The app does not include analytics or advertising SDKs in this MVP.

## What is not collected by TalkRescue

- No user accounts
- No cloud sync of history or favorites
- No backend server operated by the app author for user data storage

## Permissions

- **Microphone** — required to hear your Polish speech
- **Speech Recognition** — required to convert speech to text

## API key

The translation API key is embedded at build time via local Xcode configuration (`Secrets.xcconfig`). It is not entered in the app UI and should not be committed to git.
