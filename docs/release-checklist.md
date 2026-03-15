# Release Checklist

## Backend
- Set `ENVIRONMENT=production`.
- Replace `SECRET_KEY` with a long random secret.
- Restrict `BACKEND_CORS_ORIGINS` to production app domains only.
- Set `AI_API_KEY` if AI features are enabled in production.
- Verify `/healthz` returns `status=ok`.

## Android
- Copy `literary_life_app/android/key.properties.example` to `literary_life_app/android/key.properties`.
- Fill in the keystore path and passwords for the production signing key.
- Build with `flutter build appbundle --release`.

## iOS
- Confirm bundle id `com.literarylife.app` is registered in Apple Developer.
- Set the correct signing team, provisioning profile, and release version in Xcode.
- Build with `flutter build ipa --release`.

## Verification
- Run `flutter analyze` and `flutter test` in `literary_life_app`.
- Run `.venv/bin/pytest` in `literary_life_backend`.
- Smoke test publish, unpublish, friend share, group share, and notification open flows on both platforms.
