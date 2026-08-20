import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'reels_overlay_ui.dart';
import 'reel_details_view.dart';
import '../../../models/reels_model.dart';
import '../../../providers/navigation_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/reels_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../repositories/reels_repository.dart';
import 'reels_preload_manager.dart';

class VideoPlayerItem extends ConsumerStatefulWidget {
  final Reel reel;

  /// Whether this reel is the one currently visible and should be playing.
  final bool isCurrent;

  /// The pre-initialized controller provided by [ReelsPreloadManager].
  /// Null means the manager is still initializing — show thumbnail + spinner.
  final VideoPlayerController? controller;

  /// Whether the manager reported a permanent load error for this reel.
  final bool hasError;

  /// The reason for the error: 'codec' or 'network'.
  final String errorReason;

  /// Called when the user taps "Retry" after an error.
  final VoidCallback? onRetry;

  // Optional callbacks to override default actions that use reelsFeedProvider.
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const VideoPlayerItem({
    super.key,
    required this.reel,
    required this.isCurrent,
    required this.controller,
    required this.hasError,
    this.errorReason = 'network',
    this.onRetry,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  ConsumerState<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends ConsumerState<VideoPlayerItem>
    with SingleTickerProviderStateMixin {
  bool _showLikeAnimation = false;
  bool _isDetailsOpen = false;
  DetailsPanelMode _panelMode = DetailsPanelMode.comments;

  // Tracks buffering state for the mid-play spinner.
  bool _isBuffering = false;

  // Track max watched seconds to log activity
  int _maxWatchedSeconds = 0;

  late final ReelsNotifier _reelsNotifier;

  @override
  void initState() {
    super.initState();
    _reelsNotifier = ref.read(reelsFeedProvider.notifier);
    if (widget.isCurrent && widget.controller != null) {
      widget.controller!.play();
    }
    _attachControllerListener(widget.controller);
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If Flutter recycles this widget state for a completely different reel, reset tracking.
    if (widget.reel.id != oldWidget.reel.id) {
      _maxWatchedSeconds = 0;
    }

    // Controller reference changed (manager swapped it in) — re-attach listener.
    if (widget.controller != oldWidget.controller) {
      _detachControllerListener(oldWidget.controller);
      _attachControllerListener(widget.controller);
    }

    // Handle tab switching or overlay opening (isCurrent changing)
    if (widget.isCurrent != oldWidget.isCurrent) {
      if (oldWidget.isCurrent && !widget.isCurrent) {
        // Scrolled away or tab changed: log the activity progress
        _logActivity();
        // Also close details if open
        if (_isDetailsOpen) {
          setState(() => _isDetailsOpen = false);
          // Small delay before showing bottom nav to avoid visual clashing during scroll
          Future.microtask(
            () => ref.read(hideBottomNavProvider.notifier).state = false,
          );
        }
      }

      final controller = widget.controller;
      if (controller != null && controller.value.isInitialized) {
        if (widget.isCurrent) {
          controller.play();
        } else {
          controller.pause();
        }
      }
    }
  }

  void _attachControllerListener(VideoPlayerController? controller) {
    controller?.addListener(_onControllerUpdate);
    _syncBufferingState(controller);
  }

  void _detachControllerListener(VideoPlayerController? controller) {
    controller?.removeListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    _syncBufferingState(widget.controller);

    final controller = widget.controller;
    if (controller != null && controller.value.isInitialized) {
      final currentSeconds = controller.value.position.inSeconds;
      if (currentSeconds > _maxWatchedSeconds) {
        _maxWatchedSeconds = currentSeconds;
      }
    }
  }

  void _syncBufferingState(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      if (_isBuffering) setState(() => _isBuffering = false);
      return;
    }
    final buffering = controller.value.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  @override
  void dispose() {
    if (widget.isCurrent) {
      _logActivity();
    }
    _detachControllerListener(widget.controller);
    super.dispose();
  }

  void _logActivity() {
    final controller = widget.controller;
    if (controller != null && controller.value.isInitialized) {
      final duration = controller.value.duration.inSeconds;
      if (duration > 0 && _maxWatchedSeconds > 0) {
        final percentage = (_maxWatchedSeconds / duration) * 100;
        _reelsNotifier.logActivity(
          reelId: widget.reel.id,
          watchedPercentage: percentage,
          watchedSeconds: _maxWatchedSeconds,
        );
      }
    }
  }

  // ─── Interaction ────────────────────────────────────────────────────────────

  void _togglePlayPause() {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _handleDoubleTap() {
    if (!widget.reel.isLikedByMe) {
      if (widget.onLike != null) {
        widget.onLike!();
      } else {
        ref.read(reelsFeedProvider.notifier).toggleLike(widget.reel.id);
      }
    }
    setState(() => _showLikeAnimation = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showLikeAnimation = false);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final navBarClearance = bottomPadding + 82.0;
    final controller = widget.controller;
    final isInitialized = controller != null && controller.value.isInitialized;
    final isPlaying = isInitialized && controller.value.isPlaying;

    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // Calculate heights and margins based on keyboard state
        final topPadding = MediaQuery.of(context).padding.top;
        final videoHeightOpen = isKeyboardOpen ? screenHeight * 0.10 : screenHeight * 0.45;
        final videoHorizontalMargin = isKeyboardOpen ? 130.0 : 16.0;
        final videoTopMargin = isKeyboardOpen ? topPadding + 5 : topPadding + 10;
        final videoBorderRadius = isKeyboardOpen ? 24.0 : 16.0;

        // Ensure the details panel has enough space so it doesn't overflow (min 250px)
        final double minSafePanelHeight = 250.0;
        final double calculatedPanelTop = videoTopMargin + videoHeightOpen - 15;
        final double panelTop = math.min(calculatedPanelTop, availableHeight - minSafePanelHeight);
        final double safePanelHeight = math.max(minSafePanelHeight, availableHeight - panelTop);

        return GestureDetector(
          onTap: _isDetailsOpen
              ? () {
                  FocusScope.of(context).unfocus();
                  setState(() => _isDetailsOpen = false);
                  ref.read(hideBottomNavProvider.notifier).state = false;
                }
              : _togglePlayPause,
          onDoubleTap: _isDetailsOpen ? null : _handleDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Color
              Container(color: const Color(0xFF0A0A0A)),

              // ── Video Layer (Animated Position & Size) ────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                top: _isDetailsOpen ? videoTopMargin : 0,
                left: _isDetailsOpen ? videoHorizontalMargin : 0,
                right: _isDetailsOpen ? videoHorizontalMargin : 0,
                // Instead of using bottom, we set height directly when open
                height: _isDetailsOpen ? videoHeightOpen : availableHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_isDetailsOpen ? videoBorderRadius : 0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.hasError)
                        _ErrorView(
                          onRetry: widget.errorReason == 'codec'
                              ? null
                              : widget.onRetry,
                          isCodecError: widget.errorReason == 'codec',
                        )
                      else if (isInitialized)
                        _VideoView(controller: controller)
                      else
                        _ThumbnailLoadingView(reel: widget.reel),

                      if (!isPlaying && isInitialized && !_isBuffering)
                        const Center(
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white54,
                            size: 80,
                          ),
                        ),

                      if (_showLikeAnimation) _LikeAnimation(),

                      // Progress bar (only when full screen)
                      if (isInitialized && !_isDetailsOpen)
                        Positioned(
                          bottom: navBarClearance,
                          left: 16,
                          right: 16,
                          height: 2,
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: const VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Reels Overlay UI (Icons on right, caption on bottom) ────────
              AnimatedOpacity(
                opacity: _isDetailsOpen ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _isDetailsOpen,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currentUser = ref.watch(userProvider);
                      final isMyReel =
                          currentUser != null &&
                          currentUser.id.toString() == widget.reel.authorId;

                      final reelsState = ref.watch(reelsFeedProvider);
                      final freshReel =
                          reelsState.valueOrNull?.data.firstWhere(
                            (r) => r.id == widget.reel.id,
                            orElse: () => widget.reel,
                          ) ??
                          widget.reel;

                      return ReelsOverlayUI(
                        reel: freshReel,
                        isMyReel: isMyReel,
                        onLikePressed:
                            widget.onLike ??
                            () => ref
                                .read(reelsFeedProvider.notifier)
                                .toggleLike(widget.reel.id),
                        onCommentsPressed: () {
                          setState(() {
                            _panelMode = DetailsPanelMode.comments;
                            _isDetailsOpen = true;
                          });
                          ref.read(hideBottomNavProvider.notifier).state = true;
                        },
                        onDescriptionPressed: () {
                          setState(() {
                            _panelMode = DetailsPanelMode.description;
                            _isDetailsOpen = true;
                          });
                          ref.read(hideBottomNavProvider.notifier).state = true;
                        },
                        onSharePressed:
                            widget.onShare ??
                            () async {
                              try {
                                await Share.share(
                                  'Check out this reel by @${widget.reel.authorName} on Gor Mahia FC: ${widget.reel.videoUrl}',
                                  subject: 'Gor Mahia FC Reel',
                                );
                                ref
                                    .read(reelsFeedProvider.notifier)
                                    .shareReel(widget.reel.id);
                              } catch (e) {
                                debugPrint('Error sharing: $e');
                              }
                            },
                        onMoreOptionsPressed: () {
                          final currentUser = ref.read(userProvider);
                          final isMyReel =
                              currentUser != null &&
                              currentUser.id.toString() == widget.reel.authorId;
                          _showOptionsBottomSheet(context, ref, isMyReel);
                        },
                      );
                    },
                  ),
                ),
              ),

              // ── Details View (Caption + Comments) ───────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                // Top aligns it just below the top padding and video height (or pushed up if keyboard is large)
                top: _isDetailsOpen ? panelTop : availableHeight,
                height: safePanelHeight,
                child: ReelDetailsView(
                  reel: widget.reel,
                  height: safePanelHeight,
                  mode: _panelMode,
                  onClose: () {
                    setState(() => _isDetailsOpen = false);
                    ref.read(hideBottomNavProvider.notifier).state = false;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E281F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final reasonsAsync = ref.watch(reportReasonsProvider);

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: reasonsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Failed to load reasons',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                        data: (reasons) {
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: reasons.length,
                            itemBuilder: (context, index) {
                              final reason = reasons[index];
                              return ListTile(
                                title: Text(
                                  reason['label']!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white54,
                                  size: 14,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _submitReport(context, ref, reason['value']!);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _submitReport(
    BuildContext context,
    WidgetRef ref,
    String reasonValue,
  ) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Submitting report...')));
    try {
      await ref
          .read(reelsRepositoryProvider)
          .reportReel(widget.reel.id, reasonValue);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report')));
      }
    }
  }

  void _showOptionsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    bool isMyReel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E281F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isMyReel)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Reel',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E281F),
                        title: const Text(
                          'Delete Reel?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this reel? This cannot be undone.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await ref
                            .read(reelsFeedProvider.notifier)
                            .deleteReel(widget.reel.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reel deleted successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete reel: $e'),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              if (!isMyReel)
                ListTile(
                  leading: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportBottomSheet(context, ref);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  'Not Interested',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final message = await ref
                        .read(reelsFeedProvider.notifier)
                        .markNotInterested(widget.reel.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.blueAccent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ─── Private Sub-widgets ──────────────────────────────────────────────────────

/// Renders the actual video player, filling the screen with cover fit.
class _VideoView extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    final isPortrait = size.height >= size.width;
    return SizedBox.expand(
      child: FittedBox(
        fit: isPortrait ? BoxFit.cover : BoxFit.contain,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

/// Shows author avatar, name, and caption on a dark gradient background
/// while the video controller is still initializing.
/// Uses data already available in the reel — no backend changes needed.
class _ThumbnailLoadingView extends StatelessWidget {
  final Reel reel;
  const _ThumbnailLoadingView({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Dark gradient background ──────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1A0F), Color(0xFF1A2E1C), Color(0xFF0A1209)],
            ),
          ),
        ),

        // ── Faint club-green radial glow in the centre ────────────────────
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2E7D32).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Author avatar + spinner in the centre ─────────────────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Spinner ring around avatar
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  // Avatar
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(
                      0xFF2E7D32,
                    ).withValues(alpha: 0.4),
                    backgroundImage:
                        (reel.authorAvatarUrl != null &&
                            reel.authorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(reel.authorAvatarUrl!)
                        : null,
                    child:
                        (reel.authorAvatarUrl == null ||
                            reel.authorAvatarUrl!.isEmpty)
                        ? Text(
                            reel.authorName.isNotEmpty
                                ? reel.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Author name
              Text(
                reel.authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              // Caption (if any)
              // if (reel.caption != null && reel.caption!.isNotEmpty) ...[
              //   const SizedBox(height: 6),
              //   Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 40),
              //     child: Text(
              //       reel.caption!,
              //       textAlign: TextAlign.center,
              //       maxLines: 2,
              //       overflow: TextOverflow.ellipsis,
              //       style: TextStyle(
              //         color: Colors.white.withValues(alpha: 0.6),
              //         fontSize: 13,
              //       ),
              //     ),
              //   ),
              // ],
              // const SizedBox(height: 20),
              // "Loading video" label
              // Text(
              //   'Loading video...',
              //   style: TextStyle(
              //     color: Colors.white.withValues(alpha: 0.4),
              //     fontSize: 12,
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Error view with a clear retry button.
class _ErrorView extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isCodecError;
  const _ErrorView({this.onRetry, this.isCodecError = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCodecError ? Icons.videocam_off_rounded : Icons.wifi_off_rounded,
            color: Colors.white54,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            isCodecError
                ? 'Video format not supported'
                : 'Failed to load video',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCodecError
                ? 'This video resolution is too high for your device'
                : 'Check your connection and try again',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated heart that bursts on double-tap.
class _LikeAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder(
        key: UniqueKey(),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          final scale = 0.5 + value;
          final wobble = math.sin(value * math.pi * 5) * 0.4 * (1.0 - value);
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(angle: wobble, child: child),
          );
        },
        child: const Icon(Icons.favorite, color: Colors.red, size: 100),
      ),
    );
  }
}
