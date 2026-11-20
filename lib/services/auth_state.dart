import 'package:flutter/foundation.dart';

/// Global notifier for demo user session mode.
/// Kept in a dedicated service file to avoid circular module dependencies
/// between main.dart and screen widgets in Flutter Web compiled JS.
final ValueNotifier<bool> demoUserLoggedInNotifier = ValueNotifier<bool>(false);

/// Safe helper to read current demo mode state.
bool get isDemoLoggedIn => demoUserLoggedInNotifier.value;
