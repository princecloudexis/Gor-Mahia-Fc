import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reels_model.dart';
import '../../../repositories/reels_repository.dart';

class AdItem extends ConsumerStatefulWidget {
  final Reel ad;
  final VideoPlayerController? controller;
  final bool isCurrent;

  const AdItem({
    super.key, 
    required this.ad, 
    this.controller,
    this.isCurrent = false,
  });

  @override
  ConsumerState<AdItem> createState() => _AdItemState();
}

class _AdItemState extends ConsumerState<AdItem> {
  DateTime? _viewStartTime;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) {
      _viewStartTime = DateTime.now();
    }
  }

  @override
  void didUpdateWidget(AdItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      // Started viewing
      _viewStartTime = DateTime.now();
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      // Stopped viewing
      _sendInteraction();
    }
  }

  @override
  void dispose() {
    if (widget.isCurrent) {
      _sendInteraction();
    }
    super.dispose();
  }

  void _sendInteraction({bool clicked = false}) {
    if (_viewStartTime == null && !clicked) return;
    
    int? watchedSeconds;
    if (_viewStartTime != null) {
      watchedSeconds = DateTime.now().difference(_viewStartTime!).inSeconds;
      if (!clicked) {
        _viewStartTime = null; // Reset if we're sending watch time
      }
    }

    if ((watchedSeconds != null && watchedSeconds > 0) || clicked) {
      ref.read(reelsRepositoryProvider).recordAdInteraction(
        widget.ad.id,
        watchedSeconds: (watchedSeconds != null && watchedSeconds > 0) ? watchedSeconds : null,
        clicked: clicked ? true : null,
      );
    }
  }

  Future<void> _launchUrl() async {
    final urlStr = widget.ad.linkUrl;
    if (urlStr == null || urlStr.isEmpty) return;
    
    _sendInteraction(clicked: true);
    
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideoController = widget.controller != null && widget.controller!.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: Colors.black),
        
        // Media (Video or Image)
        if (widget.ad.mediaType == 'video' && hasVideoController)
          SizedBox.expand(
            child: FittedBox(
              fit: widget.controller!.value.size.height >= widget.controller!.value.size.width
                  ? BoxFit.cover
                  : BoxFit.contain,
              child: SizedBox(
                width: widget.controller!.value.size.width,
                height: widget.controller!.value.size.height,
                child: VideoPlayer(widget.controller!),
              ),
            ),
          )
        else if (widget.ad.mediaType == 'video' && !hasVideoController)
          const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          )
        else if (widget.ad.mediaType == 'image' && widget.ad.mediaUrl != null && widget.ad.mediaUrl!.isNotEmpty)
          Image.network(
            widget.ad.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
            ),
          )
        else
          const Center(
            child: Icon(Icons.ad_units, color: Colors.white54, size: 50),
          ),
          
        // Gradient for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 350,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ),
        
        // Ad Content
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ad label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Description / Caption
              if (widget.ad.caption != null && widget.ad.caption!.isNotEmpty) ...[
                Text(
                  widget.ad.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],
              
              // CTA Button
              if (widget.ad.ctaLabel != null && widget.ad.ctaLabel!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launchUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.ad.ctaLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
              // Padding to avoid overlap with bottom navigation bar
              const SizedBox(height: 70),
            ],
          ),
        ),
      ],
    );
  }
}
