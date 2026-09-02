import 'dart:ui';
import 'package:kogalo_network/models/location_model.dart';
import 'package:kogalo_network/providers/event_providers.dart';
import 'package:kogalo_network/providers/location_providers.dart';
import 'package:kogalo_network/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Search Query Provider ───────────────────
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// ─────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────
class LocationSelectionPage extends ConsumerWidget {
  const LocationSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch cities from API
    final citiesAsync = ref.watch(availableCitiesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: citiesAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) =>
            _ErrorView(onRetry: () => ref.invalidate(availableCitiesProvider)),
        data: (cities) {
          // Filter cities based on search
          final filtered = cities
              .where(
                (city) =>
                    city.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── App Bar ──
              _AppBar(),

              // ── Search ──
              _StickySearchBar(),

              // ── Use Current Location ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _CurrentLocationTile(),
                ),
              ),

              // ── Popular Cities (when not searching) ──
              if (searchQuery.isEmpty) ...[
                _SectionHeader(title: 'Available Cities'),
                _PopularCitiesChips(cities: cities),
              ],

              // ── All Cities List ──
              _SectionHeader(
                title: searchQuery.isEmpty ? 'All Cities' : 'Results',
              ),

              if (filtered.isEmpty)
                const _NoResults()
              else
                _CityList(cities: filtered),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOADING VIEW
// ─────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ─────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              'Could not load cities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPink,
                side: BorderSide(color: AppTheme.primaryPink.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          Text(
            'Choose your city',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
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
// STICKY SEARCH BAR
// ─────────────────────────────────────────────
class _StickySearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(pinned: true, delegate: _SearchDelegate());
  }
}

class _SearchDelegate extends SliverPersistentHeaderDelegate {
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
          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Consumer(
            builder: (context, ref, _) {
              return TextField(
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryPink.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => true;
}

// ─────────────────────────────────────────────
// CURRENT LOCATION TILE
// ─────────────────────────────────────────────
class _CurrentLocationTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CurrentLocationTile> createState() =>
      _CurrentLocationTileState();
}

class _CurrentLocationTileState extends ConsumerState<_CurrentLocationTile> {
  bool _isLoading = false;

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isLoading = true);
    await ref.read(locationControllerProvider.notifier).getUserLocation();
    if (!mounted) return;
    // Refresh home data with new location
    ref.invalidate(homePageDataProvider);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _handleUseCurrentLocation,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: AppTheme.primaryPink,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Current Location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Detect location automatically',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryPink,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.primaryPink,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// POPULAR CITIES — horizontal chips from API
// ─────────────────────────────────────────────
class _PopularCitiesChips extends ConsumerWidget {
  final List<String> cities;
  const _PopularCitiesChips({required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];
            return GestureDetector(
              onTap: () => _selectCity(context, ref, city),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_city_rounded,
                      size: 13,
                      color: AppTheme.primaryPink,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      // Capitalize first letter
                      city[0].toUpperCase() + city.substring(1),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CITY LIST
// ─────────────────────────────────────────────
class _CityList extends ConsumerWidget {
  final List<String> cities;
  const _CityList({required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cities.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 52,
              color: Theme.of(context).dividerColor,
            ),
            itemBuilder: (context, index) {
              final city = cities[index];
              final displayName = city[0].toUpperCase() + city.substring(1);
              return InkWell(
                onTap: () => _selectCity(context, ref, city),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == cities.length - 1
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Letter avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            city[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // City name
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED SELECT CITY FUNCTION
// ─────────────────────────────────────────────
void _selectCity(BuildContext context, WidgetRef ref, String cityName) {
  final location = LocationModel(
    city: cityName[0].toUpperCase() + cityName.substring(1),
    state: '',
    country: 'India',
    subLocality: null,
  );

  ref.read(locationControllerProvider.notifier).setLocation(location);
  ref.invalidate(homePageDataProvider);
  Navigator.of(context).pop();
}

// ─────────────────────────────────────────────
// NO RESULTS
// ─────────────────────────────────────────────
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 12),
            Text(
              'No Cities Found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
