import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/community_providers.dart';

class GifPickerSheet extends ConsumerStatefulWidget {
  final void Function(int? id, String? url) onGifSelected;

  const GifPickerSheet({super.key, required this.onGifSelected});

  @override
  ConsumerState<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends ConsumerState<GifPickerSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(gifProvider('').notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gifState = ref.watch(gifProvider(''));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select GIF',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: gifState.isLoading && gifState.gifs.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : gifState.gifs.isEmpty
                    ? const Center(child: Text('No GIFs available'))
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: gifState.gifs.length + (gifState.hasNextPage ? 2 : 0),
                        itemBuilder: (_, i) {
                          if (i >= gifState.gifs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: AppColors.primaryGreen),
                              ),
                            );
                          }
                          final gif = gifState.gifs[i];
                          return GestureDetector(
                            onTap: () {
                              widget.onGifSelected(int.tryParse(gif.id), gif.url);
                              Navigator.pop(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                child: Image.network(
                                  gif.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.error)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
