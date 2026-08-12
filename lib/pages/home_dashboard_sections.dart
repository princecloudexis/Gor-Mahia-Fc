import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/match_models.dart';
import '../models/event_model.dart';
import '../providers/match_providers.dart';
import '../providers/community_providers.dart';
import '../providers/shop_providers.dart';
import '../providers/navigation_providers.dart';

import 'tickets.dart';
import 'matches.dart';
import 'match_center.dart';
import 'community.dart';
import 'monthly_contribution.dart';
import 'shop.dart';
import 'shop_product_details.dart';
import 'group_details.dart';
import 'booking.dart';
import 'package:gormahiafc/providers/user_providers.dart';

EventModel _matchToEvent(MatchModel match) {
  return EventModel(
    id: match.id,
    eventName: '${match.homeTeam.name} vs ${match.awayTeam.name}',
    venueName: match.venue ?? 'Stadium',
    eventImage: match.homeTeam.logoUrl ?? match.awayTeam.logoUrl,
    eventStartDate: match.matchDatetime != null
        ? DateTime.tryParse(match.matchDatetime!)
        : DateTime.now(),
    totalPurchased: 0,
    tags: const [],
    city: match.venue,
    currencySymbol: 'KSH',
    ticketPrice: 500,
    hideVenueFromUser: false,
    symbol: 'KSH',
  );
}

class ShimmerBox extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  const ShimmerBox({Key? key, required this.height, required this.margin})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class FeaturedBannerSection extends ConsumerWidget {
  const FeaturedBannerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(matchFixturesProvider);

    return fixturesAsync.when(
      data: (data) {
        if (data.upcomingFixtures.isEmpty) return const SizedBox.shrink();
        final match = data.upcomingFixtures.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/images/placeholder_banner.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Match: ${match.homeTeam.name} vs ${match.awayTeam.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match.matchDatetimeLabel ??
                                  match.matchDatetime ??
                                  '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Booking(
                                event: _matchToEvent(match),
                                categoryIcon: Icons.sports_soccer,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'BOOK TICKET',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
      loading: () => const ShimmerBox(
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: 20),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class LiveNowSection extends ConsumerWidget {
  const LiveNowSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(matchFixturesProvider);

    return fixturesAsync.when(
      data: (data) {
        if (data.liveMatches.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'LIVE NOW',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.92),
                  padEnds: false,
                  itemCount: data.liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = data.liveMatches[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TeamLogoName(
                                name: match.homeTeam.name,
                                logo: match.homeTeam.logoUrl,
                              ),
                              Text(
                                '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TeamLogoName(
                                name: match.awayTeam.name,
                                logo: match.awayTeam.logoUrl,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.red,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${match.minuteLabel ?? ""} LIVE',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MatchCenter(matchId: match.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Watch & Chat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const ShimmerBox(
        height: 150,
        margin: EdgeInsets.symmetric(horizontal: 20),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class TeamLogoName extends StatelessWidget {
  final String name;
  final String? logo;
  const TeamLogoName({Key? key, required this.name, this.logo})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (logo != null && logo!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: logo!,
            width: 48,
            height: 48,
            errorWidget: (_, __, ___) => Icon(
              Icons.sports_soccer,
              color: Theme.of(context).iconTheme.color,
              size: 48,
            ),
          )
        else
          Icon(
            Icons.sports_soccer,
            color: Theme.of(context).iconTheme.color,
            size: 48,
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuickAccessItem(
                icon: Icons.sports_score_outlined,
                label: 'Live Score',
                onTap: () {
                  ref.read(mainShellTabIndexProvider.notifier).state = 1;
                  ref.read(matchesTabIndexProvider.notifier).state =
                      1; // Live tab
                },
              ),
              QuickAccessItem(
                icon: Icons.calendar_month_outlined,
                label: 'Fixtures',
                onTap: () {
                  ref.read(mainShellTabIndexProvider.notifier).state = 1;
                  ref.read(matchesTabIndexProvider.notifier).state =
                      0; // Fixtures tab
                },
              ),
              QuickAccessItem(
                icon: Icons.groups_outlined,
                label: 'Community',
                onTap: () {
                  ref.read(mainShellTabIndexProvider.notifier).state = 2;
                },
              ),
              QuickAccessItem(
                icon: Icons.wallet_outlined,
                label: 'Contribute',
                onTap: () {
                  ref.read(mainShellTabIndexProvider.notifier).state = 3;
                },
              ),
              QuickAccessItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Shop',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Shop()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAccessItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green.shade400
                  : AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingMatchesSection extends ConsumerWidget {
  const UpcomingMatchesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(matchFixturesProvider);

    return fixturesAsync.when(
      data: (data) {
        if (data.upcomingFixtures.isEmpty) return const SizedBox.shrink();
        final matches = data.upcomingFixtures.length > 1
            ? data.upcomingFixtures.sublist(1)
            : data.upcomingFixtures;
        if (matches.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Matches',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Matches()),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...matches
                  .take(3)
                  .map((match) => UpcomingMatchTile(match: match)),
            ],
          ),
        );
      },
      loading: () => const ShimmerBox(
        height: 100,
        margin: EdgeInsets.symmetric(horizontal: 20),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class UpcomingMatchTile extends StatelessWidget {
  final MatchModel match;
  const UpcomingMatchTile({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                (match.homeTeam.logoUrl != null &&
                    match.homeTeam.logoUrl!.isNotEmpty)
                ? CachedNetworkImage(imageUrl: match.homeTeam.logoUrl!)
                : Icon(
                    Icons.sports_soccer,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.54),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.competition ?? 'Match',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.homeTeam.name} vs ${match.awayTeam.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.matchDatetimeLabel ?? ''} • ${match.venue ?? ''}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.54),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Booking(
                    event: _matchToEvent(match),
                    categoryIcon: Icons.sports_soccer,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'BOOK TICKET',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityGroupsSection extends ConsumerStatefulWidget {
  const CommunityGroupsSection({super.key});

  @override
  ConsumerState<CommunityGroupsSection> createState() =>
      _CommunityGroupsSectionState();
}

class _CommunityGroupsSectionState
    extends ConsumerState<CommunityGroupsSection> {
  late PageController _pageController;
  final int _initialIndex = 5000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialIndex,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreGroupsProvider);
    final groups = state.groups;

    if (state.isLoading && groups.isEmpty) {
      return const ShimmerBox(
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: 20),
      );
    }

    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Community & Groups',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: 10000, // Very large number for infinite scroll
            itemBuilder: (context, index) {
              final actualIndex = index % groups.length;
              final group = groups[actualIndex];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: group.imageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(group.imageUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6),
                            BlendMode.darken,
                          ),
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/images/placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.membersCount} m',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetails(group: group),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'JOIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SupportBannerSection extends StatelessWidget {
  const SupportBannerSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.green.shade400
                    : AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support the Club',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help us reach our goals together!',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MonthlyContribution(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Contribute Now',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FanShopSection extends ConsumerWidget {
  const FanShopSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopTopPicksProvider);

    return shopAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fan Shop',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Shop()),
                    ),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade400
                            : AppColors.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Container(
                              color: Colors.white,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: product.image ?? '',
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorWidget: (_, __, ___) => Container(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name ?? 'Product',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'KSH ${product.price ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsPage(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text(
                                    'ADD TO CART',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const ShimmerBox(
        height: 150,
        margin: EdgeInsets.symmetric(horizontal: 20),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
