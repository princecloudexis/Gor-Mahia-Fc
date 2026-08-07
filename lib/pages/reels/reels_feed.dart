import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/navigation_providers.dart';
import '../../providers/reels_providers.dart';
import 'widgets/video_player_item.dart';
import 'widgets/reels_preload_manager.dart';
import 'custom_camera_screen.dart';

final GlobalKey<RefreshIndicatorState> reelsRefreshKey =
    GlobalKey<RefreshIndicatorState>();
final GlobalKey<ReelsFeedState> reelsFeedKey = GlobalKey<ReelsFeedState>();

class ReelsFeed extends ConsumerStatefulWidget {
  const ReelsFeed({super.key});

  @override
  ConsumerState<ReelsFeed> createState() => ReelsFeedState();
}

class ReelsFeedState extends ConsumerState<ReelsFeed> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isOverlayOpen = false;

  /// Central preload manager — owns all VideoPlayerControllers.
  late final ReelsPreloadManager _preloadManager;

  @override
  void initState() {
    super.initState();
    _preloadManager = ReelsPreloadManager();

    // Rebuild whenever the manager notifies (e.g., a new controller is ready).
    _preloadManager.addListener(_onManagerUpdate);
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  /// Called by the bottom nav bar to scroll back to top and refresh.
  void scrollToTopAndRefresh() {
    scrollToTop();
    reelsRefreshKey.currentState?.show();
  }

  /// Called after uploading a new reel to jump to the top without a full network refresh.
  void scrollToTop() {
    if (_pageController.hasClients && _currentIndex != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _preloadManager.removeListener(_onManagerUpdate);
    _preloadManager.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isRequestingCamera = false;

  Future<void> _openCustomCamera() async {
    if (_isRequestingCamera) return;
    setState(() {
      _isRequestingCamera = true;
      _isOverlayOpen = true;
    });

    // Pause current reel while camera is open.
    _preloadManager.pauseCurrent();

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomCameraScreen()),
      );

      if (!mounted) return;

      if (result != null && result is Map) {
        final File editedFile = result['file'];
        final String action = result['action'];

        if (action == 'save') {
          try {
            await Share.shareXFiles([
              XFile(editedFile.path),
            ], text: 'My edited Reel');
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not save/share video: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        } else if (action == 'upload') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video prepared for upload. (Upload logic pending)',
              ),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening custom camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingCamera = false;
          _isOverlayOpen = false;
        });
        // Resume current reel when we come back.
        _preloadManager.resumeCurrent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainIndex = ref.watch(mainShellTabIndexProvider);
    final isActiveTab = mainIndex == 1; // Reels is at index 1.

    // Let the manager know if this tab is active so it doesn't auto-play in the background
    _preloadManager.setActive(isActiveTab && !_isOverlayOpen);

    final reelsState = ref.watch(reelsFeedProvider);
    final uploadState = ref.watch(reelUploadProvider);

    return Stack(
      children: [
        // ── 1. Video Feed ──────────────────────────────────────────────────
        reelsState.when(
          data: (reelResponse) {
            final reels = reelResponse.data;

            if (reels.isEmpty) {
              return const Center(
                child: Text(
                  'No reels found.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }

            // Keep the manager's reel list in sync.
            _preloadManager.setReels(reels);

            // Kick off preloading if we haven't set an index yet.
            if (_currentIndex == 0) {
              _preloadManager.setCurrentIndex(0);
            }

            return RefreshIndicator(
              key: reelsRefreshKey,
              onRefresh: () => ref
                  .read(reelsFeedProvider.notifier)
                  .fetchReels(isRefresh: true),
              color: Theme.of(context).primaryColor,
              backgroundColor: const Color(0xFF1E281F),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: reels.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);

                  // Tell the manager to slide the window to the new index.
                  _preloadManager.setCurrentIndex(index);

                  // Log the view.
                  ref.read(reelsFeedProvider.notifier).logView(reels[index].id);

                  // Load more reels when near the end.
                  if (index >= reels.length - 2) {
                    ref.read(reelsFeedProvider.notifier).loadMore();
                  }
                },
                itemBuilder: (context, index) {
                  final isCurrentPage =
                      index == _currentIndex && isActiveTab && !_isOverlayOpen;

                  // Only render VideoPlayerItem for the window (current ± 1).
                  // For far-away reels, just show a thumbnail to save resources.
                  final isInWindow = (index - _currentIndex).abs() <= 1;

                  if (isInWindow) {
                    return ListenableBuilder(
                      listenable: _preloadManager,
                      builder: (context, _) {
                        return VideoPlayerItem(
                          reel: reels[index],
                          isCurrent: isCurrentPage,
                          controller: _preloadManager.getController(index),
                          hasError: _preloadManager.hasError(index),
                          onRetry: () => _preloadManager.retry(index),
                        );
                      },
                    );
                  }

                  // Far-away reel — just show a black container to save resources.
                  return Container(color: Colors.black);
                },
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reels\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(reelsFeedProvider.notifier).fetchReels(),
                  child: Text(
                    'Retry',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 2. Upload Progress Overlay ─────────────────────────────────────
        if (uploadState.isUploading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E281F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: uploadState.progress > 0
                                  ? uploadState.progress
                                  : null,
                              color: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white24,
                            ),
                            Text(
                              '${(uploadState.progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uploadState.progress >= 1.0
                                    ? 'Processing Video...'
                                    : 'Uploading Reel...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                uploadState.progress >= 1.0
                                    ? 'Almost done, please wait'
                                    : 'It will appear here shortly',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 3. Camera Button ───────────────────────────────────────────────
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _openCustomCamera,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 28,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
