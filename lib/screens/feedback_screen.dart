import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:railone/services/firestore_service.dart';

// Collects user feedback and lists submissions for the signed-in user.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  final FirestoreService _fs = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to submit feedback')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _fs.addFeedback(user.uid, subject: _subject.text.trim(), message: _message.text.trim(), rating: _rating);
      if (!mounted) return;
      setState(() => _submitting = false);
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
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
      appBar: AppBar(title: const Text('Travel Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Your Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  TextFormField(
                    controller: _message,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your feedback' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Rating:'),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (i) {
                          final idx = i + 1;
                          final bool filled = idx <= _rating;
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(0),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: Icon(
                              filled ? Icons.star : Icons.star_border,
                              color: filled ? Colors.amber.shade700 : Colors.grey,
                            ),
                            onPressed: _submitting ? null : () => setState(() => _rating = idx),
                          );
                        }),
                      ),
                      const Spacer(),
                      FilledButton.icon(onPressed: _submitting ? null : _submit, icon: const Icon(Icons.send), label: Text(_submitting ? 'Submitting...' : 'Submit')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('My Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: user == null
                  ? const Center(child: Text('Login to view your feedback'))
                  : StreamBuilder(
                      stream: _fs.listenUserFeedbacks(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Text('No feedback yet'));
                        }
                        final docs = List.of((snapshot.data as dynamic).docs);
                        docs.sort((a, b) {
                          final sa = DateTime.tryParse(a.data()['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                          final sb = DateTime.tryParse(b.data()['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                          return sb.compareTo(sa);
                        });
                        if (docs.isEmpty) {
                          return const Center(child: Text('No feedback yet'));
                        }
                        return ListView.separated(
                          itemBuilder: (context, index) {
                            final f = docs[index].data();
                            final createdAt = (f['createdAt'] != null)
                                ? DateFormat.yMMMd().add_jm().format(DateTime.parse(f['createdAt']))
                                : 'N/A';
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.rate_review, color: Colors.blue),
                                title: Text(f['subject'] ?? 'Feedback'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f['message'] ?? ''),
                                    Row(children:[
                                      ...List.generate(5, (i){
                                        final idx = i+1;
                                        final bool filled = idx <= (f['rating'] ?? 0);
                                        return Icon(
                                          filled ? Icons.star : Icons.star_border,
                                          color: filled ? Colors.amber.shade700 : Colors.grey,
                                          size: 14,
                                        );
                                      }),
                                      const SizedBox(width: 8),
                                      Text('Submitted: $createdAt', style: const TextStyle(fontSize: 12)),
                                    ])
                                  ],
                                ),
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


