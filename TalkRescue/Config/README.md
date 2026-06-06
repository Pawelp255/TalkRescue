# Translation proxy setup (TestFlight / local builds)

1. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` in this folder.
2. Set `TALKRESCUE_API_KEY` to the value from `supabase secrets set` (see `docs/SUPABASE_SETUP_GUIDE.md`).
3. Rebuild the app in Xcode.

`TALKRESCUE_SUPABASE_URL` defaults in `Config.xcconfig` and does not need to be overridden for production.

`Secrets.xcconfig` is gitignored. Never commit real API keys.

For CI or Archive builds, ensure `Secrets.xcconfig` exists on the build machine before archiving.
