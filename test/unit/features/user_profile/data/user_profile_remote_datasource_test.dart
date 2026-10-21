import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  late MockApiBaseService mockApi;

  setUp(() => mockApi = MockApiBaseService());

  UserProfileRemoteDataSourceImpl dataSource({required bool mock}) =>
      UserProfileRemoteDataSourceImpl(
        config: AppConfig(
          apiBaseUrl: 'https://api.example.com',
          usesMockData: mock,
        ),
        apiBaseService: mockApi,
      );

  group('deleteOrganization', () {
    test('calls DELETE /organisations/{orgId}', () async {
      when(
        () => mockApi.delete<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {},
          statusCode: 200,
        ),
      );

      await dataSource(mock: false).deleteOrganization('org_1');

      verify(
        () =>
            mockApi.delete<Map<String, dynamic>>(path: '/organisations/org_1'),
      ).called(1);
    });

    test('makes no request in mock mode', () async {
      await dataSource(mock: true).deleteOrganization('org_1');

      verifyNever(
        () => mockApi.delete<Map<String, dynamic>>(path: any(named: 'path')),
      );
    });
  });
}
