# Contractor Mobile

Standalone Flutter app for contractors, built with `Riverpod`, `Supabase`, `GoRouter`, and a mobile-first UI focused on timer speed and weekly clarity.

## Included flows

- Supabase email/password sign-in for invited users
- Project and task selection
- Live timer start and stop against Supabase Edge Functions
- Manual time entry screen
- Weekly timesheet review and submit
- Gemini assistant prompt screen
- Polished dashboard with motion and status cards

## Environment

Copy `.env.example` to `.env` and fill in:

```env
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
DEFAULT_ORGANIZATION_ID=
```

## Local development

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

## Verification

```bash
flutter analyze
flutter test
```
