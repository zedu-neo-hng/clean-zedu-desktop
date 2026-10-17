import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('RecentNotification entity', () {
    final now = DateTime(2026, 10, 17, 12, 0, 0);

    test('instantiates with given values', () {
      final notif = RecentNotification(
        id: '1',
        title: 'Title',
        message: 'Message',
        timestamp: now,
        isRead: false,
        icon: Icons.notifications,
      );

      expect(notif.id, '1');
      expect(notif.title, 'Title');
      expect(notif.message, 'Message');
      expect(notif.timestamp, now);
      expect(notif.isRead, isFalse);
      expect(notif.icon, Icons.notifications);
      expect(notif.avatarUrl, isNull);
    });

    test('copyWith updates properties correctly', () {
      final notif = RecentNotification(
        id: '1',
        title: 'Title',
        message: 'Message',
        timestamp: now,
        isRead: false,
      );

      final updated = notif.copyWith(isRead: true, title: 'New Title');
      expect(updated.id, '1');
      expect(updated.title, 'New Title');
      expect(updated.isRead, isTrue);
      expect(updated.message, 'Message');
    });

    test('equality and hashCode work as expected', () {
      final notifA = RecentNotification(
        id: '1',
        title: 'Title',
        message: 'Message',
        timestamp: now,
        isRead: false,
      );
      final notifB = RecentNotification(
        id: '1',
        title: 'Title',
        message: 'Message',
        timestamp: now,
        isRead: false,
      );
      final notifC = RecentNotification(
        id: '2',
        title: 'Title',
        message: 'Message',
        timestamp: now,
        isRead: false,
      );

      expect(notifA, equals(notifB));
      expect(notifA.hashCode, equals(notifB.hashCode));
      expect(notifA, isNot(equals(notifC)));
    });

    group('formatRelativeTime', () {
      test('formats less than a minute as "Just now"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: now.subtract(const Duration(seconds: 30)),
        );
        expect(notif.formatRelativeTime(now), 'Just now');
      });

      test('formats minutes as "Xm ago"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: now.subtract(const Duration(minutes: 15)),
        );
        expect(notif.formatRelativeTime(now), '15m ago');
      });

      test('formats hours as "Xh ago"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: now.subtract(const Duration(hours: 3)),
        );
        expect(notif.formatRelativeTime(now), '3h ago');
      });

      test('formats 1 day difference as "Yesterday"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        );
        expect(notif.formatRelativeTime(now), 'Yesterday');
      });

      test('formats several days as "Xd ago"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: now.subtract(const Duration(days: 4)),
        );
        expect(notif.formatRelativeTime(now), '4d ago');
      });

      test('formats older dates as "MMM d"', () {
        final notif = RecentNotification(
          id: '1',
          title: 'T',
          message: 'M',
          timestamp: DateTime(2026, 8, 25, 10, 0),
        );
        expect(notif.formatRelativeTime(now), 'Aug 25');
      });
    });
  });

  group('RecentNotificationsNotifier & Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state contains 3 mock notifications', () {
      final notifs = container.read(recentNotificationsProvider);
      expect(notifs.length, 3);
      expect(container.read(unreadNotificationsCountProvider), 2);
    });

    test('markAsRead updates isRead state for given id', () {
      final notifier = container.read(recentNotificationsProvider.notifier);
      final initialNotifs = container.read(recentNotificationsProvider);
      final unreadId = initialNotifs.firstWhere((n) => !n.isRead).id;

      notifier.markAsRead(unreadId);

      final updatedNotifs = container.read(recentNotificationsProvider);
      expect(updatedNotifs.firstWhere((n) => n.id == unreadId).isRead, isTrue);
      expect(container.read(unreadNotificationsCountProvider), 1);
    });

    test('markAllAsRead marks all notifications as read', () {
      final notifier = container.read(recentNotificationsProvider.notifier);
      expect(container.read(unreadNotificationsCountProvider), greaterThan(0));

      notifier.markAllAsRead();

      final updatedNotifs = container.read(recentNotificationsProvider);
      expect(updatedNotifs.every((n) => n.isRead), isTrue);
      expect(container.read(unreadNotificationsCountProvider), 0);
    });

    test('addNotification prepends notification to the list', () {
      final notifier = container.read(recentNotificationsProvider.notifier);
      final newNotif = RecentNotification(
        id: 'new-999',
        title: 'New DM',
        message: 'Hello there',
        timestamp: DateTime.now(),
        isRead: false,
      );

      notifier.addNotification(newNotif);

      final list = container.read(recentNotificationsProvider);
      expect(list.length, 4);
      expect(list.first.id, 'new-999');
      expect(container.read(unreadNotificationsCountProvider), 3);
    });

    test('removeNotification removes item by id', () {
      final notifier = container.read(recentNotificationsProvider.notifier);
      notifier.removeNotification('notif-1');

      final list = container.read(recentNotificationsProvider);
      expect(list.any((n) => n.id == 'notif-1'), isFalse);
    });

    test('clear empties the list', () {
      final notifier = container.read(recentNotificationsProvider.notifier);
      notifier.clear();

      final list = container.read(recentNotificationsProvider);
      expect(list, isEmpty);
      expect(container.read(unreadNotificationsCountProvider), 0);
    });
  });
}
