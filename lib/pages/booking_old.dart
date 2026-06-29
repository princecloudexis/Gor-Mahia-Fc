


import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventsbooking/api/api_client.dart';
import 'package:eventsbooking/pages/checkout.dart';
import 'package:eventsbooking/pages/login.dart';
import 'package:eventsbooking/providers/booking_provider.dart';
import 'package:eventsbooking/providers/preregistration_provider.dart';
import 'package:eventsbooking/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../providers/event_providers.dart';
import '../theme/apptheme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final selectedDateProvider = StateProvider.autoDispose<DateTime?>(
  (ref) => null,
);
final ticketQuantitiesProvider = StateProvider.autoDispose<Map<int, int>>(
  (ref) => {},
);

class Booking extends ConsumerWidget {
  final EventModel event;
  final IconData categoryIcon;

  const Booking({super.key, required this.event, required this.categoryIcon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenForBookingStateChanges(context, ref);
    _listenForPreRegistrationStateChanges(context, ref);

    final ticketDetailsAsync = ref.watch(ticketDetailsProvider(event.slug!));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('Select Tickets'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ticketDetailsAsync.when(
        loading: () => const _BookingShimmer(),
        error: (error, stack) =>
            Center(child: Text('Failed to load ticket details: $error')),
        data: (details) {
          if (details.isPreRegistrationActive) {
            return _PreRegistrationView(
              details: details,
              categoryIcon: categoryIcon,
            );
          }
          if (details.isBookingActive) {
            return _HybridBookingView(
              details: details,
              categoryIcon: categoryIcon,
            );
          }
          return _ComingSoonView(details: details, categoryIcon: categoryIcon);
        },
      ),
    );
  }

  void _listenForBookingStateChanges(BuildContext context, WidgetRef ref) {
    ref.listen<BookingState>(bookingControllerProvider, (previous, next) {
      if (next.status == BookingStatus.error && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'An unknown error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.status == BookingStatus.success && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Checkout(orderId: next.orderId!)),
        );
        ref.read(bookingControllerProvider.notifier).resetState();
      }
    });
  }

  void _listenForPreRegistrationStateChanges(
    BuildContext context,
    WidgetRef ref,
  ) {
    ref.listen<PreRegistrationState>(preRegistrationControllerProvider, (
      prev,
      next,
    ) {
      if (prev?.status == PreRegistrationStatus.loading && context.mounted) {
        Navigator.of(context).pop();
      }
      if (next.status == PreRegistrationStatus.loading && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      } else if (next.status == PreRegistrationStatus.error &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Failed to register'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.status == PreRegistrationStatus.success &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are pre-registered!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(ticketDetailsProvider(event.slug!));
      }
    });
  }
}

class _HybridBookingView extends ConsumerWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  const _HybridBookingView({required this.details, required this.categoryIcon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPerDayTickets = details.hasPerDayTickets;
    final hasSeasonalTickets = details.hasSeasonalPassTickets;

    if (!hasPerDayTickets && !hasSeasonalTickets) {
      return _BookingClosedView(details: details, categoryIcon: categoryIcon);
    }

    List<DateTime> upcomingDates = [];
    if (hasPerDayTickets) {
      final now = DateTime.now();
      final today = DateUtils.dateOnly(now);
      upcomingDates = details.availableDates
          .where((eventDate) => !eventDate.isBefore(today))
          .toList();

      final selectedDate = ref.watch(selectedDateProvider);
      if (upcomingDates.isNotEmpty &&
          (selectedDate == null ||
              !upcomingDates.any(
                (d) => DateUtils.isSameDay(d, selectedDate),
              ))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedDateProvider.notifier).state = upcomingDates.first;
        });
      }
    }

    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _EventHeader(
                  details: details,
                  categoryIcon: categoryIcon,
                ),
              ),

              if (hasSeasonalTickets) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      'Seasonal Pass',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _TicketList(
                  tickets: details.seasonalPassTickets,
                  symbol: details.symbol,
                ),
              ],

              if (hasPerDayTickets) ...[
                if (hasSeasonalTickets)
                  const SliverToBoxAdapter(
                    child: Divider(indent: 20, endIndent: 20, height: 40),
                  ),
                SliverToBoxAdapter(child: _DateSelector(dates: upcomingDates)),
                if (selectedDate != null)
                  _TicketList(
                    tickets: details.perDayTickets,
                    symbol: details.symbol,
                  )
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Please select a date to see tickets.',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        _BookingBottomBar(details: details),
      ],
    );
  }
}

