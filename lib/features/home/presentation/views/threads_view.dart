import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// One aggregated row on [ThreadsView]: a thread preview the user takes part
/// in, with the conversation it belongs to.
///
/// Desktop currently knows thread previews from the DM conversations payload
/// (`use_user_profile.dart`'s `preview_thread` list), so the aggregate is
/// built from [dmListProvider]; channel-side thread sources are wired in as
/// they become available.
class ThreadPreviewRow {
  final String threadId;
  final String message;
  final String username;
  final DateTime createdAt;
  final int messageCount;
  final DmConversation conversation;

  /// The conversation still has unread messages, so this thread shows the
  /// unread indicator.
  bool get isUnread => conversation.unreadCount > 0;

  const ThreadPreviewRow({
    required this.threadId,
    required this.message,
    required this.username,
    required this.createdAt,
    required this.messageCount,
    required this.conversation,
  });

  factory ThreadPreviewRow.from(
    DmConversation conversation,
    DmPreviewThread thread,
  ) => ThreadPreviewRow(
    threadId: thread.threadId,
    message: thread.message,
    username: thread.username,
    createdAt: thread.createdAt,
    messageCount: thread.messageCount,
    conversation: conversation,
  );
}

/// All active threads the user takes part in, aggregated in one view
/// (Ziki #2685). Opened from the sidebar rail's Threads item and reachable at
/// [AppRouter.threads].
class ThreadsView extends ConsumerWidget {
  const ThreadsView({super.key});

  /// Newest first, so the live discussions are on top.
  static List<ThreadPreviewRow> aggregate(List<DmConversation> conversations) {
    final rows = <ThreadPreviewRow>{};
    for (final conversation in conversations) {
      for (final thread in conversation.previewThreads) {
        rows.add(ThreadPreviewRow.from(conversation, thread));
      }
    }
    return rows.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _openThread(BuildContext context, WidgetRef ref, DmConversation target) {
    ref.read(selectedDmProvider.notifier).select(target);
    ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final list = ref.watch(dmListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Container(
            key: const ValueKey('threads-view-header'),
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Threads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.go(AppRouter.home),
                  icon: Icon(Icons.close, color: colors.textHint),
                  splashRadius: 20,
                  tooltip: 'Close threads',
                ),
              ],
            ),
          ),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ThreadsError(
                onRetry: () => ref.read(dmListProvider.notifier).refresh(),
              ),
              data: (conversations) {
                final rows = aggregate(conversations);
                if (rows.isEmpty) {
                  return const _ThreadsEmptyState();
                }
                return _ThreadsList(
                  rows: rows,
                  onOpen: (conversation) =>
                      _openThread(context, ref, conversation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadsList extends StatelessWidget {
  const _ThreadsList({required this.rows, required this.onOpen});

  final List<ThreadPreviewRow> rows;
  final ValueChanged<DmConversation> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('threads-view-list'),
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return _ThreadTile(row: row, onOpen: onOpen);
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.row, required this.onOpen});

  final ThreadPreviewRow row;
  final ValueChanged<DmConversation> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final author = row.username.isNotEmpty ? row.username : 'Unknown';

    return InkWell(
      key: ValueKey('threads-view-row-${row.threadId}'),
      onTap: () => onOpen(row.conversation),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryBg,
              child: Text(
                author.isNotEmpty ? author[0].toUpperCase() : '?',
                style: TextStyle(color: colors.primary, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${row.conversation.displayName}  •  $author',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(row.createdAt),
                        style: TextStyle(color: colors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (row.messageCount > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${row.messageCount} replies',
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      // The conversation still has unread messages, so this
                      // thread shows the unread dot.
                      if (row.isUnread)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            key: ValueKey(
                              'threads-view-unread-${row.threadId}',
                            ),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final hour = value.hour > 12 ? value.hour - 12 : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $period';
  }
}

class _ThreadsEmptyState extends StatelessWidget {
  const _ThreadsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      key: const ValueKey('threads-view-empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 56, color: colors.textHint),
          const SizedBox(height: 16),
          Text(
            'No threads yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reply in a thread from your conversations and it shows up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ThreadsError extends StatelessWidget {
  const _ThreadsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 12),
          Text(
            'Could not load threads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Retry',
            leading: const Icon(Icons.refresh, size: 16),
            height: 40,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
