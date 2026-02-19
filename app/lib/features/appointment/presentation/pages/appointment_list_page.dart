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
import '../../../front_desk/presentation/bloc/front_desk_bloc.dart';
import '../../../front_desk/presentation/bloc/front_desk_event.dart';
import '../../../front_desk/data/models/queue_entry_model.dart';
import '../../../../core/utils/age_utils.dart';

class AppointmentListPage extends StatefulWidget {
  final UserTier tier;
  final List<String> filterStatus;
  final List<String> filterPaymentStatus;
  final bool sortAscending;
  final String title;
  final bool showBackButton;
  final bool sliverMode;
  final VoidCallback? onNavigateToQueue;

  const AppointmentListPage({
    super.key,
    this.tier = UserTier.care,
    this.filterStatus = const [],
    this.filterPaymentStatus = const [],
    this.sortAscending = false,
    this.title = 'My Appointments',
    this.showBackButton = true,
    this.sliverMode = false,
    this.onNavigateToQueue,
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
      final uppercasedFilterStatus = widget.filterStatus
          .map((s) => s.toUpperCase())
          .toList();
      appointments = appointments
          .where((a) => uppercasedFilterStatus.contains(a.status.toUpperCase()))
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
      // Checked In appointments go to the bottom of the list
      final aCheckedIn = a.status.toUpperCase() == 'CHECKED IN' ? 1 : 0;
      final bCheckedIn = b.status.toUpperCase() == 'CHECKED IN' ? 1 : 0;
      if (aCheckedIn != bCheckedIn) return aCheckedIn.compareTo(bCheckedIn);
      // Then sort by date
      return widget.sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    if (appointments.isEmpty) {
      final emptyWidget = EmptyStateWidget(
        message:
            'No appointments found (Total: ${allAppointments.length}, Filtered: ${appointments.length})',
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
                      const SizedBox(height: 4),
                      // Patient Info (Phase 2)
                      if (appt.patientDetail != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.face_rounded,
                              size: 14,
                              color: Color(0xFF2859E2),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${appt.patientDetail!['patient_name'] ?? appt.patientDetail!['name'] ?? '-'} ${AgeUtils.formatAge(appt.patientDetail!['dob']?.toString())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF2859E2),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
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
                // Add to Queue Button (only for today's pending appointments)
                if (appt.status.toUpperCase() == 'PENDING')
                  ElevatedButton.icon(
                    onPressed: _isToday(appt.date)
                        ? () => _handleCheckIn(appt)
                        : null,
                    icon: const Icon(Icons.login_rounded, size: 14),
                    label: const Text(
                      'Add to Queue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2859E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
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
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'CHECKED IN':
        color = const Color(0xFF2859E2);
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final wibDate = date.toWib();
    return wibDate.year == now.year &&
        wibDate.month == now.month &&
        wibDate.day == now.day;
  }

  void _handleCheckIn(AppointmentEntity appt) {
    // Determine the patient name from available data
    final patientName =
        appt.patientSnapshot?['fullName']?.toString() ??
        appt.patientDetail?['patient_name']?.toString() ??
        appt.doctorName; // Fallback

    final patientId = appt.patientDetail?['name']?.toString() ?? '';

    if (patientId.isEmpty) {
      // If no patient ID, we might need to register them first or use guest mode.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot check-in: Patient ID missing in appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add to queue using FrontDeskBloc
    context.read<FrontDeskBloc>().add(
      AddToQueueEvent(
        QueueEntryModel(
          patient: patientId,
          patientName: patientName,
          queueType: 'Doctor',
          practitioner: appt.doctorId?.toString(),
          practitionerName: appt.doctorName,
          appointment: appt.id,
          status: 'Waiting',
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking in $patientName for ${appt.serviceName}...'),
        backgroundColor: const Color(0xFF2859E2),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to Queue Monitor after successful check-in
    widget.onNavigateToQueue?.call();
  }
}
