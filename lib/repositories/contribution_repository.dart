import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/models/contribution_models.dart';
import 'package:eventsbooking/utils/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class ContributionRepository {
  final ApiClient _apiClient;

  ContributionRepository(this._apiClient);

  Future<ContributionResponse> getContributions(String tab, int page) async {
    try {
      final response = await _apiClient.dio.get(
        '/user/contributions',
        queryParameters: {'tab': tab, 'page': page},
      );
      print('--- GET Contributions HTTP Status: ${response.statusCode} ---');
      print('--- GET Contributions Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        print('--- GET Contributions Response ---');
        print(response.data);
        final data = response.data['data'];
        if (data != null) {
          return ContributionResponse.fromJson(data);
        }
      }
      throw AppException('Failed to parse contributions');
    } catch (e) {
      print('--- ERROR in GET Contributions: $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<PaymentResponse> payContribution(
    int participantId,
    String phone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/contributions/$participantId/pay',
        data: {'phone': phone},
      );
      print(
        '--- POST Pay Contribution HTTP Status: ${response.statusCode} ---',
      );
      print('--- POST Pay Contribution Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        print('--- POST Pay Contribution Response ---');
        print(response.data);
        final data = response.data['data'];
        if (data != null) {
          return PaymentResponse.fromJson(data);
        }
      }
      throw AppException('Payment initiation failed');
    } catch (e) {
      print('--- ERROR in POST Pay Contribution: $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<PaymentStatusResponse> checkPaymentStatus(
    String checkoutRequestId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/user/contributions/payment/status/$checkoutRequestId',
      );
      print('--- GET Payment Status HTTP Status: ${response.statusCode} ---');
      print('--- GET Payment Status Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        print('--- GET Payment Status Response ---');
        print(response.data);
        return PaymentStatusResponse.fromJson(response.data);
      }
      throw AppException('Failed to fetch payment status');
    } catch (e) {
      print('--- ERROR in GET Payment Status: $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<ContributionCount> getContributionCount() async {
    try {
      final response = await _apiClient.dio.get('/user/contributions/count');
      print(
        '--- GET Contribution Count HTTP Status: ${response.statusCode} ---',
      );
      print('--- GET Contribution Count Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        print('--- GET Contribution Count Response ---');
        print(response.data);
        final data = response.data['data'];
        if (data != null) {
          return ContributionCount.fromJson(data);
        }
      }
      throw AppException('Failed to fetch contribution counts');
    } catch (e) {
      print('--- ERROR in GET Contribution Count: $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }
}

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepository(ref.watch(apiClientProvider));
});
