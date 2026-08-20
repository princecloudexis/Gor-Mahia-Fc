import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kogalo_network/pages/details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../api/api_client.dart';
import '../models/event_model.dart';
import '../providers/search_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/safe_svg_network.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  @override
  ConsumerState<Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).resetSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const CustomScrollView(
        physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _SearchSliverAppBar(),
          _SearchBarHeader(),
          _SearchResultsBody(),
        ],
      ),
    );
  }
}

class _SearchSliverAppBar extends StatelessWidget {
  const _SearchSliverAppBar();

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const _FilterSectionHeader(
                  icon: Icons.calendar_today_outlined,
                  title: 'Date Filters',
                ),
                const SizedBox(height: 52, child: _DateFilterBar()),
                const SizedBox(height: 12),
                const _FilterSectionHeader(
                  icon: Icons.category_outlined,
                  title: 'Category Filters',
                ),
                const SizedBox(height: 52, child: _CategoryFilterBar()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),

      title: Text(
        'Search Matches',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
      centerTitle: true,
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final hasActiveFilters = ref.watch(
              searchProvider.select((s) => s.hasActiveFilters),
            );
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: textColor),
                    onPressed: () => _showFilterBottomSheet(context),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SearchBarHeader extends StatelessWidget {
  const _SearchBarHeader();

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(pinned: true, delegate: _SearchBarDelegate());
  }
}

class _SearchResultsBody extends ConsumerWidget {
  const _SearchResultsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(searchProvider.select((state) => state.status));
    final hasActiveFilters = ref.watch(
      searchProvider.select((s) => s.hasActiveFilters),
    );
    final searchText = ref.watch(_searchControllerProvider).text;

    if (status == SearchStatus.initial &&
        searchText.isEmpty &&
        !hasActiveFilters) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _InitialView(),
      );
    }

    switch (status) {
      case SearchStatus.loading:
        return const _SearchShimmer();
      case SearchStatus.success:
        final results = ref.watch(searchProvider.select((s) => s.results));
        if (results.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResultsView(),
          );
        }
        return _ResultsList(results: results);
      case SearchStatus.error:
        final errorMessage = ref.read(searchProvider).errorMessage;
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(errorMessage ?? 'An error occurred.')),
        );
      default:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _InitialView(),
        );
    }
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: maxExtent,
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Consumer(
            builder: (context, ref, _) {
              final controller = ref.watch(_searchControllerProvider);
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return TextField(
                    controller: controller,
                    autofocus: false,
                    cursorColor: AppColors.primaryGreen,
                    onChanged: (query) {
                      ref.read(searchProvider.notifier).onQueryChanged(query);
                    },
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Search here...',
                      hintStyle: TextStyle(
                        color: theme.hintColor.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: theme.hintColor,
                                size: 20,
                              ),
                              onPressed: () {
                                controller.clear();
                                ref
                                    .read(searchProvider.notifier)
                                    .onQueryChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80.0;
  @override
  double get minExtent => 80.0;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

// Reusable Filter Section Header Widget
class _FilterSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FilterSectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Filter Chip Widget - FIXED SIZE
class _CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? avatar;

  const _CustomFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44, // Fixed height for chips
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (avatar != null) ...[avatar!, const SizedBox(width: 8)],
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // Increased font size
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterBar extends ConsumerWidget {
  const _DateFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);
    final selectedDateFilter = ref.watch(
      searchProvider.select((s) => s.selectedDateFilter),
    );

    final dateFilters = [
      {'key': 'all', 'label': 'All Dates'},
      {'key': 'today', 'label': 'Today'},
      {'key': 'weekend', 'label': 'Weekend'},
      {'key': 'this_week', 'label': 'This Week'},
      {'key': 'this_month', 'label': 'This Month'},
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: dateFilters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final filter = dateFilters[index];
        final isSelected = selectedDateFilter == filter['key'];
        return Center(
          child: _CustomFilterChip(
            label: filter['label']!,
            isSelected: isSelected,
            onTap: () => notifier.setDateFilter(filter['key']!),
          ),
        );
      },
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(searchProvider.notifier);

    final selectedCategoryId = ref.watch(
      searchProvider.select((s) => s.selectedCategoryId),
    );
    final availableCategories = ref.watch(
      searchProvider.select((s) => s.availableCategories),
    );
    final areCategoriesLoading = ref.watch(
      searchProvider.select((s) => s.areCategoriesLoading),
    );

    if (areCategoriesLoading) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Center(
            child: Shimmer(
              color: theme.scaffoldBackgroundColor,
              child: Container(
                width: 100 + (index * 15).toDouble(),
                height: 44,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: availableCategories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Center(
            child: _CustomFilterChip(
              label: 'All Categories',
              isSelected: selectedCategoryId == null,
              onTap: () => notifier.selectCategory(null),
            ),
          );
        }

        final category = availableCategories[index - 1];
        final isSelected = selectedCategoryId == category.id;

        return Center(
          child: _CustomFilterChip(
            label: category.name,
            isSelected: isSelected,
            onTap: () => notifier.selectCategory(category.id),
            avatar: category.iconUrl.isNotEmpty
                ? SafeSvgNetwork(
                    category.iconUrl,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? Colors.white
                          : theme.colorScheme.primary.withValues(alpha: 0.7),
                      BlendMode.srcIn,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<EventModel> results;
  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return _SearchResultItem(
                key: ValueKey(results[index].id),
                event: results[index],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (50 * (index % 10)).ms)
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }
}

class _SearchResultItem extends ConsumerWidget {
  final EventModel event;
  const _SearchResultItem({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storageBaseUrl = ref.read(storageBaseUrlProvider);
    final imageUrl = event.getFullImageUrl(storageBaseUrl);
    final formattedDate = event.eventStartDate != null
        ? DateFormat('EEE, MMM d, yyyy').format(event.eventStartDate!)
        : 'Date TBD';
    final priceText = event.ticketPrice != null && event.ticketPrice! > 0
        ? '${event.symbol}${event.ticketPrice!.toStringAsFixed(0)}'
        : 'Free';
    final isFree = priceText == 'Free';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (event.slug != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => EventDetails(slug: event.slug!),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: theme.highlightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (c, u, e) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: theme.highlightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.hintColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Event Details
                Expanded(
                  child: SizedBox(
                    height: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Event Name
                        Text(
                          event.eventName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Date Row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Location and Price Row
                        Row(
                          children: [
                            if (event.venueName != null) ...[
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.venueName!,
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Price Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isFree
                                      ? [
                                          Colors.green.shade500,
                                          Colors.green.shade600,
                                        ]
                                      : [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withValues(alpha: 
                                            0.85,
                                          ),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isFree
                                                ? Colors.green
                                                : theme.colorScheme.primary)
                                            .withValues(alpha: 0.25),
                                    spreadRadius: 0,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                priceText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Find Your Next Match',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Search for matches or use filters above\nto discover something amazing',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select a filter or type to search',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _NoResultsView extends ConsumerWidget {
  const _NoResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.error.withValues(alpha: 0.15),
                  theme.colorScheme.error.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Matches Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or filters\nto find what you\'re looking for',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(searchProvider.notifier).clearAllFilters();
              ref.read(_searchControllerProvider).clear();
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'Clear All Filters',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer(
            color: theme.scaffoldBackgroundColor,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.highlightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.highlightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 18,
                          width: 150,
                          decoration: BoxDecoration(
                            color: theme.highlightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: theme.highlightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: theme.highlightColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 30,
                              width: 60,
                              decoration: BoxDecoration(
                                color: theme.highlightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

final _searchControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
