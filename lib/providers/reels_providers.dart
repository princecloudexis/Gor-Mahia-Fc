import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/reels_model.dart';
import '../repositories/reels_repository.dart';
import '../pages/reels/reels_feed.dart';

/// Caches the user's location to avoid hitting GPS hardware on every single video swipe
class LocationCache {
  static double? latitude;
  static double? longitude;
  static String? city;
  static String? country;
  static bool _isFetching = false;
  static DateTime? _lastFetched;

  static Future<void> updateLocation() async {
    if (_isFetching) return;
    // Only fetch every 15 minutes max to save battery
    if (_lastFetched != null && DateTime.now().difference(_lastFetched!).inMinutes < 15) return;

    try {
      _isFetching = true;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      // Only get location if permission is already granted, don't prompt here (prompt is only on upload screen)
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)));

      latitude = position.latitude;
      longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        city = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
        country = place.country;
      }
      _lastFetched = DateTime.now();
    } catch (_) {
      // Ignore errors silently for background tracking
    } finally {
      _isFetching = false;
    }
  }
}

class ReelsNotifier extends StateNotifier<AsyncValue<ReelResponse>> {
  final ReelsRepository _repo;

  ReelsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchReels();
  }

  Future<void> fetchReels({bool isRefresh = false}) async {
    if (!isRefresh) {
      state = const AsyncValue.loading();
    }
    try {
      final res = await _repo.fetchReels();
      if (!mounted) return;
      state = AsyncValue.data(res);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void addReel(Reel newReel) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(
        ReelResponse(
          data: [newReel, ...currentState.data],
          meta: currentState.meta,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        currentState.meta == null ||
        !currentState.meta!.hasNextPage)
      return;

    try {
      final res = await _repo.fetchReels(
        cursor: currentState.meta!.nextCursor,
        position: currentState.meta!.position,
      );

      if (!mounted) return;
      state = AsyncValue.data(
        ReelResponse(data: [...currentState.data, ...res.data], meta: res.meta),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      print("Pagination error: $e");
    }
  }

  /// Returns true/false when the [key] is explicitly present in [map],
  /// or null when the key is absent (so callers can tell "not provided" from "false").
  bool? _parseBoolField(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final v = map[key];
    return v == true || v == 'true' || v == 1 || v == '1';
  }

  Future<void> toggleLike(String reelId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final int reelIndex = currentState.data.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final oldReel = currentState.data[reelIndex];
    final bool newLikeStatus = !oldReel.isLikedByMe;
    final int newLikesCount = newLikeStatus
        ? oldReel.likesCount + 1
        : (oldReel.likesCount - 1).clamp(0, 999999999);

    final newReel = oldReel.copyWith(
      isLikedByMe: newLikeStatus,
      likesCount: newLikesCount,
    );

    final List<Reel> newData = List.from(currentState.data);
    newData[reelIndex] = newReel;

    if (mounted) {
      state = AsyncValue.data(
        ReelResponse(data: newData, meta: currentState.meta),
      );
    }

    try {
      final responseData = await _repo.toggleLike(reelId);
      
      if (mounted) {
        final currentSt = state.valueOrNull;
        if (currentSt != null) {
          final idx = currentSt.data.indexWhere((r) => r.id == reelId);
          if (idx != -1) {
            // Check both 'isLikedByMe' (fetch API key) and 'liked' (toggle API key).
            // If the response contains neither key, fall back to the optimistic value
            // we already set — do NOT default to false.
            final bool? apiIsLiked = _parseBoolField(responseData, 'isLikedByMe')
                ?? _parseBoolField(responseData, 'liked');

            final int? apiLikes = responseData['likesCount'] is int 
                ? responseData['likesCount'] 
                : int.tryParse(responseData['likesCount']?.toString() ?? '');
            
            final apiReel = currentSt.data[idx].copyWith(
              // Only override if the API actually told us the liked state;
              // otherwise keep the optimistic value already in state.
              isLikedByMe: apiIsLiked ?? currentSt.data[idx].isLikedByMe,
              likesCount: apiLikes ?? currentSt.data[idx].likesCount,
            );
            
            final List<Reel> apiData = List.from(currentSt.data);
            apiData[idx] = apiReel;
            state = AsyncValue.data(ReelResponse(data: apiData, meta: currentSt.meta));
          }
        }
      }
    } catch (e) {
      // Revert optimistic update on failure
      if (mounted) {
        final revertData = List<Reel>.from(currentState.data);
        revertData[reelIndex] = oldReel; // Revert to old state
        state = AsyncValue.data(
          ReelResponse(data: revertData, meta: currentState.meta),
        );
      }
    }
  }

  Future<void> shareReel(String reelId, {String platform = 'other'}) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final int reelIndex = currentState.data.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final oldReel = currentState.data[reelIndex];
    final newReel = oldReel.copyWith(sharesCount: oldReel.sharesCount + 1);

    final List<Reel> newData = List.from(currentState.data);
    newData[reelIndex] = newReel;

    if (mounted) {
      state = AsyncValue.data(
        ReelResponse(data: newData, meta: currentState.meta),
      );
    }

    try {
      await _repo.shareReel(reelId, platform: platform);
    } catch (e) {
      // Revert optimistic update on failure
      if (mounted) {
        final revertData = List<Reel>.from(currentState.data);
        revertData[reelIndex] = oldReel; 
        state = AsyncValue.data(
          ReelResponse(data: revertData, meta: currentState.meta),
        );
      }
    }
  }

  Future<String> markNotInterested(String reelId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return "Success";

    final int reelIndex = currentState.data.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return "Success";

    final List<Reel> newData = List.from(currentState.data)..removeAt(reelIndex);

    if (mounted) {
      state = AsyncValue.data(
        ReelResponse(data: newData, meta: currentState.meta),
      );
    }

    try {
      final res = await _repo.markNotInterested(reelId);
      return res['message']?.toString() ?? "Got it, you'll see less of this.";
    } catch (e) {
      if (mounted) {
        final revertData = List<Reel>.from(currentState.data);
        state = AsyncValue.data(
          ReelResponse(data: revertData, meta: currentState.meta),
        );
      }
      rethrow;
    }
  }

  void incrementCommentCount(String reelId, {int? commentsCount}) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final int reelIndex = currentState.data.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final oldReel = currentState.data[reelIndex];
    final newReel = oldReel.copyWith(commentsCount: commentsCount ?? oldReel.commentsCount + 1);

    final List<Reel> newData = List.from(currentState.data);
    newData[reelIndex] = newReel;

    if (mounted) {
      state = AsyncValue.data(
        ReelResponse(data: newData, meta: currentState.meta),
      );
    }
  }

  Future<void> syncReelStats(String reelId) async {
    try {
      final updatedReel = await _repo.fetchReel(reelId);
      if (!mounted) return;
      final currentState = state.valueOrNull;
      if (currentState == null) return;
      
      final int reelIndex = currentState.data.indexWhere((r) => r.id == reelId);
      if (reelIndex == -1) return;

      final List<Reel> newData = List.from(currentState.data);
      newData[reelIndex] = updatedReel;
      
      state = AsyncValue.data(
        ReelResponse(data: newData, meta: currentState.meta),
      );
    } catch (e) {
      print("Failed to sync reel stats for $reelId: $e");
    }
  }

  Future<void> logView(String reelId, {int watchedSeconds = 0}) async {
    // We typically don't optimistically update view count instantly to avoid flicker,
    // just fire and forget the API call.
    await _repo.viewReel(reelId, watchedSeconds: watchedSeconds);
  }

  Future<void> logActivity({
    required String reelId,
    required double watchedPercentage,
    required int watchedSeconds,
  }) async {
    // Fire and forget updating the location cache
    LocationCache.updateLocation();

    await _repo.logActivity(
      reelId: reelId,
      eventType: 'play', // As requested by backend: POST /v1/reels/activity
      watchedPercentage: watchedPercentage,
      watchedSeconds: watchedSeconds,
      latitude: LocationCache.latitude,
      longitude: LocationCache.longitude,
      city: LocationCache.city,
      country: LocationCache.country,
    );
  }

  Future<void> deleteReel(String reelId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      await _repo.deleteReel(reelId);
      
      // Update state to remove the deleted reel
      if (mounted) {
        final newData = currentState.data.where((r) => r.id != reelId).toList();
        state = AsyncValue.data(
          ReelResponse(data: newData, meta: currentState.meta),
        );
      }
    } catch (e) {
      print('Failed to delete reel: $e');
      rethrow;
    }
  }
}

