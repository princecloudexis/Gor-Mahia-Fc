import 'package:dio/dio.dart';
import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/models/membership_models.dart';
import 'package:eventsbooking/utils/app_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipRepository {
  final ApiClient _apiClient;

  MembershipRepository(this._apiClient);

  Future<MembershipData> fetchBranchesAndPackages() async {
    try {
      final response = await _apiClient.dio.get('/user/branches');
      if (response.data != null && response.data['success'] == true) {
        return MembershipData.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch branches and packages');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<MembershipSubmitResponse> submitMembership({
    required String userId,
    required String country,
    required String branchId,
    required String packageId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/user/membership',
        data: {
          'user_id': userId,
          'country': country,
          'branch_id': branchId,
          'package_type_id': packageId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return MembershipSubmitResponse.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to submit membership');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  Future<PaymentInitiateResponse> initiatePayment({
    required String phone,
    required String membershipId,
    required String amount,
    required String packageName,
  }) async {
    try {
      debugPrint('💳 [MembershipPay] POST /user/pay → phone=$phone, membershipId=$membershipId, amount=$amount');
      final response = await _apiClient.dio.post(
        '/user/pay',
        data: {
          'phone': phone,
          'payment_status': 'pending',
          'membership_id': membershipId,
          'amount': amount,
          'package_name': packageName,
        },
      );
      debugPrint('💳 [MembershipPay] /user/pay RAW RESPONSE: ${response.data}');

      if (response.data != null && response.data['success'] == true) {
        return PaymentInitiateResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to initiate payment');
    } on DioException catch (e) {
      debugPrint('💳 [MembershipPay] /user/pay ERROR: ${e.response?.data}');
      throw AppException.fromDioException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<PaymentStatusResponse> checkPaymentStatus({
    required String checkoutRequestId,
    required String membershipId,
    required String plan,
  }) async {
    try {
      // NOTE: We do NOT send 'payment_status' here — we are ASKING for the status,
      // not telling the backend what it is. Sending 'pending' was causing the API
      // to always respond with pending.
      debugPrint('💳 [MembershipPay] POST /user/status → checkoutRequestId=$checkoutRequestId, membershipId=$membershipId');
      final response = await _apiClient.dio.post(
        '/user/status',
        data: {
          'checkout_request_id': checkoutRequestId,
          'membership_id': membershipId,
          'plan': plan,
        },
      );
      // Log the FULL raw response so we can see exactly what the API returns
      debugPrint('💳 [MembershipPay] /user/status RAW RESPONSE: ${response.data}');

      if (response.statusCode == 200) {
        return PaymentStatusResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to check payment status');
    } on DioException catch (e) {
      debugPrint('💳 [MembershipPay] /user/status ERROR: ${e.response?.data}');
      throw AppException.fromDioException(e);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.watch(apiClientProvider));
});
