import 'package:flutter/material.dart';

class RecentNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;
  final IconData? icon;

  const RecentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
    this.icon,
  });

  RecentNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? avatarUrl,
    IconData? icon,
  }) {
    return RecentNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      icon: icon ?? this.icon,
    );
  }

  String formatRelativeTime([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[timestamp.month - 1];
      return '$month ${timestamp.day}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          timestamp == other.timestamp &&
          isRead == other.isRead &&
          avatarUrl == other.avatarUrl &&
          icon == other.icon;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      message.hashCode ^
      timestamp.hashCode ^
      isRead.hashCode ^
      avatarUrl.hashCode ^
      icon.hashCode;
}
