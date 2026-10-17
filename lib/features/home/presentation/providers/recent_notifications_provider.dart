import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class RecentNotificationsNotifier extends Notifier<List<RecentNotification>> {
  @override
  List<RecentNotification> build() {
    final isDevOrDemo = _isDevOrDemo();
    if (!isDevOrDemo) {
      return const [];
    }
    return sampleNotifications();
  }

  static bool _isDevOrDemo() {
    if (!dotenv.isInitialized) {
      return true;
    }
    try {
      if (AppFlavorConfig.isDevelopment) {
        return true;
      }
      if (locator.isRegistered<AppConfig>()) {
        return locator<AppConfig>().usesMockData;
      }
      return AppConfig.fromEnvironment().usesMockData;
    } catch (_) {
      return true;
    }
  }

  static List<RecentNotification> sampleNotifications([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    return [
      RecentNotification(
        id: 'notif-1',
        title: 'Sarah Connor',
        message: 'Shared a file in #announcements: Q3 Roadmap.pdf',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        icon: Icons.alternate_email,
      ),
      RecentNotification(
        id: 'notif-2',
        title: 'Alex Mercer',
        message: 'Hey, do you have a few minutes to review the new design?',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
        icon: Icons.chat_bubble_outline,
      ),
      RecentNotification(
        id: 'notif-3',
        title: 'Workspace Admin',
        message: 'Your credits were renewed for this billing cycle.',
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: true,
        icon: Icons.notifications_active_outlined,
      ),
    ];
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final item in state)
        if (!item.isRead) item.copyWith(isRead: true) else item,
    ];
  }

  void addNotification(RecentNotification notification) {
    state = [notification, ...state];
  }

  void removeNotification(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

final recentNotificationsProvider =
    NotifierProvider<RecentNotificationsNotifier, List<RecentNotification>>(
      RecentNotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(recentNotificationsProvider);
  return notifications.where((item) => !item.isRead).length;
});
