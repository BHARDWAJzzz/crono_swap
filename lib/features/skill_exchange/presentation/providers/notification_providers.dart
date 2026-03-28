import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_notification_service.dart';
import 'auth_providers.dart';

final notificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService();
});

final notificationStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(notificationServiceProvider).getNotifications(user.id);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userDataProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(notificationServiceProvider).getUnreadCount(user.id);
});
