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
import '../../../front_desk/presentation/bloc/front_desk_state.dart';

enum AppointmentDateFilter { all, today, upcoming, past, history }

class AppointmentListPage extends StatefulWidget {
  final UserTier tier;
  final List<String> filterStatus;
  final List<String> filterPaymentStatus;
  final bool sortAscending;
  final String title;
  final bool showBackButton;
  final bool sliverMode;
  final VoidCallback? onNavigateToQueue;
  final AppointmentDateFilter dateFilter;

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
    this.dateFilter = AppointmentDateFilter.all,
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
      child: MultiBlocListener(
        listeners: [
          BlocListener<FrontDeskBloc, FrontDeskState>(
            listener: (context, state) {
              if (state is FrontDeskSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh list if needed (though it should already be handled by Bloc)
              } else if (state is FrontDeskError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
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

    // Date Filter logic
    if (widget.dateFilter != AppointmentDateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      appointments = appointments.where((a) {
        final wibDate = a.date.toWib();
        final aDate = DateTime(wibDate.year, wibDate.month, wibDate.day);

        final isFinalized = [
          'COMPLETED',
          'CANCELLED',
          'PAID',
        ].contains(a.status.toUpperCase());

        if (widget.dateFilter == AppointmentDateFilter.today) {
          return aDate.isAtSameMomentAs(today);
        } else if (widget.dateFilter == AppointmentDateFilter.upcoming) {
          // Show Today, Future dates, AND any past dates that are not yet finalized
          return aDate.isAtSameMomentAs(today) ||
              aDate.isAfter(today) ||
              (aDate.isBefore(today) && !isFinalized);
        } else if (widget.dateFilter == AppointmentDateFilter.past) {
          return aDate.isBefore(today);
        } else if (widget.dateFilter == AppointmentDateFilter.history) {
          // History shows:
          // 1. Past appointments that are already finalized
          // 2. OR any finalized appointment from today/future
          // However, to avoid confusion, let's keep it simple:
          // Show anything that is either Past OR Finalized
          return aDate.isBefore(today) || isFinalized;
        }
        return true;
      }).toList();
    }

    appointments.sort((a, b) {
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
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final appt = appointments[index];
            return _buildAppointmentCard(appt, index);
          }, childCount: appointments.length),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return _buildAppointmentCard(appt, index);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentEntity appt, int index) {
    final wibDate = appt.date.toWib();
    final patientName =
        appt.patientDetail?['patient_name']?.toString() ??
        appt.patientDetail?['name']?.toString() ??
        '-';

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8F1FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${DateFormat('dd').format(wibDate)} ${DateFormat('MMM').format(wibDate)}',
                style: const TextStyle(
                  color: Color(0xFF2859E2),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Service type
            Text(
              appt.serviceName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF1A1D1E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Patient name
            Text(
              patientName,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Status badge
            _buildStatusBadge(appt.status),
          ],
        ),
      ),
    );

    // Animate only first 10 items
    if (index < 10) {
      return FadeInUp(
        delay: Duration(milliseconds: index * 50),
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

  String _formatStatus(String status) {
    if (status.isEmpty) return status;
    final words = status.toLowerCase().split(' ');
    final capitalized = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    });
    return capitalized.join(' ');
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
      case 'SCHEDULED':
      case 'CONFIRMED':
        color = Colors.blue;
        break;
      case 'ARRIVED':
        color = Colors.teal;
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
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
