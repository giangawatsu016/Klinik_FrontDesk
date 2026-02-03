import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/blocs/auth_bloc.dart';

/// Widget that detects user idle time and triggers auto-logout
class IdleDetector extends StatefulWidget {
  final Widget child;
  final Duration idleTimeout;
  final Duration warningBefore;

  const IdleDetector({
    super.key,
    required this.child,
    this.idleTimeout = const Duration(minutes: 15),
    this.warningBefore = const Duration(minutes: 1),
  });

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  Timer? _warningTimer;
  bool _warningShown = false;
  DateTime _lastActivity = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if app was in background too long
      final idleDuration = DateTime.now().difference(_lastActivity);
      if (idleDuration >= widget.idleTimeout) {
        _performLogout();
      } else {
        _resetTimer();
      }
    } else if (state == AppLifecycleState.paused) {
      _lastActivity = DateTime.now();
    }
  }

  void _resetTimer() {
    _lastActivity = DateTime.now();
    _warningShown = false;
    _idleTimer?.cancel();
    _warningTimer?.cancel();

    // Set warning timer (before timeout)
    final warningDuration = widget.idleTimeout - widget.warningBefore;
    _warningTimer = Timer(warningDuration, _showWarningDialog);

    // Set logout timer
    _idleTimer = Timer(widget.idleTimeout, _performLogout);
  }

  void _showWarningDialog() {
    if (_warningShown || !mounted) return;
    _warningShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Session Expiring'),
          ],
        ),
        content: Text(
          'Your session will expire in ${widget.warningBefore.inMinutes} minute(s) due to inactivity.\n\nClick "Stay Logged In" to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
            child: const Text('Logout Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
            },
            child: const Text('Stay Logged In'),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    if (!mounted) return;

    // Dismiss any open dialogs first
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);

    // Trigger logout
    context.read<AuthBloc>().add(LogoutRequested());
  }

  void _onUserActivity() {
    if (!_warningShown) {
      _resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only listen when user becomes authenticated
        return current is AuthAuthenticated;
      },
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _resetTimer();
        }
      },
      child: Listener(
        onPointerDown: (_) => _onUserActivity(),
        onPointerMove: (_) => _onUserActivity(),
        onPointerUp: (_) => _onUserActivity(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onUserActivity,
          onPanUpdate: (_) => _onUserActivity(),
          child: widget.child,
        ),
      ),
    );
  }
}
