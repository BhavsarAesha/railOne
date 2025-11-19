import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:railone/models/train.dart';
import 'package:railone/screens/booking/train_details_screen.dart';
import 'package:railone/services/firebase_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final FirebaseFirestore _db = FirebaseService.db;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    // Simple client-side filter based on train attributes
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('cancelled') || lowerStatus.contains('cancel')) {
      return Colors.red;
    } else if (lowerStatus.contains('delay') || lowerStatus.contains('late')) {
      return Colors.orange;
    } else if (lowerStatus.contains('on time') || lowerStatus.contains('running')) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Tickets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by train no, name, source, destination',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('trains').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final List<Train> trains = docs.map((d) => Train.fromJson(d.data())).toList();
                final filtered = trains.where((t) {
                  if (_query.isEmpty) return true;
                  final hay = [t.number, t.name, t.source, t.destination].join(' ').toLowerCase();
                  return hay.contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No trains found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemBuilder: (context, index) {
                    final Train t = filtered[index];
                    return Card(
                      child: ListTile(
                        title: Text('${t.number} • ${t.name}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.source} → ${t.destination}  ${t.departureTime}-${t.arrivalTime}'),
                            Text('Ticket: ₹${t.ticketAmount.toStringAsFixed(0)}', 
                                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t.status, 
                              style: TextStyle(
                                color: _getStatusColor(t.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (t.lastUpdated != null)
                              Text('Upd: ${t.lastUpdated} ', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TrainDetailsScreen(train: t)),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

