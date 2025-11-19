import 'package:flutter/material.dart';
import 'package:railone/widgets/gradient_header.dart';
import 'package:railone/widgets/section_card.dart';

// Landing page entry: routes to login, signup, guest dashboard, and admin.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GradientHeader(
              title: 'RailOne',
              subtitle: 'Book tickets, order food, and manage your journey',
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Choose how you want to continue', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.login,
                    title: 'Login',
                    subtitle: 'Access your bookings and wallet',
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Sign Up',
                    subtitle: 'Create your RailOne account',
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    icon: Icons.explore,
                    title: 'Continue as Guest',
                    subtitle: 'Browse trains and menus without signing in',
                    onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                          child: const Text('Admin Login'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin/setup'),
                          child: const Text('Admin Setup (First Time Only)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

