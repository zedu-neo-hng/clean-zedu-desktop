import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

Success<ChannelMessagePage> _page(
  List<ChannelMessage> messages, {
  bool hasMore = false,
}) => Success(ChannelMessagePage(messages: messages, hasMore: hasMore));

void main() {
  late MockChannelRepository repository;

  setUp(() => repository = MockChannelRepository());

  void stubPage(int page, Result<ChannelMessagePage> result) {
    when(
      () => repository.fetchChannelMessages('ch-1', page: page),
    ).thenAnswer((_) async => result);
  }

  Future<void> pumpList(WidgetTester tester) {
    return tester
        .pumpWidget(
          ProviderScope(
            overrides: [
              channelRepositoryProvider.overrideWithValue(repository),
            ],
            retry: (_, _) => null,
            child: buildTestMaterialApp(
              const Scaffold(
                body: ChannelMessageList(
                  channelId: 'ch-1',
                  empty: Text('Welcome to #general'),
                ),
              ),
            ),
          ),
        )
        .then((_) => tester.pumpAndSettle());
  }

  testWidgets('shows the messages, newest at the bottom', (tester) async {
    stubPage(
      1,
      _page(const [
        ChannelMessage(id: '2', senderName: 'gold', text: 'newest'),
        ChannelMessage(id: '1', senderName: 'Ada', text: 'oldest'),
      ]),
    );
    await pumpList(tester);

    expect(find.text('Welcome to #general'), findsNothing);
    expect(
      tester.getTopLeft(find.text('oldest')).dy,
      lessThan(tester.getTopLeft(find.text('newest')).dy),
    );
  });

  testWidgets('shows the welcome screen when empty', (tester) async {
    stubPage(1, _page(const <ChannelMessage>[]));
    await pumpList(tester);

    expect(find.text('Welcome to #general'), findsOneWidget);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    stubPage(1, const Failure(ApiFailure(message: 'boom')));
    await pumpList(tester);

    expect(find.text("Couldn't load messages. Retry"), findsOneWidget);
  });

  testWidgets('loads older messages when the top of the list shows', (
    tester,
  ) async {
    stubPage(
      1,
      _page(const [
        ChannelMessage(id: '2', senderName: 'gold', text: 'newest'),
      ], hasMore: true),
    );
    stubPage(
      2,
      _page(const [ChannelMessage(id: '1', senderName: 'Ada', text: 'oldest')]),
    );
    await pumpList(tester);

    expect(find.text('newest'), findsOneWidget);
    expect(find.text('oldest'), findsOneWidget);
    verify(() => repository.fetchChannelMessages('ch-1', page: 2)).called(1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an inline retry when an older page fails', (tester) async {
    stubPage(
      1,
      _page(const [
        ChannelMessage(id: '2', senderName: 'gold', text: 'newest'),
      ], hasMore: true),
    );
    stubPage(2, const Failure(ApiFailure(message: 'boom')));
    await pumpList(tester);

    // The messages stay, and the failure is not retried on its own.
    expect(find.text('newest'), findsOneWidget);
    expect(find.text("Couldn't load older messages. Retry"), findsOneWidget);
    verify(() => repository.fetchChannelMessages('ch-1', page: 2)).called(1);

    stubPage(
      2,
      _page(const [ChannelMessage(id: '1', senderName: 'Ada', text: 'oldest')]),
    );
    await tester.tap(find.text("Couldn't load older messages. Retry"));
    await tester.pumpAndSettle();

    expect(find.text('oldest'), findsOneWidget);
    expect(find.text("Couldn't load older messages. Retry"), findsNothing);
  });

  testWidgets(
    'renders a placeholder initial for an empty senderName without crashing',
    (tester) async {
      stubPage(
        1,
        _page(const [
          ChannelMessage(id: '1', senderName: '', text: 'empty sender'),
        ]),
      );
      await pumpList(tester);

      expect(find.text('?'), findsOneWidget);
      expect(find.text('empty sender'), findsOneWidget);
    },
  );
}
