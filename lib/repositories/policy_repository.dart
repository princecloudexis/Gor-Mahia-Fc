import 'package:dio/dio.dart';
import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/models/policy_model.dart';
import 'package:eventsbooking/utils/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PolicyRepository(apiClient);
});

class PolicyRepository {
  final ApiClient _apiClient;
  PolicyRepository(this._apiClient);

  Future<List<PolicyModel>> _getPolicy(String endpoint) async {
    try {
      final response = await _apiClient.dio.get(endpoint);
      final List<dynamic> data = response.data['data'];
      return data.map((json) => PolicyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw AppException.fromDioException(e);
    }
  }

  Future<List<PolicyModel>> getPrivacyPolicy() async {
    return _getPolicy('/user/privacy/policy');
  }
  Future<List<PolicyModel>> getTermsOfService() async {
    return _getPolicy('/user/term/service');
  }
}