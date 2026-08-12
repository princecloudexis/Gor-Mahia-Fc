import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/reels_providers.dart';
import '../../../models/reels_model.dart';
import 'package:intl/intl.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String reelId;

  const CommentsBottomSheet({super.key, required this.reelId});

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      ref.read(reelCommentsProvider(widget.reelId).notifier).loadMore();
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(reelCommentsProvider(widget.reelId).notifier).addComment(
            text,
            parentId: _replyingToCommentId,
          );
      _commentController.clear();
      _cancelReply();
      
      // Scroll to top to see new comment (if not replying)
      if (_replyingToCommentId == null && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _onReplyTap(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(reelCommentsProvider(widget.reelId));
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle and Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          
          // Comments List
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (e, _) => Center(child: Text('Error loading comments', style: const TextStyle(color: Colors.white))),
              data: (response) {
                if (response.data.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: response.data.length + (response.meta?.hasNextPage == true ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == response.data.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    }
                    
                    final comment = response.data[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommentRow(comment),
                          // Replies section
                          if (comment.replies.isNotEmpty || comment.hasMoreReplies)
                            Padding(
                              padding: const EdgeInsets.only(left: 42.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final reply in comment.replies)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _buildCommentRow(reply, isReply: true),
                                    ),
                                  if (comment.hasMoreReplies)
                                    GestureDetector(
                                      onTap: () {
                                        final int page = (comment.replies.length / 20).ceil() + 1;
                                        ref.read(reelCommentsProvider(widget.reelId).notifier).loadReplies(comment.id, page: page);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                                        child: Text(
                                          'View ${comment.nextRepliesCount > 0 ? comment.nextRepliesCount : 'more'} replies',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Comment Input Field
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(
                left: 16, 
                right: 16, 
                top: 12, 
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingToAuthorName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to @$_replyingToAuthorName',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _cancelReply,
                            child: const Icon(Icons.close, size: 16, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white12,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _postComment,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isPosting ? Colors.white24 : theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentRow(ReelComment comment, {bool isReply = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 14 : 18,
          backgroundImage: NetworkImage(
            comment.authorAvatarUrl ?? 
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(comment.authorName)}&background=025928&color=fff',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(comment.timestamp),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    if (comment.replyingToAuthorName != null && isReply)
                      TextSpan(
                        text: '@${comment.replyingToAuthorName} ',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    TextSpan(
                      text: comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _onReplyTap(
                  isReply ? (comment.parentId ?? comment.id) : comment.id,
                  comment.authorName,
                ),
                child: const Text(
                  'Reply',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(reelCommentsProvider(widget.reelId).notifier).toggleCommentLike(comment.id);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey('${comment.id}_${comment.isLikedByMe}'),
                  color: comment.isLikedByMe ? Colors.red : Colors.white54,
                  size: 16,
                ),
              ),
            ),
            if (comment.likesCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  comment.likesCount.toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
