import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '/core/theme/app_theme.dart';
import '../blocs/medical_record_bloc.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../../../core/utils/date_utils.dart';
import 'medical_record_detail_page.dart';
import '../../../../core/presentation/components/empty_state_widget.dart';

class MedicalRecordListPage extends StatefulWidget {
  final UserTier tier;
  final List<String> filterStatus;
  final List<String> filterPaymentStatus;
  final bool sortAscending;
  final String title;
  final bool showBackButton;
  final bool sliverMode;

  const MedicalRecordListPage({
    super.key,
    this.tier = UserTier.care,
    this.filterStatus = const [],
    this.filterPaymentStatus = const [],
    this.sortAscending = false,
    this.title = 'Medical Record',
    this.showBackButton = true,
    this.sliverMode = false,
  });

  @override
  State<MedicalRecordListPage> createState() => _MedicalRecordListPageState();
}

class _MedicalRecordListPageState extends State<MedicalRecordListPage> {
  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded to preserve state across tab switches
    final bloc = context.read<MedicalRecordBloc>();
    if (bloc.state is MedicalRecordInitial) {
      bloc.add(GetMedicalRecordsRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getTheme(widget.tier);

    final content = BlocBuilder<MedicalRecordBloc, MedicalRecordState>(
      builder: (context, state) {
        if (state is MedicalRecordLoading && state is! MedicalRecordLoaded) {
          // Initial loading
          return widget.sliverMode
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Center(child: CircularProgressIndicator());
        }

        if (state is MedicalRecordError) {
          final isSessionError = state.message.contains('401');
          final emptyWidget = EmptyStateWidget(
            message: isSessionError
                ? 'Session Expired'
                : 'Oops! Something went wrong',
            lottieAsset: 'assets/animations/empty_box.json',
            isCentered: true,
            onRetry: () => context.read<MedicalRecordBloc>().add(
              GetMedicalRecordsRequested(),
            ),
          );

          return widget.sliverMode
              ? SliverFillRemaining(hasScrollBody: false, child: emptyWidget)
              : emptyWidget;
        }

        if (state is MedicalRecordLoaded) {
          return _buildContent(state.medicalRecords, state.hasReachedMax);
        }

        // Fallback
        return widget.sliverMode
            ? const SliverFillRemaining(
                child: Center(child: Text('Loading medical records...')),
              )
            : const Center(child: Text('Loading medical records...'));
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

  Widget _buildContent(
    List<AppointmentEntity> appointments,
    bool hasReachedMax,
  ) {
    if (appointments.isEmpty) {
      final emptyWidget = EmptyStateWidget(
        message: 'Belum ada Rekam Medis',
        lottieAsset: 'assets/animations/empty_box.json',
      );
      return widget.sliverMode
          ? SliverFillRemaining(hasScrollBody: false, child: emptyWidget)
          : emptyWidget;
    }

    final itemCount = hasReachedMax
        ? appointments.length
        : appointments.length + 1;

    if (widget.sliverMode) {
      return SliverPadding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 120,
        ),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= appointments.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final appt = appointments[index];
            return _buildMedicalRecordCard(appt, index);
          }, childCount: itemCount),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= appointments.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final appt = appointments[index];
        return _buildMedicalRecordCard(appt, index);
      },
    );
  }

  Widget _buildMedicalRecordCard(AppointmentEntity appt, int index) {
    final cardWidget = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicalRecordDetailPage(appointment: appt),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head: Date and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Box
                Container(
                  width: 50,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(appt.date.toWib()),
                        style: const TextStyle(
                          color: Color(0xFF2859E2),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _buildStatusBadge(appt.status),
              ],
            ),
            const SizedBox(height: 12),

            // Service Name
            Text(
              appt.serviceName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A1D1E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Doctor Info
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const Spacer(),
            const Divider(height: 16),

            // Footer: Time & Action Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time
                Row(
                  children: [
                    _getTimeIcon(appt.date.toWib()),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(appt.date.toWib()),
                      style: const TextStyle(
                        color: Color(0xFF2859E2),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Action
                Row(
                  children: const [
                    Text(
                      'Details',
                      style: TextStyle(
                        color: Color(0xFF2859E2),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
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
      icon = Icons.wb_sunny_outlined;
      color = Colors.orange;
    } else if (hour >= 11 && hour <= 15) {
      icon = Icons.wb_sunny_rounded;
      color = Colors.amber;
    } else if (hour > 15 && hour <= 18) {
      icon = Icons.wb_twilight_rounded;
      color = Colors.deepOrange;
    } else {
      icon = Icons.nights_stay_rounded;
      color = Colors.indigo;
    }

    return Icon(icon, size: 16, color: color);
  }
}
