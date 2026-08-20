class ShopBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final String image;
  final String? targetType;
  final int? targetId;

  ShopBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.buttonText,
    required this.image,
    this.targetType,
    this.targetId,
  });

  factory ShopBanner.fromJson(Map<String, dynamic> json) {
    String? parsedImage = json['image'];
    if (parsedImage != null && parsedImage.startsWith('http:https://')) {
      parsedImage = parsedImage.replaceFirst('http:https://', 'https://');
    }

    return ShopBanner(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      buttonText: json['button_text'],
      image: parsedImage ?? '',
      targetType: json['target_type'],
      targetId: json['target_id'],
    );
  }
}

class ShopCategory {
  final int id;
  final String name;
  final String? icon;

  ShopCategory({
    required this.id,
    required this.name,
    this.icon,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    String? parsedIcon = json['icon'];
    if (parsedIcon != null && parsedIcon.startsWith('http:https://')) {
      parsedIcon = parsedIcon.replaceFirst('http:https://', 'https://');
    }

    return ShopCategory(
      id: json['id'],
      name: json['name'] ?? '',
      icon: parsedIcon,
    );
  }
}

class ShopProductVariant {
  final int id;
  final String size;
  final int stock;
  final double? priceOverride;

  ShopProductVariant({
    required this.id,
    required this.size,
    required this.stock,
    this.priceOverride,
  });

  factory ShopProductVariant.fromJson(Map<String, dynamic> json) {
    return ShopProductVariant(
      id: json['id'],
      size: json['size'] ?? '',
      stock: json['stock'] ?? 0,
      priceOverride: json['price_override'] != null 
          ? double.tryParse(json['price_override'].toString()) 
          : null,
    );
  }
}

class ShopProduct {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final bool isNew;
  final bool isTopPick;
  final bool isFavourite;
  final List<ShopProductVariant> variants;

  ShopProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.isNew = false,
    this.isTopPick = false,
    this.isFavourite = false,
    this.variants = const [],
  });

  ShopProduct copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? image,
    bool? isNew,
    bool? isTopPick,
    bool? isFavourite,
    List<ShopProductVariant>? variants,
  }) {
    return ShopProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      isNew: isNew ?? this.isNew,
      isTopPick: isTopPick ?? this.isTopPick,
      isFavourite: isFavourite ?? this.isFavourite,
      variants: variants ?? this.variants,
    );
  }

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    var variantsList = <ShopProductVariant>[];
    if (json['variants'] != null) {
      json['variants'].forEach((v) {
        variantsList.add(ShopProductVariant.fromJson(v));
      });
    }

    String? parsedImage = json['image'];
    if (parsedImage != null && parsedImage.startsWith('http:https://')) {
      parsedImage = parsedImage.replaceFirst('http:https://', 'https://');
    }

    return ShopProduct(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      image: parsedImage,
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      isTopPick: json['is_top_pick'] == 1 || json['is_top_pick'] == true,
      isFavourite: json['is_favourite'] == 1 || json['is_favourite'] == true,
      variants: variantsList,
    );
  }
}

class ShopCartProduct {
  final int id;
  final String name;
  final double price;
  final String? image;

  ShopCartProduct({required this.id, required this.name, required this.price, this.image});

  factory ShopCartProduct.fromJson(Map<String, dynamic> json) {
    String? parsedImage = json['image'];
    if (parsedImage != null && parsedImage.startsWith('http:https://')) {
      parsedImage = parsedImage.replaceFirst('http:https://', 'https://');
    }

    return ShopCartProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      image: parsedImage,
    );
  }
}

class ShopCartVariant {
  final int id;
  final String size;

  ShopCartVariant({required this.id, required this.size});

  factory ShopCartVariant.fromJson(Map<String, dynamic> json) {
    return ShopCartVariant(
      id: json['id'] ?? 0,
      size: json['size'] ?? '',
    );
  }
}

class ShopCartItem {
  final int id;
  final int quantity;
  final ShopCartProduct product;
  final ShopCartVariant? variant;
  final double effectivePrice;
  final double subtotal;
  final double paymentCharge;
  final double paymentChargeRate;
  final double platformCharge;
  final double platformChargeRate;
  final double total;

  ShopCartItem({
    required this.id,
    required this.quantity,
    required this.product,
    this.variant,
    this.effectivePrice = 0.0,
    this.subtotal = 0.0,
    this.paymentCharge = 0.0,
    this.paymentChargeRate = 0.0,
    this.platformCharge = 0.0,
    this.platformChargeRate = 0.0,
    this.total = 0.0,
  });

