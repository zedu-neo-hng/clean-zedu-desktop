import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _OnlineStatusNotifier extends NetworkStatusNotifier {
  @override
  NetworkStatus build() => NetworkStatus.online;
}

class _OfflineStatusNotifier extends NetworkStatusNotifier {
  @override
  NetworkStatus build() => NetworkStatus.offline;
}

class _SwitchableStatusNotifier extends NetworkStatusNotifier {
  @override
  NetworkStatus build() => NetworkStatus.online;
}

void main() {
  group('OfflineStatusBanner', () {
    testWidgets('renders nothing when online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkStatusProvider.overrideWith(_OnlineStatusNotifier.new),
          ],
          child: buildTestMaterialApp(
            const Scaffold(body: OfflineStatusBanner()),
          ),
        ),
      );

      expect(find.byType(OfflineStatusBanner), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(
        find.text('You are offline. Check your internet connection.'),
        findsNothing,
      );
    });

    testWidgets('shows banner with icon and message when offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkStatusProvider.overrideWith(_OfflineStatusNotifier.new),
          ],
          child: buildTestMaterialApp(
            const Scaffold(body: OfflineStatusBanner()),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('You are offline. Check your internet connection.'),
        findsOneWidget,
      );
    });

    testWidgets('updates when network status changes', (tester) async {
      final notifier = _SwitchableStatusNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [networkStatusProvider.overrideWith(() => notifier)],
          child: buildTestMaterialApp(
            const Scaffold(body: OfflineStatusBanner()),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsNothing);

      notifier.setOffline();
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('You are offline. Check your internet connection.'),
        findsOneWidget,
      );

      notifier.setOnline();
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsNothing);
    });
  });
}
