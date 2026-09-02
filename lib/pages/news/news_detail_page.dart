import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/news_model.dart';
import '../../providers/news_providers.dart';

class NewsDetailPage extends ConsumerWidget {
  final int newsId;
  /// Optional pre-loaded article for instant hero display while fetching
  final NewsModel? preview;

  const NewsDetailPage({
    super.key,
    required this.newsId,
    this.preview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: detailAsync.when(
        data: (detail) => _NewsDetailView(detail: detail),
        loading: () => preview != null
            ? _NewsDetailView(
                detail: NewsDetailResponse(
                  status: 200,
                  success: true,
                  message: '',
                  data: preview!,
                  related: [],
                ),
                isLoading: true,
              )
            : const _DetailShimmer(),
        error: (e, _) => _DetailErrorView(
          onRetry: () => ref.invalidate(newsDetailProvider(newsId)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN DETAIL VIEW
// ─────────────────────────────────────────────
class _NewsDetailView extends StatelessWidget {
  final NewsDetailResponse detail;
  final bool isLoading;

  const _NewsDetailView({required this.detail, this.isLoading = false});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final news = detail.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOfficial = news.postedBy == 'admin';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Collapsing hero image AppBar ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          stretch: true,
          backgroundColor: isDark ? AppColors.bgDark : Colors.white,
          foregroundColor: Colors.white,
          leading: _BlurBackButton(),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image
                news.image != null && news.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: news.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _HeroFallback(),
                      )
                    : _HeroFallback(),
                // Gradient overlay for readability
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Article body ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source badge + date row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOfficial
                            ? AppColors.primaryGreen.withValues(alpha: 0.15)
                            : AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOfficial
                                ? Icons.verified_rounded
                                : Icons.account_balance_rounded,
                            size: 11,
                            color: isOfficial
                                ? (isDark
                                    ? Colors.green.shade300
                                    : AppColors.primaryGreen)
                                : AppColors.gold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOfficial
                                ? 'OFFICIAL'
                                : news.postedBy.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isOfficial
                                  ? (isDark
                                      ? Colors.green.shade300
                                      : AppColors.primaryGreen)
                                  : AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (news.createdAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(news.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  news.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),

                // Author row
                if (news.authorName != null && news.authorName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.greenGradient,
                          ),
                          child: Center(
                            child: Text(
                              news.authorName![0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.authorName!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOfficial ? 'Club Official' : 'Branch Reporter',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Divider with gradient accent
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Full Article',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Full description / body
                Text(
                  news.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.75,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // ── Related News section ──────────────────────────────────────────
        if (detail.related.isNotEmpty || isLoading) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Related News',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  itemBuilder: (_, __) => const _RelatedShimmerCard(),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: detail.related.length,
                  itemBuilder: (context, index) =>
                      _RelatedNewsCard(item: detail.related[index]),
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RELATED NEWS CARD (horizontal scroll)
// ─────────────────────────────────────────────
class _RelatedNewsCard extends ConsumerWidget {
  final RelatedNewsItem item;
  const _RelatedNewsCard({required this.item});

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return DateFormat('MMM d').format(date);
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailPage(newsId: item.id),
        ),
      ),
      child: Container(
        width: 200,
        height: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 100,
              width: double.infinity,
              child: item.image != null && item.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _SmallFallback(),
                    )
                  : _SmallFallback(),
            ),
            // Title + date
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_timeAgo(item.createdAt).isNotEmpty)
                      Text(
                        _timeAgo(item.createdAt),
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
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

class _SmallFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryGreen.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
          size: 24,
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkBgGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              color: AppColors.primaryGreen.withValues(alpha: 0.5),
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              'K\'OGALO NEWS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BLUR BACK BUTTON (for hero app bar)
// ─────────────────────────────────────────────
class _BlurBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER PLACEHOLDERS
// ─────────────────────────────────────────────
class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero
          Container(height: 280, color: c),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(c, 80, 10),
                const SizedBox(height: 16),
                _bar(c, double.infinity, 22),
                const SizedBox(height: 8),
                _bar(c, 260, 22),
                const SizedBox(height: 20),
                _bar(c, double.infinity, 14),
                const SizedBox(height: 6),
                _bar(c, double.infinity, 14),
                const SizedBox(height: 6),
                _bar(c, 200, 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color c, double width, double height) => Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _RelatedShimmerCard extends StatelessWidget {
  const _RelatedShimmerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 100, color: c),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 11, width: double.infinity, color: c),
                const SizedBox(height: 5),
                Container(height: 11, width: 140, color: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ERROR VIEW
// ─────────────────────────────────────────────
class _DetailErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _DetailErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Could not load article',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
