import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_models.dart';
import '../../providers/community_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'gif_picker_sheet.dart';

class PostCommentsSheet extends ConsumerStatefulWidget {
  final CommunityPost post;
  final String groupId;

  final bool isJoined;

  const PostCommentsSheet({
    super.key,
    required this.post,
    required this.groupId,
    this.isJoined = true,
  });

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPosting = false;
  int? _selectedGifId;
  String? _selectedGifUrl;
  String? _editingCommentId;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postCommentsProvider(widget.post.id).notifier).fetchInitial();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postCommentsProvider(widget.post.id).notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(postCommentsProvider(widget.post.id));

    // Auto-refresh when FCM delivers a comment/reply for this post
    ref.listen<String?>(commentsRefreshSignalProvider, (prev, next) {
      if (next == widget.post.id) {
        ref
            .read(postCommentsProvider(widget.post.id).notifier)
            .fetchInitial();
        // Reset the signal so subsequent notifications still fire
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(commentsRefreshSignalProvider.notifier).state = null;
        });
      }
    });

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white30 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Comments List
            Expanded(child: _buildCommentsList(state, isDark)),

            // Selected GIF Preview
            if (_selectedGifUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 100,
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _selectedGifUrl!,
                        fit: BoxFit.cover,
                        height: 100,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedGifId = null;
                          _selectedGifUrl = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Input Area
            if (!widget.isJoined)
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  top: 12,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Join Group to Comment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  top: 12,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyingToCommentId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Replying to $_replyingToUserName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() {
                                _replyingToCommentId = null;
                                _replyingToUserName = null;
                              }),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _commentController,
                              maxLines: 4,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Write a comment...',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (text) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.gif_box_outlined),
                          color: isDark ? Colors.white54 : Colors.black54,
                          onPressed: _showGifPicker,
                        ),
                        IconButton(
                          icon: _isPosting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _editingCommentId != null
                                      ? Icons.check
                                      : Icons.send,
                                ),
                          color: AppColors.primaryGreen,
                          onPressed:
                              (_commentController.text.trim().isEmpty &&
                                      _selectedGifId == null ||
                                  _isPosting)
                              ? null
                              : () async {
                                  setState(() => _isPosting = true);
                                  try {
                                    if (_editingCommentId != null) {
                                      await ref
                                          .read(
                                            postCommentsProvider(
                                              widget.post.id,
                                            ).notifier,
                                          )
                                          .editComment(
                                            _editingCommentId!,
                                            _commentController.text.trim(),
                                            gifId: _selectedGifId,
                                          );
                                      setState(() => _editingCommentId = null);
                                    } else {
                                      await ref
                                          .read(
                                            postCommentsProvider(
                                              widget.post.id,
                                            ).notifier,
                                          )
                                          .addComment(
                                            _commentController.text.trim(),
                                            gifId: _selectedGifId,
                                            parentId: _replyingToCommentId,
                                          );
                                      ref
                                          .read(
                                            groupPostsProvider(
                                              widget.groupId,
                                            ).notifier,
                                          )
                                          .incrementCommentCount(
                                            widget.post.id,
                                          );
                                    }
                                    _commentController.clear();
                                    setState(() {
                                      _selectedGifId = null;
                                      _selectedGifUrl = null;
                                      _replyingToCommentId = null;
                                      _replyingToUserName = null;
                                    });
                                    FocusScope.of(context).unfocus();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to post comment: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted)
                                      setState(() => _isPosting = false);
                                  }
                                },
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

  Widget _buildCommentsList(PostCommentsState state, bool isDark) {
    if (state.isLoading && state.comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.comments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(postCommentsProvider(widget.post.id).notifier)
              .fetchInitial();
        },
        child: ListView(
          controller: _scrollController,
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No comments yet. Be the first to comment!')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () async {
        await ref
            .read(postCommentsProvider(widget.post.id).notifier)
            .fetchInitial();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.comments.length + (state.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.comments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildCommentItem(state.comments[index], isDark);
        },
      ),
    );
  }

  Widget _buildCommentItem(
    CommunityComment comment,
    bool isDark, {
    bool isReply = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 48 : 16,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 12 : 16,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                child: Icon(
                  Icons.person,
                  size: isReply ? 16 : 20,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  comment.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatBaseTimestamp(comment.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                              if (comment.updatedAt != null &&
                                  comment.updatedAt!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(edited ${_formatBaseTimestamp(comment.updatedAt)})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (comment.content.isNotEmpty) Text(comment.content),
                          if (comment.gif != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: comment.gif!.url,
                                    fit: BoxFit.cover,
                                    fadeInDuration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    placeholder: (context, url) => Container(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                    errorWidget: (c, e, s) =>
                                        const Center(child: Icon(Icons.error)),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Action Buttons (Reply / View Replies)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingToCommentId = comment.id;
                                _replyingToUserName = comment.userName;
                              });
                            },
                            child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (comment.repliesCount > 0)
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(
                                      postCommentsProvider(
                                        widget.post.id,
                                      ).notifier,
                                    )
                                    .fetchReplies(comment.id);
                              },
                              child: Text(
                                (comment.replies != null && comment.replies!.isNotEmpty)
                                    ? '↻ ${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}'
                                    : 'View ${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (ref.read(userProvider)?.id.toString() == comment.userId) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        size: 18,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          setState(() {
                            _editingCommentId = comment.id;
                            _commentController.text = comment.content;
                            _selectedGifId = comment.gif != null
                                ? int.tryParse(comment.gif!.id)
                                : null;
                            _selectedGifUrl = comment.gif?.url;
                          });
                        } else if (val == 'delete') {
                          ref
                              .read(
                                postCommentsProvider(widget.post.id).notifier,
                              )
                              .deleteComment(comment.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: comment.replies!
                    .map(
                      (reply) =>
                          _buildCommentItem(reply, isDark, isReply: true),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GifPickerSheet(
        onGifSelected: (id, url) {
          setState(() {
            _selectedGifId = id;
            _selectedGifUrl = url;
          });
        },
      ),
    );
  }
}
