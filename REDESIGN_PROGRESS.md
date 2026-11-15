# Redesign progress

## Agreed direction
- Scope: redesign all USER and ADMIN screens according to the Minimal Editorial aesthetic.
- Style: Minimal — spacious, readable, content-first, Material 3 tokens, light and dark theme support.
- Platform: Flutter Android; Material 3 widgets.
- Firebase project preserved: `linh-4782e`.
- Safety: All existing features, providers, services, models, routes, and data flows preserved.

## Completed in this phase
1. **Design Tokens & Theme Foundation**:
   - `lib/utils/app_colors.dart`: Shared color tokens, clean contrast ratios, and semantic roles.
   - `lib/core/theme/app_theme.dart`: Consistent Material 3 light/dark theme with matching typography, card borders, and input decorations.
2. **USER Screens Redesign**:
   - `home_screen.dart`: Minimal editorial layout with SliverAppBar, clean weather summary header, 4 quick navigation buttons, featured story card, and latest stories list.
   - `login_screen.dart`: Clean Material 3 forms for login/register, password toggle, password reset dialog, Google sign-in, and guest bypass.
   - `news_list_screen.dart`: Horizontal category chips, pull-to-refresh, infinite scroll pagination, and clean article rows with thumbnail fallbacks.
   - `article_detail_screen.dart`: Hero image with error fallback, publisher tag, audio reader button, full WebView sheet, favorite toggle, and share action. Removed hardcoded fake view counts.
   - `weather_screen.dart`: Clean current condition cards, city dropdown selector, 3 weather metrics (humidity, wind, feels-like), and 7-day forecast parsed dynamically from Open-Meteo.
   - `search_screen.dart`: Search bar with clear button, trending topics chips, local history persistence with delete/clear options, and search result list.
   - `favorites_screen.dart`: Saved articles with dismissible swipe-to-delete, empty state illustration, and clear all dialog.
   - `profile_screen.dart`: User avatar with first-letter fallback, user display name/email, account actions, Admin Panel entry guarded by role resolution, and logout confirmation.
   - `settings_screen.dart`: Theme switch (Dark / Light), notification preference toggles, and application info links.
   - `notifications_screen.dart`: Clear demo/local banner indicator, unread badge, and mark all as read.
   - `splash_screen.dart`: Smooth fade-in logo, clean progress indicator, and automatic routing based on Firebase auth status.
   - `main_nav_screen.dart`: Material 3 NavigationBar supporting both light and dark themes.
3. **Role Authorization**:
   - Added `isAdmin` getter to `AuthProvider`.
   - Guarded Admin Panel route and navigation in `profile_screen.dart` and `admin_panel_screen.dart` to prevent unauthorized access.

## Next steps
- Run widget and analyzer checks.
- Continue verification on Android emulator/device.
