import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gormahiafc/api/api_client.dart';
import 'package:gormahiafc/models/category_model.dart';
import 'package:gormahiafc/models/event_model.dart';
import 'package:gormahiafc/pages/details.dart';
import 'package:gormahiafc/pages/search.dart';
import 'package:gormahiafc/providers/location_providers.dart';
import 'package:gormahiafc/repositories/event_repositories.dart';
import 'package:gormahiafc/widgets/safe_svg_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../providers/categoryevents_providers.dart';
import '../theme/apptheme.dart';
import '../theme/app_colors.dart';
import '../providers/event_providers.dart' hide selectedCityProvider;

const double _defaultLat = 23.0225;
const double _defaultLng = 72.5714;

const Map<String, EventFilter> _sortOptions = {
  'Popular': EventFilter.popular,
  'Date': EventFilter.date,
  'Price': EventFilter.price,
  'Distance': EventFilter.distance,
};

// ─────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────
class CategoryEvents extends ConsumerWidget {
  final CategoryModel category;
  const CategoryEvents({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);
    final sortBy = ref.watch(sortByProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final CategoryRequestParams? params = locationAsync.when(
      data: (location) {
        final city = selectedCity?.isNotEmpty == true
            ? selectedCity
            : location.city.isNotEmpty
            ? location.city.toLowerCase().trim()
            : null;

        return CategoryRequestParams(
          categoryId: category.id,
          latitude: location.latitude ?? _defaultLat,
          longitude: location.longitude ?? _defaultLng,
          city: city,
          filter: _sortOptions[sortBy] ?? EventFilter.popular,
          order: SortOrder.desc,
        );
      },
      loading: () => null,
      error: (_, __) => CategoryRequestParams(
        categoryId: category.id,
        latitude: _defaultLat,
        longitude: _defaultLng,
        city: selectedCity,
        filter: _sortOptions[sortBy] ?? EventFilter.popular,
        order: SortOrder.desc,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppTheme.primaryPink,
        backgroundColor: Theme.of(context).cardColor,
        onRefresh: () async {
          if (params != null) {
            await ref.refresh(categoryWiseEventsProvider(params).future);
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _AppBar(category: category, params: params),
            _FilterBar(),
            if (params == null)
              const _CategoryShimmer()
            else
              _CategoryBody(params: params),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────
class _AppBar extends ConsumerWidget {
  final CategoryModel category;
  final CategoryRequestParams? params;

  const _AppBar({required this.category, this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventCount = params != null
        ? ref.watch(
            categoryWiseEventsProvider(
              params!,
            ).select((d) => d.valueOrNull?.length),
          )
        : null;

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      toolbarHeight: 64,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Category Icon
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
            ),
            child: SafeSvgNetwork(
              category.iconUrl,
              width: 18,
              height: 18,
              placeholderBuilder: (_) => const Icon(
                Icons.category_outlined,
                color: AppTheme.primaryPink,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + Count + City badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (eventCount != null) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$eventCount events',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else
                      Text(
                        'Loading...',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),

                    // City badge
                    Consumer(
                      builder: (context, ref, _) {
                        final city = ref.watch(selectedCityProvider);
                        if (city == null || city.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final label = city.length > 1
                            ? '${city[0].toUpperCase()}${city.substring(1)}'
                            : city.toUpperCase();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primaryPink.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 9,
                                    color: AppTheme.primaryPink,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.primaryPink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),


        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(pinned: true, delegate: _FilterDelegate());
  }
}

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  static const List<String> _options = ['Popular', 'Date', 'Price', 'Distance'];

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          child: Consumer(
            builder: (context, ref, _) {
              final sortBy = ref.watch(sortByProvider);

              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // ── Row 1: Sort chips — 44px ──
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final opt = _options[index];
                        final isSelected = sortBy == opt;
                        return GestureDetector(
                          onTap: () =>
                              ref.read(sortByProvider.notifier).state = opt,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? null
                                  : Theme.of(context).cardColor,
                              gradient: isSelected
                                  ? AppColors.primaryGradient
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY BODY
// ─────────────────────────────────────────────
class _CategoryBody extends ConsumerWidget {
  final CategoryRequestParams params;
  const _CategoryBody({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(categoryWiseEventsProvider(params));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList.builder(
            itemCount: events.length,
            itemBuilder: (context, index) =>
                _EventCard(event: events[index], index: index),
          ),
        );
      },
      loading: () => const _CategoryShimmer(),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load events',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(categoryWiseEventsProvider(params)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPink,
                  side: BorderSide(
                    color: AppTheme.primaryPink.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EVENT CARD  ← THIS WAS THE BROKEN ONE
// ─────────────────────────────────────────────
class _EventCard extends ConsumerWidget {
  final EventModel event; // ✅ has event, NOT category
  final int index;

  const _EventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Uses event — not category, not params, not Scaffold
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final isFavorite = ref.watch(isFavoriteProvider(event.id));

    return GestureDetector(
          onTap: () {
            if (event.slug != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetails(slug: event.slug!),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: event.getFullImageUrl(storageBaseUrl),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: Theme.of(context).splashColor,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _FavBtn(
                        isFavorite: isFavorite,
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(event),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.eventName,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _PriceChip(event: event),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppTheme.primaryPink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(event.eventStartDate),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (event.distance != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.near_me_outlined,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.distance!.toStringAsFixed(1)} km',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.displayLocationString,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (80 * (index % 6)).ms)
        .slideY(begin: 0.1, end: 0);
  }
}

// ─────────────────────────────────────────────
// PRICE CHIP
// ─────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final EventModel event;
  const _PriceChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final isFree = event.ticketPrice == null || event.ticketPrice! <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFree
            ? Colors.green.withOpacity(0.1)
            : AppTheme.primaryPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFree
              ? Colors.green.withOpacity(0.4)
              : AppTheme.primaryPink.withOpacity(0.4),
        ),
      ),
      child: Text(
        isFree
            ? 'Free'
            : '${event.symbol ?? 'KSh '}${event.ticketPrice!.toStringAsFixed(0)}',
        style: TextStyle(
          color: isFree ? Colors.green : AppTheme.primaryPink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAVORITE BUTTON
// ─────────────────────────────────────────────
class _FavBtn extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavBtn({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppTheme.accentRed : Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 52,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 14),
            Text(
              'No Matches Found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different filter or check back later.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────
class _CategoryShimmer extends StatelessWidget {
  const _CategoryShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer(
            color: Theme.of(context).shadowColor,
            child: Container(
              height: 260,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).splashColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
String _formatDate(DateTime? date) {
  if (date == null) return 'TBD';
  return DateFormat('MMM d, yyyy').format(date);
}
