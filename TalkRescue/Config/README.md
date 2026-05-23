# API key setup (TestFlight / local builds)

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` in this folder.
2. Set `OPENAI_API_KEY = your_key_here` in `Secrets.xcconfig`.
3. Rebuild the app in Xcode.

`Secrets.xcconfig` is gitignored. Never commit real API keys.

For CI or Archive builds, ensure `Secrets.xcconfig` exists on the build machine before archiving.
