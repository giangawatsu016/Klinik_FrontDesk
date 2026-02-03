import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../blocs/notification_cubit.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/presentation/components/empty_state_widget.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().getNotifications(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      context.read<NotificationCubit>().markAllAsRead(),
                  child: Text(
                    'Read All',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2859E2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: GoogleFonts.outfit(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<NotificationCubit>()
                        .getNotifications(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return EmptyStateWidget(
                message: "No notifications yet",
                lottieAsset: 'assets/animations/empty_box.json',
                isCentered: true,
              );
            }

            return RefreshIndicator(
              onRefresh: () => context
                  .read<NotificationCubit>()
                  .getNotifications(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount:
                    state.notifications.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }

                  final notification = state.notifications[index];
                  return _buildNotificationTile(notification);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationEntity notification) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead
            ? Border.all(color: Colors.grey[200]!)
            : Border.all(color: const Color(0xFF2859E2).withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.outfit(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2859E2),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'PAYMENT_REMINDER':
        return Icons.payment_rounded;
      case 'SCHEDULE_REMINDER':
        return Icons.schedule_rounded;
      case 'CONSULTATION_COMPLETED':
        return Icons.check_circle_outline_rounded;
      case 'NEW_APPOINTMENT':
        return Icons.calendar_today_rounded;
      case 'TEST_NOTIFICATION':
        return Icons.notifications_active_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'PAYMENT_REMINDER':
        return Colors.orange;
      case 'SCHEDULE_REMINDER':
        return const Color(0xFF2859E2);
      case 'CONSULTATION_COMPLETED':
        return Colors.green;
      case 'NEW_APPOINTMENT':
        return Colors.purple;
      case 'TEST_NOTIFICATION':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationCubit>().markAsRead(notification.id);
    }

    // Navigate based on type
    final appointmentId = notification.data?['appointmentId'];
    if (appointmentId != null) {
      Navigator.pop(context); // Close notification list
      NavigationService().navigateTo(
        '/home',
        arguments: {
          'tab': 1, // Schedule tab
          'appointmentId': int.tryParse(appointmentId.toString()),
        },
      );
    }
  }
}
