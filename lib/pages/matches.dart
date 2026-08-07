import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/match_models.dart';
import '../providers/match_providers.dart';
import 'match_center.dart';
import 'profile.dart';
import 'search.dart';
import 'shop.dart';
import '../widgets/top_action_btn.dart';

import '../providers/navigation_providers.dart';

class Matches extends ConsumerStatefulWidget {
  const Matches({super.key});

  @override
  ConsumerState<Matches> createState() => _MatchesState();
}

class _MatchesState extends ConsumerState<Matches> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: ref.read(matchesTabIndexProvider),
    );
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      ref.read(matchesTabIndexProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<int>(matchesTabIndexProvider, (previous, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: Text(
          'Matches',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
          ),
        ),
        centerTitle: false,
        actions: [

          TopActionBtn(
            icon: Icons.shopping_bag_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Shop()),
              );
            },
          ),
          TopActionBtn(
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Fixtures'),
            Tab(text: 'Live'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/footballbg.png'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.15 : 0.10,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _FixturesTab(isDark: isDark),
            _LiveTab(isDark: isDark),
            _ResultsTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _FixturesTab extends ConsumerWidget {
  final bool isDark;
  const _FixturesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixturesAsync = ref.watch(matchFixturesProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchFixturesProvider.future),
      color: AppColors.primaryGreen,
      child: fixturesAsync.when(
        data: (data) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              if (data.liveMatches.isNotEmpty) ...[
                LiveMatchesCarousel(
                  liveMatches: data.liveMatches,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'UPCOMING FIXTURES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (data.upcomingFixtures.isEmpty)
                Center(
                  child: Text(
                    'No upcoming fixtures.',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                )
              else
                ...data.upcomingFixtures.map(
                  (fixture) => Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                    child: MatchListTile(
                      home: fixture.homeTeam.name.toUpperCase(),
                      away: fixture.awayTeam.name.toUpperCase(),
                      time: fixture.matchDatetimeLabel?.toUpperCase() ?? 'TBD',
                      isDark: isDark,
                    ),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading fixtures: $error',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              TextButton(
                onPressed: () => ref.refresh(matchFixturesProvider.future),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTab extends ConsumerWidget {
  final bool isDark;
  const _LiveTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMatchesAsync = ref.watch(matchLiveProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchLiveProvider.future),
      color: AppColors.primaryGreen,
      child: liveMatchesAsync.when(
        data: (liveMatches) {
          if (liveMatches.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Text(
                    'No live matches right now.',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              LiveMatchesCarousel(
                liveMatches: liveMatches,
                isDark: isDark,
              ),
              const SizedBox(height: 100),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading live matches: $error',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}

class LiveMatchesCarousel extends StatefulWidget {
  final List<MatchModel> liveMatches;
  final bool isDark;

  const LiveMatchesCarousel({
    super.key,
    required this.liveMatches,
    required this.isDark,
  });

  @override
  State<LiveMatchesCarousel> createState() => _LiveMatchesCarouselState();
}

class _LiveMatchesCarouselState extends State<LiveMatchesCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.liveMatches.isEmpty) return const SizedBox.shrink();

    if (widget.liveMatches.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LiveMatchCard(isDark: widget.isDark, match: widget.liveMatches.first),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 450, // Generous bound to avoid overflow for goals
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.liveMatches.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.8, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.9;
                  }
                  
                  // Calculate opacity based on how far from center it is
                  double opacityRatio = ((value - 0.8) / 0.2).clamp(0.0, 1.0);
                  double displayOpacity = 0.4 + (opacityRatio * 0.6); // Background cards are 40% opaque
                  
                  return Center(
                    child: Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: Opacity(
                        opacity: displayOpacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LiveMatchCard(
                      isDark: widget.isDark, 
                      match: widget.liveMatches[index],
                      pageIndicatorText: '${index + 1} OF ${widget.liveMatches.length}',
                    ),
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

class LiveMatchCard extends StatelessWidget {
  final bool isDark;
  final MatchModel match;
  final String? pageIndicatorText;
  const LiveMatchCard({super.key, required this.isDark, required this.match, this.pageIndicatorText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF133221), const Color(0xFF09160E)]
              : [const Color(0xFFE8F3EE), const Color(0xFFCDE6D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.competition?.toUpperCase() ?? 'MATCH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                if (match.isLive == true || (match.status != null && match.status != 'upcoming'))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: match.status == 'finished'
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: match.status == 'finished'
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getBadgeText(match.status, match.isLive),
                      style: TextStyle(
                        color: match.status == 'finished'
                            ? (isDark ? Colors.white70 : Colors.black54)
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    TeamBadge(
                      letters:
                          match.homeTeam.shortCode ??
                          (match.homeTeam.name.length >= 2
                              ? match.homeTeam.name
                                    .substring(0, 2)
                                    .toUpperCase()
                              : match.homeTeam.name.toUpperCase()),
                      logoUrl: match.homeTeam.logoUrl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textOnLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textOnLight,
                  ),
                ),
                Column(
                  children: [
                    TeamBadge(
                      letters:
                          match.awayTeam.shortCode ??
                          (match.awayTeam.name.length >= 2
                              ? match.awayTeam.name
                                    .substring(0, 2)
                                    .toUpperCase()
                              : match.awayTeam.name.toUpperCase()),
                      logoUrl: match.awayTeam.logoUrl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textOnLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${match.venue ?? 'TBD'} • ${match.minuteLabel ?? ''}',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (match.goalEvents != null && match.goalEvents!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: match.goalEvents!
                    .map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GoalScorerRow(
                          name: goal.playerName,
                          time: "${goal.minute}'",
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, pageIndicatorText != null ? 12 : 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchCenter(matchId: match.id),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.bgCardLight
                    : AppColors.bgCardDark,
                foregroundColor: isDark ? AppColors.primaryGreen : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'VIEW MATCH CENTER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          if (pageIndicatorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Text(
                  pageIndicatorText!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.greenLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getBadgeText(String? status, bool? isLive) {
    if (status == 'half_time') return 'HT';
    if (status == 'finished') return 'FT';
    if (status == 'delayed') return 'DELAYED';
    if (isLive == true || status == 'live') return 'LIVE';
    return status?.toUpperCase() ?? 'LIVE';
  }
}

class TeamBadge extends StatelessWidget {
  final String letters;
  final String? logoUrl;
  const TeamBadge({super.key, required this.letters, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.greenDarkest,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        image: logoUrl != null
            ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: logoUrl == null
          ? Center(
              child: Text(
                letters,
                style: const TextStyle(
                  color: AppColors.greenLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}

class GoalScorerRow extends StatelessWidget {
  final String name;
  final String time;
  final bool isDark;

  const GoalScorerRow({
    super.key,
    required this.name,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports_soccer, size: 12, color: AppColors.greenLight),
        const SizedBox(width: 8),
        Text(
          '$name ($time)',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class MatchListTile extends StatelessWidget {
  final String home;
  final String away;
  final String time;
  final bool isDark;

  const MatchListTile({
    super.key,
    required this.home,
    required this.away,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$home vs $away',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsTab extends ConsumerWidget {
  final bool isDark;
  const _ResultsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(matchResultsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchResultsProvider.future),
      color: AppColors.primaryGreen,
      child: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Text(
                    'No results found.',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              ...results.map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ResultListTile(match: match, isDark: isDark),
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading results: $error',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}

class ResultListTile extends StatelessWidget {
  final MatchModel match;
  final bool isDark;

  const ResultListTile({super.key, required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TeamBadge(
                  letters:
                      match.homeTeam.shortCode ??
                      (match.homeTeam.name.length >= 2
                          ? match.homeTeam.name.substring(0, 2).toUpperCase()
                          : match.homeTeam.name.toUpperCase()),
                  logoUrl: match.homeTeam.logoUrl,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.greenSurface : AppColors.greenPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.greenLight : AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                TeamBadge(
                  letters:
                      match.awayTeam.shortCode ??
                      (match.awayTeam.name.length >= 2
                          ? match.awayTeam.name.substring(0, 2).toUpperCase()
                          : match.awayTeam.name.toUpperCase()),
                  logoUrl: match.awayTeam.logoUrl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.awayTeam.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
