import 'dart:ui';
import 'package:eventsbooking/models/payment_result_model.dart';
import 'package:eventsbooking/pages/payment_result.dart';
import 'package:eventsbooking/providers/event_providers.dart';
import 'package:eventsbooking/providers/seat_provider.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:eventsbooking/models/checkout_model.dart';
import 'package:eventsbooking/providers/checkout_provider.dart';
import 'package:eventsbooking/providers/user_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class Checkout extends ConsumerStatefulWidget {
  final String orderId;
  const Checkout({super.key, required this.orderId});
  @override
  ConsumerState<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<Checkout> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _promoController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final ScrollController _scrollController;

  final GlobalKey<FormFieldState> _addressKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _phoneKey = GlobalKey<FormFieldState>();
  final Map<String, GlobalKey<FormFieldState>> _attendeeFieldKeys = {};

  bool _paymentLaunched = false;
  bool _isCheckingStatus = false;
  String? _currentReference;

  @override
  void initState() {
    super.initState();
    _promoController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promoController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCancelAndCleanup(BuildContext context, {bool shouldPop = true}) {
    ref.read(selectedSeatsProvider.notifier).state = {};
    ref.read(selectedSectionBlocksProvider.notifier).state = {};
    if (shouldPop && mounted) Navigator.of(context).pop();
  }

  void _initializeAttendeeKeys(CheckoutDetailsModel details) {
    for (var ticket in details.tickets) {
      for (var i = 0; i < ticket.quantity; i++) {
        final baseKey = '${ticket.id}-$i';
        _attendeeFieldKeys.putIfAbsent(
          '${baseKey}_fn',
          () => GlobalKey<FormFieldState>(),
        );
        _attendeeFieldKeys.putIfAbsent(
          '${baseKey}_ln',
          () => GlobalKey<FormFieldState>(),
        );
        _attendeeFieldKeys.putIfAbsent(
          '${baseKey}_em',
          () => GlobalKey<FormFieldState>(),
        );
        _attendeeFieldKeys.putIfAbsent(
          '${baseKey}_ad',
          () => GlobalKey<FormFieldState>(),
        );
      }
    }
  }

  void _scrollToFirstError() {
    final allKeys = [..._attendeeFieldKeys.values, _addressKey, _phoneKey];
    for (final key in allKeys) {
      if (key.currentState != null && key.currentState!.hasError) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
        return;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _paymentLaunched) {
      _paymentLaunched = false;
      if (_currentReference != null) {
        _verifyPaymentStatus();
      }
    }
  }

  Future<void> _verifyPaymentStatus() async {
    if (_isCheckingStatus || _currentReference == null) return;
    
    setState(() {
      _isCheckingStatus = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ProcessingPaymentDialog(), // Use the same loader
    );

    // Call verifyAndCompletePayment
    final PaymentResult result = await ref
        .read(checkoutControllerProvider(widget.orderId).notifier)
        .verifyAndCompletePayment(
          reference: _currentReference!,
          streetAddress: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading dialog
    
    setState(() {
      _isCheckingStatus = false;
      _currentReference = null;
    });

    if (result.isSuccess) {
      _handleCancelAndCleanup(context, shouldPop: false);
      ref.invalidate(ticketsProvider('upcoming'));
      ref.invalidate(ticketsProvider('past'));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PaymentSuccess()),
        (route) => false,
      );
    } else {
      // Payment failed or still pending, backend verification didn't pass
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Payment not completed or still processing.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _processPayment() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _ProcessingPaymentDialog(),
      );

      final user = ref.read(userProvider);
      final PaymentResult result = await ref
          .read(checkoutControllerProvider(widget.orderId).notifier)
          .initiatePaystackPayment(
            streetAddress: _addressController.text.trim(),
            email: user?.email ?? '',
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result.isSuccess && result.authorizationUrl != null) {
        final Uri url = Uri.parse(result.authorizationUrl!);
        if (await canLaunchUrl(url)) {
           setState(() {
             _paymentLaunched = true;
             _currentReference = result.reference;
           });
           await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not launch payment URL'), backgroundColor: AppColors.error),
           );
        }
      } else if (result.errorMessage != null) {
        _handleCancelAndCleanup(context, shouldPop: false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PaymentFailed(
              eventSlug: result.eventSlug!,
              errorMessage: result.errorMessage!,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      _scrollToFirstError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentRed,
          content: Text('Please fill all required fields before proceeding.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutDetailsAsync = ref.watch(
      checkoutControllerProvider(
        widget.orderId,
      ).select((s) => s.checkoutDetails),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Checkout?'),
            content: const Text(
              'Are you sure you want to leave? Your reservation may be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Leave',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          _handleCancelAndCleanup(context, shouldPop: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Checkout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          iconTheme: IconThemeData(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          centerTitle: true,
          elevation: 0,
          toolbarHeight: 48,
        ),
        body: checkoutDetailsAsync.when(
          data: (details) {
            _initializeAttendeeKeys(details);
            return _CheckoutContent(
              formKey: _formKey,
              details: details,
              orderId: widget.orderId,
              promoController: _promoController,
              addressController: _addressController,
              phoneController: _phoneController,
              onPay: _processPayment,
              scrollController: _scrollController,
              addressKey: _addressKey,
              phoneKey: _phoneKey,
              attendeeFieldKeys: _attendeeFieldKeys,
            );
          },
          loading: () => const _CheckoutLoadingSkeleton(),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROCESSING DIALOG
// ─────────────────────────────────────────────
class _ProcessingPaymentDialog extends StatelessWidget {
  const _ProcessingPaymentDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initiating M-Pesa payment...\nPlease check your phone and enter your PIN.\nDo not close the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHECKOUT CONTENT
// ─────────────────────────────────────────────
class _CheckoutContent extends ConsumerWidget {
  const _CheckoutContent({
    required this.formKey,
    required this.details,
    required this.orderId,
    required this.promoController,
    required this.addressController,
    required this.phoneController,
    required this.onPay,
    required this.scrollController,
    required this.addressKey,
    required this.phoneKey,
    required this.attendeeFieldKeys,
  });

  final GlobalKey<FormState> formKey;
  final CheckoutDetailsModel details;
  final String orderId;
  final TextEditingController promoController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final VoidCallback onPay;
  final ScrollController scrollController;
  final GlobalKey<FormFieldState> addressKey;
  final GlobalKey<FormFieldState> phoneKey;
  final Map<String, GlobalKey<FormFieldState>> attendeeFieldKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutControllerProvider(orderId));

    final double subtotal = details.subtotal;
    final double grandTotal = details.grandTotal(
      promoDiscount: checkoutState.promoDiscount,
    );

    return Form(
      key: formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _EventHeader(details: details),
                const SizedBox(height: 16),
                _TicketHolderForms(
                  details: details,
                  orderId: orderId,
                  attendeeFieldKeys: attendeeFieldKeys,
                ),
                const SizedBox(height: 16),
                _BillingInfoSection(
                  addressController: addressController,
                  phoneController: phoneController,
                  addressKey: addressKey,
                  phoneKey: phoneKey,
                ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                const SizedBox(height: 16),
                _PromoCodeSection(
                  orderId: orderId,
                  promoController: promoController,
                ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                const SizedBox(height: 16),
                _OrderSummaryCard(
                  details: details,
                  orderId: orderId,
                  subtotal: subtotal,
                  grandTotal: grandTotal,
                ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
              ],
            ),
          ),
          _BottomPayBar(
            total: grandTotal,
            symbol: details.symbol,
            onPay: onPay,
            isProcessing: checkoutState.isProcessingPayment,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION CARD — THEME AWARE
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsets? padding;

  const _SectionCard({this.title, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      decoration: BoxDecoration(
        // FIXED: proper theme-aware colors
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.07),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  // FIXED: theme-aware subtitle color
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EVENT HEADER — THEME AWARE
// ─────────────────────────────────────────────
class _EventHeader extends StatelessWidget {
  final CheckoutDetailsModel details;
  const _EventHeader({required this.details});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: AppTheme.primaryPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Event info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.event.eventName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    // FIXED: theme-aware text
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      // FIXED: theme-aware icon
                      color: subColor,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        details.event.displayLocationString,
                        style: TextStyle(
                          fontSize: 11,
                          // FIXED: theme-aware text
                          color: subColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

// ─────────────────────────────────────────────
// TICKET HOLDER FORMS — THEME AWARE
// ─────────────────────────────────────────────
class _TicketHolderForms extends ConsumerWidget {
  final CheckoutDetailsModel details;
  final String orderId;
  final Map<String, GlobalKey<FormFieldState>> attendeeFieldKeys;

  const _TicketHolderForms({
    required this.details,
    required this.orderId,
    required this.attendeeFieldKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(checkoutControllerProvider(orderId).notifier);
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'ATTENDEE INFORMATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              // FIXED: theme-aware label
              color: subColor,
            ),
          ),
        ),

        ...details.tickets.expand((ticket) {
          return List.generate(ticket.quantity, (index) {
            final baseKey = '${ticket.id}-$index';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SectionCard(
                children: [
                  // ── Ticket badge ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.ticketType,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                // FIXED: theme-aware
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Attendee ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                                if (ticket.dateOfAccess != null &&
                                    !ticket.isSeasonalPass) ...[
                                  Text(
                                    ' · ',
                                    style: TextStyle(color: subColor),
                                  ),
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: subColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat.MMMd().format(
                                      DateTime.parse(ticket.dateOfAccess!),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ticket.isSeasonalPass
                              ? AppTheme.primaryPurple.withOpacity(0.1)
                              : AppTheme.primaryPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.isSeasonalPass ? 'Season' : 'Day Pass',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ticket.isSeasonalPass
                                ? AppTheme.primaryPurple
                                : AppTheme.primaryPink,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 14),

                  // ── Form Fields ──
                  Row(
                    children: [
                      Expanded(
                        child: _MinimalField(
                          fieldKey: attendeeFieldKeys['${baseKey}_fn']!,
                          label: 'First Name',
                          onChanged: (v) => notifier.updateTicketHolderInfo(
                            key: baseKey,
                            firstName: v,
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MinimalField(
                          fieldKey: attendeeFieldKeys['${baseKey}_ln']!,
                          label: 'Last Name',
                          onChanged: (v) => notifier.updateTicketHolderInfo(
                            key: baseKey,
                            lastName: v,
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MinimalField(
                    fieldKey: attendeeFieldKeys['${baseKey}_em']!,
                    label: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) =>
                        notifier.updateTicketHolderInfo(key: baseKey, email: v),
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'Valid email required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _MinimalField(
                    fieldKey: attendeeFieldKeys['${baseKey}_ad']!,
                    label: 'Address',
                    onChanged: (v) => notifier.updateTicketHolderInfo(
                      key: baseKey,
                      address: v,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (100 + index * 80).ms);
          });
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MINIMAL TEXT FIELD — THEME AWARE
// ─────────────────────────────────────────────
class _MinimalField extends StatelessWidget {
  final GlobalKey<FormFieldState> fieldKey;
  final String label;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;

  const _MinimalField({
    required this.fieldKey,
    required this.label,
    required this.onChanged,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return TextFormField(
      key: fieldKey,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      // FIXED: theme-aware input text
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        // FIXED: theme-aware label
        labelStyle: TextStyle(fontSize: 12, color: subColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        // FIXED: subtle fill for both themes
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 10, height: 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BILLING INFO — THEME AWARE
// ─────────────────────────────────────────────
class _BillingInfoSection extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final GlobalKey<FormFieldState> addressKey;
  final GlobalKey<FormFieldState> phoneKey;

  const _BillingInfoSection({
    required this.addressController,
    required this.phoneController,
    required this.addressKey,
    required this.phoneKey,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'BILLING & CONTACT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              // FIXED: theme-aware
              color: subColor,
            ),
          ),
        ),
        _SectionCard(
          children: [
            _MinimalFieldWithController(
              fieldKey: addressKey,
              label: 'Street Address',
              controller: addressController,
              validator: (v) => v!.isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 10),
            _MinimalFieldWithController(
              fieldKey: phoneKey,
              label: 'M-Pesa Phone Number',
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Phone required' : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MINIMAL FIELD WITH CONTROLLER — THEME AWARE
// ─────────────────────────────────────────────
class _MinimalFieldWithController extends StatelessWidget {
  final GlobalKey<FormFieldState> fieldKey;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final FormFieldValidator<String> validator;

  const _MinimalFieldWithController({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      // FIXED: theme-aware text
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: subColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 10, height: 1),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROMO CODE — THEME AWARE
// ─────────────────────────────────────────────
class _PromoCodeSection extends ConsumerWidget {
  final String orderId;
  final TextEditingController promoController;

  const _PromoCodeSection({
    required this.orderId,
    required this.promoController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutControllerProvider(orderId));
    final notifier = ref.read(checkoutControllerProvider(orderId).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    if (checkoutState.promoStatus == PromoStatus.applied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Promo "${checkoutState.appliedPromoCode}" applied',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                promoController.clear();
                notifier.removePromoCode();
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                // FIXED: theme-aware
                color: subColor,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: promoController,
            // FIXED: theme-aware text
            style: TextStyle(fontSize: 13, color: textColor),
            decoration: InputDecoration(
              hintText: 'Promo code',
              hintStyle: TextStyle(fontSize: 13, color: subColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.primaryPink,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: checkoutState.promoStatus == PromoStatus.loading
                ? null
                : () => notifier.applyPromoCode(promoController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
              // FIXED: theme-aware disabled state
              disabledBackgroundColor: isDark
                  ? Colors.grey[800]
                  : Colors.grey[300],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: checkoutState.promoStatus == PromoStatus.loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Apply',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ORDER SUMMARY — THEME AWARE
// ─────────────────────────────────────────────
class _OrderSummaryCard extends ConsumerWidget {
  final CheckoutDetailsModel details;
  final String orderId;
  final double subtotal;
  final double grandTotal;

  const _OrderSummaryCard({
    required this.details,
    required this.orderId,
    required this.subtotal,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider(orderId));
    final displayTickets = details.groupedTickets;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bookingFee = details.bookingFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'ORDER SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              // FIXED: theme-aware
              color: subColor,
            ),
          ),
        ),
        _SectionCard(
          children: [
            ...displayTickets.map(
              (t) => _TicketRow(ticket: t, symbol: details.symbol),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),

            _PriceRow(
              label: 'Subtotal',
              value: '${details.symbol}${subtotal.toStringAsFixed(2)}',
            ),

            ...details.taxesAndFees.map((fee) {
              final feeAmount = fee.chargeType == '0'
                  ? (subtotal * fee.charges) / 100
                  : fee.charges;
              return _PriceRow(
                label: fee.title,
                value: '${details.symbol}${feeAmount.toStringAsFixed(2)}',
              );
            }),

            // ✅ Always show Booking Fee row even if 0.00, as requested
            _BookingFeeExpandable(details: details, bookingFee: bookingFee),

            if (state.promoStatus == PromoStatus.applied)
              _PriceRow(
                label: 'Discount',
                value:
                    '-${details.symbol}${state.promoDiscount.toStringAsFixed(2)}',
                valueColor: Colors.green,
              ),

            const SizedBox(height: 8),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),

            // Total row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    // FIXED: theme-aware
                    color: textColor,
                  ),
                ),
                Text(
                  '${details.symbol}${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TICKET ROW — THEME AWARE
// ─────────────────────────────────────────────
class _TicketRow extends StatelessWidget {
  final CheckoutTicketModel ticket;
  final String symbol;

  const _TicketRow({required this.ticket, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final hasSeats = ticket.seats.isNotEmpty;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primaryPink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.ticketType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    // FIXED: theme-aware
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                if (hasSeats)
                  ..._buildSeatInfo(context, ticket.seats)
                else
                  Text(
                    'Qty: ${ticket.quantity}',
                    style: TextStyle(
                      fontSize: 11,
                      // FIXED: theme-aware
                      color: subColor,
                    ),
                  ),
              ],
            ),
          ),

          Text(
            '$symbol${ticket.totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              // FIXED: theme-aware
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeatInfo(BuildContext context, List<SeatDetail> seats) {
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final Map<String, List<String>> rows = {};
    for (var seat in seats) {
      rows.putIfAbsent(seat.row, () => []).add(seat.number);
    }
    return rows.entries.map((entry) {
      return Text(
        '${entry.key.isNotEmpty ? 'Row ${entry.key}: ' : 'Seat: '}'
        '${entry.value.join(', ')}',
        style: TextStyle(
          fontSize: 11,
          // FIXED: theme-aware
          color: subColor,
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────
// PRICE ROW — THEME AWARE
// ─────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              // FIXED: theme-aware
              color: subColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              // FIXED: use valueColor or theme-aware fallback
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXPANDABLE BOOKING FEE ROW
// ─────────────────────────────────────────────
class _BookingFeeExpandable extends StatefulWidget {
  final CheckoutDetailsModel details;
  final double bookingFee;

  const _BookingFeeExpandable({
    required this.details,
    required this.bookingFee,
  });

  @override
  State<_BookingFeeExpandable> createState() => _BookingFeeExpandableState();
}

class _BookingFeeExpandableState extends State<_BookingFeeExpandable>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).textTheme.bodySmall?.color;
    final symbol = widget.details.symbol;
    final basePrice = widget.details.bookingFeeBase;
    final taxAmount = widget.details.bookingFeeTax;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header tap row ──
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  'Booking Fee',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPink,
                  ),
                ),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _rotateAnim,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.primaryPink,
                  ),
                ),
                const Spacer(),
                Text(
                  '$symbol${widget.bookingFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ],
            ),
          ),

          // ── Animated breakdown panel ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 8, left: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.12),
                ),
              ),
              child: Column(
                children: [
                  _FeeDetailRow(
                    label: 'Base Price',
                    value: '$symbol${basePrice.toStringAsFixed(2)}',
                    subColor: subColor,
                  ),
                  _FeeDetailRow(
                    label: 'Integrated GST (IGST) @ 18%',
                    value: '$symbol${taxAmount.toStringAsFixed(2)}',
                    subColor: subColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FEE DETAIL ROW (used inside breakdown panel)
// ─────────────────────────────────────────────
class _FeeDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? subColor;

  const _FeeDetailRow({
    required this.label,
    required this.value,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = subColor ?? Theme.of(context).textTheme.bodySmall?.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM PAY BAR — THEME AWARE
// ─────────────────────────────────────────────
class _BottomPayBar extends StatelessWidget {
  final double total;
  final String symbol;
  final VoidCallback onPay;
  final bool isProcessing;

  const _BottomPayBar({
    required this.total,
    required this.symbol,
    required this.onPay,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            // FIXED: proper theme-aware bottom bar
            color: isDark
                ? const Color(0xFF1C1C1E).withOpacity(0.97)
                : Colors.white.withOpacity(0.97),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Total label + amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Payable',
                      style: TextStyle(
                        fontSize: 11,
                        // FIXED: theme-aware
                        color: subColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$symbol${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Pay button
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: !isProcessing
                          ? LinearGradient(
                              colors: [AppColors.greenMain, AppColors.blueMain],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: !isProcessing
                          ? null
                          : (isDark ? Colors.grey[800] : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : onPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        // FIXED: theme-aware disabled
                        disabledForegroundColor: isDark
                            ? Colors.grey[600]
                            : Colors.grey[500],
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Confirm & Pay',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────
// LOADING SKELETON — THEME AWARE
// ─────────────────────────────────────────────
class _CheckoutLoadingSkeleton extends StatelessWidget {
  const _CheckoutLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _bone(context: context, height: 72),
          const SizedBox(height: 16),
          _bone(context: context, height: 200),
          const SizedBox(height: 16),
          _bone(context: context, height: 120),
          const SizedBox(height: 16),
          _bone(context: context, height: 48),
          const SizedBox(height: 16),
          _bone(context: context, height: 160),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _bone({required BuildContext context, double height = 16}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        // FIXED: theme-aware skeleton
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
