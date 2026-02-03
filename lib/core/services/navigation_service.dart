import 'package:flutter/material.dart';

/// Global navigation service for handling navigation from anywhere in the app
/// (e.g., from notification taps)
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a named route
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  Future<dynamic>? navigateReplacementTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate to a widget directly
  Future<dynamic>? navigateToWidget(Widget widget) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => widget),
    );
  }

  /// Go back
  void goBack() {
    navigatorKey.currentState?.pop();
  }
}
