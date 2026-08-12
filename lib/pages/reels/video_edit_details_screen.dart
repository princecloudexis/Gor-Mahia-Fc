import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_session.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'upload_reel_screen.dart';

class VideoEditDetailsScreen extends StatefulWidget {
  final File file;
  const VideoEditDetailsScreen({super.key, required this.file});

  @override
  State<VideoEditDetailsScreen> createState() => _VideoEditDetailsScreenState();
}

class _VideoEditDetailsScreenState extends State<VideoEditDetailsScreen> {
  late final VideoEditorController _controller;
  bool _isExporting = false;
  bool _isPickingMusic = false;
  bool _initError = false;
  File? _backgroundMusic;
  bool _muteOriginalAudio = false;
  
  VideoPlayerController? _audioController;
  double _audioStartOffset = 0.0;
  double _audioDuration = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      maxDuration: const Duration(seconds: 60),
    );
    _controller.initialize().then((_) {
      if (_controller.video.value.duration == Duration.zero) {
        if (mounted) setState(() => _initError = true);
        return;
      }
      if (mounted) setState(() {});
    }).catchError((error) {
      if (mounted) setState(() => _initError = true);
    });
  }

  @override
  void dispose() {
    FFmpegKit.cancel(); // Prevent memory leaks and rogue background CPU drains if user backs out during export.
    if (_controller.initialized) {
      _controller.video.pause();
    }
    _controller.dispose();
    _audioController?.dispose();
    super.dispose();
  }

  Future<void> _pickMusic() async {
    if (_isPickingMusic) return;
    setState(() => _isPickingMusic = true);

    try {
      fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final selectedFile = File(result.files.single.path!);
        
        final audioController = VideoPlayerController.file(selectedFile);
        await audioController.initialize();
        
        if (mounted) {
          setState(() {
            _backgroundMusic = selectedFile;
            _audioController?.dispose();
            _audioController = audioController;
            _audioDuration = audioController.value.duration.inMilliseconds / 1000.0;
            _audioStartOffset = 0.0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking music: $e');
    } finally {
      if (mounted) setState(() => _isPickingMusic = false);
    }
  }

  Future<void> _exportVideo() async {
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

      await FFmpegKit.execute(execute.command).then((FFmpegSession session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          File finalOutputFile = File(execute.outputPath);

          // If background music is selected or original audio is muted, run a second FFmpeg command
          if (_backgroundMusic != null || _muteOriginalAudio) {
            final directory = await getTemporaryDirectory();
            final mergedPath = '${directory.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';

            // Calculate exact duration to prevent audio from extending the video length
            final double trimDuration = (_controller.endTrim - _controller.startTrim).inMilliseconds / 1000.0;

            String mergeCommand;
            if (_backgroundMusic != null) {
              // Calculate offset limit just in case the video length changed after picking music
              double maxOffset = _audioDuration - trimDuration;
              double safeOffset = _audioStartOffset > maxOffset ? (maxOffset > 0 ? maxOffset : 0.0) : _audioStartOffset;
              
              if (_muteOriginalAudio) {
                // Map only the background music audio
                mergeCommand = '-i "${execute.outputPath}" -ss $safeOffset -i "${_backgroundMusic!.path}" -t $trimDuration -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -shortest "$mergedPath"';
              } else {
                // Mix original audio and background music
                mergeCommand = '-i "${execute.outputPath}" -ss $safeOffset -i "${_backgroundMusic!.path}" -t $trimDuration -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[a]" -map 0:v:0 -map "[a]" -c:v copy -c:a aac -shortest "$mergedPath"';
              }
            } else {
              // Just mute original audio
              mergeCommand = '-i "${execute.outputPath}" -c:v copy -an "$mergedPath"';
            }

            final mergeSession = await FFmpegKit.execute(mergeCommand);
            final mergeReturnCode = await mergeSession.getReturnCode();

            if (ReturnCode.isSuccess(mergeReturnCode)) {
              finalOutputFile = File(mergedPath);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to process audio, using cropped video without audio changes')));
              }
            }
          }

          if (mounted) {
            Navigator.pop(context, finalOutputFile);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to crop video')));
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }

    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _initError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Video format/resolution not supported\nfor editing on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                    onPressed: () {
                       Navigator.pushReplacement(
                         context,
                         MaterialPageRoute(
                           builder: (context) => UploadReelScreen(videoFile: widget.file),
                         ),
                       );
                    },
                    child: const Text('Skip Editing & Upload', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : _controller.initialized
              ? SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                              onPressed: () => Navigator.pop(context),
                            ),

                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                                onPressed: _isExporting ? null : _exportVideo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Video Preview area
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
                                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom Editor Controls
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            // Playback controls
                            AnimatedBuilder(
                              animation: _controller.video,
                              builder: (_, __) {
                                final trimmedDuration = _controller.endTrim - _controller.startTrim;
                                final position = _controller.video.value.position - _controller.startTrim;
                                final displayPosition = position.isNegative ? Duration.zero : position;

                                String formatDuration(Duration d) {
                                  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                                  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                                  return '$minutes:$seconds';
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (_controller.isPlaying) {
                                          _controller.video.pause();
                                        } else {
                                          _controller.video.play();
                                        }
                                      },
                                    ),
                                    Text(
                                      '${formatDuration(trimmedDuration)} / ${formatDuration(_controller.videoDuration)}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                );
                              },
                            ),
                            
                            // Trim slider and Speaker icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 10.0),
                                  child: IconButton(
                                    icon: Icon(
                                      _muteOriginalAudio ? Icons.volume_off : Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _muteOriginalAudio = !_muteOriginalAudio;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                                    child: TrimSlider(
                                      controller: _controller,
                                      height: 50,
                                      horizontalMargin: 10,
                                      child: TrimTimeline(
                                        controller: _controller,
                                        padding: const EdgeInsets.only(top: 10),
                                        textStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            
                            // Audio options
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: _pickMusic,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.add, color: Colors.grey, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _backgroundMusic != null 
                                                      ? 'Music selected (Tap to change)' 
                                                      : 'Add audio',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_backgroundMusic != null)
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _backgroundMusic = null;
                                              _audioController?.dispose();
                                              _audioController = null;
                                            });
                                          },
                                        )
                                    ],
                                  ),
                                  if (_backgroundMusic != null && _audioController != null)
                                    AnimatedBuilder(
                                      animation: _controller.video,
                                      builder: (context, _) {
                                        final double trimDuration = (_controller.endTrim - _controller.startTrim).inMilliseconds / 1000.0;
                                        final double maxOffset = _audioDuration - trimDuration;
                                        
                                        if (maxOffset > 0) {
                                          double currentOffset = _audioStartOffset;
                                          if (currentOffset > maxOffset) {
                                            currentOffset = maxOffset;
                                          }
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                                                child: Text(
                                                  'Select music starting point: ${currentOffset.toStringAsFixed(1)}s',
                                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                                ),
                                              ),
                                              Slider(
                                                value: currentOffset,
                                                min: 0.0,
                                                max: maxOffset,
                                                onChanged: (val) {
                                                  setState(() => _audioStartOffset = val);
                                                },
                                                onChangeEnd: (val) {
                                                  _audioController?.seekTo(Duration(milliseconds: (val * 1000).toInt()));
                                                  _audioController?.play();
                                                  Future.delayed(const Duration(seconds: 2), () {
                                                    if (mounted && _audioController != null) {
                                                      _audioController?.pause();
                                                    }
                                                  });
                                                },
                                                activeColor: Theme.of(context).primaryColor,
                                                inactiveColor: Colors.grey,
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Exporting Overlay
                  if (_isExporting)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Theme.of(context).primaryColor),
                            const SizedBox(height: 20),
                            const Text("Processing video...", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
    );
  }
}
