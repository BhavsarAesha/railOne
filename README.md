# RailOne Mock Flutter App

This project is a Flutter starter inspired by the RailOne app. It includes:

- Mock data JSON under `assets/data/` acting as offline APIs
- Models and services to load JSON
- Minimal Firebase initialization (safe if Firebase isn't configured)
- Boilerplate client screens: Splash, Landing, Login, Signup, Profile, Dashboard
- Boilerplate admin screens: Admin Login, Admin Dashboard

## Project Structure

```
lib/
  models/           # Train, PNR, Food, Refund, Grievance models
  services/         # JsonService, mock repositories, FirebaseService
  screens/          # Client and admin screens
assets/
  data/             # trains.json, pnr.json, food.json, refunds.json, grievances.json
```

## Run Locally

1. Flutter version: any recent stable supporting Dart SDK per `pubspec.yaml`.
2. Install deps:
   ```bash
   flutter pub get
   ```
3. Run:
   ```bash
   flutter run
   ```

### Optional: Configure Firebase

- Add platform-specific `google-services.json` (Android) and `GoogleService-Info.plist` (iOS/macOS) per Firebase setup.
- The app will still run without Firebase configured due to guarded initialization.

## Mock Data

- Edit JSON in `assets/data/` to change trains, PNRs, food vendors, refunds, and grievances.


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
