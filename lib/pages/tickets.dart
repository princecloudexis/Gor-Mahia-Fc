import 'package:cached_network_image/cached_network_image.dart';
import 'package:kogalo_network/api/api_client.dart';
import 'package:kogalo_network/models/user_ticket_model.dart';
import 'package:kogalo_network/pages/details.dart';
import 'package:kogalo_network/pages/ticketqr_page.dart';
import 'package:kogalo_network/providers/event_providers.dart';
import 'package:kogalo_network/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

enum TicketType { upcoming, past }

class Tickets extends ConsumerStatefulWidget {
  const Tickets({super.key});

  @override
  ConsumerState<Tickets> createState() => _TicketsState();
}

class _TicketsState extends ConsumerState<Tickets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                'Your Tickets',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              iconTheme: IconThemeData(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              surfaceTintColor: Colors.transparent,
              shadowColor: Theme.of(context).shadowColor,
              elevation: innerBoxIsScrolled ? 4 : 0,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryPink,
                labelColor: AppTheme.primaryPink,
                unselectedLabelColor: AppTheme.textLight,
                labelStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: Theme.of(context).textTheme.bodyLarge,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _TicketList(type: TicketType.upcoming),
            _TicketList(type: TicketType.past),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends ConsumerWidget {
  final TicketType type;
  const _TicketList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider(type.name));

    return ticketsAsync.when(
      loading: () => const _TicketListShimmer(),
      // error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.redAccent.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load tickets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(ticketsProvider(type.name));
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (tickets) {
        if (tickets.isEmpty) {
          return _EmptyState(type: type);
        }
        final sortedTickets = List<UserTicketModel>.from(tickets)
          ..sort((a, b) {
            final dateA = a.event.eventStartDate;
            final dateB = b.event.eventStartDate;
            if (dateA == null || dateB == null) return 0;
            return (type == TicketType.upcoming)
                ? dateA.compareTo(dateB)
                : dateB.compareTo(dateA);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedTickets.length,
          itemBuilder: (context, index) {
            return _TicketCard(ticket: sortedTickets[index], index: index)
                .animate()
                .fadeIn(duration: 400.ms, delay: (100 * (index % 10)).ms)
                .slideY(begin: 0.2, end: 0);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TicketType type;
  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = type == TicketType.upcoming;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming
                  ? Icons.confirmation_number_outlined
                  : Icons.history_rounded,
              size: 52,
              color: theme.textTheme.bodySmall?.color ?? theme.dividerColor,
            ),
            const SizedBox(height: 14),
            Text(
              isUpcoming ? 'No Upcoming Tickets' : 'No Past Tickets',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'When you buy a ticket for a match, it will show up here.'
                  : 'Matches you have attended will appear in this list.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final UserTicketModel ticket;
  final int index;
  const _TicketCard({required this.ticket, required this.index});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eventStart = ticket.event.eventStartDate;
    final eventEnd = ticket.event.eventEndDate;
    final eventStartDay = eventStart != null
        ? DateUtils.dateOnly(eventStart)
        : null;
    final eventEndDay = eventEnd != null
        ? DateUtils.dateOnly(eventEnd)
        : (eventStart != null ? DateUtils.dateOnly(eventStart) : null);
    final today = DateUtils.dateOnly(now);

    // Show QR for future + ongoing events (including same-day events).
    final canViewTicket = eventEndDay != null
        ? !eventEndDay.isBefore(today)
        : (eventStartDay != null ? !eventStartDay.isBefore(today) : false);

    return GestureDetector(
      onTap: () {
        if (ticket.event.slug != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetails(slug: ticket.event.slug!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _TicketImageHeader(ticket: ticket),
            _TicketDetailsSection(ticket: ticket, canViewTicket: canViewTicket),
          ],
        ),
      ),
    );
  }
}

class _TicketImageHeader extends ConsumerWidget {
  final UserTicketModel ticket;
  const _TicketImageHeader({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);
    final imageUrl = ticket.event.getFullImageUrl(storageBaseUrl);
    final theme = Theme.of(context);

    return ClipPath(
      clipper: TicketTopClipper(),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.image_not_supported)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  stops: const [0.0, 0.7],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Text(
                ticket.event.eventName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailsSection extends StatelessWidget {
  final UserTicketModel ticket;
  final bool canViewTicket;
  const _TicketDetailsSection({
    required this.ticket,
    required this.canViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = ticket.event.eventStartDate != null
        ? DateFormat('E, MMM d, yyyy').format(ticket.event.eventStartDate!)
        : 'Date TBD';
    final formattedTime = ticket.event.eventStartDate != null
        ? DateFormat('h:mm a').format(ticket.event.eventStartDate!)
        : 'Time TBD';
    Widget viewTicketButton = Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketQrPage(eventId: ticket.eventId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text('View Ticket', style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );

    return ClipPath(
      clipper: TicketBottomClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _TicketInfo(
                      icon: Icons.calendar_today_outlined,
                      text: formattedDate,
                    ),
                  ),
                  const VerticalDivider(width: 24),
                  Expanded(
                    child: _TicketInfo(
                      icon: Icons.access_time_outlined,
                      text: formattedTime,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _TicketInfo(
              icon: Icons.location_on_outlined,
              text: ticket.event.displayLocationString,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: _DashedLine(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: _TicketInfo(
                    icon: Icons.confirmation_number_outlined,
                    text:
                        '${ticket.totalQuantity} Ticket${ticket.totalQuantity > 1 ? 's' : ''}',
                  ),
                ),
                if (canViewTicket) viewTicketButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TicketInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedLinePainter(color: Theme.of(context).dividerColor),
      child: const SizedBox(width: double.infinity, height: 1),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicketTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 15)
      ..arcToPoint(
        Offset(size.width - 15, size.height),
        radius: const Radius.circular(15),
        clockwise: false,
      )
      ..lineTo(15, size.height)
      ..arcToPoint(
        Offset(0, size.height - 15),
        radius: const Radius.circular(15),
        clockwise: false,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TicketBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 15)
      ..arcToPoint(
        const Offset(15, 0),
        radius: const Radius.circular(15),
        clockwise: false,
      )
      ..lineTo(size.width - 15, 0)
      ..arcToPoint(
        Offset(size.width, 15),
        radius: const Radius.circular(15),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _TicketListShimmer extends StatelessWidget {
  const _TicketListShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final placeholderColor = theme.splashColor;

    final placeholderDecoration = BoxDecoration(
      color: placeholderColor,
      borderRadius: BorderRadius.circular(8),
    );

    return Shimmer(
      color: theme.shadowColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                ClipPath(
                  clipper: TicketTopClipper(),
                  child: Container(
                    height: 160,
                    color: cardColor,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 28,
                            decoration: placeholderDecoration,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ClipPath(
                  clipper: TicketBottomClipper(),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    color: cardColor,
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              const Expanded(child: _ShimmerInfoLine()),
                              const VerticalDivider(width: 24),
                              const Expanded(child: _ShimmerInfoLine()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _ShimmerInfoLine(textWidth: 200),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: _DashedLine(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _ShimmerInfoLine(textWidth: 100),
                            Container(
                              width: 130,
                              height: 40,
                              decoration: placeholderDecoration,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerInfoLine extends StatelessWidget {
  final double textWidth;
  const _ShimmerInfoLine({this.textWidth = 120});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).splashColor;

    final placeholderDecoration = BoxDecoration(
      color: placeholderColor,
      borderRadius: BorderRadius.circular(8),
    );

    return Row(
      children: [
        Container(height: 18, width: 18, decoration: placeholderDecoration),
        const SizedBox(width: 8),
        Container(
          height: 16,
          width: textWidth,
          decoration: placeholderDecoration,
        ),
      ],
    );
  }
}