class _BookingClosedView extends StatelessWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  const _BookingClosedView({required this.details, required this.categoryIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EventHeader(details: details, categoryIcon: categoryIcon),
        const Spacer(),
        const Icon(
          Icons.event_busy_outlined,
          size: 50,
          color: AppTheme.textLight,
        ),
        const SizedBox(height: 16),
        Text(
          'Booking Closed',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'There are no tickets currently available for sale for this event.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.textLight),
          ),
        ),
        const Spacer(),
      ],
    ).animate().fadeIn();
  }
}

class _PreRegistrationView extends StatelessWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  const _PreRegistrationView({
    required this.details,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          _EventHeader(details: details, categoryIcon: categoryIcon),
          details.isUserPreRegistered
              ? const _AlreadyRegisteredCard()
              : _PreRegistrationCard(details: details),
          _IncentiveSection(details: details),
        ],
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  const _ComingSoonView({required this.details, required this.categoryIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EventHeader(details: details, categoryIcon: categoryIcon),
        const Spacer(),
        const Icon(
          Icons.hourglass_top_rounded,
          size: 50,
          color: AppTheme.textLight,
        ),
        const SizedBox(height: 16),
        Text('Coming Soon', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (details.preRegisterStartDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Pre-registration opens on ${DateFormat.yMMMd().format(details.preRegisterStartDate!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppTheme.textLight),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Ticket sales have not yet started. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textLight),
            ),
          ),
        const Spacer(),
      ],
    ).animate().fadeIn();
  }
}

