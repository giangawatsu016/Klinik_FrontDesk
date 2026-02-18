import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/idle_detector.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/profile/presentation/pages/profile_page.dart' as profile;
import 'features/profile/presentation/blocs/profile_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/blocs/home_cubit.dart';
import 'features/home/presentation/blocs/search_cubit.dart';
import 'features/appointment/presentation/blocs/appointment_bloc.dart';
import 'features/appointment/presentation/blocs/medical_record_bloc.dart';
import 'features/payment/presentation/pages/payment_book_page.dart';
import 'features/payment/presentation/blocs/payment_cubit.dart';
import 'features/notification/presentation/blocs/notification_cubit.dart';
import 'features/front_desk/presentation/bloc/front_desk_bloc.dart';
import 'features/front_desk/presentation/pages/registration_screen.dart';
import 'features/front_desk/presentation/pages/queue_monitor_screen.dart';
import 'features/front_desk/presentation/pages/appointment_list_screen.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Run initializations in parallel to speed up startup
    await Future.wait([
      dotenv.load(fileName: "assets/env"),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);

    await di.init();

    // Request notification permission without blocking runApp
    // ignore: unawaited_futures
    NotificationService().requestPermissionOnly();

    runApp(const HomecareApp());
  } catch (e, stackTrace) {
    AppLogger.error('CRITICAL STARTUP ERROR', e, stackTrace);
    // Use a minimal fallback app to show error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup Error: $e', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );
  }
}

class HomecareApp extends StatelessWidget {
  const HomecareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus())),
        BlocProvider(create: (_) => di.sl<HomeCubit>()),
        BlocProvider(create: (_) => di.sl<SearchCubit>()),
        BlocProvider(create: (_) => di.sl<ProfileCubit>()),
        BlocProvider(create: (_) => di.sl<AppointmentBloc>()),
        BlocProvider(create: (_) => di.sl<MedicalRecordBloc>()),
        BlocProvider(create: (_) => di.sl<PaymentCubit>()),
        BlocProvider(create: (_) => di.sl<NotificationCubit>()),
        BlocProvider(create: (_) => di.sl<FrontDeskBloc>()),
      ],
      // Fallback to MaterialApp to rule out AdaptiveApp issues
      child: IdleDetector(
        child: MaterialApp(
          title: 'Intimedicare Homecare',
          theme: AppTheme.getTheme(UserTier.care), // Force default theme
          home: const AuthWrapper(),
          navigatorKey: NavigationService().navigatorKey,
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/profile': (context) => const profile.ProfilePage(),
            '/payment-book': (context) => const PaymentBookPage(),
            '/registration': (context) => const RegistrationScreen(),
            '/queue-monitor': (context) => const QueueMonitorScreen(),
            '/appointments': (context) => const AppointmentListScreen(),
          },
        ),
      ),
    );
  }
}
// AuthWrapper remains same

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription? _notificationSubscription;
  bool _notificationInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription = NotificationService().onForegroundMessage
        .listen((message) {
          if (!mounted) return;

          final notification = message.notification;
          if (notification != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(notification.title ?? 'Notification'),
                content: Text(notification.body ?? ''),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AuthUnauthenticated) {
          _notificationInitialized = false; // Reset flag on logout
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        if (state is AuthAuthenticated) {
          // Sync notification token when user logs in
          if (!_notificationInitialized) {
            // Force sync to ensure backend gets the token after login
            NotificationService().initialize(forceSync: true);
            _notificationInitialized = true;
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const HomePage();
          }
          // Show LoginPage for Unauthenticated, Error, AND Loading states
          // This allows the button's inline loading animation to be visible
          if (state is AuthUnauthenticated ||
              state is AuthError ||
              state is AuthLoading) {
            return const LoginPage();
          }
          // Only show full-page loading for Initial state (checking stored auth)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
