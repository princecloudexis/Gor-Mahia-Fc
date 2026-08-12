import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gormahiafc/api/api_client.dart';
import 'package:gormahiafc/models/seat_layout_model.dart';
import 'package:gormahiafc/pages/checkout.dart';
import 'package:gormahiafc/pages/login.dart';
import 'package:gormahiafc/providers/booking_provider.dart';
import 'package:gormahiafc/providers/preregistration_provider.dart';
import 'package:gormahiafc/providers/seat_provider.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/repositories/event_repositories.dart';
import 'package:gormahiafc/utils/app_exception.dart';
import 'package:gormahiafc/widgets/seat_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../providers/event_providers.dart' hide bookedSeatsByDateProvider;
import '../theme/apptheme.dart';
import '../theme/app_colors.dart';

final selectedDateProvider = StateProvider.autoDispose<DateTime?>(
  (ref) => null,
);
final ticketQuantitiesProvider = StateProvider.autoDispose<Map<int, int>>(
  (ref) => {},
);
/// Forced-booked seats scoped by date ("yyyy-MM-dd" → seat-id variants).
/// Using a date-keyed map prevents conflicts on one date from bleeding into other dates.
final forcedBookedSeatsProvider =
    StateProvider.autoDispose<Map<String, Set<String>>>((ref) => {});

final seatMapTransformControllerProvider =
    StateProvider.autoDispose<TransformationController?>((ref) => null);

class Booking extends ConsumerStatefulWidget {
  final EventModel event;
  final IconData categoryIcon;

  const Booking({super.key, required this.event, required this.categoryIcon});

  @override
  ConsumerState<Booking> createState() => _BookingState();
}

class _BookingState extends ConsumerState<Booking> {
  /// Reset all seat-selection state and refresh booked-seats data
  /// whenever the user returns to this page (e.g. pressing back from Checkout).
  void _resetSeatState() {
    if (!mounted) return;
    ref.read(selectedSeatsProvider.notifier).state = {};
    ref.read(selectedSectionBlocksProvider.notifier).state = {};
    ref.read(ticketQuantitiesProvider.notifier).state = {};
    // NOTE: forcedBookedSeatsProvider is intentionally NOT cleared here.
    // Just-booked seats stay forced-gray during the brief re-fetch window
    // after returning from checkout. They are cleared when the user switches
    // dates (via date chip tap) or when the booking page is fully disposed.

    // Refresh the date-specific booked seats so the map is up to date
    final selectedDate = ref.read(selectedDateProvider);
    if (selectedDate != null) {
      ref.invalidate(
        bookedSeatsByDateProvider((widget.event.id, selectedDate)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetSeatState();
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenForBookingStateChanges(context, ref);
    _listenForPreRegistrationStateChanges(context, ref);

    final ticketDetailsAsync = ref.watch(
      ticketDetailsProvider(widget.event.slug!),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Tickets',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: ticketDetailsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, stack) =>
            _TicketDetailsErrorView(error: error, slug: widget.event.slug!),
        data: (details) {
          if (details.isPreRegistrationActive) {
            return _PreRegistrationView(
              details: details,
              categoryIcon: widget.categoryIcon,
            );
          }
          if (details.isBookingActive) {
            return _SeatMapOrListView(
              details: details,
              eventId: widget.event.id,
              categoryIcon: widget.categoryIcon,
            );
          }
          if (details.isBookingClosed) {
            return _BookingClosedView(
              details: details,
              categoryIcon: widget.categoryIcon,
            );
          }
          return _ComingSoonView(
            details: details,
            categoryIcon: widget.categoryIcon,
          );
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
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => Checkout(orderId: next.orderId!),
              ),
            )
            .then((_) {
              // ✅ KEY FIX: when user presses back from Checkout, clear all
              //    seat state so that seats selected/blocked on this date don't
              //    bleed through to every other date on the seat map.
              _resetSeatState();
            });
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
        ref.invalidate(ticketDetailsProvider(widget.event.slug!));
      }
    });
  }
}

// ─────────────────────────────────────────────
// SEAT MAP OR LIST VIEW
// ─────────────────────────────────────────────
class _SeatMapOrListView extends ConsumerWidget {
  final TicketDetailModel details;
  final int eventId;
  final IconData categoryIcon;

