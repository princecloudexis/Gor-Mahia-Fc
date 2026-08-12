import 'package:flutter/material.dart';
import '../../../models/reels_model.dart';
import 'package:intl/intl.dart';

class ReelsOverlayUI extends StatelessWidget {
  final Reel reel;
  final bool isMyReel;
  final VoidCallback onLikePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onCommentsPressed;
  final VoidCallback onMoreOptionsPressed;

  const ReelsOverlayUI({
    super.key,
    required this.reel,
    required this.isMyReel,
    required this.onLikePressed,
    required this.onSharePressed,
    required this.onCommentsPressed,
    required this.onMoreOptionsPressed,
  });

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomClear = safePadding + 96.0;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Right side action icons ─────────────────────────
          Positioned(
            right: 12,
            bottom: bottomClear,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: reel.isLikedByMe
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  label: _formatCount(reel.likesCount),
                  color: reel.isLikedByMe ? Colors.red : Colors.white,
                  onTap: onLikePressed,
                ),
                const SizedBox(height: 22),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(reel.commentsCount),
                  onTap: onCommentsPressed,
                ),
                const SizedBox(height: 22),
                _ActionBtn(
                  icon: Icons.send_outlined,
                  label: 'Share',
                  onTap: onSharePressed,
                ),
                const SizedBox(height: 22),
                _ActionBtn(
                  icon: Icons.more_vert,
                  label: '',
                  onTap: onMoreOptionsPressed,
                ),
              ],
            ),
          ),

          // ── Left side: username, caption, audio ─────────────
          Positioned(
            left: 14,
            right: 76, // stop before right icons
            bottom: bottomClear,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        image: DecorationImage(
                          image: NetworkImage(
                            reel.authorAvatarUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(reel.authorName)}&background=025928&color=fff',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Name
                    Flexible(
                      child: Text(
                        '@${reel.authorName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                // Caption
                if (reel.caption != null && reel.caption!.isNotEmpty) ...[
                  _ExpandableCaption(text: reel.caption!),
                  const SizedBox(height: 9),
                ],
                // Audio
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original Audio - ${reel.authorName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.5,
                          shadows: const [
                            Shadow(blurRadius: 3, color: Colors.black45),
                          ],
                        ),
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
    );
  }
}

// ── Reusable action button ───────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              icon,
              key: ValueKey<String>('${icon.codePoint}_$color'),
              color: color,
              size: 32,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Expandable caption ───────────────────────────────────────────────────────
class _ExpandableCaption extends StatefulWidget {
  final String text;

  const _ExpandableCaption({required this.text});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topLeft,
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            height: 1.3,
            shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
          ),
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
