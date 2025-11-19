import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:railone/services/firestore_service.dart';

// Rail Madad: allow users to file grievances and see their tickets.
class RailMadadScreen extends StatefulWidget {
  const RailMadadScreen({super.key});

  @override
  State<RailMadadScreen> createState() => _RailMadadScreenState();
}

class _RailMadadScreenState extends State<RailMadadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _desc = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  String _category = 'Cleanliness';
  bool _submitting = false;
  final FirestoreService _fs = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _desc.dispose();
    _subject.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to submit grievance')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _fs.addGrievance(
        user.uid,
        category: _category,
        subject: _subject.text.trim().isEmpty ? 'No subject' : _subject.text.trim(),
        description: _desc.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _desc.clear();
      _subject.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted. We will get back soon.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Rail Madad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit a Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: 'Cleanliness', child: Text('Cleanliness')),
                      DropdownMenuItem(value: 'Coach Issue', child: Text('Coach Issue')),
                      DropdownMenuItem(value: 'Staff Behaviour', child: Text('Staff Behaviour')),
                      DropdownMenuItem(value: 'Security', child: Text('Security')),
                      DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'Cleanliness'),
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    minLines: 3,
                    maxLines: 6,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Describe your issue' : null,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: Text(_submitting ? 'Submitting...' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('My Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: user == null
                  ? const Center(child: Text('Login to view your tickets'))
                  : StreamBuilder(
                      stream: _fs.listenUserGrievances(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Text('No tickets yet'));
                        }
                        final docs = List.of((snapshot.data as dynamic).docs);
                        docs.sort((a, b) {
                          final sa = DateTime.tryParse(a.data()['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                          final sb = DateTime.tryParse(b.data()['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                          return sb.compareTo(sa);
                        });
                        if (docs.isEmpty) {
                          return const Center(child: Text('No tickets yet'));
                        }
                        return ListView.separated(
                          itemBuilder: (context, index) {
                            final g = docs[index].data();
                            final createdAt = (g['createdAt'] != null)
                                ? DateFormat.yMMMd().add_jm().format(DateTime.parse(g['createdAt']))
                                : 'N/A';
                            final Color statusColor = (g['status'] == 'pending') ? Colors.orange : Colors.green;
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.support_agent, color: statusColor),
                                title: Text(g['subject'] ?? 'No subject'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(g['description'] ?? ''),
                                    Text('Submitted: $createdAt', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: Chip(label: Text((g['status'] ?? 'pending').toUpperCase()), backgroundColor: statusColor.withOpacity(0.1)),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemCount: docs.length,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


