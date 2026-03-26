import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/skill_exchange/data/repositories/auth_repository.dart';
import '../../features/skill_exchange/presentation/providers/auth_providers.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final WidgetRef _ref;

  NotificationService(this._ref);

  Future<void> init() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    _fcm.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // TODO: Use flutter_local_notifications to show a banner
      }
    });
  }

  Future<void> _saveToken(String token) async {
    final user = _ref.read(userDataProvider).value;
    if (user != null) {
      await _ref.read(authRepositoryProvider).saveFcmToken(token);
    }
  }
}

final notificationServiceProvider = Provider.family<NotificationService, WidgetRef>((ref, widgetRef) {
  return NotificationService(widgetRef);
});
