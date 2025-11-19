import 'package:flutter/material.dart';
import 'package:railone/screens/admin/admin_dashboard_screen.dart';
import 'package:railone/screens/admin/admin_login_screen.dart';
import 'package:railone/screens/admin/admin_setup_screen.dart';
import 'package:railone/screens/auth/login_screen.dart';
import 'package:railone/screens/auth/signup_screen.dart';
import 'package:railone/screens/booking/booking_screen.dart';
import 'package:railone/screens/dashboard_screen.dart';
import 'package:railone/screens/landing_page.dart';
import 'package:railone/screens/profile_screen.dart';
import 'package:railone/screens/my_bookings_screen.dart';
import 'package:railone/screens/menu_screen.dart';
import 'package:railone/screens/global_search_screen.dart';
import 'package:railone/screens/track_train_screen.dart';
import 'package:railone/screens/rail_madad_screen.dart';
import 'package:railone/screens/feedback_screen.dart';
import 'package:railone/screens/splash_screen.dart';
import 'package:railone/services/firebase_service.dart';
import 'package:railone/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.ensureInitialized();
  runApp(const RailOneApp());
}

class RailOneApp extends StatelessWidget {
  const RailOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Root application: applies theme, clamps text scale for layout stability,
    // and registers all primary routes used across the app.
    return MaterialApp(
      title: 'RailOne',
      theme: AppTheme.build(),
      initialRoute: '/',
      // Clamp global text scaling to prevent layout breaks on extreme settings
      builder: (context, child) {
        final MediaQueryData data = MediaQuery.of(context);
        // Clamp textScaleFactor for consistent layouts across devices
        final double clampedTextScale = data.textScaleFactor.clamp(0.85, 1.2);
        return MediaQuery(
          data: data.copyWith(textScaler: TextScaler.linear(clampedTextScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Centralized, named routes for navigation
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/booking': (context) => const BookingScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/menu': (context) => const MenuScreen(),
        '/search': (context) => const GlobalSearchScreen(),
        '/track-train': (context) => const TrackTrainScreen(),
        '/rail-madad': (context) => const RailMadadScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/setup': (context) => const AdminSetupScreen(),
      },
    );
  }
}
