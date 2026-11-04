/// A top-level message in a channel, as returned by
/// `GET /threads/channels/{channel_id}`.
class ChannelMessage {
  /// The thread id from the backend. Null for a message the backend gave none.
  final String? id;
  final String senderName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;

  const ChannelMessage({
    required this.senderName,
    required this.text,
    this.id,
    this.avatarUrl,
    this.createdAt,
  });

  /// Identifies this message when pages are merged, so a message that shows
  /// up on two pages is listed once. Falls back to the content for a message
  /// without an [id].
  String get dedupeKey =>
      id ?? '$senderName|${createdAt?.toIso8601String()}|$text';

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return ChannelMessage(
      id: nonEmpty(json['thread_id']) ?? nonEmpty(json['id']),
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['username']) ??
          'Unknown',
      avatarUrl:
          nonEmpty(json['avatar_url']) ?? nonEmpty(json['default_avatar_url']),
      // Messages sent from the web app arrive as HTML (`<p>hi</p>`).
      text: (json['message']?.toString() ?? '')
          .replaceAll(
            RegExp(r'</(p|div|li)>\s*<(p|div|li|ul|ol)\b[^>]*>|<br\s*/?>'),
            '\n',
          )
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}
