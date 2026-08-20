import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/reels_model.dart';
import '../../../providers/reels_providers.dart';
import '../../../theme/app_colors.dart';

enum DetailsPanelMode { comments, description }

class ReelDetailsView extends ConsumerStatefulWidget {
  final Reel reel;
  final VoidCallback onClose;
  final double height; // Total height available for this panel
  final DetailsPanelMode mode;

  const ReelDetailsView({
    super.key,
    required this.reel,
    required this.onClose,
    required this.height,
    this.mode = DetailsPanelMode.comments,
  });

  @override
  ConsumerState<ReelDetailsView> createState() => _ReelDetailsViewState();
}

class _ReelDetailsViewState extends ConsumerState<ReelDetailsView> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isPosting = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  final List<String> _quickEmojis = ['❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'];

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
      ref.read(reelCommentsProvider(widget.reel.id).notifier).loadMore();
    }
  }

  Future<void> _postComment(String text) async {
    text = text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(reelCommentsProvider(widget.reel.id).notifier).addComment(
            text,
            parentId: _replyingToCommentId,
          );
      _commentController.clear();
      _cancelReply();
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
      return DateFormat('d MMMM').format(time); // "23 June" format
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
    final commentsAsync = ref.watch(reelCommentsProvider(widget.reel.id));
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      onDoubleTap: () {}, // Prevent double taps from bubbling up to the video player and triggering a like
      child: Container(
        height: widget.height,
        decoration: const BoxDecoration(
          color: Color(0xFF161616), // Dark gray almost black matching IG
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
        children: [
          // ── 1. Header (Drag Handle) ──────────────────────────────────
          GestureDetector(
            onTap: widget.onClose,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! > 10) {
                widget.onClose();
                _focusNode.unfocus();
              }
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          // ── 2. Scrollable Content (Caption + Comments) ───────────────
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [

                // ── Author & Caption Section ──
                if (widget.mode == DetailsPanelMode.description)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author Row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(
                                  widget.reel.authorAvatarUrl ?? 
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.reel.authorName)}&background=025928&color=fff',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.reel.authorName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (widget.reel.authorName.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.music_note, color: Colors.white54, size: 12),
                                          const SizedBox(width: 4),
                                          const Expanded(
                                            child: Text(
                                              'Original Audio',
                                              style: TextStyle(color: Colors.white54, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Caption
                          if (widget.reel.caption != null && widget.reel.caption!.isNotEmpty)
                            Text(
                              widget.reel.caption!,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                            ),
                          
                          const SizedBox(height: 8),
                          
                          // Date
                          Text(
                            _formatTime(widget.reel.timestamp),
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          
                          // Optional Link Card (e.g. for Ads)
                          if (widget.reel.type == 'ad' && widget.reel.linkUrl != null)
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse(widget.reel.linkUrl!)),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        Uri.parse(widget.reel.linkUrl!).host,
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 60), // Space for preview if needed
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),


                // ── Comments List ──
                if (widget.mode == DetailsPanelMode.comments)
                  commentsAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: Colors.white54)),
                  ),
                  error: (e, _) => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Error loading comments', style: TextStyle(color: Colors.white))),
                  ),
                  data: (response) {
                    if (response.data.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == response.data.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.white54)),
                            );
                          }
                          
                          final comment = response.data[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                              ref.read(reelCommentsProvider(widget.reel.id).notifier).loadReplies(comment.id, page: page);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                                              child: Text(
                                                'View ${comment.nextRepliesCount > 0 ? comment.nextRepliesCount : 'more'} replies',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                        childCount: response.data.length + (response.meta?.hasNextPage == true ? 1 : 0),
                      ),
                    );
                  },
                ),
                // Add some extra space at the bottom so the last comment is fully visible
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
          ),
          
          // ── 3. Bottom Input Area ─────────────────────────────────────
          if (widget.mode == DetailsPanelMode.comments)
            Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 12, 
              bottom: isKeyboardOpen ? 12 : 24, // extra padding for home indicator if no keyboard
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Emojis Row (only show when keyboard is open)
                if (isKeyboardOpen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickEmojis.map((emoji) => GestureDetector(
                        onTap: () => _postComment(emoji),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      )).toList(),
                    ),
                  ),
                  
                // Replying To Indicator
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
                  
                // Input Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white54, width: 1),
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _commentController,
                            builder: (context, value, child) {
                              final hasText = value.text.trim().isNotEmpty;
                              return Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: InkWell(
                                  onTap: hasText ? () => _postComment(value.text) : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: hasText ? AppColors.primaryGreen : Colors.grey.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.send, color: Colors.white, size: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        onSubmitted: (val) => _postComment(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildCommentRow(ReelComment comment, {bool isReply = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 14 : 16,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    if (comment.replyingToAuthorName != null && isReply)
                      TextSpan(
                        text: '@${comment.replyingToAuthorName} ',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    TextSpan(
                      text: comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _onReplyTap(
                      isReply ? (comment.parentId ?? comment.id) : comment.id,
                      comment.authorName,
                    ),
                    child: const Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'See Translation',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(reelCommentsProvider(widget.reel.id).notifier).toggleCommentLike(comment.id);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey('${comment.id}_${comment.isLikedByMe}'),
                  color: comment.isLikedByMe ? Colors.red : Colors.white54,
                  size: 14,
                ),
              ),
            ),
            if (comment.likesCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  comment.likesCount.toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
