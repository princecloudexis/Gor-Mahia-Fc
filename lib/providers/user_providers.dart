// providers/user_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _authRepository;
  UserNotifier(this._authRepository) : super(null);

  Future<bool> fetchUser() async {
    try {
      final user = await _authRepository.getUserProfile();
      state = user;
      print('👤 User fetched: ${user.firstName} ${user.lastName}');
      print(
        '👤 Stats - Attended: ${user.eventsAttended}, Upcoming: ${user.upcomingEvents}',
      );
      return true;
    } catch (e) {
      print('👤 fetchUser error: $e');
      if (state == null) {
        state = null;
      }
      return false;
    }
  }

  void setUserFromLogin(UserModel user) {
    state = user;
    print('👤 User set from login: ${user.firstName} ${user.lastName}');
  }

  Future<bool> updateUserProfile({
    required int id,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    XFile? imageFile,
  }) async {
    try {
      await _authRepository.updateUserProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        imageFile: imageFile,
      );
      await fetchUser();
      print('👤 Profile updated successfully');
      return true;
    } catch (e) {
      print('👤 updateUserProfile error: $e');
      return false;
    }
  }

  void clearUser() {
    state = null;
    print('👤 User cleared');
  }

  void updateUser(UserModel user) {
    state = user;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return UserNotifier(authRepository);
});

// Convenience provider to check if user exists
final hasUserProvider = Provider<bool>((ref) {
  return ref.watch(userProvider) != null;
});

final membershipDetailsProvider = FutureProvider<MembershipDetails>((ref) {
  return ref.watch(authRepositoryProvider).getMembershipDetails();
});
