import 'dart:ui';
import 'package:gormahiafc/providers/categoryevents_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gormahiafc/api/api_client.dart';
import 'package:gormahiafc/pages/booking.dart';
import 'package:gormahiafc/pages/login.dart';
import 'package:gormahiafc/providers/location_providers.dart';
import 'package:gormahiafc/providers/seat_provider.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
import '../providers/event_providers.dart';
import '../theme/apptheme.dart';

class EventDetails extends ConsumerWidget {
  final String slug;
  const EventDetails({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: locationAsync.when(
        loading: () => const _DetailsShimmer(),
        error: (err, _) => Center(child: Text('Unexpected Error: $err')),
        data: (location) {
          final lat = location.latitude ?? 0.0;
          final lng = location.longitude ?? 0.0;

          final params = (slug: slug, lat: lat, lng: lng);

          final eventAsync = ref.watch(eventDetailsProvider(params));

          return eventAsync.when(
            loading: () => const _DetailsShimmer(),
            error: (err, _) => Center(child: Text('Error loading event: $err')),
            data: (event) => _EventDetailsView(event: event),
          );
        },
      ),
    );
  }
}

class _EventDetailsView extends ConsumerWidget {
  final EventModel event;
  const _EventDetailsView({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _EventSliverAppBar(event: event),
            _EventContentSheet(event: event),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        _BookingBottomBar(event: event),
      ],
    );
  }
}

class _EventSliverAppBar extends ConsumerWidget {
  final EventModel event;
  const _EventSliverAppBar({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final imageUrl = event.getFullImageUrl(storageBaseUrl);

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _GlassIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.pop(context),
        backgroundColor: Colors.black.withOpacity(0.4),
      ),
      actions: [
        _FavoriteButton(event: event),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              imageBuilder: (context, imageProvider) => Hero(
                tag: 'event_image_${event.id}',
                child: Image(image: imageProvider, fit: BoxFit.cover),
              ),
              fadeInDuration: 200.ms,
              placeholder: (_, __) => Container(color: Colors.grey.shade300),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventContentSheet extends StatelessWidget {
  final EventModel event;
  const _EventContentSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventTitleSection(event: event),
            const SizedBox(height: 24),
            _InfoPillsLayout(event: event),
            if ((event.eventDescription ?? '').trim().isNotEmpty)
              _ExpandableEventDescription(htmlContent: event.eventDescription!),
            // if (event.tags.isNotEmpty)
            //   _ContentSection(
            //     title: 'Tags',
            //     delay: 600.ms,
            //     child: Wrap(
            //       spacing: 10.0,
            //       runSpacing: 10.0,
            //       children: event.tags
            //           .where((t) => t.trim().isNotEmpty)
            //           .map(
            //             (tag) => Chip(
            //               label: Text(tag),
            //               backgroundColor: Theme.of(context).cardColor,
            //               labelStyle: TextStyle(
            //                 color: Theme.of(context).textTheme.bodyLarge?.color,
            //               ),
            //               side: BorderSide(
            //                 color: Theme.of(
            //                   context,
            //                 ).colorScheme.onSurface.withOpacity(0.1),
            //               ),
            //             ),
            //           )
            //           .toList(),
            //     ),
            //   ),
            if (event.shouldShowMap)
              _MapSection(event: event)
            else if (!event.hideVenueFromUser)
              _MapUnavailableSection(),
          ],
        ),
      ),
    );
  }
}

class _EventTitleSection extends StatelessWidget {
  final EventModel event;
  const _EventTitleSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.eventName,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.tag_outlined, text: event.tags.join(', ')),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_2_outlined,
            text: event.creatorName ?? 'N/A',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
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
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoPillsLayout extends StatelessWidget {
  final EventModel event;
  const _InfoPillsLayout({required this.event});

  @override
  Widget build(BuildContext context) {
    final pills = [
      _InfoPill(
        icon: Icons.calendar_today_outlined,
        label: 'Date',
        value: _formatDateRange(event.eventStartDate, event.eventEndDate),
      ),

      _InfoPill(
        icon: Icons.timelapse_rounded,
        label: 'Time',
        value: _formatTimeRange(event.eventStartDate, event.eventEndDate),
      ),
      _InfoPill(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: event.displayLocationString,
      ),
    ];

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: pills[0]),
                  const SizedBox(width: 12),
                  Expanded(child: pills[1]),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: pills[2]),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.shadowColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const Spacer(),
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// class _AttendeesSection extends StatelessWidget {
//   const _AttendeesSection();

//   @override
//   Widget build(BuildContext context) {
//     return _ContentSection(
//       title: '24 Friends Going',
//       delay: 400.ms,
//       child: SizedBox(
//         height: 50,
//         child: Stack(
//           children: List.generate(5, (index) {
//             return Positioned(
//               left: index * 35.0,
//               child: _AttendeeAvatar(
//                 imageUrl: 'https://i.pravatar.cc/150?img=${index + 10}',
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }
// }

