import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late AuthRepository authRepository;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    
    authRepository = AuthRepository(mockApiClient);
  });

  group('AuthRepository', () {
    test('login success returns LoginResponse and saves token', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'token': 'mock_token_123',
        'user': {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'test@example.com',
          'phone_number': '1234567890',
        }
      };

      when(() => mockDio.post(
            '/user/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/user/login'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await authRepository.login('test@example.com', 'password123');

      // Assert
      expect(result.token, 'mock_token_123');
      expect(result.user.firstName, 'John');
      expect(result.user.email, 'test@example.com');
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'mock_token_123');
    });

    test('login failure throws Exception', () async {
      // Arrange
      when(() => mockDio.post(
            '/user/login',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/user/login'),
            data: {'success': false, 'message': 'Invalid email or password.'},
            statusCode: 401,
          ));

      // Act & Assert
      expect(
        () => authRepository.login('test@example.com', 'wrongpassword'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Invalid email or password.'))),
      );
    });

    test('signup success returns encrypted email', () async {
      // Arrange
      final formData = SignupFormData(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '0987654321',
        nationalId: '12345',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      when(() => mockDio.post(
            '/user/register/send',
            data: any(named: 'data'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/user/register/send'),
            data: {'success': true, 'encrytemail': 'encrypted_jane@example.com'},
            statusCode: 200,
          ));

      // Act
      final result = await authRepository.signup(formData);

      // Assert
      expect(result, 'encrypted_jane@example.com');
    });

    test('getUserProfile success returns UserModel', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'id': 2,
          'first_name': 'Alice',
          'last_name': 'Smith',
          'email': 'alice@example.com',
        }
      };

      when(() => mockDio.get('/user/profile')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/user/profile'),
            data: mockResponse,
            statusCode: 200,
          ));

      // Act
      final result = await authRepository.getUserProfile();

      // Assert
      expect(result.id, 2);
      expect(result.firstName, 'Alice');
    });

    test('logout clears local storage', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'old_token');
      await prefs.setBool('is_guest', true);

      when(() => mockDio.post('/user/logout')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/user/logout'),
            data: {'success': true},
            statusCode: 200,
          ));

      // Act
      await authRepository.logout();

      // Assert
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getBool('is_guest'), isNull);
    });
  });
}
