import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/repositories/community_repository.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late CommunityRepository communityRepository;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    
    communityRepository = CommunityRepository(mockApiClient);
  });

  group('CommunityRepository', () {
    test('fetchJoinedGroups success returns list of CommunityGroup', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': [
          {'id': '1', 'name': 'Kogalo Fans', 'description': 'Official group'}
        ]
      };

      when(() => mockDio.get('/v1/groups/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/groups/me'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await communityRepository.fetchJoinedGroups();

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.name, 'Kogalo Fans');
    });

    test('createPost success returns CommunityPost', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'id': '101',
          'content': 'Hello Kogalo!',
          'media': []
        }
      };

      when(() => mockDio.post(
            '/v1/groups/group1/posts',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/groups/group1/posts'),
            data: mockResponse,
            statusCode: 201,
          ));

      // Act
      final result = await communityRepository.createPost('group1', 'Hello Kogalo!', []);

      // Assert
      expect(result.id, '101');
      expect(result.content, 'Hello Kogalo!');
    });

    test('toggleLikePost success returns like data', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'liked': true,
          'likesCount': 5
        }
      };

      when(() => mockDio.post('/v1/posts/post1/like')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/posts/post1/like'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await communityRepository.toggleLikePost('post1');

      // Assert
      expect(result['liked'], true);
      expect(result['likesCount'], 5);
    });

    test('addComment success returns CommunityComment', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'id': 'c1',
          'content': 'Great post!',
        }
      };

      when(() => mockDio.post(
            '/v1/posts/post1/comments',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/posts/post1/comments'),
            data: mockResponse,
            statusCode: 201,
          ));

      // Act
      final result = await communityRepository.addComment('post1', 'Great post!');

      // Assert
      expect(result.id, 'c1');
      expect(result.content, 'Great post!');
    });

    test('fetchJoinedGroups failure throws Exception', () async {
      // Arrange
      when(() => mockDio.get('/v1/groups/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/groups/me'),
            data: {'success': false, 'message': 'Failed to fetch'},
            statusCode: 400,
          ));

      // Act & Assert
      expect(
        () => communityRepository.fetchJoinedGroups(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to fetch'))),
      );
    });
  });
}
