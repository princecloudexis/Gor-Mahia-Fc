import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reels_model.dart';

/// Manages VideoPlayerController lifecycle for the reels feed.
///
/// Strategy — "Window of 3":
///   Always keeps (currentIndex - 1), currentIndex, (currentIndex + 1)
///   controllers initialized and ready. All others are disposed to free memory.
///
/// This means:
///   • The current reel plays instantly (already initialized).
///   • The next reel is already buffering before the user swipes.
///   • Swiping back is also instant (previous is still alive).
///   • Memory stays bounded — max 3 controllers at any time.
class ReelsPreloadManager extends ChangeNotifier {
  // Active controllers keyed by the reel ID.
  final Map<String, VideoPlayerController> _controllers = {};

  // Tracks which reel IDs have encountered an unrecoverable error.
  final Map<String, bool> _errorStates = {};

  // Tracks which reel IDs are currently being initialized (to avoid double-init).
  final Set<String> _initializing = {};

  int _currentIndex = -1;
  List<Reel> _reels = [];

  bool _disposed = false;
  bool _isActive = true;

  // ─── Public API ────────────────────────────────────────────────────────────

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    _syncPlayback(_currentIndex);
  }

  /// Called by [ReelsFeed] when the reels list first loads or updates.
  void setReels(List<Reel> reels) {
    _reels = reels;
    // If we already have a current index, refresh the window.
    if (_currentIndex >= 0) {
      _updateWindow(_currentIndex);
    }
  }

  /// Called by [ReelsFeed] on every page change.
  void setCurrentIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _updateWindow(index);
    notifyListeners();
  }

  /// Returns the initialized controller for [index], or null if not ready yet.
  VideoPlayerController? getController(int index) {
    if (index < 0 || index >= _reels.length) return null;
    return _controllers[_reels[index].id];
  }

  /// Returns true if the video at [index] has a permanent load error.
  bool hasError(int index) {
    if (index < 0 || index >= _reels.length) return false;
    return _errorStates[_reels[index].id] ?? false;
  }

  /// Retry loading a video that previously errored.
  void retry(int index) {
    if (index < 0 || index >= _reels.length) return;
    final id = _reels[index].id;
    _errorStates.remove(id);
    _initializing.remove(id);
    final old = _controllers.remove(id);
    old?.dispose();
    _initController(index);
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  /// Ensures only [index-1, index, index+1] are alive (window of 3).
  /// Keeping window to ±1 avoids starving the current reel of bandwidth
  /// on slow/mobile networks.
  void _updateWindow(int index) {
    final windowIds = <String>{};
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < _reels.length) {
        windowIds.add(_reels[i].id);
      }
    }

    // Dispose controllers that are outside the window.
    final toRemove = _controllers.keys
        .where((id) => !windowIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
      _initializing.remove(id);
    }

    // Initialize controllers that are inside the window but not yet created.
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < _reels.length) {
        final id = _reels[i].id;
        if (!_controllers.containsKey(id) &&
            !_initializing.contains(id) &&
            !(_errorStates[id] ?? false)) {
          _initController(i);
        }
      }
    }

    // Play current, pause all others.
    _syncPlayback(index);
  }

  /// Initializes and starts buffering the controller at [index].
  /// Uses up to 3 auto-retries before marking as an error.
  Future<void> _initController(int index, {int attempt = 0}) async {
    if (_disposed) return;
    if (index < 0 || index >= _reels.length) return;

    final reel = _reels[index];
    final id = reel.id;

    _initializing.add(id);

    VideoPlayerController controller;

    if (reel.videoUrl.startsWith('assets/')) {
      controller = VideoPlayerController.asset(reel.videoUrl);
    } else {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(reel.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
        ),
      );
    }

    try {
      await controller.initialize();

      if (_disposed) {
        controller.dispose();
        return;
      }

      // Only store if this index is still in the current window.
      final windowIds = <String>{};
      for (int i = _currentIndex - 1; i <= _currentIndex + 1; i++) {
        if (i >= 0 && i < _reels.length) {
          windowIds.add(_reels[i].id);
        }
      }

      if (!windowIds.contains(id)) {
        // Window slid away while we were initializing — discard.
        controller.dispose();
        _initializing.remove(id);
        return;
      }

      controller.setLooping(true);
      _controllers[id] = controller;
      _initializing.remove(id);

      // Sync playback: play if current, pause otherwise.
      _syncPlayback(_currentIndex);
      notifyListeners();
    } catch (e) {
      controller.dispose();
      _initializing.remove(id);

      if (_disposed) return;

      if (attempt < 2) {
        // Exponential back-off: 2s, 5s before final failure.
        // Gives mobile networks time to recover without hammering the connection.
        final delay = attempt == 0 ? 2 : 5;
        await Future.delayed(Duration(seconds: delay));
        if (!_disposed) {
          _initController(index, attempt: attempt + 1);
        }
      } else {
        // All retries exhausted — mark as error.
        _errorStates[id] = true;
        debugPrint('[ReelsPreloadManager] Failed to load reel with ID $id after ${attempt + 1} attempts: $e');
        notifyListeners();
      }
    }
  }

  /// Plays the current controller, pauses all others.
  void _syncPlayback(int currentIndex) {
    final currentId = (currentIndex >= 0 && currentIndex < _reels.length) 
        ? _reels[currentIndex].id 
        : null;

    for (final entry in _controllers.entries) {
      final controller = entry.value;
      if (!controller.value.isInitialized) continue;

      if (entry.key == currentId && _isActive) {
        controller.setVolume(1.0);
        if (!controller.value.isPlaying) {
          controller.play();
        }
      } else {
        if (controller.value.isPlaying) {
          controller.pause();
        }
        controller.setVolume(0.0);
      }
    }
  }

  /// Pause the current reel (e.g., when overlay opens or tab changes).
  void pauseCurrent() {
    if (_currentIndex >= 0 && _currentIndex < _reels.length) {
      _controllers[_reels[_currentIndex].id]?.pause();
      notifyListeners();
    }
  }

  /// Resume the current reel (e.g., when overlay closes or tab is active again).
  void resumeCurrent() {
    if (_currentIndex >= 0 && _currentIndex < _reels.length) {
      final controller = _controllers[_reels[_currentIndex].id];
      if (controller != null && controller.value.isInitialized) {
        controller.setVolume(1.0);
        controller.play();
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
