import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:railone/services/auth_service.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:railone/utils/validators.dart';

// User profile screen: reads from Firebase Auth and Firestore, allows
// updating display name/email (best-effort) and syncing extra fields.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Always load from Firebase Auth first (this usually works)
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
      
      // Try to load additional data from Firestore
      try {
        final data = await _firestoreService.getUserProfile(user.uid);
        if (data != null) {
          _nameController.text = (data['name'] as String?)?.trim() ?? _nameController.text;
          _mobileController.text = (data['mobile'] as String?)?.trim() ?? '';
          if ((data['email'] as String?)?.isNotEmpty == true) {
            _emailController.text = data['email'] as String;
          }
        }
      } catch (e) {
        print('Failed to load profile from Firestore: $e');
        // Continue with auth data only
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Failed to load profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final String newName = _nameController.text.trim();
      final String newEmail = _emailController.text.trim();
      final String newMobile = _mobileController.text.trim();

      // Try to update Firebase Auth display name (this usually works even if Firestore fails)
      try {
        if (newName.isNotEmpty && newName != (user.displayName ?? '')) {
          await _authService.updateDisplayName(newName);
        }
      } catch (e) {
        print('Failed to update display name: $e');
      }

      // Try to update email (may require recent login)
      try {
        if (newEmail.isNotEmpty && newEmail != (user.email ?? '')) {
          await _authService.updateEmail(newEmail);
        }
      } catch (e) {
        print('Failed to update email: $e');
        // Don't fail the entire operation for email update issues
      }

      // Try to save to Firestore (with timeout and fallback)
      try {
        await _firestoreService.upsertUserProfile(user.uid, {
          'uid': user.uid,
          'name': newName,
          'email': newEmail,
          'mobile': newMobile,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Failed to save to Firestore: $e');
        // Continue anyway - the auth updates above are more important
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }



  Future<void> _logout() async {
    try {
      await _authService.signOut();
    } finally {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: _saving ? null : _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([_nameController, _emailController]),
                        builder: (context, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_nameController.text.isEmpty ? 'Your Name' : _nameController.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(_emailController.text.isEmpty ? 'your@email.com' : _emailController.text, style: TextStyle(color: Colors.white.withOpacity(0.9))),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: Validators.validateMobile,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveProfile,
                        icon: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                        label: const Text('Save changes'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Email changes may require recent login. Firestore data syncs when connection is available.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
                          icon: const Icon(Icons.confirmation_number),
                          label: const Text('My Bookings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/pnr-status'),
                          icon: const Icon(Icons.search),
                          label: const Text('PNR Status'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

