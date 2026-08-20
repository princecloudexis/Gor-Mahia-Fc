import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reels_model.dart';

/// Manages VideoPlayerController lifecycle for the reels feed.
///
/// Strategy — "Window of 5 + LRU cache":
///   • Always keeps (currentIndex - 2) → (currentIndex + 2) controllers alive.
///   • Additionally caches up to [_lruCacheSize] recently-seen controllers
///     beyond the active window, so scrolling back is instant.
///   • Total live controllers is capped at [_maxControllers] to bound memory.
///
/// Result:
///   • Scrolling forward: next 2 reels are already buffering.
///   • Scrolling back:    previous 2 reels are already ready (instant replay).
///   • Going back further: LRU cache keeps the last 3 watched reels alive.
class ReelsPreloadManager extends ChangeNotifier {
  // Active controllers keyed by reel ID.
  final Map<String, VideoPlayerController> _controllers = {};

  // LRU access order: most-recently used is at the END of the list.
  final List<String> _lruOrder = [];

  // Reel IDs currently being async-initialised (prevents double-init).
  final Set<String> _initializing = {};

  // Reel IDs that permanently failed to load.
  final Map<String, bool> _errorStates = {};
  // Human-readable reason for each error (for display in the UI).
  final Map<String, String> _errorReasons = {};

  int _currentIndex = -1;
  List<Reel> _reels = [];

  bool _disposed = false;
  bool _isActive = true;

  // ─── Tunables ───────────────────────────────────────────────────────────────
  /// Half-width of the active window on each side of the current index.
  static const int _halfWindow = 2;

  /// Extra controllers to keep alive via LRU beyond the active window.
  static const int _lruCacheSize = 5;

  /// Hard cap — never hold more than this many controllers simultaneously.
  static const int _maxControllers = (2 * _halfWindow + 1) + _lruCacheSize; // 10

