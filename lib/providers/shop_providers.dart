import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/models/shop_models.dart';
import 'package:eventsbooking/repositories/shop_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ShopRepository(apiClient);
});

final shopBannersProvider = FutureProvider<List<ShopBanner>>((ref) {
  return ref.watch(shopRepositoryProvider).getBanners();
});

final shopCategoriesProvider = FutureProvider<List<ShopCategory>>((ref) {
  return ref.watch(shopRepositoryProvider).getCategories();
});

final shopNewArrivalsProvider = FutureProvider<List<ShopProduct>>((ref) {
  return ref.watch(shopRepositoryProvider).getNewArrivals();
});

final shopTopPicksProvider = FutureProvider<List<ShopProduct>>((ref) {
  return ref.watch(shopRepositoryProvider).getTopPicks();
});

final shopCategoryProductsProvider = FutureProvider.family<List<ShopProduct>, int>((ref, categoryId) {
  return ref.watch(shopRepositoryProvider).getCategoryProducts(categoryId);
});

final shopProductDetailsProvider = FutureProvider.family<ShopProduct, int>((ref, productId) {
  return ref.watch(shopRepositoryProvider).getProductDetails(productId);
});

// To keep track of the currently selected category tab
final selectedShopCategoryProvider = StateProvider<int?>((ref) => null);

// Cart Provider
final shopCartProvider = FutureProvider.autoDispose<ShopCart>((ref) {
  return ref.watch(shopRepositoryProvider).getCart();
});

// Favorites Provider
final shopFavoritesProvider = FutureProvider.autoDispose<List<ShopProduct>>((ref) {
  return ref.watch(shopRepositoryProvider).getFavorites();
});

// Orders Provider
final shopOrdersProvider = FutureProvider.autoDispose<List<ShopOrder>>((ref) {
  return ref.watch(shopRepositoryProvider).getOrders();
});
