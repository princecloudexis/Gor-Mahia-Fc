import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Dummy Models for UI ---
class ShopProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final bool isNew;

  ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.isNew = false,
  });
}

class ShopCategory {
  final String id;
  final String name;
  final List<ShopProduct> products;

  ShopCategory({required this.id, required this.name, required this.products});
}

// --- Mock Data ---
final List<ShopCategory> mockShopCategories = [
  ShopCategory(
    id: 'c1',
    name: 'Jerseys',
    products: List.generate(
      5,
      (index) => ShopProduct(
        id: 'j$index',
        name: 'Official Home Jersey 24/25 - ${index + 1}',
        category: 'Jerseys',
        price: 2500.0,
        imageUrl: 'assets/images/jersey_mock.png', // Fallback to placeholder
        isNew: index == 0,
      ),
    ),
  ),
  ShopCategory(
    id: 'c2',
    name: 'Socks',
    products: List.generate(
      5,
      (index) => ShopProduct(
        id: 's$index',
        name: 'Pro Match Socks - ${index + 1}',
        category: 'Socks',
        price: 800.0,
        imageUrl: 'assets/images/socks_mock.png',
      ),
    ),
  ),
  ShopCategory(
    id: 'c3',
    name: 'Gloves',
    products: List.generate(
      5,
      (index) => ShopProduct(
        id: 'g$index',
        name: 'Goalkeeper Elite Gloves - ${index + 1}',
        category: 'Gloves',
        price: 3200.0,
        imageUrl: 'assets/images/gloves_mock.png',
        isNew: index == 1,
      ),
    ),
  ),
];

class Shop extends ConsumerStatefulWidget {
  const Shop({super.key});

  @override
  ConsumerState<Shop> createState() => _ShopState();
}

class _ShopState extends ConsumerState<Shop> {
  String selectedCategoryId = mockShopCategories.first.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner Section
          SliverToBoxAdapter(
            child: _buildBanner(context).animate().fadeIn(duration: 500.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // New Arrivals Section
          SliverToBoxAdapter(
            child: _buildNewArrivalsSection(
              context,
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Top Picks Section
          SliverToBoxAdapter(
            child: _buildTopPicksSection(
              context,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Category Tabs
          SliverToBoxAdapter(
            child: _buildCategoryTabs(
              context,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Selected Category Products Section
          SliverToBoxAdapter(
            child: _buildSelectedCategorySection(
              context,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ),

          // Bottom Padding for Nav Bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(16),
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
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'OFFICIAL MERCHANDISE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wear Green. Live Green.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
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
                  child: const Text(
                    'SHOP NOW',
                    style: TextStyle(
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

  Widget _buildNewArrivalsSection(BuildContext context) {
    final newArrivals = [
      ShopProduct(
        id: 'na1',
        name: 'Away Kit 26/27',
        category: 'New',
        price: 2600,
        imageUrl: '',
        isNew: true,
      ),
      ShopProduct(
        id: 'na2',
        name: 'Premium Jacket',
        category: 'New',
        price: 4500,
        imageUrl: '',
        isNew: true,
      ),
    ];

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
                onPressed: () {},
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
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: newArrivals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildNewArrivalCard(context, newArrivals[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalCard(BuildContext context, ShopProduct product) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.bgDark, AppColors.greenDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
          // Graphic Placeholder on the right
          Positioned(
            right: -20,
            bottom: -10,
            child: Icon(
              Icons.star_border_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.05),
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
                      product.name,
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
                      'KSh ${product.price.toStringAsFixed(0)}',
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
    );
  }

  Widget _buildTopPicksSection(BuildContext context) {
    final topPicks = [
      ShopProduct(
        id: 'tp1',
        name: 'Home Jersey',
        category: 'Top Picks',
        price: 2500,
        imageUrl: '',
      ),
      ShopProduct(
        id: 'tp2',
        name: 'Training Jersey',
        category: 'Top Picks',
        price: 2000,
        imageUrl: '',
      ),
      ShopProduct(
        id: 'tp3',
        name: 'Scarf',
        category: 'Top Picks',
        price: 800,
        imageUrl: '',
      ),
    ];

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
                onPressed: () {},
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
            itemCount: topPicks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildTopPickCard(context, topPicks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopPickCard(BuildContext context, ShopProduct product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            'KSh ${product.price.toStringAsFixed(0)}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
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
            itemCount: mockShopCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = mockShopCategories[index];
              final isSelected = category.id == selectedCategoryId;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategoryId = category.id;
                  });
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

  Widget _buildSelectedCategorySection(BuildContext context) {
    final selectedCategory = mockShopCategories.firstWhere(
      (cat) => cat.id == selectedCategoryId,
    );

    return Column(
      key: ValueKey(selectedCategoryId),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCategory.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full category list
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
            itemCount: selectedCategory.products.length > 5
                ? 5
                : selectedCategory.products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildProductCard(
                context,
                selectedCategory.products[index],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Image Area
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
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                  ),
                  if (product.isNew)
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
                ],
              ),
            ),
          ),
          // Product Details Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KSh ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
