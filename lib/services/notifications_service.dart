import 'package:firebase_messaging/firebase_messaging.dart';

/// Minimal FCM wrapper used to request permissions, fetch token,
/// and listen to foreground messages.
class NotificationsService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  void handleForegroundMessages(void Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }
}