  // ─── Public API ─────────────────────────────────────────────────────────────

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    _syncPlayback(_currentIndex);
  }

  void setReels(List<Reel> reels) {
    _reels = reels;
    if (_currentIndex >= 0 && _isActive) {
      _updateWindow(_currentIndex);
    }
  }

  /// Release all hardware decoders (e.g. when opening camera / upload screen).
  void releaseResources() {
    _isActive = false;
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _lruOrder.clear();
    _initializing.clear();
    notifyListeners();
  }

  /// Restore decoders after returning from camera / upload screen.
  void restoreResources() {
    if (_disposed) return;
    _isActive = true;
    if (_currentIndex >= 0) {
      _updateWindow(_currentIndex);
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    _updateWindow(index);
    notifyListeners();
  }

  VideoPlayerController? getController(int index) {
    if (index < 0 || index >= _reels.length) return null;
    return _controllers[_reels[index].id];
  }

  bool hasError(int index) {
    if (index < 0 || index >= _reels.length) return false;
    return _errorStates[_reels[index].id] ?? false;
  }

  /// Returns a human-readable error reason, e.g. 'codec' or 'network'.
  String errorReason(int index) {
    if (index < 0 || index >= _reels.length) return 'network';
    return _errorReasons[_reels[index].id] ?? 'network';
  }

  void retry(int index) {
    if (index < 0 || index >= _reels.length) return;
    final id = _reels[index].id;
    _errorStates.remove(id);
    _errorReasons.remove(id);
    _initializing.remove(id);
    final old = _controllers.remove(id);
    _lruOrder.remove(id);
    old?.dispose();
    notifyListeners(); // Immediately clear error state in UI
    _initController(index);
  }

  // ─── Internal ───────────────────────────────────────────────────────────────

  /// Computes which reel IDs should stay alive in the active window.
  Set<String> _windowIds(int index) {
    final ids = <String>{};
    for (int i = index - _halfWindow; i <= index + _halfWindow; i++) {
      if (i >= 0 && i < _reels.length) ids.add(_reels[i].id);
    }
    return ids;
  }

  /// Main entry point — called on every page change and on initial load.
  void _updateWindow(int index) {
    final wIds = _windowIds(index);

    // ── Eviction: remove controllers beyond the hard cap ────────────────────
    // Keep active-window IDs; evict least-recently-used extras first.
    if (_controllers.length > _maxControllers) {
      for (final id in List<String>.from(_lruOrder)) {
        if (_controllers.length <= _maxControllers) break;
        if (wIds.contains(id)) continue; // never evict active window
        _evict(id);
      }
    }

    // ── Step 1: Init current reel immediately ────────────────────────────────
    _initIfNeeded(index);

    // ── Step 2: Init nearby reels with a short stagger ──────────────────────
    // Slight stagger so current reel gets priority bandwidth, but neighbors
    // begin buffering very quickly so swiping feels instant.
    final capturedIndex = index;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_disposed || _currentIndex != capturedIndex) return;
      _initIfNeeded(capturedIndex - 1);
      _initIfNeeded(capturedIndex + 1);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_disposed || _currentIndex != capturedIndex) return;
      _initIfNeeded(capturedIndex - 2);
      _initIfNeeded(capturedIndex + 2);
    });

    // ── Step 3: Sync play/pause ──────────────────────────────────────────────
    _syncPlayback(index);
  }

  void _initIfNeeded(int i) {
    if (i < 0 || i >= _reels.length) return;
    final id = _reels[i].id;
    if (!_controllers.containsKey(id) &&
        !_initializing.contains(id) &&
        !(_errorStates[id] ?? false)) {
      _initController(i);
    } else if (_controllers.containsKey(id)) {
      // Already alive — bump it to the most-recently-used position.
      _touchLru(id);
    }
  }

  Future<void> _initController(int index, {int attempt = 0}) async {
    if (_disposed) return;
    if (index < 0 || index >= _reels.length) return;

    final reel = _reels[index];
    if (reel.type == 'ad' && reel.mediaType != 'video') return;

    final id = reel.id;
    _initializing.add(id);

    final urlToPlay = (reel.type == 'ad' && reel.mediaType == 'video')
        ? (reel.mediaUrl ?? reel.videoUrl)
        : reel.videoUrl;

    if (urlToPlay.isEmpty) {
      _initializing.remove(id);
      return;
    }

    late VideoPlayerController controller;
    if (urlToPlay.startsWith('assets/')) {
      controller = VideoPlayerController.asset(urlToPlay);
    } else {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(urlToPlay),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    }

    try {
      await controller.initialize();

      // Seek to start to kick off immediate buffering on some decoders.
      await controller.seekTo(Duration.zero);

      if (_disposed) {
        controller.dispose();
        return;
      }

      // Check the reel is still needed (active window or LRU budget).
      final wIds = _windowIds(_currentIndex);
      final isInWindow = wIds.contains(id);
      final hasLruBudget =
          _controllers.length < _maxControllers || _lruOrder.contains(id);

      if (!isInWindow && !hasLruBudget) {
        controller.dispose();
        _initializing.remove(id);
        return;
      }

      // If at cap, evict LRU before storing.
      if (_controllers.length >= _maxControllers && !_controllers.containsKey(id)) {
        _evictLru(exclude: _windowIds(_currentIndex));
      }

      controller.setLooping(true);
      _controllers[id] = controller;
      _touchLru(id);
      _initializing.remove(id);

      _syncPlayback(_currentIndex);
      notifyListeners();
    } catch (e) {
      controller.dispose();
      _initializing.remove(id);

      if (_disposed) return;

      // Detect hardware decoder failures — retrying won't help these.
      // The error message contains 'DecoderInitializationException' or
      // 'CodecException' or 'MediaCodecVideoRenderer' on Android.
      final errStr = e.toString();
      final isCodecFailure = errStr.contains('DecoderInitializationException') ||
          errStr.contains('CodecException') ||
          errStr.contains('MediaCodecVideoRenderer') ||
          errStr.contains('0xfffffff') ||
          errStr.contains('format_supported=YES'); // ExoPlayer codec init fail

      if (isCodecFailure) {
        // Fail immediately — the device cannot decode this format.
        _errorStates[id] = true;
        _errorReasons[id] = 'codec';
        debugPrint('[ReelsPreloadManager] Codec/hardware failure for reel $id: $e');
        notifyListeners();
        return;
      }

      if (attempt < 2) {
        final delay = attempt == 0 ? 2 : 5;
        await Future.delayed(Duration(seconds: delay));
        if (!_disposed) _initController(index, attempt: attempt + 1);
      } else {
        _errorStates[id] = true;
        _errorReasons[id] = 'network';
        debugPrint(
            '[ReelsPreloadManager] Failed to load reel $id after ${attempt + 1} attempts: $e');
        notifyListeners();
      }
    }
  }

  /// Moves [id] to the end of the LRU list (most recently used).
  void _touchLru(String id) {
    _lruOrder.remove(id);
    _lruOrder.add(id);
  }

  /// Evicts a single controller, preferring the least-recently-used one
  /// that is NOT in [exclude].
  void _evictLru({required Set<String> exclude}) {
    for (final id in List<String>.from(_lruOrder)) {
      if (!exclude.contains(id) && _controllers.containsKey(id)) {
        _evict(id);
        return;
      }
    }
  }

  void _evict(String id) {
    _controllers[id]?.dispose();
    _controllers.remove(id);
    _lruOrder.remove(id);
  }

  void _syncPlayback(int currentIndex) {
    final currentId =
        (currentIndex >= 0 && currentIndex < _reels.length)
            ? _reels[currentIndex].id
            : null;

    for (final entry in _controllers.entries) {
      final controller = entry.value;
      if (!controller.value.isInitialized) continue;

      if (entry.key == currentId && _isActive) {
        controller.setVolume(1.0);
        if (!controller.value.isPlaying) controller.play();
      } else {
        if (controller.value.isPlaying) controller.pause();
        controller.setVolume(0.0);
      }
    }
  }

  void pauseCurrent() {
    if (_currentIndex >= 0 && _currentIndex < _reels.length) {
      _controllers[_reels[_currentIndex].id]?.pause();
      notifyListeners();
    }
  }

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
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _lruOrder.clear();
    super.dispose();
  }
}
