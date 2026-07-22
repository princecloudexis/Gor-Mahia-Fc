import 'package:eventsbooking/repositories/match_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/match_providers.dart';
import '../providers/user_providers.dart';

class MatchCenter extends StatelessWidget {
  final int matchId;
  const MatchCenter({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Green Header Section (Live Polling)
            _MatchHeader(matchId: matchId, isCompact: isKeyboardOpen),

            // TabBar
            Container(
              color: isDark ? const Color(0xFF0A140F) : Colors.white,
              child: TabBar(
                indicatorColor: AppColors.primaryGreen,
                indicatorWeight: 3,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Lineup'),
                  Tab(text: 'Stats'),
                  Tab(text: 'Chat'),
                ],
              ),
            ),

            // TabBarView
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/footballbg.png'),
                    fit: BoxFit.cover,
                    opacity: isDark ? 0.10 : 0.05,
                  ),
                ),
                child: TabBarView(
                  children: [
                    _OverviewTab(isDark: isDark, matchId: matchId),
                    _LineupTab(isDark: isDark, matchId: matchId),
                    _StatsTab(isDark: isDark, matchId: matchId),
                    _ChatTab(isDark: isDark, matchId: matchId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHeader extends ConsumerStatefulWidget {
  final int matchId;
  final bool isCompact;
  const _MatchHeader({required this.matchId, this.isCompact = false});

  @override
  ConsumerState<_MatchHeader> createState() => _MatchHeaderState();
}

class _MatchHeaderState extends ConsumerState<_MatchHeader> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    // Start rotation animation from the beginning
    _rotationController.forward(from: 0.0);
    // Manually invalidate the stream provider to force an immediate fetch
    ref.invalidate(matchSummaryStreamProvider(widget.matchId));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(matchSummaryStreamProvider(widget.matchId));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryGreen, AppColors.greenDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: RotationTransition(
                    turns: _rotationController,
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  onPressed: _handleRefresh,
                ),
              ],
            ),
            summaryAsync.when(
              data: (summary) {
                return AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: widget.isCompact 
                      ? CrossFadeState.showFirst 
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${summary.homeTeam.shortCode ?? summary.homeTeam.name.toUpperCase()} ${summary.homeScore ?? 0} - ${summary.awayScore ?? 0} ${summary.awayTeam.shortCode ?? summary.awayTeam.name.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (summary.minuteLabel != null && summary.minuteLabel!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              summary.minuteLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  secondChild: Column(
                    children: [
                      Text(
                        '${summary.homeTeam.name.toUpperCase()} vs ${summary.awayTeam.name.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${summary.homeScore ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '-',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 48,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${summary.awayScore ?? 0}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 64,
                              fontWeight: FontWeight.w300,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary.minuteLabel ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              error: (e, st) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Error loading summary',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: widget.isCompact ? 4 : 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final bool isDark;
  final int matchId;
  const _OverviewTab({required this.isDark, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(matchOverviewProvider(matchId));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchOverviewProvider(matchId).future),
      color: AppColors.primaryGreen,
      child: overviewAsync.when(
        data: (overview) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildInfoCard(
                title: 'MATCH EVENTS',
                isDark: isDark,
                children: overview.goalEvents.isEmpty
                    ? [
                        Text(
                          'No match events yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ]
                    : overview.goalEvents.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildEventRow(
                            event.minuteLabel ?? '${event.minute}\'',
                            Icons.sports_soccer,
                            '${event.playerName} scores',
                            isDark,
                          ),
                        );
                      }).toList(),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'MATCH INFO',
                isDark: isDark,
                children: [
                  _buildInfoRow('Venue: ', overview.venue ?? 'TBD', isDark),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Attendance: ',
                    overview.attendance?.toString() ?? 'TBD',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Referee: ', overview.referee ?? 'TBD', isDark),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Weather: ',
                    (overview.weatherTempC != null &&
                            overview.weatherCondition != null)
                        ? '${overview.weatherTempC}°C, ${overview.weatherCondition}'
                        : 'TBD',
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(
                'Error loading overview: $error',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEventRow(
    String time,
    IconData icon,
    String detail,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 16,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Icon(icon, size: 14, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardEventRow(String time, String detail, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 16,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.yellow.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryGreen,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                fontFamily: 'Manrope',
              ),
              children: [
                TextSpan(text: label),
                TextSpan(
                  text: value,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsTab extends ConsumerWidget {
  final bool isDark;
  final int matchId;
  const _StatsTab({required this.isDark, required this.matchId});

  String _formatLabel(String key) {
    if (key == 'possession_percent') return 'Possession';
    final parts = key.split('_');
    return parts
        .map(
          (e) =>
              e.isEmpty ? '' : e.substring(0, 1).toUpperCase() + e.substring(1),
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatsProvider(matchId));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchStatsProvider(matchId).future),
      color: AppColors.primaryGreen,
      child: statsAsync.when(
        data: (statsData) {
          if (statsData.stats.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Text(
                    'No stats available.',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              ...statsData.stats.map((stat) {
                final isPossession = stat.key == 'possession_percent';
                final homeStr = isPossession ? '${stat.home}%' : '${stat.home}';
                final awayStr = isPossession ? '${stat.away}%' : '${stat.away}';

                double homePercentage = 0;
                final total = stat.home + stat.away;
                if (total > 0) {
                  homePercentage = stat.home / total;
                } else if (stat.home == 0 && stat.away == 0) {
                  homePercentage = 0.5;
                }

                return _buildStatRow(
                  _formatLabel(stat.key),
                  homeStr,
                  awayStr,
                  homePercentage,
                  isDark,
                );
              }).toList(),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(
                'Error loading stats: $error',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String homeValue,
    String awayValue,
    double homePercentage,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 45,
                child: Text(
                  homeValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      if (homePercentage > 0)
                        Expanded(
                          flex: (homePercentage * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      if (homePercentage < 1)
                        Expanded(
                          flex: ((1 - homePercentage) * 100).toInt(),
                          child: const SizedBox(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 45,
                child: Text(
                  awayValue,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineupTab extends ConsumerWidget {
  final bool isDark;
  final int matchId;
  const _LineupTab({required this.isDark, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(matchId));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(matchLineupProvider(matchId).future),
      color: AppColors.primaryGreen,
      child: lineupAsync.when(
        data: (lineupData) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildLineupCard(
                title:
                    '${lineupData.home.teamName.toUpperCase()} (${lineupData.home.formation ?? "N/A"})',
                players: lineupData.home.startingXi.map((p) => p.name).toList(),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildLineupCard(
                title:
                    '${lineupData.away.teamName.toUpperCase()} (${lineupData.away.formation ?? "N/A"})',
                players: lineupData.away.startingXi.map((p) => p.name).toList(),
                isDark: isDark,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, stack) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(
                'Error loading lineup: $error',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineupCard({
    required String title,
    required List<String> players,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...players.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                player,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  final bool isDark;
  final int matchId;
  const _ChatTab({required this.isDark, required this.matchId});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to ensure list has rebuilt before scrolling
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // Scroll to 0.0 because the list is reversed
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final repository = ref.read(matchRepositoryProvider);
      final sentMessage = await repository.postMatchChat(widget.matchId, text);
      _messageController.clear();

      // Append the message immediately to the UI
      ref
          .read(matchChatProvider(widget.matchId).notifier)
          .addMessage(sentMessage);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(matchChatProvider(widget.matchId));
    final currentUser = ref.watch(userProvider);
    final currentUserId = currentUser?.id;

    // Listen for new messages to auto-scroll
    ref.listen(matchChatProvider(widget.matchId), (previous, next) {
      if (next.value != null &&
          previous?.value != null &&
          next.value!.length > previous!.value!.length) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(matchChatProvider(widget.matchId).future),
            color: AppColors.primaryGreen,
            child: chatAsync.when(
              data: (chatMessages) {
                if (chatMessages.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Text(
                          'No chat messages yet. Be the first!',
                          style: TextStyle(
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView(
                  controller: _scrollController,
                  reverse: true, // Builds from bottom to top
                  padding: const EdgeInsets.all(20),
                  children: chatMessages.reversed
                      .map(
                        (msg) => _buildChatMessage(
                          msg.user.name,
                          msg.message,
                          msg.createdLabel,
                          widget.isDark,
                          msg.user.id == currentUserId,
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
              error: (error, stack) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Text(
                      'Error loading chat: $error',
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0A140F) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: widget.isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1A2A20)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              color: widget.isDark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: widget.isDark
                                    ? Colors.white38
                                    : Colors.black38,
                                fontSize: 14,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isSending 
                          ? null 
                          : const LinearGradient(
                              colors: [AppColors.primaryGreen, AppColors.greenDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isSending ? Colors.grey.shade400 : null,
                      shape: BoxShape.circle,
                      boxShadow: _isSending ? [] : [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(
    String username,
    String message,
    String? timeLabel,
    bool isDark,
    bool isMe,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe)
                      Text(
                        username,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    if (!isMe && timeLabel != null) const SizedBox(width: 8),
                    if (timeLabel != null)
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? AppColors.primaryGreen 
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe 
                          ? Colors.white 
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
