import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'dart:async';

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
    await flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchQueue() async {
    final queue = await widget.apiService.getQueue();
    setState(() {
      _queue = queue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final docQueue = _queue.where((i) => i.queueType == 'Doctor').toList();
    final polyQueue = _queue.where((i) => i.queueType == 'Polyclinic').toList();

    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _buildQueuePanel("Doctor Queue", docQueue, "Doctor")),
          VerticalDivider(width: 40, thickness: 2),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: type == 'Doctor' ? Colors.blue : Colors.teal,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),

        // Controls
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasWaiting && !canComplete
                    ? () => _processCall(items)
                    : null,
                icon: Icon(Icons.campaign),
                label: Text("Call Patient"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canComplete
                    ? () => _processComplete(currentConsult)
                    : null,
                icon: Icon(Icons.check_circle),
                label: Text("Completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Status Monitor
        if (canComplete)
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Current Patient",
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  currentConsult.numberQueue,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Status: ${currentConsult.status}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                Text(
                  "${currentConsult.patient?.firstName} ${currentConsult.patient?.lastName}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.status == 'Completed') {
                return SizedBox.shrink(); // Hide completed if they linger
              }
              if (item.status == 'In Consultation') {
                return SizedBox.shrink(); // Shown in big box above
              }

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
                child: Card(
                  color: item.status == 'Waiting'
                      ? (type == 'Doctor' ? Colors.blue[50] : Colors.teal[50])
                      : Colors.grey[200],
                  child: ListTile(
                    leading: Text(
                      item.numberQueue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(item.status),
                    trailing: item.isPriority
                        ? Icon(Icons.star, color: Colors.amber)
                        : null,
                  ),
                ),
              );
            },
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

      // Speak Announcement
      String name =
          "${nextPatient.patient?.firstName ?? ''} ${nextPatient.patient?.lastName ?? ''}"
              .trim();
      if (name.isEmpty) name = "Pasien";
      await flutterTts.speak(
        "Antrian Saudara $name Silahkan Menuju ke resepsionis",
      );

      _fetchQueue();
    }
  }

  void _processComplete(QueueItem item) async {
    await widget.apiService.updateQueueStatus(item.id, "Completed");
    _fetchQueue();
  }
}
