import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/community_models.dart';
import '../theme/app_colors.dart';
import '../providers/community_providers.dart';
import '../api/api_client.dart';
import 'widgets/post_comments_sheet.dart';
import 'widgets/double_tap_like_animator.dart';

class MediaViewer extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String groupId;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.post,
    required this.groupId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends ConsumerState<MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;
  bool _isTextExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
    }
    return count.toString();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The provider might update if liked inside the viewer, so we watch it.
    // However, it's a family provider fetching a list of posts.
    // We can just rely on the local post object or fetch it from the state.
    final groupState = ref.watch(groupPostsProvider(widget.groupId));
    final currentPost = groupState.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media PageView
          GestureDetector(
            onTap: _toggleOverlay,
            child: DoubleTapLikeAnimator(
              isLikedByMe: currentPost.isLikedByMe,
              onLike: () {
                ref
                    .read(groupPostsProvider(widget.groupId).notifier)
                    .toggleLike(currentPost.id);
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: currentPost.media.length,
                itemBuilder: (context, index) {
                  final media = currentPost.media[index];
                  if (media.type == 'video') {
                    return _VideoPlayerItem(
                      url: media.getFullUrl(storageBaseUrl),
                      showControls: _showOverlay,
                    );
                  } else {
                    return _ImageItem(url: media.getFullUrl(storageBaseUrl));
                  }
                },
              ),
            ),
          ),

          // Top Header Overlay
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Top Right Page Indicator
          if (currentPost.media.length > 1)
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${currentPost.media.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Engagement Overlay
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author Info
                              Row(
                                children: [
                                  ClipOval(
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      color: AppColors.primaryGreen,
                                      child: currentPost.authorAvatar == null || currentPost.authorAvatar == 'null' || currentPost.authorAvatar!.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white, size: 20)
                                          : CachedNetworkImage(
                                              imageUrl: currentPost.getFullAuthorAvatar(storageBaseUrl),
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white, size: 20),
                                              placeholder: (context, url) => const Icon(Icons.person, color: Colors.white, size: 20),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currentPost.authorName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Post Content Snippet
                              if (currentPost.content.isNotEmpty)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final span = TextSpan(
                                      text: currentPost.content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    );
                                    final tp = TextPainter(
                                      text: span,
                                      maxLines: 2,
                                      textDirection: TextDirection.ltr,
                                    );
                                    tp.layout(maxWidth: constraints.maxWidth);
                                    final isOverflowing = tp.didExceedMaxLines;

                                    return GestureDetector(
                                      onTap: isOverflowing || _isTextExpanded
                                          ? () {
                                              setState(() {
                                                _isTextExpanded =
                                                    !_isTextExpanded;
                                              });
                                            }
                                          : null,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentPost.content,
                                            maxLines: _isTextExpanded
                                                ? null
                                                : 2,
                                            overflow: _isTextExpanded
                                                ? TextOverflow.visible
                                                : TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4.0,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isOverflowing && !_isTextExpanded)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                'more',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                      blurRadius: 4.0,
                                                      color: Colors.black54,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Interaction Buttons Vertically
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _InteractionButton(
                              icon: currentPost.isLikedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: _formatCount(currentPost.likesCount),
                              color: currentPost.isLikedByMe
                                  ? Colors.red
                                  : Colors.white,
                              onTap: () {
                                ref
                                    .read(
                                      groupPostsProvider(
                                        widget.groupId,
                                      ).notifier,
                                    )
                                    .toggleLike(currentPost.id);
                              },
                            ),
                            const SizedBox(height: 20),
                            _InteractionButton(
                              icon: Icons.chat_bubble_outline,
                              label: _formatCount(currentPost.commentsCount),
                              color: Colors.white,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      top:
                                          MediaQuery.of(context).padding.top +
                                          40,
                                    ),
                                    child: PostCommentsSheet(
                                      post: currentPost,
                                      groupId: widget.groupId,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _InteractionButton(
                              icon: Icons.share_outlined,
                              label: _formatCount(currentPost.sharesCount),
                              color: Colors.white,
                              onTap: () async {
                                final text = currentPost.content.isNotEmpty
                                    ? currentPost.content
                                    : 'Check out this post!';
                                final link =
                                    currentPost.shareUrl ??
                                    'https://footballclub.staging-workhub.com/posts/${currentPost.id}';
                                await Share.share(
                                  '$text\n\n$link',
                                  subject: 'Gor Mahia FC',
                                );
                                ref
                                    .read(
                                      groupPostsProvider(
                                        widget.groupId,
                                      ).notifier,
                                    )
                                    .incrementShare(currentPost.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  final String url;

  const _ImageItem({required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.white54, size: 64),
        ),
      ),
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final String url;
  final bool showControls;

  const _VideoPlayerItem({required this.url, required this.showControls});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),

        if (widget.showControls)
          Container(
            color: Colors.black26,
            child: Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ),
          ),

        if (widget.showControls)
          Positioned(
            bottom: 120, // above the engagement overlay
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      return Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primaryGreen,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_controller.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
