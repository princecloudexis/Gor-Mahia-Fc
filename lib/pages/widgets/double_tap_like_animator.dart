import 'package:flutter/material.dart';

class DoubleTapLikeAnimator extends StatefulWidget {
  final Widget child;
  final VoidCallback onLike;
  final bool isLikedByMe;

  const DoubleTapLikeAnimator({
    super.key,
    required this.child,
    required this.onLike,
    required this.isLikedByMe,
  });

  @override
  State<DoubleTapLikeAnimator> createState() => _DoubleTapLikeAnimatorState();
}

class _DoubleTapLikeAnimatorState extends State<DoubleTapLikeAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Sequence: scale up quickly and slightly bounce, stay a bit, scale down quickly
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.2).chain(CurveTween(curve: Curves.linear)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showHeart = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.isLikedByMe) {
      widget.onLike();
    }
    
    // Restart animation
    setState(() {
      _showHeart = true;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.favorite,
                color: Colors.redAccent,
                size: 120,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
