import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/models/contribution_models.dart';
import 'package:kogalo_network/utils/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ContributionRepository {
  final ApiClient _apiClient;

  ContributionRepository(this._apiClient);

  Future<ContributionResponse> getContributions(String tab, int page) async {
    try {
      debugPrint('--- FETCHING Contributions (Tab: $tab, Page: $page) ---');
      final response = await _apiClient.dio.get(
        '/user/contributions',
        queryParameters: {'tab': tab, 'page': page},
      );
      debugPrint(
        '--- GET Contributions HTTP Status: ${response.statusCode} ---',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('--- GET Contributions Response for Tab: $tab ---');
        debugPrint(response.data.toString());
        final data = response.data['data'];
        if (data != null) {
          return ContributionResponse.fromJson(data);
        }
      }
      throw AppException('Failed to parse contributions');
    } catch (e) {
      debugPrint('--- ERROR in GET Contributions (Tab: $tab): $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<PaymentResponse> payContribution(
    int participantId,
    String email,
    String amount,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/contributions/$participantId/pay',
        data: {
          'email': email,
          'amount': amount,
        },
      );
      debugPrint(
        '--- POST Pay Contribution HTTP Status: ${response.statusCode} ---',
      );
      debugPrint('--- POST Pay Contribution Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('--- POST Pay Contribution Response ---');
        debugPrint(response.data.toString());
        final data = response.data['data'];
        if (data != null) {
          return PaymentResponse.fromJson(data);
        }
      }
      throw AppException('Payment initiation failed');
    } catch (e) {
      debugPrint('--- ERROR in POST Pay Contribution: $e ---');
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
      debugPrint('--- GET Payment Status HTTP Status: ${response.statusCode} ---');
      debugPrint('--- GET Payment Status Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('--- GET Payment Status Response ---');
        debugPrint(response.data.toString());
        return PaymentStatusResponse.fromJson(response.data);
      }
      throw AppException('Failed to fetch payment status');
    } catch (e) {
      debugPrint('--- ERROR in GET Payment Status: $e ---');
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
      debugPrint(
        '--- GET Contribution Count HTTP Status: ${response.statusCode} ---',
      );
      debugPrint('--- GET Contribution Count Body: ${response.data} ---');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('--- GET Contribution Count Response ---');
        debugPrint(response.data.toString());
        final data = response.data['data'];
        if (data != null) {
          return ContributionCount.fromJson(data);
        }
      }
      throw AppException('Failed to fetch contribution counts');
    } catch (e) {
      debugPrint('--- ERROR in GET Contribution Count: $e ---');
      if (e is DioException) {
        throw AppException.fromDioException(e);
      }
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<ContributionHistoryResponse> getContributionHistory(int page) async {
    try {
      debugPrint('--- FETCHING Contribution History (Page: $page) ---');
      final response = await _apiClient.dio.get(
        '/user/contributions/history',
        queryParameters: {'page': page},
      );
      debugPrint(
        '--- GET Contribution History HTTP Status: ${response.statusCode} ---',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return ContributionHistoryResponse.fromJson(data);
        }
      }
      throw AppException('Failed to parse contribution history');
    } catch (e) {
      debugPrint('--- ERROR in GET Contribution History: $e ---');
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
