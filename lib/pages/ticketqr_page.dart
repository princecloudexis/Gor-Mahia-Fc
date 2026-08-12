import 'package:gormahiafc/models/ticket_holder_model.dart';
import 'package:gormahiafc/providers/event_providers.dart';
import 'package:gormahiafc/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

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

class TicketQrPage extends ConsumerStatefulWidget {
  final int eventId;
  const TicketQrPage({super.key, required this.eventId});

  @override
  ConsumerState<TicketQrPage> createState() => _TicketQrPageState();
}

class _TicketQrPageState extends ConsumerState<TicketQrPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdersAsync = ref.watch(ticketHolderDetailsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Your Ticket')),
      body: holdersAsync.when(
        loading: () => const _QrPageShimmer(),
        error: (err, _) => Center(child: Text('Error: ${err.toString()}')),
        data: (detailsList) {
          final allHolders = detailsList
              .expand((detail) => detail.holders)
              .toList();

          if (allHolders.isEmpty) {
            return const Center(child: Text('No ticket details found.'));
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: allHolders.length,
                  itemBuilder: (context, index) {
                    return _QrCodeTicketView(holder: allHolders[index]);
                  },
                ),
              ),
              if (allHolders.length > 1) ...[
                const SizedBox(height: 16),
                _PageIndicator(
                  itemCount: allHolders.length,
                  currentIndex: _currentPage,
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _QrCodeTicketView extends StatelessWidget {
  final TicketHolder holder;
  const _QrCodeTicketView({required this.holder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrBytes = holder.qrCodeBytes;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child:
          Column(
                children: [
                  ClipPath(
                    clipper: TicketTopClipper(),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(color: theme.shadowColor, blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            holder.eventName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                holder.isSeasonalPass
                                    ? Icons.all_inclusive_rounded
                                    : Icons.local_activity_outlined,
                                size: 18,
                                color: AppTheme.primaryPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                holder.isSeasonalPass
                                    ? 'SEASONAL PASS'
                                    : 'DAY PASS',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            holder.displayDateString,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipPath(
                    clipper: TicketBottomClipper(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(color: theme.shadowColor, blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        children: [
                          CustomPaint(
                            painter: DashedLinePainter(
                              color: theme.dividerColor,
                            ),
                            child: const SizedBox(
                              width: double.infinity,
                              height: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.memory(
                              qrBytes,
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scan this code at the venue entrance',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(holder.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            holder.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                          ),

                          if (holder.seatLabel != null &&
                              holder.seatLabel!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryPurple.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Seat: ${holder.seatLabel}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _PageIndicator({required this.itemCount, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isSelected = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSelected ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryPink
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _QrPageShimmer extends StatelessWidget {
  const _QrPageShimmer();

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
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            ClipPath(
              clipper: TicketTopClipper(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor),
                child: Column(
                  children: [
                    Container(
                      width: 250,
                      height: 32,
                      decoration: placeholderDecoration,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 20,
                      decoration: placeholderDecoration,
                    ),
                  ],
                ),
              ),
            ),
            ClipPath(
              clipper: TicketBottomClipper(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(color: cardColor),
                child: Column(
                  children: [
                    CustomPaint(
                      painter: DashedLinePainter(color: theme.dividerColor),
                      child: const SizedBox(width: double.infinity, height: 20),
                    ),
                    Container(
                      width: 244,
                      height: 244,
                      decoration: BoxDecoration(
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 220,
                      height: 16,
                      decoration: placeholderDecoration,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 160,
                      height: 24,
                      decoration: placeholderDecoration,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 16,
                      decoration: placeholderDecoration,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
