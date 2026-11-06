import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class _FakeDmListNotifier extends DmListNotifier {
  _FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

DmConversation _conversation({
  required String channelId,
  required String username,
  required List<DmPreviewThread> threads,
  int unreadCount = 0,
}) {
  return DmConversation(
    channelId: channelId,
    username: username,
    participantId: 'user-$channelId',
    previewMessage: '',
    unreadCount: unreadCount,
    previewThreads: threads,
  );
}

DmPreviewThread _thread(
  String threadId, {
  String message = '',
  String username = 'Ada Okafor',
  required DateTime createdAt,
  int messageCount = 0,
}) {
  return DmPreviewThread(
    threadId: threadId,
    message: message,
    userId: 'user-demo',
    username: username,
    createdAt: createdAt,
    messageCount: messageCount,
  );
}

Future<void> _pumpThreads(
  WidgetTester tester,
  List<DmConversation> conversations,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
        dmListProvider.overrideWith(() => _FakeDmListNotifier(conversations)),
      ],
      child: buildTestMaterialApp(const Scaffold(body: ThreadsView())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty state when no conversation has threads', (
    tester,
  ) async {
    await _pumpThreads(tester, []);

    expect(find.byKey(const ValueKey('threads-view-empty')), findsOneWidget);
    expect(find.text('No threads yet'), findsOneWidget);
  });

  testWidgets('lists one row per thread, newest first', (tester) async {
    final older = _conversation(
      channelId: 'channel-1',
      username: 'Ada Okafor',
      unreadCount: 1,
      threads: [
        _thread(
          'thread-1',
          message: 'Where are the design files?',
          createdAt: DateTime(2026, 1, 1, 10),
          messageCount: 3,
        ),
      ],
    );
    final newer = _conversation(
      channelId: 'channel-2',
      username: 'Bola Ige',
      threads: [
        _thread(
          'thread-2',
          message: 'Deploy finished',
          username: 'Chidi Ada',
          createdAt: DateTime(2026, 1, 2, 9),
        ),
      ],
    );

    await _pumpThreads(tester, [older, newer]);

    expect(find.byKey(const ValueKey('threads-view-list')), findsOneWidget);
    // Newest first: the second thread's row sits above the first's.
    final row = find.byKey(const ValueKey('threads-view-row-thread-1'));
    final newerRow = find.byKey(const ValueKey('threads-view-row-thread-2'));
    expect(row, findsOneWidget);
    expect(newerRow, findsOneWidget);
    expect(tester.getCenter(newerRow).dy, lessThan(tester.getCenter(row).dy));

    expect(find.text('Where are the design files?'), findsOneWidget);
    expect(find.text('Deploy finished'), findsOneWidget);
    expect(find.text('3 replies'), findsOneWidget);
  });

  testWidgets('shows the unread dot only on conversations with unread', (
    tester,
  ) async {
    final unread = _conversation(
      channelId: 'channel-1',
      username: 'Ada Okafor',
      unreadCount: 2,
      threads: [_thread('thread-1', createdAt: DateTime(2026, 1, 1))],
    );
    final read = _conversation(
      channelId: 'channel-2',
      username: 'Bola Ige',
      threads: [_thread('thread-2', createdAt: DateTime(2026, 1, 2))],
    );

    await _pumpThreads(tester, [unread, read]);

    expect(
      find.byKey(const ValueKey('threads-view-unread-thread-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('threads-view-unread-thread-2')),
      findsNothing,
    );
  });

  testWidgets('tapping a row filters to that DM and lands back on Home', (
    tester,
  ) async {
    final target = _conversation(
      channelId: 'channel-1',
      username: 'Ada Okafor',
      threads: [_thread('thread-1', createdAt: DateTime(2026, 1, 1))],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          dmListProvider.overrideWith(() => _FakeDmListNotifier([target])),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/threads',
            routes: [
              GoRoute(
                path: '/threads',
                builder: (context, state) => const ThreadsView(),
              ),
              GoRoute(
                path: AppRouter.home,
                builder: (context, state) =>
                    const Scaffold(body: Text('home landing')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('threads-view-row-thread-1')));
    await tester.pumpAndSettle();

    expect(find.text('home landing'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.text('home landing')),
    );
    expect(container.read(selectedDmProvider), target);
    expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
  });
}
