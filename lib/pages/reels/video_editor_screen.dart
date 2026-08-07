import 'dart:io';
import 'package:eventsbooking/pages/reels/upload_reel_screen.dart';
import 'package:eventsbooking/pages/reels/video_edit_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';

class VideoEditorScreen extends StatefulWidget {
  final File file;
  const VideoEditorScreen({super.key, required this.file});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late final VideoEditorController _controller;
  bool _isExporting = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      maxDuration: const Duration(seconds: 60),
    );
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          }
        });
  }

  @override
  void dispose() {
    FFmpegKit.cancel(); // CRITICAL: Prevent memory leaks and rogue background CPU drains if user backs out during export.
    if (_controller.initialized) {
      _controller.video.pause();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportVideo(bool saveToDevice) async {
    if (!mounted) return;
    setState(() => _isExporting = true);

    try {
      final config = VideoFFmpegVideoEditorConfig(
        _controller,
        commandBuilder: (config, videoPath, outputPath) {
          final videoConfig = config as VideoFFmpegVideoEditorConfig;
          final List<String> filters = videoConfig.getExportFilters();
          final String filtersStr = videoConfig.filtersCmd(filters);
          final bool isCopy = filters.isEmpty;
          // Use libx264 with ultrafast preset to make it extremely fast
          final String codecCmd = isCopy ? '-c copy' : '-c:v libx264 -preset ultrafast -crf 28';
          return "${videoConfig.startTrimCmd} -i $videoPath ${videoConfig.toTrimCmd} $filtersStr $codecCmd -y $outputPath";
        },
      );
      final execute = await config.getExecuteConfig();

      await FFmpegKit.execute(execute.command).then((
        FFmpegSession session,
      ) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UploadReelScreen(videoFile: File(execute.outputPath)),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to export video')),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }

    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.initialized
          ? SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CropGridViewer.preview(controller: _controller),
                            AnimatedBuilder(
                              animation: _controller.video,
                              builder: (_, __) => AnimatedOpacity(
                                opacity: _controller.isPlaying ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: _controller.video.play,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.black,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildBottomBar(),
                    ],
                  ),
                  if (_isExporting)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 20),
                            Text(
                              "Processing video...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: () async {
                final editedFile = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoEditDetailsScreen(file: widget.file),
                  ),
                );
                if (editedFile != null && editedFile is File) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoEditorScreen(file: editedFile),
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
              ),
              child: const Text(
                'Edit video',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: _isExporting ? null : () => _exportVideo(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
