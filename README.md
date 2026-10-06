# CampusMate

CampusMate is an Android Flutter utility app for UIU students. It uses Supabase Auth, Postgres and private Storage for accounts and profile images. The Android application ID is `com.binarybrains.campusmate`.

## Run the app on Windows during development

1. Install Flutter and Visual Studio Build Tools with the Desktop development with C++ workload.
2. From this folder, run `flutter pub get` and then `flutter run -d windows`.
3. The CampusMate2 Supabase project URL and publishable key are set as development defaults in `lib/main.dart`. Override them with `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...` for another environment. The publishable key is intended for a client app; never put a Supabase secret or service-role key in the app.

When the app is ready for release, build the Android APK with `flutter build apk --release`.

## Supabase setup

The connected Supabase project is `CampusMate2` (`umgzplbqrkpyocvcubtf`) in Singapore (`ap-southeast-1`). The schema and current tuition dates are recorded in `supabase/migrations/20261004142311_campusmate_initial_schema.sql` and `supabase/migrations/20261004144556_set_tuition_installment_deadlines.sql`:

- `campusmate_profiles`: one profile per Auth user, unique student ID, avatar storage path, owner-only access, and automatic profile creation when an account signs up.
- `tuition_installments`: three rows, one per installment. Authenticated users can read deadlines; client writes are disabled so dates can be managed in the Supabase dashboard.
- `notifications` and `push_devices`: owner-only notification inbox and FCM token storage, ready for the notification feature.
- `profile-avatars`: private Storage bucket with per-user upload/read policies. The client displays images with short-lived signed URLs.

The currently supplied UIU tuition deadlines are:

```sql
update public.tuition_installments set due_on = date '2026-08-11' where id = 1;
update public.tuition_installments set due_on = date '2026-09-15' where id = 2;
update public.tuition_installments set due_on = date '2026-10-06' where id = 3;
```

The app shows the third installment as the upcoming deadline on October 4, 2026.

Custom SMTP and the six-digit Confirm Signup OTP template have been configured by the project owner. Keep email confirmation enabled in Supabase Auth. The app only creates a session after the signup OTP is verified and blocks unconfirmed users at password sign-in.

## Push notifications

Push notifications are deferred. The app currently uses Supabase only; when push work begins, we can add a delivery provider and keep its credentials out of the Flutter app.

## Current screens

- First-run welcome, email/password sign-in, signup, and six-digit email verification with a resend timer.
- Dashboard with upcoming tuition deadline, campus-life and academic feature tiles, notification placeholder, and bottom navigation.
- Empty chats state and profile editing/logout.

The feature tiles, tuition calculator, and notification button are UI placeholders for the next implementation phase.
