import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

import '../models/community_models.dart';
import '../providers/community_providers.dart';
import '../repositories/community_repository.dart';
import 'widgets/gif_picker_sheet.dart';

class CreatePost extends ConsumerStatefulWidget {
  final CommunityGroup group;
  final CommunityPost? existingPost;

  const CreatePost({super.key, required this.group, this.existingPost});

  @override
  ConsumerState<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends ConsumerState<CreatePost> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final int _maxChars = 280;
  bool _hasImage = false;
  XFile? _selectedMedia;
  bool _hasPoll = false;
  bool _hasLocation = false;
  String _selectedLocation = '';
  List<TextEditingController> _pollOptions = [
    TextEditingController(text: ''),
    TextEditingController(text: ''),
  ];
  bool _isPublishing = false;
  int? _selectedGifId;
  String? _selectedGifUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _textController.text = widget.existingPost!.content;
      // We are not loading existing media or polls for edit in this simple version,
      // but you can expand this if you have the full data structure available locally.
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptions) {
      c.dispose();
    }
    super.dispose();
  }

  int get _remainingChars => _maxChars - _textController.text.length;
  bool get _canPost {
    if (_hasPoll) {
      final hasQuestion = _pollQuestionController.text.trim().isNotEmpty;
      final validOptions = _pollOptions
          .where((o) => o.text.trim().isNotEmpty)
          .length;
      return hasQuestion && validOptions >= 2;
    }
    return _textController.text.trim().isNotEmpty;
  }

  double get _progressValue =>
      (_textController.text.length / _maxChars).clamp(0.0, 1.0);

  Color get _counterColor {
    if (_remainingChars <= 0) return Colors.red;
    if (_remainingChars <= 20) return Colors.orange;
    return AppColors.primaryGreen;
  }

  void _showLocationPicker() {
    final locations = [
      'New York, USA',
      'London, UK',
      'Tokyo, Japan',
      'Paris, France',
      'Sydney, Australia',
      'Toronto, Canada',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDark : AppColors.bgLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                ),
              ),
              const SizedBox(height: 8),
              ...locations.map(
                (loc) => ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  title: Text(
                    loc,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _hasLocation = true;
                      _selectedLocation = loc;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GifPickerSheet(
        onGifSelected: (id, url) {
          setState(() {
            _selectedGifId = id;
            _selectedGifUrl = url;
            _hasImage = false; // Mutually exclusive
            _selectedMedia = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('GIF selected!'),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _handleMediaPermission() async {
    PermissionStatus photosStatus = await Permission.photos.status;
    PermissionStatus storageStatus = await Permission.storage.status;

    // If already granted, return true
    if (photosStatus.isGranted ||
        photosStatus.isLimited ||
        storageStatus.isGranted ||
        storageStatus.isLimited) {
      return true;
    }

    // Now request the actual OS permission
    if (Platform.isAndroid) {
      photosStatus = await Permission.photos.request();
      storageStatus = await Permission.storage.request();
      if (photosStatus.isGranted ||
          photosStatus.isLimited ||
          storageStatus.isGranted ||
          storageStatus.isLimited) {
        return true;
      }
    } else {
      photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) return true;
    }

    // If still denied (permanently), show settings dialog
    if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Please allow gallery access in your device settings to upload media.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
          ),
          onPressed: () {
            if (_textController.text.isNotEmpty || _hasImage || _hasPoll) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _textController,
                _pollQuestionController,
                ..._pollOptions,
              ]),
              builder: (context, _) {
                return AnimatedOpacity(
                  opacity: _canPost ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _canPost && !_isPublishing ? _publishPost : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryGreen
                          .withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isPublishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.existingPost != null ? 'Save' : 'Post',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.15,
                      ),
                      radius: 22,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text Input
                          ValueListenableBuilder(
                            valueListenable: _textController,
                            builder: (context, value, _) {
                              return TextField(
                                controller: _textController,
                                autofocus: true,
                                maxLines: null,
                                maxLength: _maxChars,
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.textOnDark
                                      : AppColors.textOnLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'What\'s happening?',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                    fontSize: 17,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  counterText: '',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Image Attachment
                          if (_hasImage) _buildImageAttachment(isDark),
                          // GIF Attachment
                          if (_selectedGifUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _selectedGifUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedGifId = null;
                                        _selectedGifUrl = null;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Poll Section
                          if (_hasPoll) ...[
                            const SizedBox(height: 12),
                            _buildPollSection(isDark),
                          ],
                          // Location Tag
                          if (_hasLocation && _selectedLocation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildLocationTag(isDark),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Character counter + Toolbar
            _buildBottomToolbar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAttachment(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            if (_selectedMedia != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_selectedMedia!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 52,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image Preview',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black26,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasImage = false;
                    _selectedMedia = null;
                    _selectedGifId = null;
                    _selectedGifUrl = null;
                  });
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.poll_outlined,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Poll',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _hasPoll = false),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pollQuestionController,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            ),
            decoration: InputDecoration(
              hintText: 'Ask a question...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Options',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_pollOptions.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _pollOptions[i],
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Option ${i + 1}',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primaryGreen),
                  ),
                  suffixIcon: _pollOptions.length > 2
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _pollOptions[i].dispose();
                              _pollOptions.removeAt(i);
                            });
                          },
                          child: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
          if (_pollOptions.length < 4)
            GestureDetector(
              onTap: () {
                setState(() {
                  _pollOptions.add(
                    TextEditingController(
                      text: 'Option ${_pollOptions.length + 1}',
                    ),
                  );
                });
              },
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add option',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationTag(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: AppColors.primaryGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            _selectedLocation,
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _hasLocation = false;
              _selectedLocation = '';
            }),
            child: Icon(Icons.close, color: AppColors.primaryGreen, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.public, color: AppColors.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Everyone can reply',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildToolbarButton(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onTap: () async {
                    bool hasPermission = await _handleMediaPermission();

                    if (hasPermission) {
                      final picker = ImagePicker();
                      final picked = await picker.pickMedia();
                      if (picked != null) {
                        try {
                          CroppedFile? croppedFile = await ImageCropper()
                              .cropImage(
                                sourcePath: picked.path,
                                uiSettings: [
                                  AndroidUiSettings(
                                    toolbarTitle: 'Crop Image',
                                    toolbarColor: AppColors.primaryGreen,
                                    toolbarWidgetColor: Colors.white,
                                    initAspectRatio:
                                        CropAspectRatioPreset.square,
                                    lockAspectRatio: false,
                                    aspectRatioPresets: [
                                      CropAspectRatioPreset.square,
                                      CropAspectRatioPreset.ratio4x3,
                                      CropAspectRatioPreset.ratio16x9,
                                      CropAspectRatioPreset.original,
                                    ],
                                  ),
                                  IOSUiSettings(
                                    title: 'Crop Image',
                                    aspectRatioPresets: [
                                      CropAspectRatioPreset.square,
                                      CropAspectRatioPreset.ratio4x3,
                                      CropAspectRatioPreset.ratio16x9,
                                      CropAspectRatioPreset.original,
                                    ],
                                  ),
                                ],
                              );

                          if (croppedFile != null) {
                            setState(() {
                              _selectedMedia = XFile(croppedFile.path);
                              _hasImage = true;
                              _hasPoll = false;
                              _selectedGifId = null;
                              _selectedGifUrl = null;
                            });
                          }
                        } on MissingPluginException catch (_) {
                          setState(() {
                            _selectedMedia = picked;
                            _hasImage = true;
                            _hasPoll = false;
                            _selectedGifId = null;
                            _selectedGifUrl = null;
                          });
                        } catch (e) {
                          setState(() {
                            _selectedMedia = picked;
                            _hasImage = true;
                            _hasPoll = false;
                            _selectedGifId = null;
                            _selectedGifUrl = null;
                          });
                        }
                      }
                    }
                  },
                  isActive: _hasImage,
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  onTap: _showGifPicker,
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.poll_outlined,
                  label: 'Poll',
                  onTap: () => setState(() {
                    _hasPoll = !_hasPoll;
                    if (_hasPoll) {
                      _hasImage = false;
                      _selectedMedia = null;
                      _selectedGifId = null;
                      _selectedGifUrl = null;
                    }
                  }),
                  isActive: _hasPoll,
                ),
                const SizedBox(width: 4),
                _buildToolbarButton(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  onTap: _showLocationPicker,
                  isActive: _hasLocation,
                ),
                const Spacer(),
                // Character counter
                ValueListenableBuilder(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        if (_remainingChars <= 20)
                          Text(
                            '$_remainingChars',
                            style: TextStyle(
                              color: _counterColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _progressValue,
                            strokeWidth: 2,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _counterColor,
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: label,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGreen.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primaryGreen : inactiveColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publishPost() async {
    setState(() {
      _isPublishing = true;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);

      if (_hasPoll) {
        final options = _pollOptions
            .map((e) => e.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (options.length < 2) {
          throw Exception("A poll requires at least two options.");
        }
        await repo.createPoll(
          widget.group.id,
          _pollQuestionController.text.trim(),
          options,
          24,
        );
      } else {
        // Normal post or Edit post
        final List<CommunityMedia> media = [];
        if (_hasImage && _selectedMedia != null) {
          final uploadedMedia = await repo.uploadMedia(_selectedMedia!.path);
          media.add(uploadedMedia);
        }

        if (widget.existingPost != null) {
          await ref
              .read(groupPostsProvider(widget.group.id).notifier)
              .editPost(
                widget.existingPost!.id,
                _textController.text.trim(),
                media: media,
                gifId: _selectedGifId,
              );
        } else {
          await repo.createPost(
            widget.group.id,
            _textController.text.trim(),
            media,
            gifId: _selectedGifId,
          );
        }
      }

      // Only refresh for new posts (edit already updates state directly)
      if (widget.existingPost == null) {
        ref.refresh(groupPostsProvider(widget.group.id));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Post published successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _showDiscardDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.existingPost != null ? 'Edit Post' : 'Create Post',
          style: TextStyle(
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to discard this post? Your changes will be lost.',
          style: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Editing',
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
