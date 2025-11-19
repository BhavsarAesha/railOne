import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:railone/services/firebase_service.dart';
import 'package:railone/screens/pnr_status_screen.dart';

// Global search across trains, PNR, and food (basic demo implementation).
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _db = FirebaseService.db;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.addListener(() => setState(() => _query = _controller.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search trains, PNR, food', border: InputBorder.none),
        ),
        bottom: const TabBar(tabs: [
          Tab(text: 'Trains'),
          Tab(text: 'PNR'),
          Tab(text: 'Food'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrains(),
          _buildPnr(),
          _buildFood(),
        ],
      ),
    );
  }

  Widget _buildTrains() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('trains').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final results = docs.where((d) {
          if (_query.isEmpty) return true;
          final data = d.data();
          final hay = '${data['number']} ${data['name']} ${data['source']} ${data['destination']}'.toLowerCase();
          return hay.contains(_query);
        }).toList();
        if (results.isEmpty) return const Center(child: Text('No trains found'));
        return ListView.separated(
          itemCount: results.length,
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final t = results[i].data();
            return Card(
              child: ListTile(
                title: Text('${t['number']} • ${t['name']}'),
                subtitle: Text('${t['source']} → ${t['destination']}  ${t['departureTime']}-${t['arrivalTime']}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPnr() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Check PNR Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter 10-digit PNR Number',
                      hintText: '1234567890',
                      prefixIcon: const Icon(Icons.confirmation_number),
                      border: const OutlineInputBorder(),
                      counterText: '${_controller.text.length}/10',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    onSubmitted: (pnr) => _checkPnrStatus(pnr),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _controller.text.length == 10 ? () => _checkPnrStatus(_controller.text) : null,
                      icon: const Icon(Icons.search),
                      label: const Text('Check Status'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PNR Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• PNR (Passenger Name Record) is a unique 10-digit number'),
                  Text('• It contains details about your train journey'),
                  Text('• You can check seat/berth status, train running status'),
                  Text('• PNR is generated when you book train tickets'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkPnrStatus(String pnr) {
    if (pnr.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit PNR number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PnrStatusScreen(pnr: pnr),
      ),
    );
  }

  Widget _buildFood() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: const InputDecoration(labelText: 'Search food vendors or items'),
          onSubmitted: (q) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search food: $q')));
          },
        ),
      ),
    );
  }
}


