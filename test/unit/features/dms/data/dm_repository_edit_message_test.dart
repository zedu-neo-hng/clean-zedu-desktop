import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('DmRepository.editMessage', () {
    late MockApiBaseService api;
    late DmRepository repository;

    setUp(() {
      api = MockApiBaseService();
      repository = DmRepository(api);
    });

    test('sends the message id and channel id in the edit request', () async {
      when(
        () => api.put<Map<String, dynamic>>(
          path: '/dms/messages/channel-1',
          data: {
            'content': 'fixed',
            'message_id': 'message-1',
            'thread_id': 'thread-1',
          },
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: <String, dynamic>{},
          statusCode: 200,
        ),
      );

      await repository.editMessage(
        'message-1',
        channelId: 'channel-1',
        content: 'fixed',
        threadId: 'thread-1',
      );

      verify(
        () => api.put<Map<String, dynamic>>(
          path: '/dms/messages/channel-1',
          data: {
            'content': 'fixed',
            'message_id': 'message-1',
            'thread_id': 'thread-1',
          },
        ),
      ).called(1);
    });
  });
}
