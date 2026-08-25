import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/repositories/notification_repository.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late NotificationRepository notificationRepository;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    
    notificationRepository = NotificationRepository(mockApiClient);
  });

  group('NotificationRepository', () {
    test('getNotifications returns PaginatedNotificationsResponse', () async {
      // Arrange
      final mockResponse = {
        'status': 200,
        'success': true,
        'data': [
          {
            'id': 'n1',
            'title': 'Match Update',
            'body': 'Gor Mahia won!',
            'type': 'match',
            'isRead': false,
            'createdAt': '2023-10-01T12:00:00Z',
          }
        ],
        'meta': {
          'currentPage': 1,
          'lastPage': 2,
          'total': 10
        }
      };

      when(() => mockDio.get(
            '/v1/notifications',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/notifications'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await notificationRepository.getNotifications();

      // Assert
      expect(result.notifications.isNotEmpty, true);
      expect(result.notifications.first.title, 'Match Update');
      expect(result.total, 10);
    });

    test('markAsRead success does not throw', () async {
      // Arrange
      when(() => mockDio.post('/v1/notifications/n1/read')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/notifications/n1/read'),
            data: {'status': 200, 'success': true},
            statusCode: 200,
          ));

      // Act & Assert
      expect(() async => await notificationRepository.markAsRead('n1'), returnsNormally);
    });

    test('markAsRead failure throws exception', () async {
      // Arrange
      when(() => mockDio.post('/v1/notifications/n1/read')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/notifications/n1/read'),
            data: {'status': 400, 'success': false},
            statusCode: 400,
          ));

      // Act & Assert
      expect(
        () => notificationRepository.markAsRead('n1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
