import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';

class LoginResponse {
  final String token;
  final UserModel user;
  LoginResponse({required this.token, required this.user});
}

class SignupFormData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String nationalId;
  final String password;
  final String passwordConfirmation;

  SignupFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.nationalId,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phone,
      'national_id': nationalId,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class AuthRepository {
  final ApiClient _apiClient;
  AuthRepository(this._apiClient);
  Future<void> updateUserProfile({
    required int id,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    XFile? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      });

      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.name,
            ),
          ),
        );
      }
      final response = await _apiClient.dio.post(
        '/user/profile',
        data: formData,
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to update profile.',
        );
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? 'Profile update failed.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  // auth_repository.dart
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/user/profile');

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch profile.');
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ??
          'An error occurred fetching the profile.';
      throw Exception(errorMessage);
    }
  }

  Future<MembershipDetails> getMembershipDetails() async {
    try {
      final response = await _apiClient.dio.get('/user/membership/details');
      if (response.data['status'] == 200 || response.data['success'] == true) {
        return MembershipDetails.fromJson(response.data['data']);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch membership details.',
        );
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ??
          'An error occurred fetching membership details.';
      throw Exception(errorMessage);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/reset/password',
        data: {'email': email},
      );
      if (response.data['success'] == true) {
        return;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to send password reset email.',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorMessage =
            e.response?.data['message'] ??
            'Could not find a user with that email.';
        throw Exception(errorMessage);
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> resendRegisterOtp(String encryptedEmail) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/register/resend/otp',
        data: {'encrytemail': encryptedEmail},
      );
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to resend OTP. Please try again.',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorMessage =
            e.response?.data['message'] ??
            'An error occurred while resending OTP.';
        throw Exception(errorMessage);
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<LoginResponse> verifyOtp(String encryptedEmail, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/register/submit',
        data: {'encryptString': encryptedEmail, 'confirmationCode': otp},
      );
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true) {
        final user = UserModel.fromJson(responseData);
        final token = responseData['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return LoginResponse(token: token, user: user);
      } else {
        throw Exception(responseData['message'] ?? 'OTP Verification failed.');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid OTP.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<String> signup(SignupFormData data) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/register/send',
        data: data.toJson(),
      );
      if (response.data['success'] == true) {
        return response.data['encrytemail'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Signup failed.');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorMessage =
            e.response?.data['message'] ?? 'An error occurred during signup.';
        throw Exception(errorMessage);
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    // print("Attempting to login...");
    // print("Endpoint: /user/login");
    // print("Request Body: {'email': '$email', 'password': '$password'}");

    try {
      final response = await _apiClient.dio.post(
        '/user/login',
        data: {'login_email': email, 'login_password': password},
      );
      // print("Login successful! Status Code: ${response.statusCode}");
      // print("Response Data: ${response.data}");

      if (response.data['success'] == true) {
        final user = UserModel.fromJson(response.data);
        final token = response.data['token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return LoginResponse(token: token, user: user);
      } else {
        throw Exception(response.data['message'] ?? 'Login failed.');
      }
    } on DioException catch (e) {
      // print("LOGIN FAILED (DioException)");
      if (e.response != null && e.response?.data is Map) {
        final errorMessage =
            e.response?.data['message'] ?? 'Invalid email or password.';
        throw Exception(errorMessage);
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    } catch (e) {
      print("LOGIN FAILED (General Exception)");
      print("Error: ${e.toString()}");
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    // 1. Call the logout API FIRST while the token is still in SharedPreferences,
    //    so the Bearer header is attached correctly by the Dio interceptor.
    try {
      await _apiClient.dio.post('/user/logout');
    } catch (_) {
      // Ignore errors — we always clear local data regardless of API result.
    }

    // 2. Only THEN remove the token and guest flag from local storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_guest');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
