import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/front_desk_bloc.dart';
import '../bloc/front_desk_event.dart';
import '../bloc/front_desk_state.dart';
import '../../data/models/queue_entry_model.dart';
import '../../../../core/utils/age_utils.dart';

class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FrontDeskBloc>().add(LoadQueueEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Queue Monitor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () =>
                context.read<FrontDeskBloc>().add(LoadQueueEvent()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<FrontDeskBloc, FrontDeskState>(
        buildWhen: (prev, curr) =>
            curr is FrontDeskLoaded || curr is FrontDeskError,
        builder: (context, state) {
          if (state is FrontDeskLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2859E2)),
            );
          } else if (state is FrontDeskLoaded) {
            final allQueue = state.activeQueue;

            // Separate active queues by type (exclude Completed)
            final activeStatuses = [
              'Waiting',
              'Consultation',
              'Pharmacy',
              'Payment',
            ];
            final doctorQueue = allQueue
                .where(
                  (e) =>
                      e.queueType == 'Doctor' &&
                      activeStatuses.contains(e.status),
                )
                .toList();
            final polyclinicQueue = allQueue
                .where(
                  (e) =>
                      e.queueType == 'Polyclinic' &&
                      activeStatuses.contains(e.status),
                )
                .toList();

            // Statistics from combined queues
            final combinedQueue = [...doctorQueue, ...polyclinicQueue];
            final waitingCount = combinedQueue
                .where((e) => e.status == 'Waiting')
                .length;
            final consultationCount = combinedQueue
                .where((e) => e.status == 'Consultation')
                .length;
            final pharmacyCount = combinedQueue
                .where((e) => e.status == 'Pharmacy')
                .length;
            final paymentCount = combinedQueue
                .where((e) => e.status == 'Payment')
                .length;

            // Daily Completed Count from today's queue data
            final dailyCompletedCount = state.todayCompleted;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 24 : 12),
                  child: Column(
                    children: [
                      // Statistics Row
                      _buildQueueStats(
                        waiting: waitingCount,
                        consultation: consultationCount,
                        pharmacy: pharmacyCount,
                        payment: paymentCount,
                        completed: dailyCompletedCount,
                        isCompact: !isWide,
                      ),
                      SizedBox(height: isWide ? 24 : 16),

                      // Responsive queues layout
                      if (isWide)
                        // Desktop: Side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildQueueColumnWithCenter(
                                'Antrian Dokter',
                                Icons.person,
                                doctorQueue,
                                const Color.fromARGB(255, 40, 89, 255),
                                isCompact: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildQueueColumnWithCenter(
                                'Antrian Polyclinic',
                                Icons.local_hospital,
                                polyclinicQueue,
                                const Color.fromARGB(255, 40, 89, 255),
                                isCompact: false,
                              ),
                            ),
                          ],
                        )
                      else
                        // Mobile: Stacked vertically
                        Column(
                          children: [
                            _buildQueueColumnWithCenter(
                              'Antrian Doctor',
                              Icons.person,
                              doctorQueue,
                              const Color(0xFF2859E2),
                              isCompact: true,
                            ),
                            const SizedBox(height: 16),
                            _buildQueueColumnWithCenter(
                              'Antrian Polyclinic',
                              Icons.local_hospital,
                              polyclinicQueue,
                              const Color.fromARGB(255, 40, 89, 255),
                              isCompact: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          } else if (state is FrontDeskError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Initialize Queue...'));
        },
      ),
    );
  }

  Widget _buildQueueStats({
    required int waiting,
    required int consultation,
    required int pharmacy,
    required int payment,
    required int completed,
    bool isCompact = false,
  }) {
    const Color statColor = Color(0xFF2859E2);
    final gap = SizedBox(width: isCompact ? 3 : 6);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Waiting',
            waiting.toString(),
            statColor,
            Icons.access_time,
            isCompact: isCompact,
          ),
        ),
        gap,
        Expanded(
          child: _buildStatCard(
            'Consultation',
            consultation.toString(),
            statColor,
            Icons.medical_services,
            isCompact: isCompact,
          ),
        ),
        gap,
        Expanded(
          child: _buildStatCard(
            'Pharmacy',
            pharmacy.toString(),
            statColor,
            Icons.local_pharmacy,
            isCompact: isCompact,
          ),
        ),
        gap,
        Expanded(
          child: _buildStatCard(
            'Payment',
            payment.toString(),
            statColor,
            Icons.payment,
            isCompact: isCompact,
          ),
        ),
        gap,
        Expanded(
          child: _buildStatCard(
            'Completed',
            completed.toString(),
            statColor,
            Icons.check_circle,
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isCompact ? 10 : 12),
          SizedBox(width: isCompact ? 3 : 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 6 : 7,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueColumnWithCenter(
    String title,
    IconData icon,
    List<QueueEntryModel> queue,
    Color accentColor, {
    bool isCompact = false,
  }) {
    // Get patients in active statuses (Consultation, Pharmacy, Payment)
    final servingPatients = queue
        .where(
          (e) =>
              e.status == 'Consultation' ||
              e.status == 'Pharmacy' ||
              e.status == 'Payment',
        )
        .toList();

    // Filter queue: Waiting only (active statuses shown in serving section)
    final waitingQueue = queue.where((e) => e.status == 'Waiting').toList();

    return Column(
      children: [
        // Currently Serving Section — shows ALL active patients
        _buildServingSection(
          title,
          icon,
          servingPatients,
          accentColor,
          waitingQueue.length,
          isCompact: isCompact,
        ),
        const SizedBox(height: 16),

        // Queue List — call patient always allowed for top entry
        _buildQueueList(
          'Waiting',
          waitingQueue,
          false, // no longer blocks calling
          accentColor,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildServingSection(
    String title,
    IconData icon,
    List<QueueEntryModel> servingPatients,
    Color accentColor,
    int waitingCount, {
    bool isCompact = false,
  }) {
    final activeCount = servingPatients.length;
    // Dynamic height: header (~36px) + each patient row (~44px) or empty state
    final contentHeight = activeCount > 0
        ? (isCompact ? 36.0 : 40.0) + (activeCount * (isCompact ? 44.0 : 50.0))
        : (isCompact ? 80.0 : 100.0);

    final container = Container(
      constraints: BoxConstraints(minHeight: isCompact ? 80 : 100),
      height: contentHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: isCompact ? 6 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
        child: Column(
          children: [
            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 6 : 8,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isCompact ? 12 : 14,
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$waitingCount w • $activeCount a',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: isCompact ? 8 : 9,
                    ),
                  ),
                ],
              ),
            ),

            // Active Patients List
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: servingPatients.isNotEmpty
                    ? ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 12,
                          vertical: isCompact ? 4 : 6,
                        ),
                        itemCount: servingPatients.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          return _buildServingPatientRow(
                            servingPatients[index],
                            isCompact: isCompact,
                          );
                        },
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: isCompact ? 14 : 18,
                            ),
                            SizedBox(width: isCompact ? 4 : 8),
                            Text(
                              'No patient',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: isCompact ? 9 : 10,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    // On mobile, use full width; on desktop use 70% centered
    if (isCompact) {
      return container;
    }
    return Center(
      child: FractionallySizedBox(widthFactor: 0.7, child: container),
    );
  }

  /// Renders a single patient row inside the serving card
  Widget _buildServingPatientRow(
    QueueEntryModel patient, {
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () => _showQueueDetailDialog(patient),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
        child: Row(
          children: [
            // Queue number
            Text(
              patient.queueNumber ?? '-',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: isCompact ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    patient.patientName ?? 'Unknown',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: isCompact ? 9 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${patient.practitioner ?? patient.polyclinic ?? ''} • ${patient.paymentMethod ?? 'N/A'}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: isCompact ? 7 : 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 10,
                vertical: isCompact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusInfo(
                  patient.status,
                ).color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
              ),
              child: Text(
                _getStatusInfo(patient.status).label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: isCompact ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(
    String sectionTitle,
    List<QueueEntryModel> queue,
    bool hasInConsultation,
    Color accentColor, {
    bool isCompact = false,
  }) {
    final isCompleted = sectionTitle == 'Completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sectionTitle (${queue.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Queue Items
          if (queue.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No patients',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                ),
              ),
            )
          else
            ...queue.asMap().entries.map(
              (e) => _buildQueueItem(
                e.value,
                hasInConsultation,
                accentColor,
                e.key == 0, // isFirstInWaiting
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    QueueEntryModel entry,
    bool hasInConsultation,
    Color accentColor,
    bool isFirstInWaiting,
  ) {
    final isPriority = entry.isPriority == 1;
    final statusInfo = _getStatusInfo(entry.status);

    // Allow calling the first waiting patient regardless of active patients
    final canCall = entry.status == 'Waiting' && isFirstInWaiting;

    return GestureDetector(
      onTap: () => _showQueueDetailDialog(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            // Queue Number
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusInfo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  entry.queueNumber ?? '-',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: statusInfo.color,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.patientName ?? 'Unknown',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPriority)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'P',
                            style: GoogleFonts.outfit(
                              color: Colors.red,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.practitioner ?? entry.polyclinic ?? '-'} • ${entry.paymentMethod ?? 'N/A'}',
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action Button
            _buildActionButton(entry, canCall, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    QueueEntryModel entry,
    bool canCall,
    Color accentColor,
  ) {
    if (entry.status == 'Completed') {
      return Icon(Icons.check_circle, color: Colors.green.shade300, size: 22);
    }

    // Show status chip for active statuses (Consultation/Pharmacy/Payment)
    if (entry.status == 'Consultation' ||
        entry.status == 'Pharmacy' ||
        entry.status == 'Payment') {
      final statusInfo = _getStatusInfo(entry.status);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusInfo.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          statusInfo.label,
          style: GoogleFonts.outfit(
            color: statusInfo.color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (entry.status == 'Waiting') {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: canCall
                ? accentColor.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.campaign,
            color: canCall ? accentColor : Colors.grey.shade400,
            size: 14,
          ),
        ),
        tooltip: canCall ? 'Call Patient' : 'Complete current patient first',
        onPressed: canCall
            ? () {
                context.read<FrontDeskBloc>().add(
                  UpdateQueueStatusEvent(entry.name!, 'Consultation'),
                );
              }
            : null,
      );
    }

    return const SizedBox.shrink();
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
                    if (entry.status == 'Waiting') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<FrontDeskBloc>().add(
                              UpdateQueueStatusEvent(
                                entry.name!,
                                'Consultation',
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.campaign, size: 18),
                          label: Text(
                            'Call',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2859E2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        return (label: 'Waiting', color: const Color(0xFFF59E0B));
      case 'Consultation':
        return (label: 'Consultation', color: const Color(0xFF2859E2));
      case 'Pharmacy':
        return (label: 'Pharmacy', color: const Color(0xFF7C3AED));
      case 'Payment':
        return (label: 'Payment', color: const Color(0xFF0D9488));
      case 'Completed':
        return (label: 'Completed', color: const Color(0xFF22C55E));
      case 'Skipped':
        return (label: 'Skipped', color: Colors.grey);
      // Legacy support
      case 'Called':
        return (label: 'Consultation', color: const Color(0xFF2859E2));
      default:
        return (label: status, color: Colors.grey);
    }
  }
}
