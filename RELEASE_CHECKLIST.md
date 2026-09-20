# FCBaz Production Release Checklist

This checklist is intentionally strict. A public release should not be published
until every required item below is verified.

## 1. Production data

- Configure a production `FCBAZ_API_BASE_URL`.
- Configure `PARSE_API_KEY` and verify all FC27 provider endpoints return real data.
- Confirm player, price, SBC, Evolution, Objective, market and news endpoints do not fall back to fabricated data.
- Confirm Console and PC prices are mapped correctly.

## 2. Supabase

Run `backend/SUPABASE_SCHEMA.sql` in the production Supabase project.

Backend environment:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Verify:

- Registration and login work.
- Email confirmation behavior matches the production Supabase Auth configuration.
- Access-token refresh works.
- Cloud backup upload works.
- Restore works on a second test account/device.
- Service-role key exists only on the backend.

## 3. Firebase Cloud Messaging

Backend environment:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `CRON_SECRET`

GitHub Actions secrets:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`

Verify the Firebase Android app is registered with package:

`ir.fcbaz.app`

Verify:

- Android notification permission appears on supported Android versions.
- Device token registration succeeds after login.
- Foreground messages appear in Notification Center.
- Background/terminated push is delivered on a physical device.
- Price alerts trigger once on crossing the target and do not repeatedly spam.

## 4. Android signing

Required GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Keep the original keystore permanently backed up offline. Future updates must use
the same signing identity.

## 5. Privacy and account behavior

- Auth tokens must remain in secure storage and must not be exported in backups.
- Account/Cloud API responses must use `Cache-Control: no-store`.
- Local backup must export only FCBaz-owned preferences.
- Verify account logout removes local auth credentials.
- Verify destructive Cloud Restore requires confirmation.

## 6. UI and data integrity

- Test Persian RTL on small and large Android screens.
- Test English mode for layout overflow even if Persian remains the primary experience.
- Verify Dark, Light and System theme persistence.
- Verify empty, loading and network-error states.
- Verify all images have fallback states.
- Verify no placeholder/fake player, market or SBC data is displayed.

## 7. Final release gate

Only when Sahand explicitly requests a new release:

1. Run `flutter pub get`.
2. Run `flutter analyze`.
3. Run the full `flutter test` suite.
4. Fix every release-blocking error.
5. Build signed release APK.
6. Build signed release AAB.
7. Record SHA256 hashes.
8. Install the release APK on a physical Android device.
9. Smoke-test Login, Home, Search, Player Details, Market, Squad, My Club,
   Cloud Sync, Notification Center and Update Checker.
10. Publish the GitHub Release only after the smoke test passes.

No debug/preview APK should be published as a public FCBaz release.
