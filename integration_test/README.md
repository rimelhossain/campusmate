# CampusMate Windows UI flow test

This integration test signs in to the configured Supabase project, switches
between Dashboard and Chats, then calculates tuition for 12 credits with a 50%
waiver and checks that all three installment cards appear. It also creates a
Marketplace listing and marks it sold out, creates and resolves a Lost & Found
post, creates and solves a Study Help post, then toggles the theme twice.

## One-time setup

1. Copy `test_credentials.example.json` to `test_credentials.json` in this folder.
2. Put the test account's email and password in the copied file. The actual
   credentials file is ignored by Git.
3. From the project root, run `flutter pub get` to fetch the integration-test
   SDK dependency.

## Run on Windows

From the project root, run:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/campusmate_ui_flow_test.dart -d windows --keep-app-running --dart-define-from-file=integration_test/test_credentials.json
```

The test starts CampusMate in a Windows test window and makes real Supabase
Auth and database requests. It expects the account to be email-verified and
the `tuition_installments` table to contain all three deadlines. The
`--keep-app-running` option leaves the app open on the profile page after the
test finishes. The feature checks create persistent test posts in Supabase
with unique titles beginning `CampusMate test`; they remain in their
sold-out, resolved, and solved states after the test.
