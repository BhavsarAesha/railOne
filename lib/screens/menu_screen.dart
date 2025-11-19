import 'package:flutter/material.dart';
import 'package:railone/services/auth_service.dart';

// App menu hub: quick links to profile, food orders, and sign-out.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}


