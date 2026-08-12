import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:gal/gal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/reels_providers.dart';

class UploadReelScreen extends ConsumerStatefulWidget {
  final File videoFile;

  const UploadReelScreen({super.key, required this.videoFile});

  @override
  ConsumerState<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends ConsumerState<UploadReelScreen> {
  late VideoPlayerController _videoController;
  final TextEditingController _captionController = TextEditingController();
  bool _showPlayIcon = false;
  bool _videoInitError = false;

  // Location state
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _city;
  String? _country;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      }).catchError((error) {
        if (mounted) setState(() { _videoInitError = true; });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putVideo(widget.videoFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel saved to Gallery!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to Gallery: $e')),
        );
      }
    }
  }

  void _addHashtag() {
    final currentText = _captionController.text;
    if (currentText.trim().endsWith('#')) return;
    final newText = currentText.isEmpty || currentText.endsWith(' ')
        ? '$currentText#'
        : '$currentText #';
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      // 1. Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled. Please enable GPS.';
          _isFetchingLocation = false;
        });
        return;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied.';
            _isFetchingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied. Enable it in Settings.';
          _isFetchingLocation = false;
        });
        return;
      }

      // 3. Get position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Reverse geocode to get city & country
      String? city;
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality?.isNotEmpty == true
              ? place.locality
              : place.subAdministrativeArea;
          country = place.country;
        }
      } catch (_) {
        // Geocoding failure is non-fatal — we still have lat/lng
      }

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _city = city;
          _country = country;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not get location. Try again.';
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _removeLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _city = null;
      _country = null;
      _locationError = null;
    });
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  Future<void> _uploadAndShareReel() async {
    ref.read(reelUploadProvider.notifier).uploadReel(
      widget.videoFile.path,
      _captionController.text,
      durationSeconds: _videoController.value.duration.inSeconds,
      latitude: _latitude,
      longitude: _longitude,
      city: _city,
      country: _country,
    );

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1210),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Reel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white, size: 28),
            onPressed: _downloadVideo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // ── Video Preview ──────────────────────────────────────────
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _videoController.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_videoController.value.isPlaying) {
                                    _videoController.pause();
                                    _showPlayIcon = true;
                                  } else {
                                    _videoController.play();
                                    _showPlayIcon = false;
                                  }
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  VideoPlayer(_videoController),
                                  AnimatedOpacity(
                                    opacity: _showPlayIcon ||
                                            !_videoController.value.isPlaying
                                        ? 1.0
                                        : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _videoController.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _videoInitError
                            ? const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                                      SizedBox(height: 12),
                                      Text(
                                        'Preview not supported on this device\nBut you can still upload it!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Caption Field ──────────────────────────────────────────
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: 'Write a caption... add #hashtags',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
                    filled: true,
                    fillColor: const Color(0xFF1A2B1C),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Quick Action Buttons ───────────────────────────────────
                Row(
                  children: [
                    _QuickActionChip(
                      icon: Icons.tag,
                      label: 'Hashtag',
                      color: primaryColor,
                      onTap: _addHashtag,
                    ),
                    const SizedBox(width: 10),
                    _QuickActionChip(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      color: primaryColor,
                      onTap: _fetchCurrentLocation,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Location Status Card ───────────────────────────────────
                if (_isFetchingLocation)
                  _LocationCard(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Getting your location...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else if (_locationError != null)
                  _LocationCard(
                    borderColor: Colors.redAccent,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white54, size: 20),
                          onPressed: _fetchCurrentLocation,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )
                else if (_latitude != null)
                  _LocationCard(
                    borderColor: primaryColor,
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: primaryColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _city != null && _country != null
                                    ? '$_city, $_country'
                                    : _city ?? _country ?? 'Location selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white38, size: 20),
                          onPressed: _removeLocation,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1210),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadAndShareReel,
              icon: const Icon(Icons.upload_rounded, color: Colors.white),
              label: const Text(
                'Upload Reel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
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

class _LocationCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _LocationCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor?.withValues(alpha: 0.5) ??
              Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
