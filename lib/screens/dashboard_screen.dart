import 'package:flutter/material.dart';
import 'package:railone/models/food.dart';
import 'package:railone/models/pnr.dart';
import 'package:railone/models/train.dart';
import 'package:railone/services/mock_repositories.dart';
import 'package:railone/services/auth_service.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:railone/screens/pnr_status_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TrainRepository _trainRepo = TrainRepository();
  final PnrRepository _pnrRepo = PnrRepository();
  final FoodRepository _foodRepo = FoodRepository();

  late Future<List<Train>> _trainsFuture;
  late Future<List<FoodVendor>> _foodFuture;
  int _selectedIndex = 0;
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();

  @override
  void initState() {
    super.initState();
    _trainsFuture = _trainRepo.getTrains();
    _foodFuture = _foodRepo.getVendors();
  }

  String _formatNotifTime(dynamic value) {
    DateTime? dt;
    if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(dt.toLocal());
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D5BFF), Color(0xFF6EA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context),
          const SizedBox(height: 12),
          Text('Hi, ${_auth.currentUser?.displayName ?? 'there'}!', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          const SizedBox(height: 12),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Journey Planner', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF0A2A6B))),
                    const SizedBox(height: 12),
                    _buildJourneyPlannerRow(context),
                    const SizedBox(height: 16),
                    Text('More Offerings', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF0A2A6B))),
                    const SizedBox(height: 12),
                    _buildOfferingsGrid(context),
                    const SizedBox(height: 16),
                    Text('Do You know?', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF0A2A6B))),
                    const SizedBox(height: 8),
                    _buildDidYouKnowCarousel(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final User? user = _auth.currentUser;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 22, fontWeight: FontWeight.w700),
                children: const [
                  TextSpan(text: 'Rail'),
                  TextSpan(text: 'One', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        if (user != null)
          StreamBuilder<int>(
            stream: _fs.listenUnreadNotificationsCount(user.uid),
            builder: (context, snap) {
              final int count = snap.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => _openNotifications(context),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              );
            },
          )
        else
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final String name = _auth.currentUser?.displayName ?? 'there';
    return Text('Hi, $name!', style: TextStyle(color: Colors.grey.shade700));
  }

  Widget _buildJourneyPlannerRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _JourneyCard(title: 'Reserved', image: 'assets/images/reserved.svg', onTap: () => Navigator.pushNamed(context, '/booking'))),
        const SizedBox(width: 12),
        Expanded(child: _JourneyCard(title: 'Unreserved', image: 'assets/images/unreserved.svg', onTap: () {})),
        const SizedBox(width: 12),
        Expanded(child: _JourneyCard(title: 'Platform', image: 'assets/images/platform.svg', onTap: () {})),
      ],
    );
  }

  Widget _buildOfferingsGrid(BuildContext context) {
    final List<_Feature> features = [
      _Feature(Icons.route, 'Search\nTrains', () => Navigator.pushNamed(context, '/booking')),
      _Feature(Icons.receipt_long, 'PNR\nStatus', () => _showPnrDialog(context)),
      _Feature(Icons.train_outlined, 'Coach\nPosition', () {}),
      _Feature(Icons.directions_transit, 'Track Your\nTrain', () => Navigator.pushNamed(context, '/track-train')),
      _Feature(Icons.restaurant, 'Order\nFood', () {}),
      _Feature(Icons.assignment_return, 'File\nRefund', () {}),
      _Feature(Icons.handshake_outlined, 'Rail\nMadad', () => Navigator.pushNamed(context, '/rail-madad')),
      _Feature(Icons.feedback_outlined, 'Travel\nFeedback', () => Navigator.pushNamed(context, '/feedback')),
    ];

    // Compute a fluid number of columns based on available width
    final double w = MediaQuery.of(context).size.width;
    int columns = 4;
    if (w < 360) columns = 2;
    else if (w < 480) columns = 3;
    else if (w < 720) columns = 4;
    else if (w < 900) columns = 5;
    else columns = 6;

    // Non-scrollable grid inside parent scroll view
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: features.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .9,
      ),
      itemBuilder: (context, index) {
        final f = features[index];
        return _FeatureTile(icon: f.icon, label: f.label, onTap: f.onTap);
      },
    );
  }

  Widget _buildDidYouKnowCarousel(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => Container(
          width: 220,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 3,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) {
        setState(() => _selectedIndex = i);
        switch (i) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, '/my-bookings');
            break;
          case 2:
            Navigator.pushNamed(context, '/profile');
            break;
          case 3:
            Navigator.pushNamed(context, '/menu');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_outlined), label: 'My Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'You'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'Menu'),
      ],
    );
  }

  Future<void> _showPnrDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PNR Status'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter 10-digit PNR number',
            prefixIcon: Icon(Icons.confirmation_number),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 10,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
          onPressed: () async {
            final pnr = controller.text.trim();
            if (pnr.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(pnr)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid 10-digit PNR number')),
              );
              return;
            }
            if (!mounted) return;
            Navigator.of(context).pop();
            // Navigate to PNR status screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PnrStatusScreen(pnr: pnr),
              ),
            );
          },
            child: const Text('Check Status')
          ),
        ],
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Notifications'),
                trailing: TextButton(
                  onPressed: () => _fs.markAllNotificationsRead(user.uid),
                  child: const Text('Mark all read'),
                ),
              ),
              Flexible(
                child: StreamBuilder(
                  stream: _fs.listenNotifications(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                    }
                    final docs = (snapshot.data as dynamic).docs;
                    if (docs.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No notifications')));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final bool read = data['read'] == true;
                        return ListTile(
                          leading: Icon(read ? Icons.notifications : Icons.fiber_new, color: read ? Colors.grey : Theme.of(context).colorScheme.primary),
                          title: Text(data['title'] ?? 'Update'),
                          subtitle: Text(data['body'] ?? ''),
                          trailing: Text(
                            _formatNotifTime(data['createdAt']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: docs.length,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;
  const _JourneyCard({required this.title, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _JourneyArtwork(image: image),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0A2A6B))),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Feature(this.icon, this.label, this.onTap);
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0A2A6B))),
          ],
        ),
      ),
    );
  }
}

class _JourneyArtwork extends StatelessWidget {
  final String image;
  const _JourneyArtwork({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image.endsWith('.svg')) {
      return SvgPicture.asset(image, fit: BoxFit.cover);
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}

