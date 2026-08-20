import 'package:kogalo_network/models/membership_models.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/repositories/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MembershipStatus { initial, loading, loaded, submitting, success, error }

class MembershipState {
  final MembershipStatus status;
  final MembershipData? data;
  final String? errorMessage;
  final MembershipSubmitResponse? submitResponse;

  MembershipState({
    this.status = MembershipStatus.initial,
    this.data,
    this.errorMessage,
    this.submitResponse,
  });

  MembershipState copyWith({
    MembershipStatus? status,
    MembershipData? data,
    String? errorMessage = '',
    MembershipSubmitResponse? submitResponse,
  }) {
    return MembershipState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage == '' ? this.errorMessage : errorMessage,
      submitResponse: submitResponse ?? this.submitResponse,
    );
  }
}

class MembershipController extends StateNotifier<MembershipState> {
  final MembershipRepository _repository;
  final Ref _ref;

  MembershipController(this._repository, this._ref) : super(MembershipState()) {
    fetchBranchesAndPackages();
  }

  Future<void> fetchBranchesAndPackages() async {
    state = state.copyWith(status: MembershipStatus.loading, errorMessage: null);
    try {
      final data = await _repository.fetchBranchesAndPackages();
      state = state.copyWith(status: MembershipStatus.loaded, data: data, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        status: MembershipStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> submitMembership({
    required String country,
    required String branchId,
    required String packageId,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) {
      state = state.copyWith(
        status: MembershipStatus.error,
        errorMessage: 'You are browsing as a guest. Please log in to purchase a membership.',
      );
      return;
    }

    state = state.copyWith(status: MembershipStatus.submitting, errorMessage: null);
    try {
      final response = await _repository.submitMembership(
        country: country,
        branchId: branchId,
        packageId: packageId,
      );
      state = state.copyWith(
        status: MembershipStatus.success,
        submitResponse: response,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: MembershipStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
  
  Future<void> renewMembership({
    required String packageId,
    required String branchId,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) {
      state = state.copyWith(
        status: MembershipStatus.error,
        errorMessage: 'You must be logged in to renew your membership.',
      );
      return;
    }

    state = state.copyWith(status: MembershipStatus.submitting, errorMessage: null);
    try {
      final response = await _repository.renewMembership(
        packageId: packageId,
        branchId: branchId,
      );
      state = state.copyWith(
        status: MembershipStatus.success,
        submitResponse: response,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: MembershipStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetStatus() {
    state = state.copyWith(status: MembershipStatus.loaded, errorMessage: null);
  }
}

final membershipControllerProvider =
    StateNotifierProvider<MembershipController, MembershipState>((ref) {
  final repository = ref.watch(membershipRepositoryProvider);
  return MembershipController(repository, ref);
});

final membershipRenewalStatusProvider = FutureProvider.autoDispose<MembershipRenewalStatus>((ref) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.getRenewalStatus();
});