final reelsFeedProvider =
    StateNotifierProvider.autoDispose<ReelsNotifier, AsyncValue<ReelResponse>>((
      ref,
    ) {
      final repo = ref.watch(reelsRepositoryProvider);
      return ReelsNotifier(repo);
    });

class ReelCommentsNotifier extends StateNotifier<AsyncValue<ReelCommentResponse>> {
  final ReelsRepository _repo;
  final String reelId;
  final Ref ref;

  ReelCommentsNotifier(this._repo, this.reelId, this.ref) : super(const AsyncValue.loading()) {
    fetchComments();
  }

  Future<void> fetchComments() async {
    state = const AsyncValue.loading();
    try {
      final res = await _repo.fetchReelComments(reelId);
      if (!mounted) return;
      state = AsyncValue.data(res);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.meta == null || !currentState.meta!.hasNextPage) {
      return;
    }
    try {
      final res = await _repo.fetchReelComments(reelId, cursor: currentState.meta!.nextCursor);
      if (!mounted) return;
      state = AsyncValue.data(
        ReelCommentResponse(
          data: [...currentState.data, ...res.data],
          meta: res.meta,
        ),
      );
    } catch (e) {
      print("Pagination error: $e");
    }
  }

  Future<void> addComment(String content, {String? parentId}) async {
    try {
      final result = await _repo.addReelComment(reelId, content, parentId: parentId);
      final newComment = result['comment'] as ReelComment;
      final commentsCount = result['commentsCount'] as int?;
      
      if (!mounted) return;
      final currentState = state.valueOrNull;
      if (currentState != null) {
        if (parentId == null) {
          state = AsyncValue.data(
            ReelCommentResponse(
              data: [newComment, ...currentState.data],
              meta: currentState.meta,
            ),
          );
        } else {
          final newData = _addReplyToTree(currentState.data, parentId, newComment);
          state = AsyncValue.data(
            ReelCommentResponse(
              data: newData,
              meta: currentState.meta,
            ),
          );
        }
        if (commentsCount == null) {
          ref.read(reelsFeedProvider.notifier).syncReelStats(reelId);
          ref.read(myReelsProvider.notifier).syncReelStats(reelId);
        } else {
          ref.read(reelsFeedProvider.notifier).incrementCommentCount(reelId, commentsCount: commentsCount);
          ref.read(myReelsProvider.notifier).incrementCommentCount(reelId, commentsCount: commentsCount);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadReplies(String commentId, {int page = 1}) async {
    try {
      final res = await _repo.fetchCommentReplies(commentId, page: page);
      if (!mounted) return;
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final newData = _appendRepliesToTree(currentState.data, commentId, res.data, res.meta);
        state = AsyncValue.data(
          ReelCommentResponse(
            data: newData,
            meta: currentState.meta,
          ),
        );
      }
    } catch (e) {
      print("Failed to load replies: $e");
    }
  }

  List<ReelComment> _addReplyToTree(List<ReelComment> comments, String parentId, ReelComment reply) {
    return comments.map((c) {
      if (c.id == parentId) {
        return c.copyWith(
          replies: [...c.replies, reply],
          repliesCount: c.repliesCount + 1,
        );
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _addReplyToTree(c.replies, parentId, reply));
      }
      return c;
    }).toList();
  }

  List<ReelComment> _appendRepliesToTree(List<ReelComment> comments, String commentId, List<ReelComment> newReplies, ReelPagination? meta) {
    return comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(
          replies: [...c.replies, ...newReplies],
          hasMoreReplies: meta?.hasNextPage ?? false,
          nextRepliesCount: meta?.nextCount ?? 0,
        );
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _appendRepliesToTree(c.replies, commentId, newReplies, meta));
      }
      return c;
    }).toList();
  }

  Future<void> toggleCommentLike(String commentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    final newData = _toggleLikeInTree(currentState.data, commentId);
    state = AsyncValue.data(
      ReelCommentResponse(data: newData, meta: currentState.meta),
    );

    try {
      final responseData = await _repo.toggleCommentLike(commentId);
      if (!mounted) return;
      
      final currentSt = state.valueOrNull;
      if (currentSt != null) {
        final bool isLiked = responseData['liked'] == true || responseData['liked'] == 'true' || responseData['liked'] == 1;
        final int? apiLikes = responseData['likesCount'] is int 
            ? responseData['likesCount'] 
            : int.tryParse(responseData['likesCount']?.toString() ?? '');
            
        final syncedData = _updateLikeInTree(currentSt.data, commentId, isLiked, apiLikes);
        state = AsyncValue.data(
          ReelCommentResponse(data: syncedData, meta: currentSt.meta),
        );
      }
    } catch (e) {
      // Revert on failure (we just re-fetch or reverse optimistic, for simplicity we could just reverse it)
      if (mounted) {
        final revertData = _toggleLikeInTree(state.valueOrNull!.data, commentId); // Toggle back
        state = AsyncValue.data(
          ReelCommentResponse(data: revertData, meta: currentState.meta),
        );
      }
    }
  }

  List<ReelComment> _toggleLikeInTree(List<ReelComment> comments, String commentId) {
    return comments.map((c) {
      if (c.id == commentId) {
        final newLikeStatus = !c.isLikedByMe;
        final newLikesCount = newLikeStatus ? c.likesCount + 1 : (c.likesCount - 1).clamp(0, 999999999);
        return c.copyWith(
          isLikedByMe: newLikeStatus,
          likesCount: newLikesCount,
        );
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _toggleLikeInTree(c.replies, commentId));
      }
      return c;
    }).toList();
  }

  List<ReelComment> _updateLikeInTree(List<ReelComment> comments, String commentId, bool isLiked, int? likesCount) {
    return comments.map((c) {
      if (c.id == commentId) {
        return c.copyWith(
          isLikedByMe: isLiked,
          likesCount: likesCount ?? c.likesCount,
        );
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _updateLikeInTree(c.replies, commentId, isLiked, likesCount));
      }
      return c;
    }).toList();
  }
}

