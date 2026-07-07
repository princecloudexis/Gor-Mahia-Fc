import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/pages/location.dart';
import 'package:eventsbooking/pages/categoryevents.dart';
import 'package:eventsbooking/pages/details.dart';
import 'package:eventsbooking/pages/notifications.dart';
import 'package:eventsbooking/pages/profile.dart';
import 'package:eventsbooking/pages/search.dart';
import 'package:eventsbooking/providers/location_providers.dart';
import 'package:eventsbooking/widgets/safe_svg_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../providers/event_providers.dart' hide selectedCityProvider;
import '../models/event_model.dart';
import '../models/category_model.dart';
import '../theme/apptheme.dart';
import '../theme/app_colors.dart';
import '../providers/user_providers.dart';

final selectedCategoryProvider = StateProvider<CategoryModel?>((ref) => null);
final currentBannerIndexProvider = StateProvider<int>((ref) => 0);

class Home extends ConsumerStatefulWidget {
  const Home({super.key});
  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  Widget build(BuildContext context) {
    final mainDataProvider = ref.watch(homePageDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: mainDataProvider.when(
        loading: () => const _HomeContentShimmer(),
        error: (error, stack) => Center(
          child: ErrorDisplayWidget(
            message: 'Failed to load data. Please try again.',
            onRetry: () => ref.invalidate(homePageDataProvider),
          ),
        ),
        data: (homePageData) => _FootballRefreshIndicator(
          onRefresh: () async {
            ref.read(favoritesProvider.notifier).refresh();
            ref.invalidate(nearYouEventsProvider);
            await ref.refresh(homePageDataProvider.future);
          },
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildAppBar(context, ref),
              _buildGreeting(context),
              if (homePageData.recentEvents.isNotEmpty)
                _buildBannerSection(ref, homePageData.recentEvents),
              _buildCategoriesHeader(context),
              _buildCategories(context, ref, homePageData.categories),

              _buildSectionHeader('Hot Fixtures This Week', context),
              _buildDiscoverThisWeek(homePageData.discoverThisWeekEvents),
              if (homePageData.eventsByCity.isNotEmpty) ...[
                _buildSectionHeader('Matches Near Your City', context),
                _buildHorizontalEvents(homePageData.eventsByCity),
              ] else ...[
                _buildSectionHeader('Matches Near Your City', context),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: const EmptyContentWidget(
                      message: 'No fixtures scheduled\nfor your city yet.',
                      icon: Icons.sports_soccer_outlined,
                    ),
                  ),
                ),
              ],
              _buildUpcomingHeader(context),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildUpcomingEvents(homePageData.upcomingEvents),

              _buildSectionHeader('Kick-Offs Near You', context),
              _buildNearbyEvents(ref),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Matches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── GREETING & PROFILE HDR ──────────────────────────────
  Widget _buildGreeting(BuildContext context) {
    final user = ref.watch(userProvider);
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: ClipOval(
                child: (user?.cleanedImageUrl != null)
                    ? CachedNetworkImage(
                        imageUrl: user!.cleanedImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : const Icon(Icons.person, color: Colors.white54),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.firstName ?? "Guest"} ${user?.lastName ?? ""}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        user?.membershipPlan ?? "Free Plan",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primaryGreen,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Location
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _LocationWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORIES LABEL ──────────────────────
  Widget _buildCategoriesHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          'Browse by Match Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ───────────────────────────────
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: AppColors.bgDark,
      toolbarHeight: 60,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset(
            'assets/images/Gor-Mahia-FC-logo.png',
            height: 34,
            width: 34,
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
              children: [
                TextSpan(
                  text: "K'OGALO ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "FAN HUB",
                  style: TextStyle(color: AppColors.greenLight),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _TopIconBtn(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Notifications()),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // ─── SECTION HEADER ────────────────────────
  Widget _buildSectionHeader(String title, BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ─── CATEGORIES ────────────────────────────
  Widget _buildCategories(
    BuildContext context,
    WidgetRef ref,
    List<CategoryModel> categories,
  ) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = ref.watch(selectedCategoryProvider) == null;
              return _CategoryChip(
                label: 'All',
                isSelected: isSelected,
                onTap: () =>
                    ref.read(selectedCategoryProvider.notifier).state = null,
              );
            }
            final cat = categories[index - 1];
            return _CategoryChip(
              label: cat.name,
              iconUrl: cat.iconUrl,
              isSelected: ref.watch(selectedCategoryProvider)?.id == cat.id,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryEvents(category: cat),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── BANNER ────────────────────────────────
  Widget _buildBannerSection(WidgetRef ref, List<EventModel> events) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _BannerSection(events: events),
      ),
    );
  }

  // ─── DISCOVER THIS WEEK ────────────────────
  Widget _buildDiscoverThisWeek(List<EventModel> events) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: EmptyContentWidget(
            message: 'No fixtures scheduled in your city this week.',
            icon: Icons.sports_soccer_outlined,
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: _DiscoverPageView(
        events: events,
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildHorizontalEvents(List<EventModel> events) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 160,
          child: const EmptyContentWidget(
            message: 'No fixtures scheduled\nfor your city yet.',
            icon: Icons.sports_soccer_outlined,
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: events.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _EventCard(event: events[index]),
          ),
        ),
      ),
    );
  }

  // ─── UPCOMING EVENTS ───────────────────────
  Widget _buildUpcomingEvents(List<EventModel> events) {
    if (events.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final count = events.length > 5 ? 5 : events.length;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _UpcomingEventTile(event: events[index]),
        ),
        childCount: count,
      ),
    );
  }

  // ─── NEARBY EVENTS ─────────────────────────
  Widget _buildNearbyEvents(WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: locationAsync.when(
          data: (location) {
            // Check if coordinates are available
            final lat = location.latitude;
            final lng = location.longitude;

            // If no coordinates, show city-based events instead
            if (lat == null || lng == null) {
              return const EmptyContentWidget(
                message: 'Enable GPS to see\nmatches near your stadium.',
                icon: Icons.stadium_outlined,
              );
            }

            final coords = (lat: lat, lng: lng);
            final nearbyAsync = ref.watch(nearYouEventsProvider(coords));

            return nearbyAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyContentWidget(
                    message: 'No matches near your location.',
                    icon: Icons.sports_soccer_outlined,
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: events.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _EventCard(event: events[index]),
                  ),
                );
              },
              loading: () => const _HorizontalListShimmer(
                height: 240,
                itemWidth: 200,
                itemCount: 4,
                itemBorderRadius: 16,
              ),
              error: (e, _) => ErrorDisplayWidget(
                message: 'Could not load nearby events.',
                onRetry: () => ref.invalidate(nearYouEventsProvider(coords)),
              ),
            );
          },
          loading: () => const _HorizontalListShimmer(
            height: 240,
            itemWidth: 200,
            itemCount: 4,
            itemBorderRadius: 16,
          ),
          error: (_, __) => const EmptyContentWidget(
            message: 'Could not get location.',
            icon: Icons.stadium_outlined,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOCATION WIDGET
// ─────────────────────────────────────────────
class _LocationWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationSelectionPage()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryGreen,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: locationAsync.when(
                  data: (location) => Text(
                    location?.displayAddress ?? 'Location',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => Text(
                    'Finding...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error',
                    style: TextStyle(color: AppTheme.accentRed, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Tap to change',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOP ICON BUTTON
// ─────────────────────────────────────────────
class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
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
            icon,
            size: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY CHIP — slim pill
// ─────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.iconUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : Theme.of(context).cardColor,
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null) ...[
              SafeSvgNetwork(iconUrl!, height: 14, width: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BANNER SECTION
// ─────────────────────────────────────────────
class _BannerSection extends ConsumerStatefulWidget {
  final List<EventModel> events;
  const _BannerSection({required this.events});

  @override
  ConsumerState<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends ConsumerState<_BannerSection> {
  late final PageController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next =
          (ref.read(currentBannerIndexProvider) + 1) % widget.events.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final currentIndex = ref.watch(currentBannerIndexProvider);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) =>
                ref.read(currentBannerIndexProvider.notifier).state = i,
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetails(slug: event.slug!),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.getFullImageUrl(storageBaseUrl),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _ImageErrorWidget(),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                      // Event name
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.eventName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.eventStartDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(event.eventStartDate!),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Dot indicators
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.events.length, (i) {
            final isActive = i == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryBlue
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────
// DISCOVER PAGE VIEW — large card scroller
// ─────────────────────────────────────────────
class _DiscoverPageView extends StatefulWidget {
  final List<EventModel> events;
  const _DiscoverPageView({required this.events});

  @override
  State<_DiscoverPageView> createState() => _DiscoverPageViewState();
}

class _DiscoverPageViewState extends State<_DiscoverPageView> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
    _controller.addListener(() {
      if (mounted) setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.events.length,
        itemBuilder: (context, index) {
          final scale = max(0.92, 1 - (_page - index).abs() * 0.08);
          return Transform.scale(
            scale: scale,
            child: _DiscoverCard(event: widget.events[index]),
          );
        },
      ),
    );
  }
}

class _DiscoverCard extends ConsumerWidget {
  final EventModel event;
  const _DiscoverCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final isFavorite =
        ref
            .watch(favoritesProvider)
            .asData
            ?.value
            .any((fav) => fav.id == event.id) ??
        false;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetails(slug: event.slug!)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: event.getFullImageUrl(storageBaseUrl),
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _ImageErrorWidget(),
              ),
              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Favorite
              Positioned(
                top: 12,
                right: 12,
                child: _FavoriteBtn(
                  isFavorite: isFavorite,
                  onTap: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(event),
                ),
              ),
              // Info
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.eventName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          event.eventStartDate != null
                              ? DateFormat(
                                  'MMM d, yyyy',
                                ).format(event.eventStartDate!)
                              : '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.displayLocationString,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EVENT CARD — horizontal list card
// ─────────────────────────────────────────────
class _EventCard extends ConsumerWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetails(slug: event.slug!)),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: event.getFullImageUrl(storageBaseUrl),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _ImageErrorWidget(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.displayLocationString,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (event.eventStartDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('MMM d').format(event.eventStartDate!),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UPCOMING EVENT TILE — list row
// ─────────────────────────────────────────────
class _UpcomingEventTile extends ConsumerWidget {
  final EventModel event;
  const _UpcomingEventTile({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetails(slug: event.slug!)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.eventStartDate != null
                        ? DateFormat('MMM').format(event.eventStartDate!)
                        : '--',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  Text(
                    event.eventStartDate != null
                        ? DateFormat('d').format(event.eventStartDate!)
                        : '--',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryPink,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: event.getFullImageUrl(storageBaseUrl),
                width: 56,
                height: 52,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _ImageErrorWidget(),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.displayLocationString,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAVORITE BUTTON
// ─────────────────────────────────────────────
class _FavoriteBtn extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const _FavoriteBtn({required this.isFavorite, required this.onTap});

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
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppTheme.accentRed : Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ERROR WIDGET
// ─────────────────────────────────────────────
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorDisplayWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPink,
                  side: BorderSide(
                    color: AppTheme.primaryPink.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY CONTENT WIDGET
// ─────────────────────────────────────────────
class EmptyContentWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyContentWidget({
    super.key,
    this.message = 'Nothing here yet.',
    this.icon = Icons.event_busy_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// IMAGE ERROR WIDGET
// ─────────────────────────────────────────────
class _ImageErrorWidget extends StatelessWidget {
  const _ImageErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER — HOME CONTENT
// ─────────────────────────────────────────────
class _HomeContentShimmer extends StatelessWidget {
  const _HomeContentShimmer();

  Widget _box(
    BuildContext context, {
    double? width,
    required double height,
    double radius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Theme.of(context).shadowColor,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // AppBar shimmer
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 12,
                16,
                12,
              ),
              child: Row(
                children: [
                  _box(context, width: 16, height: 16, radius: 4),
                  const SizedBox(width: 6),
                  _box(context, width: 120, height: 14, radius: 4),
                  const Spacer(),
                  _box(context, width: 36, height: 36, radius: 10),
                  const SizedBox(width: 6),
                  _box(context, width: 36, height: 36, radius: 10),
                  const SizedBox(width: 6),
                  _box(context, width: 36, height: 36, radius: 10),
                ],
              ),
            ),
          ),

          // Categories shimmer
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _box(context, width: 80, height: 36, radius: 20),
                ),
              ),
            ),
          ),

          // Banner shimmer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _box(context, height: 200, radius: 20),
            ),
          ),

          // Section headers + cards
          for (int s = 0; s < 3; s++) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: _box(context, width: 160, height: 18, radius: 6),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: s == 0 ? 340 : 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _box(
                      context,
                      width: s == 0 ? 260 : 200,
                      height: s == 0 ? 340 : 240,
                      radius: s == 0 ? 24 : 16,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Upcoming shimmer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: _box(context, width: 140, height: 18, radius: 6),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _box(context, height: 72, radius: 14),
              ),
              childCount: 3,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HORIZONTAL LIST SHIMMER
// ─────────────────────────────────────────────
class _HorizontalListShimmer extends StatelessWidget {
  final double height;
  final double itemWidth;
  final int itemCount;
  final double itemBorderRadius;

  const _HorizontalListShimmer({
    required this.height,
    required this.itemWidth,
    required this.itemCount,
    required this.itemBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Theme.of(context).shadowColor,
      child: SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: itemCount,
          itemBuilder: (_, __) => Container(
            width: itemWidth,
            height: height,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).splashColor,
              borderRadius: BorderRadius.circular(itemBorderRadius),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Football-Themed Pull-to-Refresh Indicator
// ─────────────────────────────────────────────────────────────────────────────
class _FootballRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const _FootballRefreshIndicator({
    required this.onRefresh,
    required this.child,
  });

  @override
  State<_FootballRefreshIndicator> createState() =>
      _FootballRefreshIndicatorState();
}

class _FootballRefreshIndicatorState extends State<_FootballRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _spinController.repeat();
    try {
      await widget.onRefresh();
    } catch (_) {
      // Silently swallow errors
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        // Wait for the exit animation to finish before stopping the spin
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && !_isRefreshing) {
            _spinController.stop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      displacement: 70,
      strokeWidth: 0,
      elevation: 0,
      color: Colors.transparent,
      backgroundColor: Colors.transparent,
      onRefresh: _handleRefresh,
      notificationPredicate: (notification) {
        if (notification.depth != 0) return false;
        if (notification.metrics.extentBefore != 0) return false;
        if (notification is OverscrollNotification) {
          return notification.dragDetails != null;
        }
        return true;
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child:
                  Center(
                        child: RotationTransition(
                          turns: _spinController,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.greenMain,
                                  AppColors.blueMain,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.greenMain.withOpacity(0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sports_soccer_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      )
                      .animate(target: _isRefreshing ? 1 : 0)
                      .slideY(
                        begin: -4.0,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fade(duration: 300.ms),
            ),
          ),
        ],
      ),
    );
  }
}
