import 'package:zedu/core/core.dart';

/// A non-intrusive banner that appears when the application is offline.
///
/// Watches [networkStatusProvider] and shows a red banner with a cloud-off
/// icon when the status is [NetworkStatus.offline]. Returns an empty
/// [SizedBox] when online so it takes no space in the layout.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    final colors = context.colors;

    if (networkStatus == NetworkStatus.online) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: colors.error, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: colors.onPrimary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Check your internet connection.',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
