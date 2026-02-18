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
        message: 'No medical records found',
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
        sliver: SliverList(
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

    // Note: Non-sliver mode in this specific page implementation also needs scroll listener,
    // but the task focuses on Home Tab 2 which is sliver mode.
    // For completeness, if standalone, we would add ScrollController here.
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
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
                      // Tag & Transaction Number
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
                          const SizedBox(width: 8),
                          if (appt.transactionNumber != null)
                            Expanded(
                              child: Text(
                                appt.transactionNumber!,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (appt.transactionNumber == null) const Spacer(),
                          if (appt.status == 'COMPLETED')
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 20,
                            )
                          else
                            _buildStatusBadge(appt.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appt.serviceName,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${appt.doctorTitlePrefix ?? ''} ${appt.doctorName} ${appt.doctorTitleSuffix ?? ''}'
                                      .trim(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (appt.doctorSpecialization != null &&
                                    appt.doctorSpecialization!.isNotEmpty)
                                  Text(
                                    appt.doctorSpecialization!,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
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
                      'View Medical Record',
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
