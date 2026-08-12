import 'dart:ui';
import 'dart:io';
import 'package:gormahiafc/repositories/community_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../theme/app_colors.dart';
import '../models/community_models.dart';
import '../providers/community_providers.dart';
import '../providers/user_providers.dart';
import '../api/api_client.dart';
import 'create_post.dart';
import 'group_info.dart';
import 'media_viewer.dart';
import 'widgets/post_comments_sheet.dart';
import 'widgets/double_tap_like_animator.dart';

class GroupDetails extends ConsumerStatefulWidget {
  final CommunityGroup group;
  final bool isJoined;

  /// When set (via notification tap), the comments sheet for this post
  /// is opened automatically after the group posts are loaded.
  final String? initialPostId;
  final String? initialCommentId;

  const GroupDetails({
    super.key,
    required this.group,
    this.isJoined = true,
    this.initialPostId,
    this.initialCommentId,
  });

  @override
  ConsumerState<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends ConsumerState<GroupDetails> {
  late bool _hasJoined;
  bool _isJoining = false;
  bool _isLeaving = false;
  final ScrollController _scrollController = ScrollController();
  bool _didAutoOpenComments = false;

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.group.isJoined;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasJoined) {
        ref.read(groupPostsProvider(widget.group.id).notifier).fetchNextPage();
      }
    }
  }

  String _formatTimestamp(String? isoString, {String? updatedIsoString}) {
    if (isoString == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);

      String formattedTime = 'Just now';
      if (difference.inDays > 0) {
        formattedTime = '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        formattedTime = '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        formattedTime = '${difference.inMinutes}m';
      } else if (difference.inSeconds > 0) {
        formattedTime = '${difference.inSeconds}s';
      }

      if (updatedIsoString != null && updatedIsoString.isNotEmpty) {
        try {
          final updatedTime = DateTime.parse(updatedIsoString).toLocal();
          final updatedDiff = DateTime.now().difference(updatedTime);
          String updatedFormatted = 'Just now';
          if (updatedDiff.inDays > 0) {
            updatedFormatted = '${updatedDiff.inDays}d';
          } else if (updatedDiff.inHours > 0) {
            updatedFormatted = '${updatedDiff.inHours}h';
          } else if (updatedDiff.inMinutes > 0) {
            updatedFormatted = '${updatedDiff.inMinutes}m';
          } else if (updatedDiff.inSeconds > 0) {
            updatedFormatted = '${updatedDiff.inSeconds}s';
          }
          return '$formattedTime (edited $updatedFormatted)';
        } catch (e) {
          // Ignore
        }
      }
      return formattedTime;
    } catch (e) {
      return 'Just now';
    }
  }

  /// Returns only the base timestamp (no edited suffix) — used for the new badge design.
  String _formatBaseTimestamp(String? isoString) {
    if (isoString == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);
      if (difference.inDays > 0) return '${difference.inDays}d';
      if (difference.inHours > 0) return '${difference.inHours}h';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m';
      if (difference.inSeconds > 0) return '${difference.inSeconds}s';
      return 'Just now';
    } catch (e) {
      return 'Just now';
    }
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

  void _showJoinRequiredSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please join the group to interact with posts.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _showLeaveConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2126) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Leave Group',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${widget.group.name}"? You will lose access to group posts and activities.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Leave Group',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLeaving = true);
    try {
      final message = await ref
          .read(communityRepositoryProvider)
          .leaveGroup(widget.group.id);
      if (!mounted) return;
      // Refresh lists so My Groups tab updates
      ref.invalidate(joinedGroupsProvider);
      ref.invalidate(exploreGroupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLeaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupName = widget.group.name;
    final members = '${widget.group.membersCount} members';
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/footballbg.png'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.15 : 0.10,
          ),
        ),
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 48),
                  centerTitle: false,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.group.imageUrl != null) ...[
                        Hero(
                          tag: 'group_avatar_${widget.group.id}',
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: CachedNetworkImageProvider(
                              widget.group.getFullImageUrl(storageBaseUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.group.type == 'private') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white54,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.lock_outline,
                                size: 8,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Private',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.group.imageUrl != null)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 4.0,
                            sigmaY: 4.0,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.group.getFullImageUrl(
                              storageBaseUrl,
                            ),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.primaryGreen),
                          ),
                        )
                      else
                        Container(color: AppColors.primaryGreen),
                      // Gradient overlay to ensure text and icons readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (_hasJoined)
                    _isLeaving
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E2126)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) {
                              if (value == 'info') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupInfo(group: widget.group),
                                  ),
                                );
                              } else if (value == 'leave') {
                                _showLeaveConfirmationDialog();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'info',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20),
                                    SizedBox(width: 12),
                                    Text('Group Info'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'leave',
                                child: Row(
                                  children: [
                                    Icon(Icons.exit_to_app_rounded, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Leave Group', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          )
                  else
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupInfo(group: widget.group),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ];
          },
          body: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () => ref
                .read(groupPostsProvider(widget.group.id).notifier)
                .fetchInitial(),
            child: _buildPostsTab(isDark, storageBaseUrl),
          ),
        ),
      ),
      floatingActionButton: _hasJoined
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePost(group: widget.group),
                  ),
                );
              },
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit),
            )
          : null,
      bottomNavigationBar: !_hasJoined
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.group.isPending || _isJoining
                        ? null
                        : () async {
                            setState(() {
                              _isJoining = true;
                            });
                            try {
                              await ref
                                  .read(communityRepositoryProvider)
                                  .joinGroup(widget.group.id);
                              if (!mounted) return;
                              setState(() {
                                _hasJoined = true;
                                _isJoining = false;
                              });
                              ref.refresh(joinedGroupsProvider);
                              ref.invalidate(exploreGroupsProvider);
                              ref.read(groupPostsProvider(widget.group.id).notifier).fetchInitial();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'You have successfully joined $groupName!',
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _isJoining = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to join: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryGreen
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.group.isPending ? 'Requested' : 'Join Group',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        color: isDark ? Colors.white : Colors.black,
        colorOpacity: 0.1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 150,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab(bool isDark, String storageBaseUrl) {
    final state = ref.watch(groupPostsProvider(widget.group.id));

    if (state.isLoading && state.posts.isEmpty) {
      return _buildSkeleton(isDark);
    }

    // Auto-open comments for the notification target post (runs only once)
    if (widget.initialPostId != null &&
        !_didAutoOpenComments &&
        state.posts.isNotEmpty) {
      _didAutoOpenComments = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetPost = state.posts.firstWhere(
          (p) => p.id == widget.initialPostId,
          orElse: () => state.posts.first,
        );
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 40,
              ),
              child: PostCommentsSheet(
                post: targetPost,
                groupId: widget.group.id,
                isJoined: _hasJoined,
              ),
            ),
          );
        }
      });
    }

    if (state.posts.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share something!',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount:
          state.posts.length +
          ((!_hasJoined && state.posts.isNotEmpty) || (state.hasNextPage && state.isLoading)
              ? 1
              : 0),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        if (index == state.posts.length) {
          if (!_hasJoined) {
            return Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryGreen,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Join the group to see more posts!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Members can see all history and interact with the community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }

        final post = state.posts[index];
        return _buildPostCard(post, isDark, storageBaseUrl);
      },
    );
  }

  Widget _buildPostCard(
    CommunityPost post,
    bool isDark,
    String storageBaseUrl,
  ) {
    return DoubleTapLikeAnimator(
      isLikedByMe: post.isLikedByMe,
      onLike: () {
        if (!_hasJoined) {
          _showJoinRequiredSnackbar();
          return;
        }
        ref
            .read(groupPostsProvider(widget.group.id).notifier)
            .toggleLike(post.id);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Container(
                width: 40,
                height: 40,
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                child:
                    post.authorAvatar == null ||
                        post.authorAvatar == 'null' ||
                        post.authorAvatar!.isEmpty
                    ? Icon(Icons.person, color: AppColors.primaryGreen)
                    : CachedNetworkImage(
                        imageUrl: post.getFullAuthorAvatar(storageBaseUrl),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            Icon(Icons.person, color: AppColors.primaryGreen),
                        placeholder: (context, url) =>
                            Icon(Icons.person, color: AppColors.primaryGreen),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textOnLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' · ${_formatBaseTimestamp(post.timestamp)}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 12,
                        ),
                      ),
                      if (post.updatedAt != null &&
                          post.updatedAt!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(edited ${_formatBaseTimestamp(post.updatedAt!)})',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (ref.read(userProvider)?.id.toString() ==
                          post.authorId)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          color: isDark
                              ? AppColors.bgCardDark
                              : AppColors.bgCardLight,
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreatePost(
                                    group: widget.group,
                                    existingPost: post,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              ref
                                  .read(
                                    groupPostsProvider(
                                      widget.group.id,
                                    ).notifier,
                                  )
                                  .deletePost(post.id);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.content,
                    style: TextStyle(
                      height: 1.4,
                      fontSize: 15,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (post.media.isNotEmpty)
                    _buildMediaGrid(post, isDark, storageBaseUrl),
                  if (post.isPoll && post.pollData != null)
                    _buildPollUI(post, isDark),
                  if (post.media.isNotEmpty ||
                      (post.isPoll && post.pollData != null))
                    const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_hasJoined) {
                            _showJoinRequiredSnackbar();
                            return;
                          }
                          ref
                              .read(
                                groupPostsProvider(widget.group.id).notifier,
                              )
                              .toggleLike(post.id);
                        },
                        child: _buildActionItem(
                          post.isLikedByMe
                              ? Icons.favorite
                              : Icons.favorite_border,
                          _formatCount(post.likesCount),
                          isDark,
                          color: post.isLikedByMe ? Colors.red : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 40,
                              ),
                              child: PostCommentsSheet(
                                post: post,
                                groupId: widget.group.id,
                                isJoined: _hasJoined,
                              ),
                            ),
                          );
                        },
                        child: _buildActionItem(
                          Icons.chat_bubble_outline,
                          _formatCount(post.commentsCount),
                          isDark,
                        ),
                      ),
                      if (post.isPoll)
                        _buildActionItem(
                          Icons.poll_outlined,
                          _formatCount(post.pollVotesCount),
                          isDark,
                        ),
                      GestureDetector(
                        onTap: () async {
                          if (!_hasJoined) {
                            _showJoinRequiredSnackbar();
                            return;
                          }
                          final text = post.content.isNotEmpty
                              ? post.content
                              : 'Check out this post on Gor Mahia FC!';

                          // The backend doesn't provide a deep link URL currently.
                          final link = post.shareUrl != null
                              ? '\n\n${post.shareUrl}'
                              : '';
                          final shareText = '$text$link';

                          ShareResult? shareResult;

                          // If the post has an image, download and share the actual image file natively!
                          if (post.media.isNotEmpty &&
                              post.media.first.type == 'image') {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            try {
                              final imageUrl = post.media.first.getFullUrl(
                                storageBaseUrl,
                              );
                              final response = await ref
                                  .read(apiClientProvider)
                                  .dio
                                  .get<List<int>>(
                                    imageUrl,
                                    options: Options(
                                      responseType: ResponseType.bytes,
                                    ),
                                  );

                              if (context.mounted)
                                Navigator.pop(context); // close dialog

                              if (response.statusCode == 200 &&
                                  response.data != null) {
                                final tempDir = await getTemporaryDirectory();
                                final file = File(
                                  '${tempDir.path}/shared_image.jpg',
                                );
                                await file.writeAsBytes(response.data!);

                                shareResult = await Share.shareXFiles(
                                  [XFile(file.path)],
                                  text: shareText,
                                  subject: 'Gor Mahia FC',
                                );
                              }
                            } catch (e) {
                              if (context.mounted)
                                Navigator.pop(context); // close dialog on error
                            }
                          }

                          // Fallback to sharing just text if no image or image download failed
                          if (shareResult == null) {
                            shareResult = await Share.share(
                              shareText,
                              subject: 'Gor Mahia FC',
                            );
                          }

                          if (shareResult.status == ShareResultStatus.success) {
                            ref
                                .read(
                                  groupPostsProvider(widget.group.id).notifier,
                                )
                                .incrementShare(post.id);
                          }
                        },
                        child: _buildActionItem(
                          Icons.share_outlined,
                          _formatCount(post.sharesCount),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(
    CommunityPost post,
    bool isDark,
    String storageBaseUrl,
  ) {
    final media = post.media;
    if (media.isEmpty) return const SizedBox();

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    // Shimmer placeholder — same size as its parent container
    Widget shimmerPlaceholder() => Shimmer(
      duration: const Duration(milliseconds: 1200),
      color: isDark ? Colors.white : Colors.black,
      colorOpacity: 0.07,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(color: isDark ? Colors.white10 : Colors.black12),
    );

    Widget buildItem(int index) {
      final item = media[index];
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaViewer(
                post: post,
                groupId: widget.group.id,
                initialIndex: index,
              ),
            ),
          );
        },
        child: item.type == 'video'
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black87),
                  const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 28,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              )
            : CachedNetworkImage(
                imageUrl: item.getFullUrl(storageBaseUrl),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                fadeOutDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) => shimmerPlaceholder(),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? Colors.white10 : Colors.black12,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      );
    }

    Widget content;
    if (media.length == 1) {
      content = buildItem(0);
    } else if (media.length == 2) {
      content = Row(
        children: [
          Expanded(child: buildItem(0)),
          Container(width: 1.5, color: borderColor),
          Expanded(child: buildItem(1)),
        ],
      );
    } else if (media.length == 3) {
      content = Row(
        children: [
          Expanded(child: buildItem(0)),
          Container(width: 1.5, color: borderColor),
          Expanded(
            child: Column(
              children: [
                Expanded(child: buildItem(1)),
                Container(height: 1.5, color: borderColor),
                Expanded(child: buildItem(2)),
              ],
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildItem(0)),
                Container(width: 1.5, color: borderColor),
                Expanded(child: buildItem(1)),
              ],
            ),
          ),
          Container(height: 1.5, color: borderColor),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildItem(2)),
                Container(width: 1.5, color: borderColor),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      buildItem(3),
                      if (media.length > 4)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${media.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Determine the fixed aspect ratio for the outer container.
    // This is the KEY fix: every container has a known size BEFORE the image loads.
    final double aspectRatio;
    if (media.length == 1 && media[0].type == 'video') {
      aspectRatio = 16 / 9;
    } else if (media.length == 1) {
      aspectRatio = 4 / 3; // Portrait-friendly, prevents layout jump
    } else {
      aspectRatio = 1.0; // Square grid for multi-media
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildPollUI(CommunityPost post, bool isDark) {
    if (post.pollData == null || post.pollData!.options.isEmpty)
      return const SizedBox();

    final totalVotes = post.pollData!.options.fold<int>(
      0,
      (sum, opt) => sum + opt.votes,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            post.pollData!.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              final percentage = totalVotes > 0
                  ? option.votes / totalVotes
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: !_hasJoined
                      ? () {
                          _showJoinRequiredSnackbar();
                        }
                      : post.pollData!.isExpired
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This poll has expired.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : post.pollData!.hasVoted
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You have already voted on this poll.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : () async {
                          final errorMessage = await ref
                              .read(
                                groupPostsProvider(widget.group.id).notifier,
                              )
                              .voteOnPoll(post.id, index);
                          if (errorMessage != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    option.text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(percentage * 100).toStringAsFixed(0)}% (${option.votes} votes)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()..add(
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '$totalVotes votes',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String count,
    bool isDark, {
    Color? color,
  }) {
    final finalColor = color ?? (isDark ? Colors.white70 : Colors.black87);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.transparent,
      child: Row(
        children: [
          Icon(icon, size: 20, color: finalColor),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: finalColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
