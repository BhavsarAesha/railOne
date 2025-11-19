import 'package:flutter/material.dart';
// Admin portal: manages users, bookings, payments, trains, grievances,
// feedbacks and now food orders. Uses tabs via an IndexedStack to keep
// state across sections and streams Firestore collections for live data.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:railone/services/auth_service.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  double _dialogMaxWidth(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return math.min(w * 0.95, 520);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAdminHeroHeader(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildBookingsTab(),
                _buildPaymentsTab(),
                _buildTrainsTab(),
                _buildGrievancesTab(),
                _buildFeedbacksTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.train_outlined), label: 'Trains'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), label: 'Grievances'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback_outlined), label: 'Feedbacks'),
        ],
      ),
    );
  }

  Widget _buildAdminHeroHeader() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  radius: 20,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('RailOne Management', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;
        if (constraints.maxWidth >= 900) columns = 4;
        else if (constraints.maxWidth >= 600) columns = 3;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard('Total Users', Icons.people_alt_rounded, Theme.of(context).colorScheme.primary, () => setState(() => _selectedIndex = 1)),
                    _buildStatCard('Total Bookings', Icons.confirmation_number_rounded, Colors.teal, () => setState(() => _selectedIndex = 2)),
                    _buildStatCard('Total Payments', Icons.payments_rounded, Colors.indigo, () => setState(() => _selectedIndex = 3)),
                    _buildStatCard('Active Trains', Icons.train_rounded, Colors.orange, () => setState(() => _selectedIndex = 4)),
                    _buildStatCard('Pending Grievances', Icons.report_problem_rounded, Colors.red, () => setState(() => _selectedIndex = 5)),
                    _buildStatCard('Total Orders', Icons.restaurant_menu_rounded, Colors.purple, () {}),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, VoidCallback onTap) {
    final Color fg = Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: fg),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: _getStreamForCard(title),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('-', style: TextStyle(color: Colors.white));
                }
                if (!snapshot.hasData) {
                  return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
                }
                return Text(
                  _getCountForCard(title, snapshot.data),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: fg),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream? _getStreamForCard(String title) {
    switch (title) {
      case 'Total Users':
        return _firestoreService.getAllUsers();
      case 'Total Bookings':
        return _firestoreService.getAllBookings();
      case 'Total Payments':
        return _firestoreService.getAllPayments();
      case 'Active Trains':
        return _firestoreService.getAllTrains();
      case 'Pending Grievances':
        return _firestoreService.getAllGrievances();
      case 'Total Orders':
        return _firestoreService.listenAllOrders();
      default:
        return null;
    }
  }

  String _getCountForCard(String title, dynamic data) {
    if (data == null) return '0';
    
    switch (title) {
      case 'Total Users':
        return data.docs.length.toString();
      case 'Total Bookings':
        return data.docs.length.toString();
      case 'Total Payments':
        return data.docs.length.toString();
      case 'Total Orders':
        return data.docs.length.toString();
      case 'Active Trains':
        return data.docs.length.toString();
      case 'Pending Grievances':
        final pending = data.docs.where((doc) => doc.data()['status'] == 'pending').length;
        return pending.toString();
      default:
        return '0';
    }
  }

  Widget _buildOrdersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Food Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // One-click developer seeding for demo/testing
                    await _firestoreService.seedRestaurantsWithMenu(restaurants: 10, itemsPerRestaurant: 10);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeded restaurants and menus')));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to seed: $e')));
                  }
                },
                icon: const Icon(Icons.playlist_add),
                label: const Text('Seed Food Data'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.listenAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snapshot.data!.docs;
                if (orders.isEmpty) return const Center(child: Text('No orders'));
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index].data();
                    final String status = (o['status'] ?? 'Placed') as String;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text('₹${(o['totalAmount'] as num?)?.toStringAsFixed(0) ?? o['totalAmount']} • ${o['paymentMode']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${o['userId']}'),
                            Text('Train ${o['trainNumber']} • ${o['deliveryStation']}'),
                            Text('Status: $status'),
                          ],
                        ),
                        // Quick status update actions for the order lifecycle
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => _firestoreService.updateOrderStatus(o['id'], v),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'Placed', child: Text('Placed')),
                            PopupMenuItem(value: 'Preparing', child: Text('Preparing')),
                            PopupMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                            PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
                          ],
                          child: Chip(label: Text(status)),
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbacksTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Feedbacks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllFeedbacks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final feedbacks = snapshot.data!.docs;
                if (feedbacks.isEmpty) {
                  return const Center(child: Text('No feedback yet'));
                }
                return ListView.builder(
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final f = feedbacks[index].data();
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.rate_review, color: Colors.blue),
                        title: Text(f['subject'] ?? 'Feedback'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['message'] ?? ''),
                            if (f['rating'] != null) Text('Rating: ${f['rating']}/5', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payments',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              StreamBuilder(
                stream: _firestoreService.getAllPayments(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final payments = snapshot.data!.docs;
                  final success = payments.where((d) => (d.data()['paymentStatus'] ?? 'Success') == 'Success').length;
                  final pending = payments.where((d) => (d.data()['paymentStatus'] ?? '') == 'Pending').length;
                  return Row(children: [
                    _buildBookingStatChip('Total: ${payments.length}', Colors.blue),
                    const SizedBox(width: 8),
                    _buildBookingStatChip('Success: $success', Colors.green),
                    const SizedBox(width: 8),
                    _buildBookingStatChip('Pending: $pending', Colors.orange),
                  ]);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllPayments(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final payments = snapshot.data!.docs;
                if (payments.isEmpty) {
                  return const Center(child: Text('No payments found'));
                }
                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index].data();
                    final status = (p['paymentStatus'] ?? 'Success') as String;
                    final isPending = status.toLowerCase() == 'pending';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          isPending ? Icons.hourglass_bottom : Icons.check_circle,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                        title: Text(
                          '₹${p['amount']?.toStringAsFixed(0) ?? p['amount']} • ${p['paymentMethod'] ?? 'N/A'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p['userName'] != null) Text('User: ${p['userName']} (${p['userEmail'] ?? ''})', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (p['trainNumber'] != null) Text('Train: ${p['trainNumber']} • ${p['trainName'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis) ,
                            if (p['from'] != null && p['to'] != null) Text('${p['from']} → ${p['to']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (p['pnr'] != null) Text('PNR: ${p['pnr']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (p['transactionId'] != null) Text('Txn: ${p['transactionId']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (p['paymentDate'] != null) Text('Paid: ${p['paymentDate']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Text(status.toUpperCase(), style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showBroadcastDialog(),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Broadcast'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final users = snapshot.data!.docs;
                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data();
                    final uid = users[index].id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          user['name'] ?? 'Unknown User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No email', maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Mobile: ${user['mobile'] ?? 'Not provided'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Joined: ${DateFormat.yMMMd().format(DateTime.parse(user['createdAt'] ?? DateTime.now().toIso8601String()))}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'notify',
                              child: Text('Notify'),
                            ),
                            const PopupMenuItem(
                              value: 'view_bookings',
                              child: Text('View Bookings'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) => _handleUserAction(value, uid, user),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController();
    final TextEditingController body = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Notification'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: _dialogMaxWidth(context),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: body,
                    decoration: const InputDecoration(labelText: 'Message'),
                    minLines: 2,
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final int count = await _firestoreService.sendNotificationToAll(
                  title: title.text.trim(),
                  body: body.text.trim(),
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sent to $count users')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  StreamBuilder(
                    stream: _firestoreService.getAllBookings(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final bookings = snapshot.data!.docs;
                      final confirmedCount = bookings.where((doc) => doc.data()['status'] == 'confirmed').length;
                      final cancelledCount = bookings.where((doc) => doc.data()['status'] == 'cancelled').length;
                      
                      return Row(
                        children: [
                          _buildBookingStatChip('Total: ${bookings.length}', Colors.blue),
                          const SizedBox(width: 8),
                          _buildBookingStatChip('Confirmed: $confirmedCount', Colors.green),
                          const SizedBox(width: 8),
                          _buildBookingStatChip('Cancelled: $cancelledCount', Colors.red),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final bookings = snapshot.data!.docs;
                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }
                
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index].data();
                    final status = booking['status'] ?? 'confirmed';
                    final isCancelled = status == 'cancelled';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          isCancelled ? Icons.cancel : Icons.confirmation_number,
                          color: isCancelled ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          '${booking['trainNumber']} • ${booking['trainName']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${booking['from']} → ${booking['to']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${booking['departureTime']} - ${booking['arrivalTime']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Tickets: ${booking['quantity'] ?? 1} • Amount: ₹${booking['amount']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (booking['selectedCoach'] != null)
                              Text('Coach: ${booking['selectedCoach']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (booking['seatCodes'] != null && (booking['seatCodes'] as List).isNotEmpty)
                              Text('Seats: ${(booking['seatCodes'] as List).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (booking['userName'] != null)
                              Text('User: ${booking['userName']} (${booking['userEmail'] ?? 'No email'})', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (booking['pnr'] != null)
                              Text('PNR: ${booking['pnr']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text('Booked: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(booking['createdAt']))}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (booking['passengers'] != null)
                              Text('Passengers: ${(booking['passengers'] as List).length}'),
                            if (isCancelled) ...[
                              Text('Status: Cancelled by User', 
                                   style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              if (booking['cancelledAt'] != null)
                                Text('Cancelled on: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(booking['cancelledAt']))}', 
                                     style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${booking['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (isCancelled)
                              const Text('CANCELLED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onTap: () => _showBookingDetailsDialog(booking),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        final List passengers = (booking['passengers'] as List?) ?? const [];
        return AlertDialog(
          title: const Text('Booking Details'),
          content: SizedBox(
            width: _dialogMaxWidth(context),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${booking['trainNumber']} • ${booking['trainName']}'),
                  Text('${booking['from']} → ${booking['to']}'),
                  Text('Departure: ${booking['departureTime']}'),
                  Text('Coach: ${booking['selectedCoach'] ?? '-'}'),
                  if (booking['seatCodes'] != null && (booking['seatCodes'] as List).isNotEmpty)
                    Text('Seats: ${(booking['seatCodes'] as List).join(', ')}'),
                  const SizedBox(height: 12),
                  const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (passengers.isEmpty)
                    const Text('No passenger details')
                  else
                    ...passengers.asMap().entries.map((e) {
                      final i = e.key + 1;
                      final p = e.value as Map;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('$i')),
                        title: Text(p['name']?.toString() ?? 'Passenger $i'),
                        subtitle: Text('Age: ${p['age'] ?? '-'} • Gender: ${p['gender'] ?? '-'} • Mobile: ${p['mobile'] ?? '-'}'),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildTrainsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Train Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTrainDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Train'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllTrains(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final trains = snapshot.data!.docs;
                if (trains.isEmpty) {
                  return const Center(child: Text('No trains found'));
                }
                
                return ListView.builder(
                  itemCount: trains.length,
                  itemBuilder: (context, index) {
                    final train = trains[index].data();
                    final trainId = trains[index].id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.train, color: Colors.blue),
                        title: Text('${train['number']} • ${train['name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${train['source']} → ${train['destination']}'),
                            Text('${train['departureTime']} - ${train['arrivalTime']}'),
                            Text('Status: ${train['status']}'),
                            Text('Ticket: ₹${train['ticketAmount']?.toStringAsFixed(0) ?? '0'}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) => _handleTrainAction(value, trainId, train),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrievancesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grievance Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestoreService.getAllGrievances(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final grievances = snapshot.data!.docs;
                if (grievances.isEmpty) {
                  return const Center(child: Text('No grievances found'));
                }
                
                return ListView.builder(
                  itemCount: grievances.length,
                  itemBuilder: (context, index) {
                    final grievance = grievances[index].data();
                    final grievanceId = grievances[index].id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.report_problem,
                          color: grievance['status'] == 'pending' ? Colors.orange : Colors.green,
                        ),
                        title: Text(grievance['subject'] ?? 'No subject'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grievance['description'] ?? 'No description'),
                            Text('Status: ${grievance['status']}'),
                            Text('Submitted: ${DateFormat.yMMMd().format(DateTime.parse(grievance['createdAt']))}'),
                          ],
                        ),
                        trailing: grievance['status'] == 'pending'
                            ? ElevatedButton(
                                onPressed: () => _updateGrievanceStatus(grievanceId, 'resolved'),
                                child: const Text('Resolve'),
                              )
                            : const Chip(label: Text('Resolved'), backgroundColor: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _handleUserAction(String action, String uid, Map<String, dynamic> user) {
    switch (action) {
      case 'notify':
        _showNotifyUserDialog(uid, user['name'] ?? 'User');
        break;
      case 'view_bookings':
        _showUserBookings(uid, user['name']);
        break;
      case 'edit':
        _showEditUserDialog(uid, user);
        break;
      case 'delete':
        _showDeleteUserDialog(uid, user['name']);
        break;
    }
  }

  void _handleTrainAction(String action, String trainId, Map<String, dynamic> train) {
    switch (action) {
      case 'edit':
        _showEditTrainDialog(trainId, train);
        break;
      case 'delete':
        _showDeleteTrainDialog(trainId, train['name']);
        break;
    }
  }

  void _showUserBookings(String uid, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bookings for $userName'),
        content: SizedBox(
          width: _dialogMaxWidth(context),
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _firestoreService.getUserBookings(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final bookings = snapshot.data!;
              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found'));
              }
              
              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return ListTile(
                    title: Text('${booking['trainNumber']} • ${booking['trainName']}'),
                    subtitle: Text('${booking['from']} → ${booking['to']} • ₹${booking['amount']}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    // Implementation for adding users
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add user functionality coming soon')),
    );
  }

  void _showEditUserDialog(String uid, Map<String, dynamic> user) {
    // Implementation for editing users
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user functionality coming soon')),
    );
  }

  void _showDeleteUserDialog(String uid, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implementation for deleting users
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete user functionality coming soon')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotifyUserDialog(String uid, String userName) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController();
    final TextEditingController body = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notify $userName'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: _dialogMaxWidth(context),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: body,
                    decoration: const InputDecoration(labelText: 'Message'),
                    minLines: 2,
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _firestoreService.addNotification(uid, title: title.text.trim(), body: body.text.trim());
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAddTrainDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController number = TextEditingController();
    final TextEditingController name = TextEditingController();
    final TextEditingController source = TextEditingController();
    final TextEditingController destination = TextEditingController();
    final TextEditingController departure = TextEditingController();
    final TextEditingController arrival = TextEditingController();
    final TextEditingController status = TextEditingController(text: 'On Time');
    final TextEditingController ticketAmount = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Train'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: _dialogMaxWidth(context),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: number,
                          decoration: const InputDecoration(labelText: 'Train Number'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Train Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: source,
                          decoration: const InputDecoration(labelText: 'Source'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: destination,
                          decoration: const InputDecoration(labelText: 'Destination'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: departure,
                          decoration: const InputDecoration(labelText: 'Departure Time'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: arrival,
                          decoration: const InputDecoration(labelText: 'Arrival Time'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: status,
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: ticketAmount,
                          decoration: const InputDecoration(labelText: 'Ticket Amount (₹)'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _firestoreService.addTrain({
                  'number': number.text.trim(),
                  'name': name.text.trim(),
                  'source': source.text.trim(),
                  'destination': destination.text.trim(),
                  'departureTime': departure.text.trim(),
                  'arrivalTime': arrival.text.trim(),
                  'status': status.text.trim(),
                  'ticketAmount': double.tryParse(ticketAmount.text) ?? 0.0,
                });
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Train added')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditTrainDialog(String trainId, Map<String, dynamic> train) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController number = TextEditingController(text: train['number']);
    final TextEditingController name = TextEditingController(text: train['name']);
    final TextEditingController source = TextEditingController(text: train['source']);
    final TextEditingController destination = TextEditingController(text: train['destination']);
    final TextEditingController departure = TextEditingController(text: train['departureTime']);
    final TextEditingController arrival = TextEditingController(text: train['arrivalTime']);
    final TextEditingController status = TextEditingController(text: train['status']);
    final TextEditingController ticketAmount = TextEditingController(text: train['ticketAmount']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Train'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        content: SizedBox(
          width: _dialogMaxWidth(context),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: number,
                          decoration: const InputDecoration(labelText: 'Train Number'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Train Name'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: source,
                          decoration: const InputDecoration(labelText: 'Source'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: destination,
                          decoration: const InputDecoration(labelText: 'Destination'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: departure,
                          decoration: const InputDecoration(labelText: 'Departure Time'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: arrival,
                          decoration: const InputDecoration(labelText: 'Arrival Time'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: status,
                          decoration: const InputDecoration(labelText: 'Status'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: ticketAmount,
                          decoration: const InputDecoration(labelText: 'Ticket Amount (₹)'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _firestoreService.updateTrain(trainId, {
                  'number': number.text.trim(),
                  'name': name.text.trim(),
                  'source': source.text.trim(),
                  'destination': destination.text.trim(),
                  'departureTime': departure.text.trim(),
                  'arrivalTime': arrival.text.trim(),
                  'status': status.text.trim(),
                  'ticketAmount': double.tryParse(ticketAmount.text) ?? 0.0,
                });
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Train updated')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTrainDialog(String trainId, String trainName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Train'),
        content: Text('Are you sure you want to delete $trainName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteTrain(trainId);
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Train deleted')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _updateGrievanceStatus(String grievanceId, String status) async {
    try {
      await _firestoreService.updateGrievanceStatus(grievanceId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grievance status updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _logout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}

