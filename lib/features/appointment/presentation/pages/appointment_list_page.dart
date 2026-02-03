import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../blocs/appointment_bloc.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../../core/utils/date_utils.dart'; // Ext
import 'appointment_detail_page.dart';
import '../../../../core/presentation/components/empty_state_widget.dart';

class AppointmentListPage extends StatefulWidget {
  final UserTier tier;
  final List<String> filterStatus;
  final List<String> filterPaymentStatus;
  final bool sortAscending;
  final String title;
  final bool showBackButton;
  final bool sliverMode;

  const AppointmentListPage({
    super.key,
    this.tier = UserTier.care,
    this.filterStatus = const [],
    this.filterPaymentStatus = const [],
    this.sortAscending = false,
    this.title = 'My Appointments',
    this.showBackButton = true,
    this.sliverMode = false,
  });

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(GetAppointmentsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getTheme(widget.tier);

    final content = BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return widget.sliverMode
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Center(child: CircularProgressIndicator());
        }
        if (state is AppointmentError) {
          final isSessionError = state.message.contains('401');
          final emptyWidget = EmptyStateWidget(
            message: isSessionError
                ? 'Session Expired'
                : 'Oops! Something went wrong',
            lottieAsset: 'assets/animations/empty_box.json',
            isCentered: true,
            onRetry: () =>
                context.read<AppointmentBloc>().add(GetAppointmentsRequested()),
          );

          return widget.sliverMode
              ? SliverFillRemaining(hasScrollBody: false, child: emptyWidget)
              : emptyWidget;
        }

        if (state is AppointmentsLoaded) {
          return _buildContent(state.appointments);
        }
        return widget.sliverMode
            ? const SliverFillRemaining(
                child: Center(child: Text('Loading appointments...')),
              )
            : const Center(child: Text('Loading appointments...'));
      },
    );

    if (widget.sliverMode) {
      return content;
    }

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          automaticallyImplyLeading: false,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: content,
      ),
    );
  }

  Widget _buildContent(List<AppointmentEntity> allAppointments) {
    // Filter and Sort
    var appointments = List<AppointmentEntity>.from(allAppointments);

    if (widget.filterStatus.isNotEmpty) {
      appointments = appointments
          .where((a) => widget.filterStatus.contains(a.status.toUpperCase()))
          .toList();
    }

    if (widget.filterPaymentStatus.isNotEmpty) {
      appointments = appointments
          .where(
            (a) => widget.filterPaymentStatus.contains(
              a.paymentStatus?.toUpperCase(),
            ),
          )
          .toList();
    }

    appointments.sort((a, b) {
      return widget.sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    if (appointments.isEmpty) {
      final emptyWidget = EmptyStateWidget(
        message: 'No appointments found',
        lottieAsset: 'assets/animations/empty_box.json',
      );
      return widget.sliverMode
          ? SliverFillRemaining(hasScrollBody: false, child: emptyWidget)
          : emptyWidget;
    }

    if (widget.sliverMode) {
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 120,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final appt = appointments[index];
            return _buildAppointmentCard(appt, index);
          }, childCount: appointments.length),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return _buildAppointmentCard(appt, index);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentEntity appt, int index) {
    // Keep it simple for appointments - Service Name is title
    String displayTitle = appt.serviceName;

    final cardWidget = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailPage(appointment: appt),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: const Color(0xFFE8F1FF)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Box (Clinical Style)
                Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2859E2).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(appt.date.toWib()),
                        style: const TextStyle(
                          color: Color(0xFF2859E2),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM').format(appt.date.toWib()),
                        style: const TextStyle(
                          color: Color(0xFF2859E2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SERVICE',
                              style: TextStyle(
                                color: Color(0xFF2859E2),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(appt.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1D1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${appt.doctorTitlePrefix ?? ''} ${appt.doctorName} ${appt.doctorTitleSuffix ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time
                Row(
                  children: [
                    _getTimeIcon(appt.date.toWib()),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('HH:mm').format(appt.date.toWib()),
                      style: const TextStyle(
                        color: Color(0xFF2859E2),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      ' WIB',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                // Link
                Row(
                  children: const [
                    Text(
                      'View Detail',
                      style: TextStyle(
                        color: Color(0xFF2859E2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF2859E2),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Animate only first 5 items for better performance
    if (index < 5) {
      return FadeInUp(
        delay: Duration(milliseconds: index * 100),
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  String getTodayOrDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    String timeStr = '${DateFormat('HH:mm').format(date)} WIB';

    if (aDate == today) {
      return 'Today, $timeStr';
    } else {
      return '${DateFormat('dd MMM').format(date)}, $timeStr';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _getTimeIcon(DateTime date) {
    final hour = date.hour;
    IconData icon;
    Color color;

    if (hour >= 5 && hour < 11) {
      icon = Icons.wb_sunny_outlined; // Pagi
      color = Colors.orange;
    } else if (hour >= 11 && hour <= 15) {
      icon = Icons.wb_sunny_rounded; // Siang
      color = Colors.amber;
    } else if (hour > 15 && hour <= 18) {
      icon = Icons.wb_twilight_rounded; // Sore
      color = Colors.deepOrange;
    } else {
      icon = Icons.nights_stay_rounded; // Malam
      color = Colors.indigo;
    }

    return Icon(icon, size: 16, color: color);
  }
}
