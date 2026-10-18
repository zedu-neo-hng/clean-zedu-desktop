import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class NotificationPreviewPopover extends ConsumerWidget {
  const NotificationPreviewPopover({
    super.key,
    this.notifications,
    this.onViewAll,
    this.onClose,
  });

  final List<RecentNotification>? notifications;
  final VoidCallback? onViewAll;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    final List<RecentNotification> items =
        notifications ?? ref.watch(recentNotificationsProvider);
    final displayItems = items.take(3).toList();
    final unreadCount = items.where((n) => !n.isRead).length;

    return SizedBox(
      width: 360,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderOutline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Notifications',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ref
                              .read(recentNotificationsProvider.notifier)
                              .markAllAsRead();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Mark all read',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),

              // Items List
              if (displayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 32,
                          color: colors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent notifications',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...displayItems.map((notification) {
                  return _NotificationPreviewTile(
                    notification: notification,
                    onTap: () {
                      ref
                          .read(recentNotificationsProvider.notifier)
                          .markAsRead(notification.id);
                    },
                  );
                }),

              Divider(height: 1, color: colors.divider),

              // Footer: View all notifications
              InkWell(
                onTap: () {
                  if (onViewAll != null) {
                    onViewAll!();
                  } else {
                    onClose?.call();
                    ref
                        .read(userProfileNotifierProvider.notifier)
                        .selectSection(UserProfileSection.notifications);
                    context.go(AppRouter.profile);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all notifications',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  const _NotificationPreviewTile({
    required this.notification,
    required this.onTap,
  });

  final RecentNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return InkWell(
      onTap: onTap,
      hoverColor: colors.primaryBg.withValues(alpha: 0.35),
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : colors.primaryBg.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? colors.divider.withValues(alpha: 0.6)
                    : colors.primaryBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: notification.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        notification.avatarUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.person, size: 16, color: colors.primary),
                      ),
                    )
                  : Icon(
                      notification.icon ?? Icons.notifications_none,
                      size: 16,
                      color: notification.isRead
                          ? colors.textHint
                          : colors.primary,
                    ),
            ),
            const SizedBox(width: 10),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notification.formatRelativeTime(),
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread Dot Indicator
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
