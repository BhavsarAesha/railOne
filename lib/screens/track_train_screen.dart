import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:railone/services/pnr_service.dart';
import 'package:railone/models/pnr.dart';

// Track trains by PNR or train number with an approximate progress bar.
class TrackTrainScreen extends StatefulWidget {
  const TrackTrainScreen({super.key});

  @override
  State<TrackTrainScreen> createState() => _TrackTrainScreenState();
}

class _TrackTrainScreenState extends State<TrackTrainScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _fs = FirestoreService();
  bool _loading = false;
  Map<String, dynamic>? _data;
  String? _error;

  Future<void> _search() async {
    final String q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _data = null; });
    try {
      Map<String, dynamic>? record;
      final bool isPnr = RegExp(r'^\d{10}$').hasMatch(q);
      if (isPnr) {
        final PnrRecord? r = await PnrService.checkPnrStatus(q);
        if (r != null) {
          record = _pnrToMap(r);
        }
      }
      record ??= await _fs.getTrainByNumber(q);
      if (record == null) {
        setState(() { _error = 'No data found for "$q"'; _loading = false; });
        return;
      }
      // Compute realistic progress if needed
      final now = DateTime.now();
      String dep = (record['departureTime'] ?? record['departure'] ?? '00:00') as String;
      String arr = (record['arrivalTime'] ?? record['arrival'] ?? '00:00') as String;
      double progress = _computeProgress(dep, arr, now);
      setState(() { _data = { ...?record, 'progress': progress }; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  double _computeProgress(String dep, String arr, DateTime now) {
    try {
      final DateFormat fmt = DateFormat('HH:mm');
      final DateTime depTime = fmt.parse(dep);
      final DateTime arrTime = fmt.parse(arr);
      DateTime todayDep = DateTime(now.year, now.month, now.day, depTime.hour, depTime.minute);
      DateTime todayArr = DateTime(now.year, now.month, now.day, arrTime.hour, arrTime.minute);
      if (!todayArr.isAfter(todayDep)) {
        todayArr = todayArr.add(const Duration(days: 1));
      }
      if (now.isBefore(todayDep)) return 0.0;
      if (now.isAfter(todayArr)) return 1.0;
      final total = todayArr.difference(todayDep).inMinutes.toDouble();
      final done = now.difference(todayDep).inMinutes.toDouble();
      return (done / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  Map<String, dynamic> _pnrToMap(PnrRecord r) {
    return {
      'trainNumber': r.trainNumber,
      'trainName': r.trainName,
      'from': r.from,
      'to': r.to,
      'departureTime': r.departureTime,
      'arrivalTime': r.arrivalTime,
      'trainStatus': r.trainStatus,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Your Train')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter PNR (10-digit) or Train Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _loading ? null : _search, icon: const Icon(Icons.search), label: const Text('Search')),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_data != null) _buildResult(context, _data!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, Map<String, dynamic> d) {
    final String title = (d['trainNumber'] != null && d['trainName'] != null)
        ? '${d['trainNumber']} • ${d['trainName']}'
        : (d['name'] ?? 'Train');
    final String from = d['from'] ?? d['source'] ?? 'N/A';
    final String to = d['to'] ?? d['destination'] ?? 'N/A';
    final String dep = d['departureTime'] ?? d['departure'] ?? 'N/A';
    final String arr = d['arrivalTime'] ?? d['arrival'] ?? 'N/A';
    final String status = d['trainStatus'] ?? d['status'] ?? 'On Time';
    final double progress = (d['progress'] as double?) ?? 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.train, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(from, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Dep: $dep', style: const TextStyle(fontSize: 12)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(to, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Arr: $arr', style: const TextStyle(fontSize: 12)),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toStringAsFixed(0)}% completed', style: const TextStyle(fontSize: 12)),
                Chip(label: Text(status), backgroundColor: (status.toString().toLowerCase().contains('delay') ? Colors.red : Colors.green).withOpacity(0.1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


