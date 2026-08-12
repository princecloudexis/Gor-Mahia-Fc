import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reels_model.dart';

class AdItem extends StatelessWidget {
  final Reel ad;
  final VideoPlayerController? controller;

  const AdItem({super.key, required this.ad, this.controller});

  Future<void> _launchUrl() async {
    final urlStr = ad.linkUrl;
    if (urlStr == null || urlStr.isEmpty) return;
    
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideoController = controller != null && controller!.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: Colors.black),
        
        // Media (Video or Image)
        if (ad.mediaType == 'video' && hasVideoController)
          SizedBox.expand(
            child: FittedBox(
              fit: controller!.value.size.height >= controller!.value.size.width
                  ? BoxFit.cover
                  : BoxFit.contain,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller!.value.size.height,
                child: VideoPlayer(controller!),
              ),
            ),
          )
        else if (ad.mediaType == 'video' && !hasVideoController)
          const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          )
        else if (ad.mediaType == 'image' && ad.mediaUrl != null && ad.mediaUrl!.isNotEmpty)
          Image.network(
            ad.mediaUrl!,
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
              if (ad.caption != null && ad.caption!.isNotEmpty) ...[
                Text(
                  ad.caption!,
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
              if (ad.ctaLabel != null && ad.ctaLabel!.isNotEmpty)
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
                      ad.ctaLabel!,
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
