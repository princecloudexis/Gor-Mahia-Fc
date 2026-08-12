import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gormahiafc/theme/app_colors.dart';
import 'package:gormahiafc/providers/shop_providers.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/pages/shop_payment_processing.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopCheckoutPage extends ConsumerStatefulWidget {
  final double cartTotal;

  const ShopCheckoutPage({super.key, required this.cartTotal});

  @override
  ConsumerState<ShopCheckoutPage> createState() => _ShopCheckoutPageState();
}

class _ShopCheckoutPageState extends ConsumerState<ShopCheckoutPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  int? _createdOrderId;
  String? _createdOrderNumber;

  bool _paymentLaunched = false;
  String? _currentReference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = ref.read(userProvider);
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _paymentLaunched) {
      _paymentLaunched = false;
      if (_currentReference != null && _createdOrderNumber != null) {
        _proceedToProcessingPage(_currentReference!, _createdOrderNumber!);
      }
    }
  }

  void _proceedToProcessingPage(String reference, String orderNumber) {
    // Clear cart since order was placed successfully
    final repository = ref.read(shopRepositoryProvider);
    repository.clearCart().catchError((_) {});
    ref.invalidate(shopCartProvider);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShopPaymentProcessingPage(
            reference: reference,
            orderNumber: orderNumber,
          ),
        ),
      );
    }
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(shopRepositoryProvider);

      // 1. Place the order only if we haven't already
      if (_createdOrderId == null) {
        final orderResponse = await repository.placeOrder(
          deliveryName: _nameController.text.trim(),
          deliveryPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          paymentMethod: 'paystack',
          notes: _notesController.text.trim(),
        );
        _createdOrderId = orderResponse.orderId;
        _createdOrderNumber = orderResponse.orderNumber;

        // Cart is cleared on backend after order placement
        ref.invalidate(shopCartProvider);
      }

      // 2. Initiate Paystack checkout
      final paystackResponse = await repository.initializePaystackPayment(
        orderId: _createdOrderId!,
        email: _emailController.text.trim(),
      );

      // 3. Launch Paystack checkout URL
      final Uri url = Uri.parse(paystackResponse.authorizationUrl);
      if (await canLaunchUrl(url)) {
        setState(() {
          _paymentLaunched = true;
          _currentReference = paystackResponse.reference;
        });
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch payment page.');
      }

      // We do NOT navigate here. We wait for the app to resume from the browser!
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgSurfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount to Pay:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'KSh ${widget.cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgSurfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!val.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Delivery Phone Number',
                            prefixIcon: const Icon(Icons.phone_iphone),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Address Field
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please enter your delivery address'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Notes Field
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Notes (Optional)',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            contentPadding: EdgeInsets.only(
                              top: 20,
                              bottom: 20,
                              left: 0,
                              right: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _processCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Place Order & Pay Online',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}
