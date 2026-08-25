import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/repositories/reels_repository.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late ReelsRepository reelsRepository;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    
    reelsRepository = ReelsRepository(mockApiClient);
  });

  group('ReelsRepository', () {
    test('fetchReels success returns ReelResponse', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': [
          {
            'id': 1, // Using integer ID because JSON parser usually does
            'videoUrl': 'https://video.com/1.mp4',
            'caption': 'Great goal!',
            'authorId': 1,
            'authorName': 'John',
            'likesCount': 10,
            'commentsCount': 2,
            'isLikedByMe': false,
            'durationSeconds': 15,
            'viewsCount': 100
          }
        ]
      };

      when(() => mockDio.get(
            '/v1/reels',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/reels'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await reelsRepository.fetchReels(limit: 10);

      // Assert
      expect(result.data.isNotEmpty, true);
      expect(result.data.first.id, '1'); // The model might parse int to string
      expect(result.data.first.caption, 'Great goal!');
    });

    test('toggleLike success returns updated like data', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'liked': true,
          'likesCount': 11
        }
      };

      when(() => mockDio.post('/v1/reels/1/like')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/reels/1/like'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await reelsRepository.toggleLike('1');

      // Assert
      expect(result['liked'], true);
      expect(result['likesCount'], 11);
    });

    test('addReelComment success returns mapped comment data', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'id': 'c1',
          'content': 'Nice video',
          'authorId': '2',
          'authorName': 'Alice'
        }
      };

      when(() => mockDio.post(
            '/v1/reels/1/comments',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/v1/reels/1/comments'),
            data: mockResponse,
            statusCode: 201,
          ));

      // Act
      final result = await reelsRepository.addReelComment('1', 'Nice video');

      // Assert
      expect(result['comment'], isNotNull);
      expect(result['comment'].content, 'Nice video');
    });
  });
}