final reelCommentsProvider =
    StateNotifierProvider.family.autoDispose<ReelCommentsNotifier, AsyncValue<ReelCommentResponse>, String>((
      ref,
      reelId,
    ) {
      final repo = ref.watch(reelsRepositoryProvider);
      return ReelCommentsNotifier(repo, reelId, ref);
    });

class ReelUploadState {
  final bool isUploading;
  final double progress;
  final String? error;
  final String? videoPath;

  ReelUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
    this.videoPath,
  });

  ReelUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? error,
    String? videoPath,
  }) {
    return ReelUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      videoPath: videoPath ?? this.videoPath,
    );
  }
}

class ReelUploadNotifier extends StateNotifier<ReelUploadState> {
  final ReelsRepository _repo;
  final Ref _ref;

  ReelUploadNotifier(this._repo, this._ref) : super(ReelUploadState());

  Future<void> uploadReel(
    String videoPath,
    String caption, {
    int durationSeconds = 0,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.0, error: null, videoPath: videoPath);
    try {
      final videoUrl = await _repo.uploadReelMedia(
        videoPath,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      final newReel = await _repo.createReel(
        videoUrl,
        caption,
        durationSeconds: durationSeconds,
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );

      if (mounted) {
        state = ReelUploadState(); // Reset
      }

      // Add the new reel to the top of the feed without fully refreshing!
      _ref.read(reelsFeedProvider.notifier).addReel(newReel);
      
      // Also add it to "My Reels" locally so it shows immediately
      _ref.read(myReelsProvider.notifier).addReel(newReel);
      
      // We also want to scroll to the top so they can see it instantly.
      reelsFeedKey.currentState?.scrollToTop();


    } catch (e) {
      if (mounted) {
        state = state.copyWith(isUploading: false, error: e.toString());
      }
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = ReelUploadState();
  }
}

final reelUploadProvider = StateNotifierProvider<ReelUploadNotifier, ReelUploadState>((ref) {
  final repo = ref.watch(reelsRepositoryProvider);
  return ReelUploadNotifier(repo, ref);
});

// ─────────────────────────────────────────────
// MY REELS
// ─────────────────────────────────────────────

class MyReelsNotifier extends StateNotifier<AsyncValue<List<Reel>>> {
  final ReelsRepository _repo;

  MyReelsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchMyReels();
  }

  Future<void> fetchMyReels({bool isRefresh = false}) async {
    if (!isRefresh) {
      state = const AsyncValue.loading();
    }
    try {
      final res = await _repo.fetchMyReels();
      if (!mounted) return;
      
      // If we had locally added reels that the backend hasn't returned yet (due to delay), 
      // we could preserve them, but for now we just update the state.
      state = AsyncValue.data(res.data);
    } catch (e, stackTrace) {
      if (!mounted) return;
      if (!isRefresh || state.valueOrNull == null) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  void addReel(Reel newReel) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      // Check if it already exists to avoid duplicates
      if (!currentState.any((r) => r.id == newReel.id)) {
        state = AsyncValue.data([newReel, ...currentState]);
      }
    } else {
      state = AsyncValue.data([newReel]);
    }
  }

  Future<void> deleteReel(String reelId) async {
    try {
      await _repo.deleteReel(reelId);
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.where((r) => r.id != reelId).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editReel(String reelId, String caption, String visibility) async {
    try {
      final updatedReel = await _repo.editReel(reelId, caption: caption, visibility: visibility);
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.map((r) => r.id == reelId ? updatedReel : r).toList(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void incrementCommentCount(String reelId, {int? commentsCount}) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final int reelIndex = currentState.indexWhere((r) => r.id == reelId);
    if (reelIndex == -1) return;

    final oldReel = currentState[reelIndex];
    final newReel = oldReel.copyWith(commentsCount: commentsCount ?? oldReel.commentsCount + 1);

    final List<Reel> newData = List.from(currentState);
    newData[reelIndex] = newReel;

    if (mounted) {
      state = AsyncValue.data(newData);
    }
  }

  Future<void> syncReelStats(String reelId) async {
    try {
      final updatedReel = await _repo.fetchReel(reelId);
      if (!mounted) return;
      final currentState = state.valueOrNull;
      if (currentState == null) return;
      
      final int reelIndex = currentState.indexWhere((r) => r.id == reelId);
      if (reelIndex == -1) return;

      final List<Reel> newData = List.from(currentState);
      newData[reelIndex] = updatedReel;
      
      state = AsyncValue.data(newData);
    } catch (e) {
      print("Failed to sync my reel stats for $reelId: $e");
    }
  }
}

final myReelsProvider = StateNotifierProvider<MyReelsNotifier, AsyncValue<List<Reel>>>((ref) {
  final repo = ref.watch(reelsRepositoryProvider);
  return MyReelsNotifier(repo);
});
