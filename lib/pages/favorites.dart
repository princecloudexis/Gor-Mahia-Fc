import 'package:cached_network_image/cached_network_image.dart';
import 'package:gormahiafc/pages/details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../api/api_client.dart';
import '../models/event_model.dart';
import '../providers/event_providers.dart';
import 'package:gormahiafc/theme/apptheme.dart';
import 'package:gormahiafc/theme/app_colors.dart';
import '../models/shop_models.dart';
import '../providers/shop_providers.dart';
import '../pages/shop_product_details.dart';

class Favorites extends ConsumerWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Favorites',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
            tabs: const [
              Tab(text: 'Matches'),
              Tab(text: 'Shop'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EventsFavoritesTab(),
            _ShopFavoritesTab(),
          ],
        ),
      ),
    );
  }
}

class _EventsFavoritesTab extends ConsumerWidget {
  const _EventsFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: favoritesAsync.when(
            data: (favoriteEvents) {
              if (favoriteEvents.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    title: 'No Favorite Matches Yet',
                    subtitle: 'Tap the heart on any match to save it here for later.',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final event = favoriteEvents[index];
                  return _FavoriteCard(event: event)
                      .animate(delay: (100 * (index % 10)).ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, curve: Curves.easeOutCubic);
                }, childCount: favoriteEvents.length),
              );
            },
            loading: () => const _FavoritesListShimmer(),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('Error: ${error.toString()}')),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopFavoritesTab extends ConsumerWidget {
  const _ShopFavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(shopFavoritesProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 16),
          sliver: favoritesAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    title: 'No Favorite Products Yet',
                    subtitle: 'Tap the heart on any product to save it here for later.',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return _ShopFavoriteCard(product: product)
                      .animate(delay: (100 * (index % 10)).ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, curve: Curves.easeOutCubic);
                }, childCount: products.length),
              );
            },
            loading: () => const _FavoritesListShimmer(),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('Error: ${error.toString()}')),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 52,
              color: theme.textTheme.bodySmall?.color ?? theme.dividerColor,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _FavoriteCard extends ConsumerWidget {
  final EventModel event;
  const _FavoriteCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final imageUrl = event.getFullImageUrl(storageBaseUrl);
    final theme = Theme.of(context);
    final formattedDate = event.eventStartDate != null
        ? DateFormat('E, MMM d, yyyy').format(event.eventStartDate!)
        : 'Date To Be Determined';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Dismissible(
        key: ValueKey(event.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          ref.read(favoritesProvider.notifier).toggleFavorite(event);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${event.eventName} removed from favorites.'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(event);
                },
              ),
            ),
          );
        },
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete_outline, color: AppTheme.accentRed),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (event.slug != null && event.slug!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetails(slug: event.slug!),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: theme.splashColor),
                    errorWidget: (context, url, error) => Container(
                      color: theme.splashColor,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: formattedDate,
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: event.displayLocationString,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FavoritesListShimmer extends StatelessWidget {
  const _FavoritesListShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _FavoriteCardShimmer(),
        childCount: 5,
      ),
    );
  }
}

class _FavoriteCardShimmer extends StatelessWidget {
  const _FavoriteCardShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer(
      color: theme.shadowColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.splashColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.splashColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 18,
                      width: 150,
                      decoration: BoxDecoration(
                        color: theme.splashColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: theme.splashColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: theme.splashColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
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

class _ShopFavoriteCard extends ConsumerWidget {
  final ShopProduct product;
  const _ShopFavoriteCard({required this.product});

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'https://footballclub.staging-workhub.com/' +
        path.replaceFirst(RegExp(r'^/+'), '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = _getImageUrl(product.image);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Dismissible(
        key: ValueKey('shop_${product.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          try {
            await ref.read(shopRepositoryProvider).toggleFavorite(product.id);
            ref.invalidate(shopFavoritesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} removed from favorites.'),
                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.black87,
                ),
              );
            }
          } catch (e) {
            ref.invalidate(shopFavoritesProvider);
          }
        },
        background: Container(
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete_outline, color: AppTheme.accentRed),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: product),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                Container(color: theme.splashColor),
                            errorWidget: (context, url, error) => Container(
                              color: theme.splashColor,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.textLight,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KSh ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
