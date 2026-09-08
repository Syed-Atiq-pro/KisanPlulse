# AgriSense

AgriSense is an AI-powered smart farming platform designed around real farm workflows: crop health, weather intelligence, irrigation, farm management, finance, markets, services and personalized AI assistance.

## Phase 1 — Foundation

Current implementation:

- Flutter application architecture
- Riverpod state-management dependency
- GoRouter navigation
- Material 3 design system
- Supabase Flutter integration
- Build-time Supabase credentials
- Email/password authentication screen
- Farmer dashboard foundation
- PostgreSQL profile schema + RLS migration
- Feature-based project structure

## Architecture

```text
View -> ViewModel -> Repository -> Service -> Supabase/API
```

Feature boundaries are kept separate so later modules can be added without turning the app into one large codebase.

## Run locally

Install Flutter, then:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Use only the Supabase publishable key in the Flutter client. Never put a service-role/secret key in the app.

## Roadmap

1. Foundation and authentication
2. Farms, fields and crop management
3. Weather and location intelligence
4. AI crop disease detection
5. AI farming assistant
6. Irrigation and soil intelligence
7. Finance and market intelligence
8. Marketplace and services
9. Notifications and multilingual voice
10. IoT integration
11. Analytics and advanced prediction models
12. Admin platform, security hardening, testing and production deployment
