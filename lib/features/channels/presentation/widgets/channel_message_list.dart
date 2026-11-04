import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The messages of a channel, newest at the bottom. Shows [empty] when the
/// channel has no messages yet.
class ChannelMessageList extends ConsumerWidget {
  const ChannelMessageList({
    super.key,
    required this.channelId,
    required this.empty,
  });

  final String channelId;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(channelHistoryProvider(channelId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(channelHistoryProvider(channelId)),
              child: const Text("Couldn't load messages. Retry"),
            ),
          ),
          data: (history) {
            final messages = history.messages;
            if (messages.isEmpty) return empty;
            // The footer sits after the oldest message, which is the top of
            // this reversed list. Older pages are appended behind the reader,
            // so the scroll offset (measured from the newest end) holds.
            final showFooter = history.hasMore || history.loadMoreError != null;
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: messages.length + (showFooter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _OlderMessagesFooter(channelId: channelId);
                }
                return ChannelMessageTile(message: messages[index]);
              },
            );
          },
        );
  }
}

/// The top of the list while older messages remain: loads the next page once
/// it scrolls into view, and offers a retry when that fails.
class _OlderMessagesFooter extends ConsumerWidget {
  const _OlderMessagesFooter({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(channelHistoryProvider(channelId)).value;
    final notifier = ref.read(channelHistoryProvider(channelId).notifier);

    if (history?.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: TextButton(
            onPressed: notifier.loadMore,
            child: const Text("Couldn't load older messages. Retry"),
          ),
        ),
      );
    }

    if (history != null && history.hasMore && !history.isLoadingMore) {
      // Built means visible: the list only builds what is on screen. Retries
      // are left to the button above so a failing request cannot loop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) notifier.loadMore();
      });
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Loading older messages',
          ),
        ),
      ),
    );
  }
}

class ChannelMessageTile extends StatelessWidget {
  const ChannelMessageTile({super.key, required this.message});

  final ChannelMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = message.avatarUrl;
    final time = message.createdAt;
    final trimmedName = message.senderName.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.characters.first.toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(initial, style: TextStyle(color: colors.onPrimary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    children: [
                      if (time != null)
                        TextSpan(
                          text:
                              '  ${TimeOfDay.fromDateTime(time).format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  message.text,
                  style: TextStyle(fontSize: 15, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