  factory ShopCartItem.fromJson(Map<String, dynamic> json) {
    return ShopCartItem(
      id: json['cart_item_id'] ?? json['id'] ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      product: ShopCartProduct.fromJson(json['product'] ?? {}),
      variant: json['variant'] != null ? ShopCartVariant.fromJson(json['variant']) : null,
      effectivePrice: double.tryParse(json['effective_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      paymentCharge: double.tryParse((json['payment_charge'] ?? json['vat'])?.toString() ?? '0') ?? 0.0,
      paymentChargeRate: double.tryParse((json['payment_charge_rate'] ?? json['vat_rate'])?.toString() ?? '0') ?? 0.0,
      platformCharge: double.tryParse(json['platform_charge']?.toString() ?? '0') ?? 0.0,
      platformChargeRate: double.tryParse(json['platform_charge_rate']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ShopCart {
  final int id;
  final List<ShopCartItem> items;
  final int totalItems;
  final double subtotal;
  final double totalPaymentCharge;
  final double platformCharge;
  final double cartTotal;

  ShopCart({
    required this.id,
    required this.items,
    this.totalItems = 0,
    this.subtotal = 0.0,
    this.totalPaymentCharge = 0.0,
    this.platformCharge = 0.0,
    required this.cartTotal,
  });

  factory ShopCart.fromJson(Map<String, dynamic> json) {
    var itemsList = <ShopCartItem>[];
    double calculatedTotal = 0.0;
    if (json['items'] != null) {
      json['items'].forEach((v) {
        final item = ShopCartItem.fromJson(v);
        itemsList.add(item);
        calculatedTotal += item.total;
      });
    }

    return ShopCart(
      id: json['cart_id'] ?? json['id'] ?? 0,
      items: itemsList,
      totalItems: json['total_items'] ?? itemsList.length,
      subtotal: json['subtotal'] != null ? (double.tryParse(json['subtotal'].toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.subtotal),
      totalPaymentCharge: json['total_payment_charge'] != null ? (double.tryParse(json['total_payment_charge'].toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.paymentCharge),
      platformCharge: json['platform_charge'] != null ? (double.tryParse(json['platform_charge'].toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.platformCharge),
      cartTotal: (json['total_price'] ?? json['cart_total']) != null ? (double.tryParse((json['total_price'] ?? json['cart_total']).toString()) ?? 0.0) : calculatedTotal,
    );
  }
}

class ShopOrderResponse {
  final int orderId;
  final String orderNumber;
  final String totalAmount;

  ShopOrderResponse({required this.orderId, required this.orderNumber, required this.totalAmount});

  factory ShopOrderResponse.fromJson(Map<String, dynamic> json) {
    return ShopOrderResponse(
      orderId: json['order_id'] ?? json['id'] ?? 0,
      orderNumber: json['order_number'] ?? json['reference'] ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
    );
  }
}

class MpesaStkPushResponse {
  final String checkoutRequestId;
  final String orderId;
  final double amount;

  MpesaStkPushResponse({required this.checkoutRequestId, required this.orderId, required this.amount});

  factory MpesaStkPushResponse.fromJson(Map<String, dynamic> json) {
    return MpesaStkPushResponse(
      checkoutRequestId: json['checkout_request_id'] ?? json['CheckoutRequestID'] ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ShopPaystackResponse {
  final String reference;
  final String accessCode;
  final String authorizationUrl;
  final String publicKey;
  final int shopOrderId;
  final int amount;

  ShopPaystackResponse({
    required this.reference,
    required this.accessCode,
    required this.authorizationUrl,
    required this.publicKey,
    required this.shopOrderId,
    required this.amount,
  });

  factory ShopPaystackResponse.fromJson(Map<String, dynamic> json) {
    return ShopPaystackResponse(
      reference: json['reference'] ?? '',
      accessCode: json['access_code'] ?? '',
      authorizationUrl: json['authorization_url'] ?? '',
      publicKey: json['public_key'] ?? '',
      shopOrderId: json['shop_order_id'] ?? 0,
      amount: json['amount'] != null ? int.tryParse(json['amount'].toString()) ?? 0 : 0,
    );
  }
}

class MpesaStatusResponse {
  final String payment; // "pending", "success", "failed"
  final String message;
  final Map<String, dynamic>? data;

  MpesaStatusResponse({required this.payment, required this.message, this.data});

  factory MpesaStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    
    String parsedStatus = 'pending';
    // Check top-level keys first (most common API response patterns)
    if (json['payment'] != null) {
      parsedStatus = json['payment'].toString().toLowerCase();
    } else if (json['payment_status'] != null) {
      // Also check payment_status at the top level
      parsedStatus = json['payment_status'].toString().toLowerCase();
    } else if (json['status'] != null && json['status'] is String) {
      parsedStatus = json['status'].toString().toLowerCase();
    } else if (data is Map) {
      // Fall back to nested data object
      if (data['payment'] != null) {
        parsedStatus = data['payment'].toString().toLowerCase();
      } else if (data['payment_status'] != null) {
        parsedStatus = data['payment_status'].toString().toLowerCase();
      } else if (data['status'] != null) {
        parsedStatus = data['status'].toString().toLowerCase();
      }
    }
    
    // Normalize status aliases to canonical values
    if (parsedStatus == 'completed' || parsedStatus == 'paid') {
      parsedStatus = 'success';
    } else if (parsedStatus == 'cancelled' || parsedStatus == 'canceled') {
      parsedStatus = 'failed';
    }
    
    // Handle the case where the API returns {status: true, payment: 'pending'}
    // but the 'payment' field is not the actual Paystack status — 
    // the general endpoint returns status:true (bool) when payment is confirmed
    // and payment field is absent or set to something other than 'failed'
    if (parsedStatus == 'pending' && json['status'] == true && json['payment'] == null) {
      parsedStatus = 'success';
    }

    return MpesaStatusResponse(
      payment: parsedStatus,
      message: json['message'] ?? '',
      data: data is Map<String, dynamic> ? data : null,
    );
  }
}

class ShopOrderItem {
  final int id;
  final String productName;
  final double price;
  final int quantity;
  final String? image;
  final double subtotal;
  final double paymentCharge;
  final double paymentChargeRate;
  final double platformCharge;
  final double platformChargeRate;

  double get total => subtotal + paymentCharge + platformCharge;

  ShopOrderItem({
    required this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    this.image,
    this.subtotal = 0.0,
    this.paymentCharge = 0.0,
    this.paymentChargeRate = 0.0,
    this.platformCharge = 0.0,
    this.platformChargeRate = 0.0,
  });

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    String? parsedImage = json['image'] ?? json['product_image'];
    if (parsedImage != null && parsedImage.startsWith('http:https://')) {
      parsedImage = parsedImage.replaceFirst('http:https://', 'https://');
    }

    return ShopOrderItem(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? '',
      price: double.tryParse((json['price'] ?? json['unit_price'])?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      image: parsedImage,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      paymentCharge: double.tryParse((json['payment_charge'] ?? json['vat'])?.toString() ?? '0') ?? 0.0,
      paymentChargeRate: double.tryParse((json['payment_charge_rate'] ?? json['vat_rate'])?.toString() ?? '0') ?? 0.0,
      platformCharge: double.tryParse(json['platform_charge']?.toString() ?? '0') ?? 0.0,
      platformChargeRate: double.tryParse(json['platform_charge_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ShopOrder {
  final int id;
  final String orderNumber;
  final double subtotal;
  final double paymentCharge;
  final double platformCharge;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? paymentReference;
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final String? notes;
  final DateTime? createdAt;
  final List<ShopOrderItem> items;

  ShopOrder({
    required this.id,
    required this.orderNumber,
    this.subtotal = 0.0,
    this.paymentCharge = 0.0,
    this.platformCharge = 0.0,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentReference,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryAddress,
    this.notes,
    this.createdAt,
    required this.items,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    var itemsList = <ShopOrderItem>[];
    final itemsSource = json['items'] ?? json['items_preview'];
    if (itemsSource != null) {
      itemsSource.forEach((v) {
        itemsList.add(ShopOrderItem.fromJson(v));
      });
    }

    DateTime? parsedDate;
    final dateString = json['created_at'] ?? json['placed_at'];
    if (dateString != null) {
      try {
        parsedDate = DateTime.parse(dateString.toString().replaceAll(' ', 'T'));
      } catch (e) {
        // ignore date parse errors
      }
    }

    final pricing = json['pricing'] as Map<String, dynamic>?;

    return ShopOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? json['reference'] ?? '',
      subtotal: (pricing?['subtotal'] ?? json['subtotal']) != null ? (double.tryParse((pricing?['subtotal'] ?? json['subtotal']).toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.subtotal),
      paymentCharge: (pricing?['payment_charge'] ?? json['payment_charge']) != null ? (double.tryParse((pricing?['payment_charge'] ?? json['payment_charge']).toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.paymentCharge),
      platformCharge: (pricing?['platform_charge'] ?? json['platform_charge']) != null ? (double.tryParse((pricing?['platform_charge'] ?? json['platform_charge']).toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.platformCharge),
      totalAmount: (pricing?['total'] ?? json['total'] ?? json['total_amount']) != null ? (double.tryParse((pricing?['total'] ?? json['total'] ?? json['total_amount']).toString()) ?? 0.0) : itemsList.fold(0.0, (sum, item) => sum + item.total),
      status: json['status'] ?? json['order_status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      paymentReference: json['payment_reference'],
      deliveryName: json['delivery_name'],
      deliveryPhone: json['delivery_phone'],
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      createdAt: parsedDate,
      items: itemsList,
    );
  }
}
