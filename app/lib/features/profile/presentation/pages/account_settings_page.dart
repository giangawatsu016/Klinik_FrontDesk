import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/notification_service.dart';

const Color _primaryBlue = Color(0xFF2859E2);

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage>
    with WidgetsBindingObserver {
  bool _isTestingNotification = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _checkPermission();
      // If we are back from settings and permission is now authorized, ensure we sync
      if (_notificationsEnabled) {
        await NotificationService().initialize(forceSync: true);
      }
    }
  }

  Future<void> _checkPermission() async {
    final status = await NotificationService().getAuthorizationStatus();
    if (mounted) {
      setState(() {
        _notificationsEnabled = status == AuthorizationStatus.authorized;
      });
    }
  }

  Future<void> _togglePermission(bool value) async {
    if (value) {
      // User wants to enable
      await NotificationService().requestPermissionOnly();
      // If still denied, open settings
      final status = await NotificationService().getAuthorizationStatus();
      if (status != AuthorizationStatus.authorized) {
        await openAppSettings();
      } else {
        // Permission granted, NOW we must sync the token
        await NotificationService().initialize(forceSync: true);
      }
    } else {
      // User wants to disable - cannot be done programmatically, must open settings
      // We show a dialog first so it's not jarring
      bool? goSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Notifications?'),
          content: const Text(
            'System permissions cannot be changed by the app. Please disable notifications in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (goSettings == true) {
        await openAppSettings();
      } else {
        // User cancelled, ensure toggle stays ON in UI
        _checkPermission();
      }
    }
  }

  Future<void> _sendTestNotification() async {
    // ... existing implementation
    setState(() => _isTestingNotification = true);

    try {
      final dioClient = sl<DioClient>();
      await dioClient.dio.post('/notifications/test');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your notifications.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send test notification';
        if (e.toString().contains('No FCM token')) {
          errorMessage = 'Notification not set up. Please allow notifications.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingNotification = false);
    }
  }

  // ... (remove _checkNotificationStatus if it's there or keep it)
  // ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notifications Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.bell,
                          color: _primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1D1E),
                          ),
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _togglePermission,
                        activeTrackColor: _primaryBlue.withValues(alpha: 0.5),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _primaryBlue;
                          }
                          return Colors.grey;
                        }),
                      ),
                    ],
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isTestingNotification
                            ? null
                            : _sendTestNotification,
                        // ... rest of button
                        icon: _isTestingNotification
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(CupertinoIcons.bell_circle, size: 22),
                        label: Text(
                          _isTestingNotification
                              ? 'Sending...'
                              : 'Send Test Notification',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // About Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1D1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutItem('App Version', '1.0.0'),
                  _buildAboutItem('Developer', 'Intimedicare Team'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
