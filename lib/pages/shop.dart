import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventsbooking/pages/shop_product_details.dart';
import 'package:eventsbooking/models/shop_models.dart';
import 'package:eventsbooking/providers/shop_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventsbooking/pages/shop_cart.dart';
import 'package:eventsbooking/pages/shop_orders.dart';
import 'profile.dart';
import 'search.dart';
import '../widgets/top_action_btn.dart';
import 'package:eventsbooking/pages/shop_all_products.dart';

class Shop extends ConsumerStatefulWidget {
  const Shop({super.key});

  @override
  ConsumerState<Shop> createState() => _ShopState();
}

class _ShopState extends ConsumerState<Shop> {
  // Helper to construct full URLs
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'https://footballclub.staging-workhub.com/' +
        path.replaceFirst(RegExp(r'^/+'), '');
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(shopBannersProvider);
    final categoriesAsync = ref.watch(shopCategoriesProvider);
    final newArrivalsAsync = ref.watch(shopNewArrivalsProvider);
    final topPicksAsync = ref.watch(shopTopPicksProvider);
    final selectedCategoryId = ref.watch(selectedShopCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Shop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
        actions: [
          TopActionBtn(
            icon: Icons.receipt_long_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopOrdersPage()),
              );
            },
          ),
          TopActionBtn(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shopping_cart_outlined, 
                  size: 18, 
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                ref
                    .watch(shopCartProvider)
                    .when(
                      data: (cart) {
                        final count = cart.items.fold<int>(
                          0,
                          (sum, item) => sum + item.quantity,
                        );
                        if (count == 0) return const SizedBox.shrink();
                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShopCartPage()),
              );
            },
          ),
          TopActionBtn(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
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
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/footballbg.png'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.15 : 0.10,
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
          // Banner Section
          SliverToBoxAdapter(
            child: bannersAsync.when(
              data: (banners) {
                if (banners.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'No banners available',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                  );
                }
                return _buildBanner(
                  context,
                  banners.first,
                ).animate().fadeIn(duration: 500.ms);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) {
                print('Error: $err');
                return Center(child: Text('Error: $err'));
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // New Arrivals Section
          SliverToBoxAdapter(
            child: newArrivalsAsync.when(
              data: (newArrivals) {
                if (newArrivals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(child: Text('No new arrivals yet.')),
                  );
                }
                return _buildNewArrivalsSection(
                  context,
                  newArrivals,
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                print('Error: $err');
                return Center(child: Text('Error: $err'));
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Top Picks Section
          SliverToBoxAdapter(
            child: topPicksAsync.when(
              data: (topPicks) {
                if (topPicks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(child: Text('No top picks yet.')),
                  );
                }
                return _buildTopPicksSection(
                  context,
                  topPicks,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                print('Error: $err');
                return Center(child: Text('Error: $err'));
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Category Tabs
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(child: Text('No categories available.')),
                  );
                }

                // Auto-select first category if none selected
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ref.read(selectedShopCategoryProvider) == null &&
                      categories.isNotEmpty) {
                    ref.read(selectedShopCategoryProvider.notifier).state =
                        categories.first.id;
                  }
                });

                return _buildCategoryTabs(
                  context,
                  categories,
                  selectedCategoryId,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                print('Error: $err');
                return Center(child: Text('Error: $err'));
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Selected Category Products Section
          SliverToBoxAdapter(
            child: selectedCategoryId != null
                ? ref
                      .watch(shopCategoryProductsProvider(selectedCategoryId))
                      .when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('No products in this category'),
                              ),
                            );
                          }

                          final categoryName =
                              categoriesAsync.value
                                  ?.firstWhere(
                                    (c) => c.id == selectedCategoryId,
                                    orElse: () => ShopCategory(id: 0, name: ''),
                                  )
                                  .name ??
                              '';

                          return _buildSelectedCategorySection(
                            context,
                            categoryName,
                            products,
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Error loading products: $err')),
                      )
                : const SizedBox.shrink(),
          ),

          // Bottom Padding for Nav Bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ShopBanner banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: const AssetImage('assets/images/banner.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    banner.subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (banner.buttonText != null && banner.buttonText!.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      banner.buttonText!,
                      style: const TextStyle(
                        color: Colors.black87,
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
    );
  }

  Widget _buildNewArrivalsSection(
    BuildContext context,
    List<ShopProduct> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Arrivals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopAllProductsPage(
                        title: 'New Arrivals',
                        products: products,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Explore',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildNewArrivalCard(context, products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalCard(BuildContext context, ShopProduct product) {
    return _NewArrivalCard(product: product, getImageUrl: _getImageUrl);
  }

  Widget _buildTopPicksSection(
    BuildContext context,
    List<ShopProduct> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Picks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopAllProductsPage(
                        title: 'Top Picks',
                        products: products,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildTopPickCard(context, products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopPickCard(BuildContext context, ShopProduct product) {
    return _TopPickCard(product: product, getImageUrl: _getImageUrl);
  }

  Widget _buildCategoryTabs(
    BuildContext context,
    List<ShopCategory> categories,
    int? selectedCategoryId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedCategoryId;
              return GestureDetector(
                onTap: () {
                  ref.read(selectedShopCategoryProvider.notifier).state =
                      category.id;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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

  Widget _buildSelectedCategorySection(
    BuildContext context,
    String categoryName,
    List<ShopProduct> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopAllProductsPage(
                        title: categoryName,
                        products: products,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length > 5 ? 5 : products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildProductCard(context, products[index]);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product) {
    return _ProductCard(product: product, getImageUrl: _getImageUrl);
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final ShopProduct product;
  final String Function(String?) getImageUrl;

  const _ProductCard({required this.product, required this.getImageUrl});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  late bool _isFavorite;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavourite;
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;
    setState(() {
      _isFavorite = !_isFavorite;
      _isToggling = true;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final isFavNow = await repo.toggleFavorite(widget.product.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavNow;
          _isToggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: widget.product),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child:
                          widget.product.image != null &&
                              widget.product.image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: widget.getImageUrl(
                                  widget.product.image,
                                ),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade400,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400,
                            ),
                    ),
                    if (widget.product.isNew)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: _isFavorite
                                ? Colors.red
                                : (isDark ? Colors.white : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'KSh ${widget.product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.greenLight
                                : AppColors.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          size: 16,
                          color: isDark
                              ? AppColors.greenLight
                              : AppColors.primaryGreen,
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
    );
  }
}

class _NewArrivalCard extends ConsumerStatefulWidget {
  final ShopProduct product;
  final String Function(String?) getImageUrl;

  const _NewArrivalCard({required this.product, required this.getImageUrl});

  @override
  ConsumerState<_NewArrivalCard> createState() => _NewArrivalCardState();
}

class _NewArrivalCardState extends ConsumerState<_NewArrivalCard> {
  late bool _isFavorite;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavourite;
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;
    setState(() {
      _isFavorite = !_isFavorite;
      _isToggling = true;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final isFavNow = await repo.toggleFavorite(widget.product.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavNow;
          _isToggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: widget.product),
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColors.bgDark, AppColors.greenDark.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image:
              widget.product.image != null && widget.product.image!.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    widget.getImageUrl(widget.product.image),
                    errorListener: (err) =>
                        debugPrint('Product image error: $err'),
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (widget.product.image == null || widget.product.image!.isEmpty)
              Positioned(
                right: -20,
                bottom: -10,
                child: Icon(
                  Icons.star_border_rounded,
                  size: 140,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _toggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: _isFavorite ? Colors.red : Colors.white70,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'JUST DROPPED',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'KSh ${widget.product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.black87,
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
    );
  }
}

class _TopPickCard extends ConsumerStatefulWidget {
  final ShopProduct product;
  final String Function(String?) getImageUrl;

  const _TopPickCard({required this.product, required this.getImageUrl});

  @override
  ConsumerState<_TopPickCard> createState() => _TopPickCardState();
}

class _TopPickCardState extends ConsumerState<_TopPickCard> {
  late bool _isFavorite;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavourite;
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;
    setState(() {
      _isFavorite = !_isFavorite;
      _isToggling = true;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final isFavNow = await repo.toggleFavorite(widget.product.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavNow;
          _isToggling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: widget.product),
          ),
        );
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurfaceDark : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child:
                        widget.product.image != null &&
                            widget.product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.getImageUrl(
                                widget.product.image,
                              ),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey.shade400,
                            ),
                          ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: _isFavorite
                              ? Colors.red
                              : (isDark ? Colors.white : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              'KSh ${widget.product.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
