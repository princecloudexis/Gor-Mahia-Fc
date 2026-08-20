import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video_editor_screen.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraPermissionGranted = false;
  bool _isInitializing = true;
  bool _isRecording = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Check permissions
    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      cameraStatus = statuses[Permission.camera] ?? cameraStatus;
      micStatus = statuses[Permission.microphone] ?? micStatus;
    }

    if (cameraStatus.isGranted && micStatus.isGranted) {
      _isCameraPermissionGranted = true;
      try {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          await _initCamera(_cameras[_selectedCameraIndex]);
        }
      } catch (e) {
        debugPrint("Camera initialization error: $e");
      }
    } else {
      _isCameraPermissionGranted = false;
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _initCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _switchCamera() async {
    if (_cameras.length > 1 && !_isRecording) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      setState(() {
        _isInitializing = true;
      });
      await _initCamera(_cameras[_selectedCameraIndex]);
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      try {
        final XFile video = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        _processVideo(video.path);
      } catch (e) {
        debugPrint("Error stopping record: $e");
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        debugPrint("Error starting record: $e");
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // Only check storage/photos permission if gallery is clicked
    bool isGranted = false;
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      var videosStatus = await Permission.videos.status;

      if (!storageStatus.isGranted && !videosStatus.isGranted) {
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.videos,
        ].request();
        storageStatus = statuses[Permission.storage] ?? storageStatus;
        videosStatus = statuses[Permission.videos] ?? videosStatus;
      }
      isGranted = storageStatus.isGranted || videosStatus.isGranted;
    } else {
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted && !photosStatus.isLimited) {
        photosStatus = await Permission.photos.request();
      }
      isGranted = photosStatus.isGranted || photosStatus.isLimited;
    }

    if (!isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery permission is required to select a video.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video != null) {
      _processVideo(video.path);
    }
  }

  Future<void> _processVideo(String path) async {
    // Navigate to VideoEditorScreen
    if (!mounted) return;

    // Stop camera temporarily if needed or just push screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(file: File(path)),
      ),
    );

    if (!mounted) return;

    // If we have a valid result from the editor, pop and pass it back
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false, // Extend to top edge
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Blank Screen
            if (_isInitializing)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_isCameraPermissionGranted &&
                _controller != null &&
                _controller!.value.isInitialized)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                child: CameraPreview(_controller!),
              )
            else
              // Blank screen when permission is denied, as requested
              Container(color: Colors.black),

            // Top UI
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),

            // Bottom UI
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Gallery Button
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Record Button
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording ? Colors.red : Colors.white,
                            width: 6,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: _isRecording ? 30 : 60,
                            height: _isRecording ? 30 : 60,
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.white,
                              borderRadius: _isRecording
                                  ? BorderRadius.circular(5)
                                  : BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Switch Camera Button
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