class _EventHeader extends ConsumerWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  const _EventHeader({required this.details, required this.categoryIcon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final imageUrl = details.eventImage?.startsWith('http') ?? false
        ? details.eventImage!
        : '$storageBaseUrl/${details.eventImage}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).shadowColor.withOpacity(0.5),
        ),
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
                  Container(color: Theme.of(context).splashColor),
              errorWidget: (context, url, err) => Container(
                color: Theme.of(context).splashColor,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.eventName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.venueName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(categoryIcon, size: 16, color: AppTheme.primaryPink),
                    const SizedBox(width: 4),
                    Text(
                      details.categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DateSelector extends ConsumerWidget {
  final List<DateTime> dates;
  const _DateSelector({required this.dates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dates.isEmpty) return const SizedBox.shrink();
    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Select Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected =
                  selectedDate != null &&
                  DateUtils.isSameDay(date, selectedDate);
              return GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = date;
                  ref.read(ticketQuantitiesProvider.notifier).state = {};
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 65,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPink
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(color: Theme.of(context).shadowColor),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<TicketCategoryModel> tickets;
  final String symbol;

  const _TicketList({required this.tickets, required this.symbol});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Text('No tickets available for this selection.'),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      sliver: SliverList.separated(
        itemBuilder: (context, index) =>
            _TicketCard(category: tickets[index], symbol: symbol, index: index),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemCount: tickets.length,
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final TicketCategoryModel category;
  final String symbol;
  final int index;

  const _TicketCard({
    required this.category,
    required this.symbol,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketQuantities = ref.watch(ticketQuantitiesProvider);
    final currentQuantity = ticketQuantities[category.id] ?? 0;

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: currentQuantity > 0
                  ? AppTheme.primaryPink
                  : Theme.of(context).shadowColor.withOpacity(0.5),
              width: currentQuantity > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    category.price == 0
                        ? 'Free'
                        : '$symbol${category.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                category.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${category.available} available',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  _QuantitySelector(category: category),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: (200 + index * 100).ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _QuantitySelector extends ConsumerWidget {
  final TicketCategoryModel category;
  const _QuantitySelector({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketQuantities = ref.watch(ticketQuantitiesProvider);
    final currentQuantity = ticketQuantities[category.id] ?? 0;
    final maxQuantityPerOrder = category.maxPerOrder;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: currentQuantity > 0
                ? () {
                    final newQuantities = Map<int, int>.from(ticketQuantities);
                    newQuantities.update(
                      category.id,
                      (value) => value - 1,
                      ifAbsent: () => 0,
                    );
                    if (newQuantities[category.id]! <= 0) {
                      newQuantities.remove(category.id);
                    }
                    ref.read(ticketQuantitiesProvider.notifier).state =
                        newQuantities;
                  }
                : null,
            icon: const Icon(Icons.remove, size: 18),
            splashRadius: 20,
          ),
          Text(
            '$currentQuantity',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed:
                (currentQuantity < maxQuantityPerOrder &&
                    currentQuantity < category.available)
                ? () {
                    final newQuantities = Map<int, int>.from(ticketQuantities);
                    newQuantities[category.id] =
                        (newQuantities[category.id] ?? 0) + 1;
                    ref.read(ticketQuantitiesProvider.notifier).state =
                        newQuantities;
                  }
                : null,
            icon: const Icon(Icons.add, size: 18),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _BookingBottomBar extends ConsumerWidget {
  final TicketDetailModel details;
  const _BookingBottomBar({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingControllerProvider);
    final user = ref.watch(userProvider);
    final ticketQuantities = ref.watch(ticketQuantitiesProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    final totalTickets = ticketQuantities.values.fold<int>(
      0,
      (sum, item) => sum + item,
    );
    final totalAmount = details.tickets.fold<double>(
      0,
      (sum, ticket) => sum + ticket.price * (ticketQuantities[ticket.id] ?? 0),
    );

    final bool perDayTicketSelected = ticketQuantities.keys.any(
      (id) => details.perDayTickets.any((ticket) => ticket.id == id),
    );

    final bool canProceed =
        totalTickets > 0 && (!perDayTicketSelected || selectedDate != null);

    String buttonText = 'Select Tickets';
    if (perDayTicketSelected && selectedDate == null) {
      buttonText = 'Select a Date';
    } else if (totalTickets > 0) {
      buttonText = 'Proceed to Checkout';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalTickets > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$totalTickets Tickets',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                  Text(
                    totalAmount == 0
                        ? 'Free'
                        : '${details.symbol}${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed:
                  canProceed && bookingState.status != BookingStatus.loading
                  ? () {
                      if (user == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Login(),
                          ),
                        );
                      } else {
                        ref
                            .read(bookingControllerProvider.notifier)
                            .submitBooking(
                              ticketQuantities: ticketQuantities,
                              selectedDate: perDayTicketSelected
                                  ? selectedDate
                                  : null,
                            );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.textLight.withAlpha(70),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: bookingState.status == BookingStatus.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyRegisteredCard extends StatelessWidget {
  const _AlreadyRegisteredCard();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 60),
          SizedBox(height: 16),
          Text(
            "You're on the list!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "We'll notify you when tickets are available.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PreRegistrationCard extends ConsumerWidget {
  final TicketDetailModel details;
  const _PreRegistrationCard({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preRegState = ref.watch(preRegistrationControllerProvider);
    final user = ref.watch(userProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const Text(
            'Be the First to Know!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pre-register now to get notified when tickets go live.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: preRegState.status == PreRegistrationStatus.loading
                ? null
                : () {
                    if (user == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    } else {
                      ref
                          .read(preRegistrationControllerProvider.notifier)
                          .submitPreRegistration(
                            eventSlug: details.slug,
                            name: '${user.firstName} ${user.lastName}',
                            email: user.email,
                            phoneNumber: user.phoneNumber,
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              user == null ? 'Login to Pre-Register' : 'Pre-Register Now',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncentiveSection extends ConsumerWidget {
  final TicketDetailModel details;
  const _IncentiveSection({required this.details});

  Future<void> _shareToInstagram(String imageUrl, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));

      // Get a temporary directory to save the file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/event_image.jpg').create();

      // Write the image data to the file
      await file.writeAsBytes(response.bodyBytes);

      // Close the loading dialog before showing the share sheet
      if (context.mounted) Navigator.of(context).pop();

      // Use share_plus to share the local file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this amazing event! #events',
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share image. Please try again.')),
        );
      }
    }
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    if (details.giftcards.isEmpty) return const SizedBox.shrink();

    final giftCard = details.giftcards.first;
    final giftCardImageUrl = giftCard.image.startsWith('http')
        ? giftCard.image
        : '$storageBaseUrl/giftcard/${giftCard.image}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pre-Register & Win!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: giftCardImageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stack) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 35,
                      color: Colors.grey,
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
                      giftCard.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      giftCard.description,
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          const Center(
            child: Text(
              'Spread the Word',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchURL(details.facebookShareUrl, context),
                  icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
                  label: const Text('Share', style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _shareToInstagram(giftCardImageUrl, context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        FaIcon(FontAwesomeIcons.instagram, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}

class _BookingShimmer extends StatelessWidget {
  const _BookingShimmer();
  Widget _buildShimmerBox({
    double? width,
    required double height,
    double radius = 12.0,
    required BuildContext context,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).splashColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildShimmerBox(width: 80, height: 80, context: context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(
                          height: 20,
                          width: double.infinity,
                          radius: 4,
                          context: context,
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(
                          height: 14,
                          width: 150,
                          radius: 4,
                          context: context,
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(
                          height: 14,
                          width: 100,
                          radius: 4,
                          context: context,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: _buildShimmerBox(
                height: 20,
                width: 120,
                radius: 4,
                context: context,
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildShimmerBox(
                    width: 65,
                    height: 80,
                    radius: 16,
                    context: context,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: _buildShimmerBox(
                height: 150,
                width: double.infinity,
                radius: 20,
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
