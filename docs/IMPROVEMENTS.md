# Budgie Codebase Improvements (Non-functional)

This document lists targeted, low-risk improvements applied to the app to enhance maintainability, stability, and performance without changing existing functionality or design.

## Summary of Improvements

1. Provider lifecycle safety for GetIt-managed singletons
   - Switched ChangeNotifierProvider(create: ...) to ChangeNotifierProvider.value(value: ...) for classes provided by GetIt.
   - Prevents Provider from disposing GetIt’s singleton instances, avoiding subtle bugs on hot-restart or navigation.

2. Safer route argument handling in AppRouter
   - Defensive checks when reading `settings.arguments` for `editExpense` and `addExpense` routes.
   - Avoids runtime type errors if routes are invoked with unexpected arguments; falls back to a friendly error screen.

3. Documentation
   - This document created to track quality improvements and rationale.

## Notes
- No UI/UX changes.
- No business logic change.
- The DI container remains the single source of instances; Provider simply exposes them to the widget tree without taking ownership.

## Potential Next Improvements (deferred)
- Gate verbose `debugPrint` calls under `kDebugMode` to reduce release noise.
- Centralize monthId formatting into a small utility to avoid duplication across screens.
- Add lightweight widget and unit tests for routing and DI wiring.
- Consider using typed route arguments to avoid dynamic casts entirely.
