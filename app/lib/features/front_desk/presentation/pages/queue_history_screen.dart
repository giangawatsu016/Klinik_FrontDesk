import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/queue_entry_model.dart';
import '../../../../core/utils/age_utils.dart';

class QueueHistoryScreen extends StatefulWidget {
  const QueueHistoryScreen({super.key});

  @override
  State<QueueHistoryScreen> createState() => _QueueHistoryScreenState();
}

class _QueueHistoryScreenState extends State<QueueHistoryScreen> {
  int _historyPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<FrontDeskBloc>().add(const LoadQueueHistoryEvent(page: 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Queue History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.read<FrontDeskBloc>().add(
              LoadQueueHistoryEvent(page: _historyPage),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<FrontDeskBloc, FrontDeskState>(
        buildWhen: (prev, curr) =>
            curr is FrontDeskLoaded || curr is FrontDeskLoading,
        builder: (context, state) {
          if (state is FrontDeskLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2859E2)),
            );
          }

          List<QueueEntryModel> history = [];
          int total = 0;
          if (state is FrontDeskLoaded) {
            history = state.historyEntries;
            total = state.historyTotal;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Time History',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        total.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Center(
                      child: Text(
                        'No completed entries yet.',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final date = entry.creation != null
                          ? DateFormat(
                              'dd MMM yyyy\nHH:mm',
                            ).format(DateTime.parse(entry.creation!).toLocal())
                          : '-';

                      return GestureDetector(
                        onTap: () => _showQueueDetailDialog(entry),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[200]!),
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
                              // Queue Number Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.queueNumber ?? '-',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Patient Name
                              Text(
                                entry.patientName ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Type
                              Text(
                                entry.queueType,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // Date
                              Text(
                                date,
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                // Pagination Controls
                if (total > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _historyPage > 0
                              ? () {
                                  setState(() => _historyPage--);
                                  context.read<FrontDeskBloc>().add(
                                    LoadQueueHistoryEvent(page: _historyPage),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: Text(
                            'Prev',
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2859E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Page ${_historyPage + 1} of ${((total - 1) ~/ 20) + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: (_historyPage + 1) * 20 < total
                              ? () {
                                  setState(() => _historyPage++);
                                  context.read<FrontDeskBloc>().add(
                                    LoadQueueHistoryEvent(page: _historyPage),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right, size: 18),
                          label: Text(
                            'Next',
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2859E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQueueDetailDialog(QueueEntryModel entry) {
    final statusInfo = _getStatusInfo(entry.status);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with queue number
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusInfo.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      entry.queueNumber ?? '-',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusInfo.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status chip
                _buildStatusChip(entry.status),
                const SizedBox(height: 20),

                // Details
                _buildDetailRow('Patient Name', entry.patientName ?? 'Unknown'),
                if (entry.patientBirthDate != null)
                  _buildDetailRow(
                    'Patient Age',
                    AgeUtils.formatAge(entry.patientBirthDate!),
                  ),
                _buildDetailRow('Queue Type', entry.queueType),

                _buildDetailRow(
                  'Doctor',
                  entry.practitionerName ?? entry.practitioner ?? ' - ',
                ),
                _buildDetailRow('Polyclinic', entry.polyclinic ?? ' - '),

                _buildDetailRow(
                  'Issuer / Method',
                  entry.paymentMethod ?? ' - ',
                  isHighlighted: false,
                ),

                _buildDetailRow(
                  'Called At',
                  entry.calledAt != null
                      ? DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(DateTime.parse(entry.calledAt!).toLocal())
                      : ' - ',
                ),

                _buildDetailRow(
                  'Created At',
                  entry.creation != null
                      ? DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(DateTime.parse(entry.creation!).toLocal())
                      : ' - ',
                ),

                _buildDetailRow(
                  'Priority',
                  entry.isPriority == 1 ? 'Yes' : 'No',
                  isHighlighted: entry.isPriority == 1,
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isHighlighted ? Colors.red : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo.label,
            style: GoogleFonts.outfit(
              color: statusInfo.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status) {
      case 'Waiting':
        return (
          label: 'Waiting',
          color: const Color.fromARGB(255, 40, 89, 255),
        );
      case 'Called':
        return (label: 'In Consultation', color: const Color(0xFF2859E2));
      case 'Completed':
        return (label: 'Completed', color: Colors.green);
      default:
        return (label: status, color: Colors.grey);
    }
  }
}