// class _AttendeeAvatar extends StatelessWidget {
//   final String imageUrl;
//   const _AttendeeAvatar({required this.imageUrl});
//   @override
//   Widget build(BuildContext context) {
//     return CircleAvatar(
//       radius: 25,
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       child: CircleAvatar(
//         radius: 22,
//         backgroundImage: CachedNetworkImageProvider(imageUrl),
//       ),
//     );
//   }
// }

class _BookingBottomBar extends ConsumerWidget {
  final EventModel event;
  const _BookingBottomBar({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    void onBookTap() {
      if (user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } else {
        ref.read(seatMapFutureProvider(event.id));
        ref.read(ticketDetailsProvider(event.slug!));
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Booking(
              event: event,
              categoryIcon: Icons.confirmation_number_outlined,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          ),
        );
      }
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).shadowColor.withOpacity(0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                children: [
                  // ── Price ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Price',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatPrice(event.ticketPrice, event.currencySymbol),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // ── Book Button (FIXED) ──
                  Expanded(
                    child: GestureDetector(
                      onTap: onBookTap,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Book Tickets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    ).animate().slideY(
      begin: 1.5,
      end: 0,
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }
}

class _DetailsShimmer extends StatelessWidget {
  const _DetailsShimmer();

  Widget _buildShimmerBox({
    double? width,
    required double height,
    double radius = 16,
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
    final theme = Theme.of(context);
    return Shimmer(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                backgroundColor: theme.scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(color: theme.highlightColor),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildShimmerBox(
                          width: 280,
                          height: 32,
                          radius: 8,
                          context: context,
                        ),
                        const SizedBox(height: 16),
                        _buildShimmerBox(
                          width: 220,
                          height: 16,
                          radius: 8,
                          context: context,
                        ),
                        const SizedBox(height: 12),
                        _buildShimmerBox(
                          width: 250,
                          height: 16,
                          radius: 8,
                          context: context,
                        ),
                        const SizedBox(height: 32),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildShimmerBox(
                                    height: 90,
                                    context: context,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildShimmerBox(
                                    height: 90,
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildShimmerBox(height: 90, context: context),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildShimmerBox(
                          width: 150,
                          height: 24,
                          radius: 8,
                          context: context,
                        ),
                        const SizedBox(height: 16),
                        _buildShimmerBox(height: 100, context: context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  final EventModel event;
  const _MapSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(event.latitude ?? '');
    final lng = double.tryParse(event.longitude ?? '');
    if (lat == null || lng == null) return _MapUnavailableSection();
    final eventPosition = LatLng(lat, lng);
    return _ContentSection(
      title: 'Location Map',
      delay: 400.ms,
      trailing: GestureDetector(
        onTap: () => _launchMaps(context, event),
        child: Row(
          children: [
            Text(
              'Open Map',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AbsorbPointer(
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: eventPosition,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(event.id.toString()),
                  position: eventPosition,
                  infoWindow: InfoWindow(title: event.venueName),
                ),
              },
              // liteModeEnabled: true,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Duration delay;
  const _ContentSection({
    required this.title,
    required this.child,
    this.trailing,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: delay).slideY(begin: 0.1);
  }
}

class _FavoriteButton extends ConsumerWidget {
  final EventModel event;
  const _FavoriteButton({required this.event});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(event.id));
    return _GlassIconButton(
      onTap: () async {
        try {
          await ref.read(favoritesProvider.notifier).toggleFavorite(event);
        } catch (e) {
          if (!context.mounted) return;
          if (e.toString().contains('User is not logged in')) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const Login()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not update favorite status.'),
              ),
            );
          }
        }
      },
      icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: isFavorite ? AppTheme.accentRed : Colors.white,
      backgroundColor: Colors.black.withOpacity(0.4),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final Color? backgroundColor;
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color ?? Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapUnavailableSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ContentSection(
      title: 'Location',
      delay: 400.ms,
      child: Row(
        children: [
          Icon(
            Icons.map_outlined,
            color: Theme.of(context).hintColor,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'A specific map for this location is not available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableEventDescription extends StatefulWidget {
  final String htmlContent;

  const _ExpandableEventDescription({super.key, required this.htmlContent});

  @override
  State<_ExpandableEventDescription> createState() =>
      _ExpandableEventDescriptionState();
}

class _ExpandableEventDescriptionState
    extends State<_ExpandableEventDescription> {
  bool _isExpanded = false;

  late final String plainText;

  @override
  void initState() {
    super.initState();
    plainText = _stripHtmlTags(widget.htmlContent).trim();
  }

  String _stripHtmlTags(String htmlText) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      fontSize: 16,
    );

    return _ContentSection(
      title: 'About Match',
      delay: 500.ms,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: _isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 120),
              child: Text(
                plainText,
                softWrap: true,
                overflow: TextOverflow.fade,
                style: textStyle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Show Less' : 'Show More',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null) return 'Date TBD';
  return DateFormat('E, MMM d, yyyy').format(start);
}

String _formatTimeRange(DateTime? start, DateTime? end) {
  if (start == null) return 'Time TBD';
  final fmt = DateFormat('h:mm a');
  return fmt.format(start);
}

String _formatPrice(double? price, String? symbol) {
  if (price == null || price <= 0) return 'Free';
  final formatted = NumberFormat('#,##0').format(price);
  return '${symbol ?? 'KSh '}$formatted';
}

Future<void> _launchMaps(BuildContext context, EventModel event) async {
  final lat = event.latitude;
  final lng = event.longitude;
  if (lat == null || lng == null) return;
  final query = Uri.encodeComponent('${event.venueName}, ${event.city}');
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$query',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map application.')),
      );
    }
  }
}
