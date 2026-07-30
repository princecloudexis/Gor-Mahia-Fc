import 'package:dio/dio.dart';
import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/models/shop_models.dart';
import 'package:flutter/foundation.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  Future<List<ShopBanner>> getBanners() async {
    const endpoint = '/user/shop/banners';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final list = (response.data['data'] as List)
            .map((e) => ShopBanner.fromJson(e))
            .toList();
        debugPrint('🛒 [Shop] Banners loaded: ${list.length} items');
        return list;
      }
      throw Exception(response.data['message'] ?? 'Failed to load banners');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<List<ShopCategory>> getCategories() async {
    const endpoint = '/user/shop/categories';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final list = (response.data['data'] as List)
            .map((e) => ShopCategory.fromJson(e))
            .toList();
        debugPrint('🛒 [Shop] Categories loaded: ${list.length} items');
        return list;
      }
      throw Exception(response.data['message'] ?? 'Failed to load categories');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<List<ShopProduct>> getNewArrivals() async {
    const endpoint = '/user/shop/new-arrivals';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final list = (response.data['data'] as List)
            .map((e) => ShopProduct.fromJson(e))
            .toList();
        debugPrint('🛒 [Shop] New Arrivals loaded: ${list.length} items');
        return list;
      }
      throw Exception(response.data['message'] ?? 'Failed to load new arrivals');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<List<ShopProduct>> getTopPicks() async {
    const endpoint = '/user/shop/top-picks';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final list = (response.data['data'] as List)
            .map((e) => ShopProduct.fromJson(e))
            .toList();
        debugPrint('🛒 [Shop] Top Picks loaded: ${list.length} items');
        return list;
      }
      throw Exception(response.data['message'] ?? 'Failed to load top picks');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<List<ShopProduct>> getCategoryProducts(int categoryId) async {
    final endpoint = '/user/shop/category/$categoryId/products';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final list = (response.data['data'] as List)
            .map((e) => ShopProduct.fromJson(e))
            .toList();
        debugPrint('🛒 [Shop] Category $categoryId Products loaded: ${list.length} items');
        return list;
      }
      throw Exception(response.data['message'] ?? 'Failed to load products');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<ShopProduct> getProductDetails(int productId) async {
    final endpoint = '/user/shop/product/$productId';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == true) {
        final product = ShopProduct.fromJson(response.data['data']);
        debugPrint('🛒 [Shop] Product loaded: ${product.name}');
        return product;
      }
      throw Exception(response.data['message'] ?? 'Failed to load product details');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<bool> toggleFavorite(int productId) async {
    const endpoint = '/user/shop/favourite/toggle';
    debugPrint('🛒 [Shop] POST $endpoint for productId: $productId');
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {'product_id': productId},
      );
      debugPrint('🛒 [Shop] ✅ POST $endpoint → ${response.statusCode}');
      debugPrint('🛒 [Shop] Response: ${response.data}');
      if (response.data['status'] == 200) {
        return response.data['is_favourite'] == true;
      }
      throw Exception(response.data['message'] ?? 'Failed to toggle favorite');
    } on DioException catch (e) {
      debugPrint('🛒 [Shop] ❌ POST $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [Shop] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to connect to the server.';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Unknown error on $endpoint: $e');
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<List<ShopProduct>> getFavorites() async {
    const endpoint = '/user/shop/favourite/list';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      if (response.data['status'] == 200 || response.data['status'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => ShopProduct.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Error getting favorites: $e');
      throw Exception('Failed to load shop favorites');
    }
  }

  Future<List<ShopOrder>> getOrders() async {
    const endpoint = '/user/shop/orders';
    debugPrint('🛒 [Shop] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [Shop] ✅ GET $endpoint → ${response.statusCode}');
      if (response.data['status'] == 200 || response.data['status'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => ShopOrder.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🛒 [Shop] ❌ Error getting orders: $e');
      throw Exception('Failed to load order history');
    }
  }

  Future<ShopCart> getCart() async {
    const endpoint = '/user/shop/cart';
    debugPrint('🛒 [ShopCart] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [ShopCart] ✅ GET $endpoint → ${response.statusCode}');
      if (response.data['status'] == true) {
        return ShopCart.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to load cart');
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCart] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCart] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to load cart.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> addToCart({required int productId, int? variantId, required int quantity}) async {
    const endpoint = '/user/shop/cart/add';
    debugPrint('🛒 [ShopCart] POST $endpoint');
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          'product_id': productId,
          if (variantId != null) 'variant_id': variantId,
          'quantity': quantity,
        }
      );
      debugPrint('🛒 [ShopCart] ✅ POST $endpoint → ${response.statusCode}');
      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to add to cart');
      }
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCart] ❌ POST $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCart] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to add to cart.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> updateCartItem(int itemId, int quantity) async {
    final endpoint = '/user/shop/cart/item/$itemId';
    debugPrint('🛒 [ShopCart] PUT $endpoint');
    try {
      final response = await _apiClient.dio.put(
        endpoint,
        data: {'quantity': quantity}
      );
      debugPrint('🛒 [ShopCart] ✅ PUT $endpoint → ${response.statusCode}');
      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update item');
      }
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCart] ❌ PUT $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCart] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to update item.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> removeCartItem(int itemId) async {
    final endpoint = '/user/shop/cart/item/$itemId';
    debugPrint('🛒 [ShopCart] DELETE $endpoint');
    try {
      final response = await _apiClient.dio.delete(endpoint);
      debugPrint('🛒 [ShopCart] ✅ DELETE $endpoint → ${response.statusCode}');
      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove item');
      }
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCart] ❌ DELETE $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCart] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to remove item.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<void> clearCart() async {
    const endpoint = '/user/shop/cart/clear';
    debugPrint('🛒 [ShopCart] DELETE $endpoint');
    try {
      final response = await _apiClient.dio.delete(endpoint);
      debugPrint('🛒 [ShopCart] ✅ DELETE $endpoint → ${response.statusCode}');
      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to clear cart');
      }
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCart] ❌ DELETE $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCart] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to clear cart.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }
  // ==========================================
  // PHASE 3: CHECKOUT & PAYMENT
  // ==========================================

  Future<ShopOrderResponse> placeOrder({
    required String deliveryName,
    required String deliveryPhone,
    required String deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    const endpoint = '/user/shop/order/place';
    debugPrint('🛒 [ShopCheckout] POST $endpoint');
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          'delivery_name': deliveryName,
          'delivery_phone': deliveryPhone,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      debugPrint('🛒 [ShopCheckout] ✅ POST $endpoint → ${response.statusCode}');
      if (response.data['status'] == true) {
        return ShopOrderResponse.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to place order');
    } on DioException catch (e) {
      debugPrint('🛒 [ShopCheckout] ❌ POST $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopCheckout] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to place order.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<MpesaStkPushResponse> initiateMpesaPayment({
    required int orderId,
    required String phone,
  }) async {
    const endpoint = '/user/shop/mpesa/stk-push';
    debugPrint('🛒 [ShopMpesa] POST $endpoint → orderId=$orderId, phone=$phone');
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          'shop_order_id': orderId,
          'phone': phone,
        },
      );
      debugPrint('🛒 [ShopMpesa] ✅ POST $endpoint RAW RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        final payload = response.data['data'] ?? response.data;
        return MpesaStkPushResponse.fromJson(payload);
      }
      throw Exception(response.data['message'] ?? 'Failed to initiate payment');
    } on DioException catch (e) {
      debugPrint('🛒 [ShopMpesa] ❌ POST $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopMpesa] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to initiate payment.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<ShopPaystackResponse> initializePaystackPayment({
    required int orderId,
    required String email,
  }) async {
    const endpoint = '/user/shop/paystack/initialize';
    debugPrint('🛒 [ShopPaystack] POST $endpoint → orderId=$orderId, email=$email');
    try {
      final response = await _apiClient.dio.post(
        endpoint,
        data: {
          'shop_order_id': orderId,
          'email': email,
        },
      );
      debugPrint('🛒 [ShopPaystack] ✅ POST $endpoint RAW RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        final payload = response.data['data'] ?? response.data;
        return ShopPaystackResponse.fromJson(payload);
      }
      throw Exception(response.data['message'] ?? 'Failed to initiate payment');
    } on DioException catch (e) {
      debugPrint('🛒 [ShopPaystack] ❌ POST $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopPaystack] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to initiate payment.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<MpesaStatusResponse> checkMpesaStatus(String checkoutRequestId) async {
    final endpoint = '/user/shop/mpesa/status/$checkoutRequestId';
    debugPrint('🛒 [ShopMpesa] GET $endpoint');
    try {
      final response = await _apiClient.dio.get(endpoint);
      debugPrint('🛒 [ShopMpesa] RAW STATUS RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        return MpesaStatusResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to check status');
    } on DioException catch (e) {
      debugPrint('🛒 [ShopMpesa] ❌ GET $endpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopMpesa] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to check status.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  Future<MpesaStatusResponse> checkPaystackStatus(String reference) async {
    final shopEndpoint = '/user/shop/paystack/status/$reference';
    final generalEndpoint = '/user/payment/paystack/status/$reference';
    debugPrint('🛒 [ShopPaystack] GET $shopEndpoint');
    try {
      // First try the shop-specific status endpoint
      final response = await _apiClient.dio.get(shopEndpoint);
      debugPrint('🛒 [ShopPaystack] RAW STATUS RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        final shopStatus = MpesaStatusResponse.fromJson(response.data);
        if (shopStatus.payment == 'success') {
          return shopStatus;
        }
        // Shop says pending — try the general endpoint to force Paystack verification
        debugPrint('🛒 [ShopPaystack] Shop status pending, trying general verify endpoint...');
        try {
          final generalResponse = await _apiClient.dio.get(generalEndpoint);
          debugPrint('🛒 [ShopPaystack] General verify response: ${generalResponse.data}');
          if (generalResponse.statusCode == 200) {
            final generalStatus = MpesaStatusResponse.fromJson(generalResponse.data);
            if (generalStatus.payment == 'success') return generalStatus;
          }
        } catch (_) {
          // ignore error from general endpoint, return shop status
        }
        return shopStatus;
      }
      throw Exception(response.data['message'] ?? 'Failed to check status');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return MpesaStatusResponse(payment: 'pending', message: 'Waiting for confirmation...');
      }
      debugPrint('🛒 [ShopPaystack] ❌ GET $shopEndpoint → ${e.response?.statusCode}');
      debugPrint('🛒 [ShopPaystack] Error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ?? 'Failed to check status.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }
}