  const _SeatMapOrListView({
    required this.details,
    required this.eventId,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seatMapAsync = ref.watch(seatMapFutureProvider(eventId));

    return seatMapAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading Seat Map..."),
          ],
        ),
      ),
      error: (e, s) {
        return _StandardListView(
          details: details,
          categoryIcon: categoryIcon,
          eventId: eventId,
        );
      },
      data: (apiData) {
        if (apiData == null || apiData['seat_map_json'] == null) {
          return _StandardListView(
            details: details,
            categoryIcon: categoryIcon,
            eventId: eventId,
          );
        }

        final rawJson = apiData['seat_map_json'];
        Map<String, dynamic> jsonMap;

        if (rawJson is String) {
          try {
            jsonMap = jsonDecode(rawJson) as Map<String, dynamic>;
          } catch (e) {
            return _StandardListView(
              details: details,
              categoryIcon: categoryIcon,
              eventId: eventId,
            );
          }
        } else if (rawJson is Map<String, dynamic>) {
          jsonMap = rawJson;
        } else {
          return _StandardListView(
            details: details,
            categoryIcon: categoryIcon,
            eventId: eventId,
          );
        }

        if (!_hasActualContent(jsonMap)) {
          return _StandardListView(
            details: details,
            categoryIcon: categoryIcon,
            eventId: eventId,
          );
        }

        final jsonString = jsonEncode(jsonMap);
        final layoutAsync = ref.watch(seatLayoutParserProvider(jsonString));

        return layoutAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Preparing seat layout..."),
              ],
            ),
          ),
          error: (e, s) => _StandardListView(
            details: details,
            categoryIcon: categoryIcon,
            eventId: eventId,
          ),
          data: (layoutData) {
            if (layoutData == null ||
                (layoutData.seats.isEmpty && layoutData.sections.isEmpty)) {
              return _StandardListView(
                details: details,
                categoryIcon: categoryIcon,
                eventId: eventId,
              );
            }

            return _SeatMapWithDateAwareBookings(
              details: details,
              layoutData: layoutData,
              eventId: eventId,
              categoryIcon: categoryIcon,
              staticBookedSeats: _parseBookedSeats(apiData['bookedSeats']),
              apiSelectedDate: _parseApiDate(apiData['selectedDate']),
            );
          },
        );
      },
    );
  }

  bool _hasActualContent(Map<String, dynamic> json) {
    final children = json['children'];
    if (children == null || children is! List || children.isEmpty) return false;
    for (final child in children) {
      if (child is! Map<String, dynamic>) continue;
      final className = child['className'];
      if (className == 'Layer') {
        final layerChildren = child['children'];
        if (layerChildren is List) {
          for (final lc in layerChildren) {
            if (lc is Map<String, dynamic>) {
              final lcClass = lc['className'];
              if (lcClass == 'Group' ||
                  lcClass == 'Rect' ||
                  lcClass == 'Text') {
                return true;
              }
            }
          }
        }
      } else if (className == 'Group') {
        return true;
      }
    }
    return false;
  }

  Set<String> _parseBookedSeats(dynamic bookedRaw) {
    final Set<String> bookedSeats = {};
    if (bookedRaw == null) return bookedSeats;

    String normalizeIdPart(String? input) {
      if (input == null || input.trim().isEmpty) return 'unknown';
      return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    }

    void addAllVariants(String groupKey, String seatValue) {
      final normalizedGroup = normalizeIdPart(groupKey);

      // 1. Raw seat value: "A5"
      bookedSeats.add(seatValue);
      bookedSeats.add(seatValue.toLowerCase());

      // 2. group_seat: "111_A5"
      bookedSeats.add('${groupKey}_$seatValue');
      bookedSeats.add('${groupKey}_${seatValue.toLowerCase()}');

      // 3. normalizedGroup_seat (same for numeric groups)
      if (normalizedGroup != groupKey) {
        bookedSeats.add('${normalizedGroup}_$seatValue');
        bookedSeats.add('${normalizedGroup}_${seatValue.toLowerCase()}');
      }

      // 4. If seatValue already has group prefix like "111_C4"
      //    → also add without prefix: "C4"
      final prefixWithUnderscore = '${groupKey}_';
      if (seatValue.startsWith(prefixWithUnderscore)) {
        final stripped = seatValue.substring(prefixWithUnderscore.length);
        bookedSeats.add(stripped);
        bookedSeats.add(stripped.toLowerCase());
        // also add groupKey_stripped (already there but be safe)
        bookedSeats.add('${groupKey}_$stripped');
      }

      // 5. Extract alphanumeric part: "seatA5" → "A5"
      final m = RegExp(r'([A-Za-z]+\d+)').firstMatch(seatValue);
      if (m != null && m.group(1) != seatValue) {
        final extracted = m.group(1)!;
        bookedSeats.add(extracted);
        bookedSeats.add(extracted.toLowerCase());
        bookedSeats.add('${groupKey}_$extracted');
        bookedSeats.add('${normalizedGroup}_$extracted');
      }
    }

    try {
      if (bookedRaw is Map) {
        bookedRaw.forEach((key, value) {
          final groupKey = key.toString();
          if (value is List) {
            for (final e in value) {
              if (e != null) addAllVariants(groupKey, e.toString());
            }
          } else if (value != null) {
            addAllVariants(groupKey, value.toString());
          }
        });
      } else if (bookedRaw is List) {
        for (final v in bookedRaw) {
          if (v != null) {
            final s = v.toString();
            bookedSeats.add(s);
            bookedSeats.add(s.toLowerCase());
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing booked seats: $e');
    }

    debugPrint('📍 Parsed booked seats (${bookedSeats.length}): $bookedSeats');
    return bookedSeats;
  }

  /// Safely parse the API-returned date string (e.g. "2026-06-01") into a DateTime.
  DateTime? _parseApiDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────
// COMPACT SEAT SELECTION VIEW
// ─────────────────────────────────────────────
class _SeatSelectionView extends ConsumerWidget {
  final TicketDetailModel details;
  final SeatLayoutData layoutData;
  final Set<String> bookedSeats;
  final IconData categoryIcon;
  final int eventId;

  const _SeatSelectionView({
    required this.details,
    required this.layoutData,
    required this.bookedSeats,
    required this.categoryIcon,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (details.hasPerDayTickets && details.availableDates.isNotEmpty) {
      final selectedDate = ref.watch(selectedDateProvider);
      if (selectedDate == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedDateProvider.notifier).state =
              details.availableDates.first;
        });
      }
    }

    return Column(
      children: [
        _CompactTopSection(
          details: details,
          categoryIcon: categoryIcon,
          eventId: eventId,
        ),
        Expanded(
          child: _SeatMapWithControls(
            layoutData: layoutData,
            bookedSeats: bookedSeats,
            details: details,
          ),
        ),
        _SeatBookingBottomBar(
          details: details,
          layoutData: layoutData,
          eventId: eventId,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// COMPACT TOP SECTION — THEME AWARE
// ─────────────────────────────────────────────
class _CompactTopSection extends ConsumerWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  final int eventId;

  const _CompactTopSection({
    required this.details,
    required this.categoryIcon,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodySmall?.color;

    String imageUrl;
    if (details.eventImage == null || details.eventImage!.isEmpty) {
      imageUrl = 'https://via.placeholder.com/150x150.png?text=No+Image';
    } else if (details.eventImage!.startsWith('http')) {
      imageUrl = details.eventImage!;
    } else {
      final correctedBaseUrl = storageBaseUrl.endsWith('/')
          ? storageBaseUrl
          : '$storageBaseUrl/';
      imageUrl =
          '${correctedBaseUrl}storage/Creator/event/image/${details.eventImage}';
    }

    final hasDateSelector =
        details.hasPerDayTickets && details.availableDates.isNotEmpty;
    final hasSeasonalPass = details.hasSeasonalPassTickets;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Event Info Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Event image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).cardColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).cardColor,
                      child: Icon(Icons.image, color: subColor, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Event name + venue
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.eventName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          // FIXED: use theme color not hardcoded white
                          color: textColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: subColor,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              details.venueName,
                              style: TextStyle(fontSize: 11, color: subColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 12, color: AppTheme.primaryPink),
                      const SizedBox(width: 4),
                      Text(
                        details.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Date selector ──
          if (hasDateSelector)
            SizedBox(
              height: 56,
              child: _CompactDateSelector(
                dates: details.availableDates,
                eventId: eventId,
              ),
            )
          else if (hasSeasonalPass)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: AppTheme.primaryPink,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Seasonal Pass",
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COMPACT DATE SELECTOR — THEME AWARE
// ─────────────────────────────────────────────
class _CompactDateSelector extends ConsumerWidget {
  final List<DateTime> dates;
  final int eventId;

  const _CompactDateSelector({required this.dates, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: dates.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected =
            selectedDate != null && DateUtils.isSameDay(date, selectedDate);

        return GestureDetector(
          onTap: () {
            ref.read(selectedDateProvider.notifier).state = date;
            ref.read(selectedSeatsProvider.notifier).state = {};
            ref.read(selectedSectionBlocksProvider.notifier).state = {};
            ref.read(ticketQuantitiesProvider.notifier).state = {};
            // Map is date-keyed so no cross-date bleed, but still clear on
            // date change to free memory for dates no longer needed.
            ref.read(forcedBookedSeatsProvider.notifier).state = {};
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              // FIXED: theme-aware background
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.greenMain, AppColors.blueMain],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryPink
                    : Theme.of(context).dividerColor,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    // FIXED: theme-aware text
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM').format(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withOpacity(0.85)
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// SEAT MAP WITH CONTROLS
// ─────────────────────────────────────────────
class _SeatMapWithControls extends ConsumerStatefulWidget {
  final SeatLayoutData layoutData;
  final Set<String> bookedSeats;
  final TicketDetailModel details;

  const _SeatMapWithControls({
    required this.layoutData,
    required this.bookedSeats,
    required this.details,
  });

  @override
  ConsumerState<_SeatMapWithControls> createState() =>
      _SeatMapWithControlsState();
}

class _SeatMapWithControlsState extends ConsumerState<_SeatMapWithControls>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.addListener(_onAnimate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(seatMapTransformControllerProvider.notifier).state =
            _transformController;
      }
    });
  }

  void _onAnimate() {
    if (_animation != null) {
      _transformController.value = _animation!.value;
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimate);
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SeatMapWidget(
            layoutData: widget.layoutData,
            bookedSeats: widget.bookedSeats,
            details: widget.details,
          ),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child:
              Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pinch_rounded,
                            size: 14,
                            color: Colors.white60,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pinch to zoom • Tap to select',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .then(delay: 3000.ms)
                  .fadeOut(duration: 800.ms),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SEAT BOOKING BOTTOM BAR — THEME AWARE
// ─────────────────────────────────────────────
class _SeatBookingBottomBar extends ConsumerStatefulWidget {
  final TicketDetailModel details;
  final SeatLayoutData layoutData;
  final int eventId;

  const _SeatBookingBottomBar({
    required this.details,
    required this.layoutData,
    required this.eventId,
  });

  @override
  ConsumerState<_SeatBookingBottomBar> createState() =>
      _SeatBookingBottomBarState();
}

class _SeatBookingBottomBarState extends ConsumerState<_SeatBookingBottomBar> {
  bool _isSubmitting = false;

  late final Map<int, TicketCategoryModel> _ticketsById;
  late final Map<String, TicketCategoryModel> _ticketsByName;

  @override
  void initState() {
    super.initState();
    final allTickets = widget.details.tickets;
    _ticketsById = {for (final t in allTickets) t.id: t};
    _ticketsByName = {};
    for (final t in allTickets) {
      _ticketsByName[t.name.trim().toLowerCase()] = t;
    }
  }

  TicketCategoryModel? _matchTicketByName(String section) {
    final key = section.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_ticketsByName.containsKey(key)) return _ticketsByName[key];
    for (final entry in _ticketsByName.entries) {
      final ticketName = entry.key;
      if (key.contains(ticketName) || ticketName.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  TicketCategoryModel? _resolveTicketForSeat(SeatEntity seat) {
    if (seat.ticketId != null) {
      final t = _ticketsById[seat.ticketId!];
      if (t != null) return t;
    }
    return _matchTicketByName(seat.section);
  }

  TicketCategoryModel? _resolveTicketForSection(SectionEntity section) {
    if (section.ticketId != null) {
      final t = _ticketsById[section.ticketId!];
      if (t != null) return t;
    }
    return _matchTicketByName(section.label);
  }

  bool _looksLikeSeatCode(String input) {
    return RegExp(r'^[A-Za-z]+\d+$').hasMatch(input.trim());
  }

  bool _looksLikeGroupedSeatCode(String input) {
    return RegExp(r'^[^_]+_[A-Za-z]+\d+$').hasMatch(input.trim());
  }

  String _seatApiValue(SeatEntity seat) {
    final id = seat.id.trim();
    final raw = seat.rawId?.trim() ?? '';
    final label = seat.label.trim();
    final group = seat.groupId?.trim() ?? '';

    if (raw.isNotEmpty) {
      if (_looksLikeGroupedSeatCode(raw)) return raw;
      if (group.isNotEmpty && _looksLikeSeatCode(raw)) return '${group}_$raw';
    }

    if (group.isNotEmpty && _looksLikeSeatCode(label)) return '${group}_$label';
    if (_looksLikeGroupedSeatCode(id)) return id;
    if (raw.isNotEmpty) return raw;
    return id;
  }

  Future<void> _bookSelectedSeats() async {
    final selectedSeats = ref.read(selectedSeatsProvider);
    final selectedBlocks = ref.read(selectedSectionBlocksProvider);

    if (selectedSeats.isEmpty && selectedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one seat.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(eventRepositoryProvider);
      final Map<String, SeatEntity> seatMap = {
        for (final s in widget.layoutData.seats) s.id: s,
      };
      final Map<String, SectionEntity> sectionMap = {
        for (final s in widget.layoutData.sections) s.id: s,
      };

      final List<Map<String, dynamic>> assigned = [];
      final List<Map<String, dynamic>> blocks = [];
      final selectedDate = ref.read(selectedDateProvider);
      String? dateOfAccess;

      if (selectedDate != null) {
        dateOfAccess = DateFormat('yyyy-MM-dd').format(selectedDate);
      } else if (widget.details.hasPerDayTickets &&
          widget.details.availableDates.isNotEmpty) {
        throw AppException('Please select a date before booking seats.');
      }

      if (widget.details.hasPerDayTickets && dateOfAccess != null) {
        final latestBooked = await repo.getBookedSeatsByDate(
          eventId: widget.eventId,
          date: selectedDate!,
        );
        final conflicts = <String>[];

        for (final seatId in selectedSeats) {
          final seat = seatMap[seatId];
          if (seat == null) continue;
          final apiSeat = _seatApiValue(seat);
          if (latestBooked.contains(apiSeat) ||
              latestBooked.contains(apiSeat.toLowerCase())) {
            conflicts.add(apiSeat);
          }
        }

        if (conflicts.isNotEmpty) {
          throw AppException(
            'These seats were just booked: ${conflicts.join(', ')}',
          );
        }
      }

      for (final seatId in selectedSeats) {
        final seat = seatMap[seatId];
        if (seat == null) continue;
        final ticket = _resolveTicketForSeat(seat);
        if (ticket == null) continue;
        final apiSeat = _seatApiValue(seat);
        assigned.add({
          'seat': apiSeat,
          'ticket_id': ticket.id,
          'ticket': ticket.name,
          'allotment': 1,
          'date_of_access': dateOfAccess,
        });
      }

      selectedBlocks.forEach((sectionId, qty) {
        if (qty <= 0) return;
        final section = sectionMap[sectionId];
        if (section == null) return;
        final ticket = _resolveTicketForSection(section);
        if (ticket == null) return;
        blocks.add({
          'block_id': section.id,
          'ticket_id': ticket.id,
          'ticket': ticket.name,
          'quantity': qty,
          'allotment': 0,
          'date_of_access': dateOfAccess,
        });
      });

      if (assigned.isEmpty && blocks.isEmpty) {
        throw AppException(
          'Could not map selections to tickets. Please contact support.',
        );
      }

      final result = await repo.bookFromMapTickets(
        assigned: assigned,
        blocks: blocks,
      );

      if (!mounted) return;

      // ── Pre-fill forced seats BEFORE navigating to checkout ──────────────
      // This keeps the just-booked seats gray during the brief re-fetch window
      // after returning from checkout, preventing them from flashing their base
      // color (blue/green) while bookedSeatsByDateProvider is still loading.
      final currentDate = ref.read(selectedDateProvider);
      if (currentDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        final allForced = Map<String, Set<String>>.from(
          ref.read(forcedBookedSeatsProvider),
        );
        final dateSet = Set<String>.from(allForced[dateKey] ?? {});
        for (final seatId in selectedSeats) {
          dateSet.add(seatId);
          dateSet.add(seatId.toLowerCase());
          // Also add just the label part (e.g. "B5" from "111_B5")
          final underscoreIdx = seatId.indexOf('_');
          if (underscoreIdx > 0 && underscoreIdx < seatId.length - 1) {
            final label = seatId.substring(underscoreIdx + 1);
            dateSet.add(label);
            dateSet.add(label.toLowerCase());
          }
        }
        allForced[dateKey] = dateSet;
        ref.read(forcedBookedSeatsProvider.notifier).state = allForced;
      }

      ref.read(selectedSeatsProvider.notifier).state = {};
      ref.read(selectedSectionBlocksProvider.notifier).state = {};

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => Checkout(orderId: result.orderId)),
      );
    } catch (e) {
      final message = e is AppException ? e.message : 'Failed to book seats.';

      if (e is SeatConflictException && e.seats.isNotEmpty) {
        // Scope conflict seats to the date that was being booked,
        // so they don't bleed into other dates.
        final selectedDate = ref.read(selectedDateProvider);
        final dateKey = selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate)
            : 'unknown';
        final allForced =
            Map<String, Set<String>>.from(ref.read(forcedBookedSeatsProvider));
        final dateSet = Set<String>.from(allForced[dateKey] ?? {});
        for (final seat in e.seats) {
          final s = seat.trim();
          if (s.isEmpty) continue;
          dateSet.add(s);
          dateSet.add(s.toLowerCase());
          final underscoreIndex = s.indexOf('_');
          if (underscoreIndex > 0 && underscoreIndex < s.length - 1) {
            final stripped = s.substring(underscoreIndex + 1);
            dateSet.add(stripped);
            dateSet.add(stripped.toLowerCase());
          }
        }
        allForced[dateKey] = dateSet;
        ref.read(forcedBookedSeatsProvider.notifier).state = allForced;
      }

      if (message.toLowerCase().contains('already booked')) {
        ref.read(selectedSeatsProvider.notifier).state = {};

        final selectedDate = ref.read(selectedDateProvider);
        if (selectedDate != null) {
          ref.invalidate(
            bookedSeatsByDateProvider((widget.eventId, selectedDate)),
          );
        }
        // ref.invalidate(seatMapFutureProvider(widget.eventId));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSeats = ref.watch(selectedSeatsProvider);
    final selectedBlocks = ref.watch(selectedSectionBlocksProvider);
    final seatMap = {for (final s in widget.layoutData.seats) s.id: s};
    final sectionMap = {for (final s in widget.layoutData.sections) s.id: s};

    int totalTickets = 0;
    double estimatedPrice = 0;

    for (final seatId in selectedSeats) {
      final seat = seatMap[seatId];
      if (seat == null) continue;
      final ticket = _resolveTicketForSeat(seat);
      if (ticket == null) continue;
      totalTickets += 1;
      estimatedPrice += ticket.price;
    }

    selectedBlocks.forEach((sectionId, qty) {
      if (qty <= 0) return;
      final section = sectionMap[sectionId];
      if (section == null) return;
      final ticket = _resolveTicketForSection(section);
      if (ticket == null) return;
      totalTickets += qty;
      estimatedPrice += ticket.price * qty;
    });

    final canSubmit = totalTickets > 0 && !_isSubmitting;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // FIXED: theme-aware background
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalTickets ${totalTickets == 1 ? 'Ticket' : 'Tickets'}',
                    style: TextStyle(
                      fontSize: 12,
                      // FIXED: theme-aware text
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estimatedPrice == 0
                        ? '${widget.details.symbol}0'
                        : '${widget.details.symbol}${estimatedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      // FIXED: theme-aware text
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Book button
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: canSubmit
                      ? LinearGradient(
                          colors: [AppColors.greenMain, AppColors.blueMain],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: canSubmit
                      ? null
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: AppColors.greenMain.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: canSubmit ? _bookSelectedSeats : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: isDark
                        ? Colors.grey[600]
                        : Colors.grey[500],
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Book Seats',
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
    );
  }
}

// ─────────────────────────────────────────────
// STANDARD LIST VIEW
// ─────────────────────────────────────────────
class _StandardListView extends ConsumerWidget {
  final TicketDetailModel details;
  final IconData categoryIcon;
  final int eventId;

  const _StandardListView({
    required this.details,
    required this.categoryIcon,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPerDayTickets = details.hasPerDayTickets;
    final hasSeasonalTickets = details.hasSeasonalPassTickets;

    if (!hasPerDayTickets && !hasSeasonalTickets) {
      return _BookingClosedView(details: details, categoryIcon: categoryIcon);
    }

    List<DateTime> upcomingDates = [];
    if (hasPerDayTickets) {
      final today = DateUtils.dateOnly(DateTime.now());
      upcomingDates = details.availableDates
          .where((eventDate) => !eventDate.isBefore(today))
          .toList();

      final selectedDate = ref.watch(selectedDateProvider);
      if (upcomingDates.isNotEmpty && selectedDate == null) {
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
                SliverToBoxAdapter(
                  child: _DateSelector(dates: upcomingDates, eventId: eventId),
                ),
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

// ─────────────────────────────────────────────
// BOOKING BOTTOM BAR — THEME AWARE
// ─────────────────────────────────────────────
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
        totalTickets > 0 && (perDayTicketSelected || selectedDate != null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // FIXED: use cardColor not hardcoded
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    totalAmount == 0
                        ? '${details.symbol}0'
                        : '${details.symbol}${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
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

// ─────────────────────────────────────────────
// EVENT HEADER — THEME AWARE
// ─────────────────────────────────────────────
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
        border: Border.all(color: Theme.of(context).dividerColor),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // FIXED: theme-aware
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.venueName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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

// ─────────────────────────────────────────────
// DATE SELECTOR — THEME AWARE
// ─────────────────────────────────────────────
class _DateSelector extends ConsumerWidget {
  final List<DateTime> dates;
  final int eventId;

  const _DateSelector({required this.dates, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dates.isEmpty) return const SizedBox.shrink();
    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Select Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
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
                  ref.read(forcedBookedSeatsProvider.notifier).state = {};  // clear all date-scoped conflicts
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 65,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    // FIXED: theme-aware
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppColors.greenMain, AppColors.blueMain],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(color: Theme.of(context).dividerColor),
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
                          fontSize: 12,
                          // FIXED: theme-aware
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodySmall?.color,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TICKET LIST & CARD — THEME AWARE
// ─────────────────────────────────────────────
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
                  : Theme.of(context).dividerColor,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // FIXED: theme-aware
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    category.price == 0
                        ? '${symbol}0'
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
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${category.available} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          IconButton(
            onPressed:
                (currentQuantity < category.maxPerOrder &&
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

// ─────────────────────────────────────────────
// REMAINING VIEWS (unchanged logic, theme fixed)
// ─────────────────────────────────────────────
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
        Icon(
          Icons.event_busy_outlined,
          size: 50,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(height: 16),
        Text(
          'Booking Closed',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(),
      ],
    );
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
        Text('Coming Soon', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
      ],
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
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/event_image.jpg').create();
      await file.writeAsBytes(response.bodyBytes);
      if (context.mounted) Navigator.of(context).pop();
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this amazing event! #events');
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share image. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final bool hasGiftcard = details.giftcards.isNotEmpty;
    var giftCard = hasGiftcard ? details.giftcards.first : null;

    String? giftCardImageUrl;
    if (giftCard != null) {
      giftCardImageUrl = giftCard.image.startsWith('http')
          ? giftCard.image
          : '$storageBaseUrl/giftcard/${giftCard.image}';
    }

    String? shareImageUrl = giftCardImageUrl;
    if (shareImageUrl == null && details.eventImage != null) {
      shareImageUrl = details.eventImage!.startsWith('http')
          ? details.eventImage!
          : '$storageBaseUrl/${details.eventImage}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasGiftcard) ...[
            Text(
              'Pre-Register & Win!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: giftCardImageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stack) => Container(
                      width: 70,
                      height: 70,
                      color: Theme.of(context).splashColor,
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
                        giftCard!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        giftCard.description,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
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
          ],
          Center(
            child: Text(
              'Spread the Word',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _launchURL(details.facebookShareUrl, context),
                  icon: const FaIcon(
                    FontAwesomeIcons.facebook,
                    color: Color(0xFF1877F2),
                  ),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      color: Color(0xFF1877F2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: Color(0xFF1877F2),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: shareImageUrl == null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No image available to share right now.',
                              ),
                            ),
                          );
                        }
                      : () => _shareToInstagram(shareImageUrl!, context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF833AB4),
                          Color(0xFFFD1D1D),
                          Color(0xFFFCAF45),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        FaIcon(FontAwesomeIcons.instagram, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

class _TicketDetailsErrorView extends ConsumerWidget {
  final Object error;
  final String slug;

  const _TicketDetailsErrorView({required this.error, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String errorText = error.toString().toLowerCase();

    IconData icon;
    Color iconColor;
    String title;
    String message;

    if (errorText.contains('sqlstate') ||
        errorText.contains('500') ||
        errorText.contains('server') ||
        errorText.contains('internal') ||
        errorText.contains('temporarily unavailable')) {
      icon = Icons.cloud_off_rounded;
      iconColor = Colors.orange;
      title = 'Server Error';
      message =
          'Tickets are temporarily unavailable due to a server issue.\n'
          'Please try again in a few moments.';
    } else if (errorText.contains('connection') ||
        errorText.contains('timeout') ||
        errorText.contains('socket') ||
        errorText.contains('internet')) {
      icon = Icons.wifi_off_rounded;
      iconColor = Colors.redAccent;
      title = 'No Connection';
      message = 'Please check your internet connection and try again.';
    } else if (errorText.contains('authentication') ||
        errorText.contains('401') ||
        errorText.contains('log in')) {
      icon = Icons.lock_outline_rounded;
      iconColor = Colors.amber;
      title = 'Session Expired';
      message = 'Please log in again to continue.';
    } else {
      icon = Icons.error_outline_rounded;
      iconColor = Colors.redAccent;
      title = 'Something Went Wrong';
      message = 'Unable to load tickets right now. Please try again.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 56, color: iconColor),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.invalidate(ticketDetailsProvider(slug)),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Go Back', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  side: BorderSide(color: Colors.grey[700]!, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEAT MAP WITH DATE-AWARE BOOKINGS
// ─────────────────────────────────────────────
class _SeatMapWithDateAwareBookings extends ConsumerWidget {
  final TicketDetailModel details;
  final SeatLayoutData layoutData;
  final int eventId;
  final IconData categoryIcon;
  final Set<String> staticBookedSeats;

  /// The date returned by the seat-map API alongside the initial booked seats.
  /// Used to (a) pre-initialize the date picker and (b) use staticBookedSeats
  /// as an accurate fallback while bookedSeatsByDateProvider is loading.
  final DateTime? apiSelectedDate;

  const _SeatMapWithDateAwareBookings({
    required this.details,
    required this.layoutData,
    required this.eventId,
    required this.categoryIcon,
    required this.staticBookedSeats,
    this.apiSelectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final forcedBookedSeatsMap = ref.watch(forcedBookedSeatsProvider);

    // ── Auto-initialize selectedDate from API on first build ──────────────
    // When the seat map loads, the API already tells us which date the booked
    // seats belong to. Pre-select that date so bookedSeatsByDateProvider fires
    // immediately instead of waiting for the user to tap a date chip.
    if (selectedDate == null &&
        apiSelectedDate != null &&
        details.hasPerDayTickets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Guard: another callback may have already set this
        if (ref.read(selectedDateProvider) != null) return;
        final availableDates = details.availableDates;
        final match = availableDates.firstWhere(
          (d) => DateUtils.isSameDay(d, apiSelectedDate!),
          orElse: () =>
              availableDates.isNotEmpty ? availableDates.first : apiSelectedDate!,
        );
        debugPrint('📅 Auto-initializing selectedDate from API: $match');
        ref.read(selectedDateProvider.notifier).state = match;
      });
    }

    // Resolve forced seats for a given date only — KEY FIX for cross-date bleed.
    // A conflict reported on Date 2 must never appear on Date 1 or Date 3.
    Set<String> forcedForDate(DateTime? date) {
      if (date == null) return {};
      final key = DateFormat('yyyy-MM-dd').format(date);
      return forcedBookedSeatsMap[key] ?? {};
    }

    // ── No per-day tickets → static + any forced for event-level ──────────
    if (!details.hasPerDayTickets) {
      return _SeatSelectionView(
        details: details,
        layoutData: layoutData,
        bookedSeats: {
          ...staticBookedSeats,
          ...forcedBookedSeatsMap.values.expand((s) => s),
        },
        categoryIcon: categoryIcon,
        eventId: eventId,
      );
    }

    // ── Has per-day tickets but no date selected yet ───────────────────────
    // Use staticBookedSeats (accurate for apiSelectedDate) as fallback
    // while the auto-init postFrameCallback hasn't fired yet.
    if (selectedDate == null) {
      return _SeatSelectionView(
        details: details,
        layoutData: layoutData,
        bookedSeats: {...staticBookedSeats},
        categoryIcon: categoryIcon,
        eventId: eventId,
      );
    }

    // ── Has per-day tickets + date selected ───────────────────────────────
    final forcedForThisDate = forcedForDate(selectedDate);
    final bookedAsync = ref.watch(
      bookedSeatsByDateProvider((eventId, selectedDate)),
    );

    // Whether the currently selected date matches the API's initial date.
    // When true, staticBookedSeats are an accurate fallback during loading.
    final isApiDate = apiSelectedDate != null &&
        DateUtils.isSameDay(selectedDate, apiSelectedDate!);

    return bookedAsync.when(
      loading: () => Stack(
        children: [
          _SeatSelectionView(
            details: details,
            layoutData: layoutData,
            // For the API date: show pre-fetched static seats (no flash of
            // "all seats available"). For other dates: only this date's forced.
            bookedSeats: isApiDate
                ? {...staticBookedSeats, ...forcedForThisDate}
                : forcedForThisDate,
            categoryIcon: categoryIcon,
            eventId: eventId,
          ),
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.7),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Refreshing seat availability...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      error: (e, s) {
        debugPrint('❌ bookedSeatsByDateProvider error: $e');
        // On error, use static seats for the API date; otherwise show only
        // runtime conflicts to avoid stale cross-date contamination.
        return _SeatSelectionView(
          details: details,
          layoutData: layoutData,
          bookedSeats: isApiDate
              ? {...staticBookedSeats, ...forcedForThisDate}
              : forcedForThisDate,
          categoryIcon: categoryIcon,
          eventId: eventId,
        );
      },
      data: (dateBookedSeats) {
        debugPrint(
          '✅ Date-specific booked seats for $selectedDate: '
          '${dateBookedSeats.length}',
        );
        // ONLY date-specific + runtime forced conflicts.
        // Do NOT merge staticBookedSeats here — the date-specific provider
        // already returned the correct set for this date.
        return _SeatSelectionView(
          details: details,
          layoutData: layoutData,
          bookedSeats: {
            ...dateBookedSeats,     // ✅ only this date's booked seats from API
            ...forcedForThisDate,   // ✅ runtime conflicts for THIS date only
          },
          categoryIcon: categoryIcon,
          eventId: eventId,
        );
      },
    );
  }
}
