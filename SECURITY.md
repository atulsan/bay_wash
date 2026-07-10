# Bay Wash Security Notes

## Secrets

- Do not commit API keys, private keys, keystores, passwords, tokens, or `.env` files.
- The OpenRouteService key is read only from Dart defines:
  - `OPENROUTESERVICE_API_KEY`
  - `ORS_API_KEY`
- For production, put route and traffic calls behind a Bay Wash backend proxy with user/session authorization, rate limiting, origin checks, and server-side key storage. Any key shipped inside a mobile app package can be extracted.

## Android Release Signing

Release builds no longer fall back to the debug signing key. Provide signing material through environment variables:

```bash
BAYWASH_UPLOAD_KEYSTORE=/secure/path/upload-keystore.jks
BAYWASH_UPLOAD_KEYSTORE_PASSWORD=...
BAYWASH_UPLOAD_KEY_ALIAS=...
BAYWASH_UPLOAD_KEY_PASSWORD=...
```

Keep keystores outside the repository.

## Platform Hardening

- Android blocks cleartext traffic and excludes app data from backups/device transfer.
- Android release builds enable code/resource shrinking and block screenshots/screen recording.
- iOS keeps App Transport Security strict and masks the app switcher preview.
- Sensitive mock payment, OTP, and phone fields disable keyboard suggestions/autocorrect/autofill hints.

## Before Production

- Replace demo OTP, booking, station, payment, and vendor authorization with server-enforced flows.
- Add backend authorization checks for every station/vendor action.
- Run dependency audit, mobile static analysis, and store-signing verification before each release.
