import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class QueueMonitorScreen extends StatefulWidget {
  final ApiService apiService;
  const QueueMonitorScreen({super.key, required this.apiService});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  List<QueueItem> _queue = [];
  Timer? _timer;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchQueue();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) => _fetchQueue());
  }

  void _initTts() async {
    await flutterTts.setLanguage("id-ID");
    await flutterTts.setSpeechRate(0.9);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchQueue() async {
    try {
      final queue = await widget.apiService.getQueue();
      debugPrint("QUEUE DEBUG: Fetched ${queue.length} items");
      setState(() {
        _queue = queue;
      });
    } catch (e) {
      debugPrint("QUEUE DEBUG: Error fetching queue: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final docQueue = _queue.where((i) => i.queueType == 'Doctor').toList();
    final polyQueue = _queue.where((i) => i.queueType == 'Polyclinic').toList();

    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(child: _buildQueuePanel("Doctor Queue", docQueue, "Doctor")),
          VerticalDivider(
            width: 40,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildQueuePanel(
              "Polyclinic Queue",
              polyQueue,
              "Polyclinic",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuePanel(String title, List<QueueItem> items, String type) {
    // Logic for Buttons
    // Calling: Are there waiting patients?
    final hasWaiting = items.any((i) => i.status == 'Waiting');
    // Completing: Is there someone in consultation?
    final currentConsult = items
        .where((i) => i.status == 'In Consultation')
        .firstOrNull;
    final canComplete = currentConsult != null;

    final colorTheme = type == 'Doctor' ? Colors.blue : Colors.teal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            color: colorTheme.shade900,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),

        // Controls
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasWaiting && !canComplete
                    ? () => _processCall(items)
                    : null,
                icon: Icon(LucideIcons.megaphone, size: 20),
                label: Text("Call Patient"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canComplete
                    ? () => _processComplete(currentConsult)
                    : null,
                icon: Icon(LucideIcons.checkCircle, size: 20),
                label: Text("Completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),

        // Status Monitor
        if (canComplete)
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Current Patient",
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  currentConsult.numberQueue,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.green[900],
                    fontFamily: 'Inter',
                    letterSpacing: -1,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Status: ${currentConsult.status}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "${currentConsult.patient?.firstName} ${currentConsult.patient?.lastName}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            height: 148, // Match approx height of active card for symmetry
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.armchair,
                    size: 32,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Waiting for Patient",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: items.where((i) => i.status == 'Waiting').length,
              separatorBuilder: (ctx, i) =>
                  Divider(color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final waitingItems = items
                    .where((i) => i.status == 'Waiting')
                    .toList();
                final item = waitingItems[index];

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("Queue Details: ${item.numberQueue}"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient: ${item.patient?.firstName ?? '-'} ${item.patient?.lastName ?? ''}",
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Doctor: ${item.doctor?.gelarDepan ?? ''} ${item.doctor?.namaDokter ?? '-'}",
                            ),
                            SizedBox(height: 8),
                            Text("Polyclinic: ${item.polyclinic ?? '-'}"),
                            SizedBox(height: 8),
                            Text("Status: ${item.status}"),
                            SizedBox(height: 8),
                            Text(
                              "Created: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(item.appointmentTime).add(Duration(hours: 7)))}",
                            ),
                            if (item.isPriority)
                              Text(
                                "Priority: YES",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.status == 'Waiting'
                          ? colorTheme.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                item.numberQueue,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorTheme.shade900,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              item.status,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        if (item.isPriority)
                          Icon(LucideIcons.star, color: Colors.amber, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _processCall(List<QueueItem> items) async {
    // Find first waiting (sorted logic handled by backend, so first in list that is 'Waiting')
    // Actually backend returns sorted list.
    final nextPatient = items.where((i) => i.status == 'Waiting').firstOrNull;
    if (nextPatient != null) {
      await widget.apiService.updateQueueStatus(
        nextPatient.id,
        "In Consultation",
      );

      _fetchQueue();

      // Speak Announcement
      // Reverted Logic: "Nomor Antrian [No] Silahkan Menuju [Poli]"
      String queueNo = nextPatient.numberQueue;
      // Spacing for better pronunciation (e.g. A-001 -> A Kosong Kosong Satu)
      // For now, simple reading.
      String destination = nextPatient.queueType == 'Doctor'
          ? "Ruang Dokter"
          : "Poliklinik";

      await flutterTts.speak(
        "Nomor Antrian $queueNo, Silahkan Menuju $destination",
      );
    }
  }

  void _processComplete(QueueItem item) async {
    await widget.apiService.updateQueueStatus(item.id, "Completed");
    _fetchQueue();
  }
}
