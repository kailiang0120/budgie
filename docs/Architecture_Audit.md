# Budgie Architecture & Structure Audit

Date: 2025-08-15

## Summary
- Created by automated audit to highlight misplacements and redundancies.
- Non-breaking refactors proposed to simplify maintenance without changing behavior.

## Issues Found

- Duplicate global navigatorKey defined in multiple places.
- Route mapping duplicated across `MaterialApp.routes`, `AppRouter.generateRoute`, and `NavigationHelper`.
- Raw `'/add_expense'` route literal used inconsistently.
- Domain layer imports infrastructure and data models (layer violation).
- Global `fabRouteObserver` defined inside a widget file.
- `NotificationService` (infra) imports `main.dart` and triggers navigation (infra→UI coupling).
- Documentation states TFLite removed, but code and assets still use it (architecture drift).

## Actions Applied (Non-breaking)
- Introduced `core/router/navigation_keys.dart` as a single source for `navigatorKey` and `scaffoldMessengerKey`.
- Updated imports to use the centralized keys; removed duplicate key in `AppRouter` and `main.dart`.
- Added `Routes.addExpense` and replaced raw `'/add_expense'` usage.
- Introduced `core/router/route_observers.dart` and imported in `main.dart`; `AnimatedFloatButton` now uses it.
- Kept runtime behavior identical; no functional changes to routing targets or transitions.

## Recommended Next Steps (Choose One for TFLite)
- API-only: remove `tflite_flutter`, TFLite assets, and hybrid code; align docs.
- Hybrid: update docs to reflect hybrid; keep assets and code.

## Additional Refactor Suggestions (Future)
- Introduce domain ports for API client, connectivity, settings, currency; move infra dependencies out of domain services.
- Remove data fetching from `NavigationHelper`; pass data via arguments or `FutureBuilder` inside pages.
- Consider consolidating to a single routing mechanism (`onGenerateRoute`).
