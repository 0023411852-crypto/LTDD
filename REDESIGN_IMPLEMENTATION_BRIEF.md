# UI Redesign Implementation Brief — Minimal

## Non-negotiable constraints
- This is an Android Flutter application. Build every screen with Flutter/Dart widgets and Material 3; do not introduce HTML, CSS, React, or a separate web admin.
- Preserve the Firebase project `linh-4782e`. Do not replace, regenerate, or modify Firebase project identifiers, API configuration, Android application ID, SHA configuration, or existing auth providers as part of visual redesign.
- Do not delete, stub out, rename away, or silently disable any existing feature, provider, route, API call, model, or user flow. If a feature is currently incomplete, preserve it and mark it as incomplete rather than pretending it works.
- Keep the current Provider state-management approach unless a migration is explicitly approved.
- Before changing a file, inspect its callers and current behavior. Prefer incremental refactoring and shared widgets.
- Do not hardcode API data, weather forecasts, article counts, views, user counts, admin metrics, or notification delivery results as real data.

## Visual direction
Minimal editorial: quiet, readable, spacious, content-first. Avoid gradients, heavy shadows, excessive rounded containers, decorative icons, and dense dashboards. Use white/near-white surfaces, restrained blue accents, neutral text, and clear typography. Admin may use a restrained teal accent while retaining the same design language.

## Design tokens
See `lib/utils/app_colors.dart` and `lib/core/theme/app_theme.dart`. Use `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, and shared tokens. Do not add arbitrary hex colors inside feature screens. Spacing scale: 4, 8, 12, 16, 20, 24, 32. Screen horizontal padding: 16dp (24dp on wider layouts). Minimum touch target: 48dp. Cards: 16–18dp radius, subtle border, no heavy elevation. Use Roboto/system font. Support light and dark themes.

## Screen scope — preserve all
### Authentication / entry
- Splash: wait for Firebase auth initialization; route correctly to signed-in or signed-out flow.
- Login: email/password, Google, password reset, validation, loading and errors. Keep Facebook/Apple affordances only if clearly marked unavailable until configured; do not fake successful login.
- Register: name, email, password, confirmation, terms validation and Firebase registration.

### USER
- Home: featured article, categories, current weather summary, latest stories, search entry.
- News list: categories, search, refresh, pagination/load-more, loading/error/empty.
- Article detail: hero image fallback, source, metadata, content/WebView, share, favorite, open original source.
- Weather: current conditions, city selection, hourly and 7-day forecast from provider/API; never hardcode forecast values.
- Search: query, filters, history, empty/loading/error and result navigation.
- Favorites: persisted favorites, remove/save, empty state.
- Profile: Firebase account data, profile actions, sign-out; Admin entry only after trusted role check.
- Settings: theme and every existing setting must remain functional or be honestly marked not yet available.
- Notifications: preserve list/read state; distinguish local/demo items from server-delivered notifications.

### ADMIN
- Admin entry is shown only after trusted role resolution. Enforce authorization in Firebase Realtime Database Security Rules (or trusted backend), not only in Flutter UI.
- Dashboard, news CRUD/moderation, category CRUD, user management, notification composition/send, reports/analytics, admin settings.
- Split the current large admin screen into focused widgets/screens while retaining all current actions and state flows.
- Never present local in-memory/demo values as production analytics or successful remote operations.

## Required implementation sequence
1. Audit and record every existing action, provider method, route, model and API call. Create a feature-preservation checklist before editing.
2. Apply the shared theme and tokens. Remove duplicated hardcoded styling only after replacing it with equivalent theme styling.
3. Build shared components: section heading, news card, featured article, category chip, weather summary/forecast row, search field, empty/error/loading states, form field, admin metric/list row.
4. Refactor USER screens in this order: Home, News list, Article detail, Weather, Search, Favorites, Profile, Settings, Notifications, Login/Register, Splash.
5. Refactor ADMIN into a shell plus focused feature sections.
6. Implement/verify role resolution and server-side authorization without changing Firebase project identity.
7. For each phase: `dart format .`, `flutter analyze`, `flutter test`, build/run Android. Fix regressions before proceeding.
8. Compare screenshots at a common Android viewport (e.g.  Pixel 7 /  Android 15, 393x852 logical px), plus a smaller device and dark mode. Check keyboard, safe areas, overflow and text scaling.

## Acceptance criteria
- All features and navigation flows present before redesign still work after redesign.
- No screen has overflow, clipped buttons, hidden keyboard fields, or unreadable contrast.
- All screens share typography, spacing, card, button, input and navigation rules.
- Data shown as live/real comes from the existing provider/service/backend; demo content is explicitly labeled.
- USER cannot access ADMIN through direct route manipulation or database requests.
- Firebase project remains exactly `linh-4782e`.
- `flutter analyze` and tests pass, or all remaining failures are listed with exact file/line and reason.
- Provide before/after screenshots and a feature-preservation checklist.

## Change safety
Do not perform a repository-wide rewrite in one pass. Make small commits or checkpoints. Keep a copy of the original implementation until the redesigned screen passes its acceptance checks. Never delete legacy files merely because they appear unused; verify imports/routes and explain any proposed cleanup first.
