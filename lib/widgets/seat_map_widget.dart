import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:kogalo_network/models/ticket_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seat_layout_model.dart';
import '../providers/seat_provider.dart';
import '../theme/apptheme.dart';

class SeatMapWidget extends ConsumerStatefulWidget {
  final SeatLayoutData layoutData;
  final Set<String> bookedSeats;
  final TicketDetailModel details;

  const SeatMapWidget({
    super.key,
    required this.layoutData,
    required this.details,
    this.bookedSeats = const {},
  });

  @override
  ConsumerState<SeatMapWidget> createState() => _SeatMapWidgetState();
}

class _SeatMapWidgetState extends ConsumerState<SeatMapWidget> {
  final TransformationController _controller = TransformationController();
  bool _isInit = false;
  double _minScale = 0.1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setupInitialZoom(BoxConstraints constraints) {
    if (_isInit) return;

    final mapW = widget.layoutData.stageWidth;
    final mapH = widget.layoutData.stageHeight;
    final screenW = constraints.maxWidth;
    final screenH = constraints.maxHeight;

    if (mapW <= 0 || mapH <= 0) return;

    final scaleX = screenW / mapW;
    final scaleY = screenH / mapH;
    final fitScale = math.min(scaleX, scaleY) * 0.92;

    final dx = (screenW - (mapW * fitScale)) / 2.0;
    final dy = (screenH - (mapH * fitScale)) / 2.0;

    _minScale = fitScale * 0.55;

    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(fitScale);

    _isInit = true;
  }

  void _handleMapTap(Offset sceneTapPosition) {
    debugPrint('🖱️ Map tapped at: $sceneTapPosition');
    debugPrint('📦 Total sections: ${widget.layoutData.sections.length}');

    // ── STEP 1: Skip seats ──
    for (final seat in widget.layoutData.seats) {
      final seatCenterX = seat.x + seat.width / 2;
      final seatCenterY = seat.y + seat.height / 2;
      final seatRect = Rect.fromCenter(
        center: Offset(seatCenterX, seatCenterY),
        width: seat.width + 8,
        height: seat.height + 8,
      );
      if (seatRect.contains(sceneTapPosition)) {
        debugPrint('🪑 Tap on seat, skipping section check');
        return;
      }
    }

    // ── STEP 2: Check sections ──
    for (final section in widget.layoutData.sections) {
      debugPrint(
        '🔍 Checking section: ${section.label} '
        'bounds: (${section.minX.toStringAsFixed(1)}, ${section.minY.toStringAsFixed(1)}) → '
        '(${section.maxX.toStringAsFixed(1)}, ${section.maxY.toStringAsFixed(1)}) '
        'polygonPoints: ${section.polygonPoints.length} '
        'ticketId: ${section.ticketId}',
      );

      if (sceneTapPosition.dx < section.minX ||
          sceneTapPosition.dx > section.maxX ||
          sceneTapPosition.dy < section.minY ||
          sceneTapPosition.dy > section.maxY) {
        debugPrint('❌ Outside AABB for ${section.label}');
        continue;
      }

      debugPrint('Inside AABB for ${section.label}, checking polygon...');

      if (section.polygonPoints.length < 4) {
        debugPrint('❌ Not enough polygon points');
        continue;
      }

      final path = Path();
      path.moveTo(section.polygonPoints[0], section.polygonPoints[1]);
      for (int i = 2; i < section.polygonPoints.length; i += 2) {
        path.lineTo(section.polygonPoints[i], section.polygonPoints[i + 1]);
      }
      path.close();

      final hit = path.contains(sceneTapPosition);
      debugPrint('🎯 Path hit test for ${section.label}: $hit');

      if (hit) {
        debugPrint('🎉 Section tapped: ${section.label}');
        _showSectionSheet(context, ref, section, widget.details);
        return;
      }
    }

    debugPrint('🚫 No section hit');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _ThemedColorMapper(isDark);

    return Container(
      color: colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _setupInitialZoom(constraints);

          // GestureDetector OUTSIDE InteractiveViewer
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final scenePoint = _controller.toScene(details.localPosition);
              debugPrint(
                '🖱️ Screen: ${details.localPosition} → Scene: $scenePoint',
              );
              _handleMapTap(scenePoint);
            },
            child: InteractiveViewer(
              transformationController: _controller,
              boundaryMargin: const EdgeInsets.all(1500),
              minScale: _minScale,
              maxScale: 5.5,
              constrained: false,
              child: SizedBox(
                width: widget.layoutData.stageWidth,
                height: widget.layoutData.stageHeight,
                child: RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SeatMapBackgroundPainter(
                            lines: widget.layoutData.lines,
                            polygons: widget.layoutData.polygons,
                            circles: widget.layoutData.circles,
                            decorationRects: widget.layoutData.decorationRects,
                            colors: colors,
                          ),
                        ),
                      ),

                      ...widget.layoutData.sections.map(
                        (section) => _SectionHighlightWidget(section: section),
                      ),

                      ...widget.layoutData.seats.map(
                        (seat) => _SingleSeatWidget(
                          seat: seat,
                          colors: colors,
                          bookedSeats: widget.bookedSeats,
                          allSeats: widget.layoutData.seats,
                        ),
                      ),

                      ...widget.layoutData.texts.map((txt) {
                        final isDarkMode =
                            Theme.of(context).brightness == Brightness.dark;

                        Color textColor;
                        final rawColor = txt.color;
                        if (rawColor == '#000' ||
                            rawColor == '#000000' ||
                            rawColor == 'black') {
                          textColor = isDarkMode
                              ? Colors.white
                              : Colors.black87;
                        } else {
                          textColor = colors.fromColorString(
                            rawColor,
                            isText: true,
                          );
                        }

                        final textWidth = (txt.width ?? 120.0).clamp(
                          20.0,
                          600.0,
                        );

                        return Positioned(
                          left: txt.x,
                          top: txt.y,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: txt.rotation,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: (txt.width ?? 120.0).clamp(20.0, 800.0),
                                child: Text(
                                  txt.text,
                                  textAlign: txt.align == 'center'
                                      ? TextAlign.center
                                      : txt.align == 'right'
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: txt.fontSize.clamp(8, 32),
                                    fontWeight: txt.isBold
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    decoration: TextDecoration.none,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 3,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                        offset: const Offset(1, 1),
                                      ),
                                      Shadow(
                                        blurRadius: 3,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                        offset: const Offset(-1, -1),
                                      ),
                                      Shadow(
                                        blurRadius: 3,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                        offset: const Offset(1, -1),
                                      ),
                                      Shadow(
                                        blurRadius: 3,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                        offset: const Offset(-1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SingleSeatWidget extends ConsumerWidget {
  final SeatEntity seat;
  final _ThemedColorMapper colors;
  final Set<String> bookedSeats;
  // ── NEW: all seats in layout so we can count per-group selections ──
  final List<SeatEntity> allSeats;

  const _SingleSeatWidget({
    required this.seat,
    required this.colors,
    required this.bookedSeats,
    required this.allSeats, // ← NEW
  });

  bool _isBooked() {
    if (!seat.isAvailable) return true;
    if (bookedSeats.isEmpty) return false;

    final candidates = <String>{};
    candidates.add(seat.id);
    candidates.add(seat.id.toLowerCase());

    if (seat.label.isNotEmpty) {
      candidates.add(seat.label);
      candidates.add(seat.label.toLowerCase());
    }

    if (seat.rawId != null && seat.rawId!.isNotEmpty) {
      candidates.add(seat.rawId!);
      candidates.add(seat.rawId!.toLowerCase());

      final m = RegExp(r'([A-Za-z]+\d+)').firstMatch(seat.rawId!);
      if (m != null) {
        candidates.add(m.group(1)!);
        candidates.add(m.group(1)!.toLowerCase());
      }
    }

    if (seat.groupId != null && seat.groupId!.isNotEmpty) {
      final gid = seat.groupId!;
      candidates.add('${gid}_${seat.label}');
      candidates.add('${gid}_${seat.label.toLowerCase()}');
      if (seat.rawId != null && seat.rawId!.isNotEmpty) {
        candidates.add('${gid}_${seat.rawId!}');
        candidates.add('${gid}_${seat.rawId!.toLowerCase()}');
      }
    }

    if (seat.section.isNotEmpty) {
      candidates.add('${seat.section}_${seat.label}');
      candidates.add('${seat.section}-${seat.label}');
    }

    return candidates.any((c) => bookedSeats.contains(c));
  }

  /// How many seats from the same group are currently selected
  int _selectedInGroup(Set<String> currentSeats) {
    if (seat.groupId == null || seat.groupId!.isEmpty) return 0;
    return currentSeats.where((selectedId) {
      // Match seats with same groupId prefix
      return selectedId.startsWith('${seat.groupId}_') ||
          allSeats.any((s) => s.id == selectedId && s.groupId == seat.groupId);
    }).length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSeats = ref.watch(selectedSeatsProvider);
    final isSelected = selectedSeats.contains(seat.id);
    final isAlreadyBooked = _isBooked();

    // ── Group limit check ──
    final groupLimit = seat.groupLimit;
    final hasGroupLimit = groupLimit != null && groupLimit > 0;
    final selectedCountInGroup = hasGroupLimit
        ? _selectedInGroup(selectedSeats)
        : 0;
    final isGroupLimitReached =
        hasGroupLimit &&
        !isSelected && // don't lock already-selected seats
        selectedCountInGroup >= groupLimit!;

    final baseColor = colors.fromColorString(seat.color);
    final bg = isAlreadyBooked
        ? Colors.grey.shade500
        : isGroupLimitReached
        ? Colors
              .grey
              .shade400 // ← slightly different shade for limit-reached
        : isSelected
        ? AppTheme.primaryPink
        : baseColor;

    final txt = isAlreadyBooked || isSelected || isGroupLimitReached
        ? Colors.white
        : colors.getContrast(bg);

    final isCircle =
        seat.shape == 'circle' || (seat.width - seat.height).abs() <= 2;

    final borderColor = isAlreadyBooked
        ? Colors.grey.shade700
        : isGroupLimitReached
        ? Colors.grey.shade500
        : isSelected
        ? Colors.white
        : bg.withValues(alpha: 0.85);

    return Positioned(
      left: seat.x,
      top: seat.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isAlreadyBooked
            ? () => _showBookedSnackBar(context)
            : isGroupLimitReached
            ? () => _showGroupLimitSnackBar(context, groupLimit!)
            : () => SeatSelectionController(ref, context).toggleSeat(seat.id),
        child: Transform.rotate(
          angle: seat.rotation,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: seat.width,
            height: seat.height,
            decoration: BoxDecoration(
              color: bg,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle
                  ? null
                  : BorderRadius.circular(seat.width * 0.18),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.45),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : isGroupLimitReached
                  ? [] // no shadow when limit reached
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: seat.width > 12
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          seat.label,
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.w700,
                            fontSize: seat.width > 20 ? 11 : 9,
                            decoration: TextDecoration.none,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _showBookedSnackBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.block_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Seat ${seat.label} is already booked',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showGroupLimitSnackBar(BuildContext context, int limit) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You can only select $limit seat${limit == 1 ? '' : 's'} '
                'from "${seat.section}" section.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2000),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _SectionHighlightWidget extends ConsumerWidget {
  final SectionEntity section;
  const _SectionHighlightWidget({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
      selectedSectionBlocksProvider.select((m) => m[section.id] ?? 0),
    );

    if (qty == 0) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _SectionHighlighter(section.polygonPoints)),
      ),
    );
  }
}

class _SectionHighlighter extends CustomPainter {
  final List<double> points;
  _SectionHighlighter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 4) return;

    final path = Path()..moveTo(points[0], points[1]);
    for (int i = 2; i < points.length; i += 2) {
      path.lineTo(points[i], points[i + 1]);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryPink.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.primaryPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SectionHighlighter oldDelegate) => false;
}

class _SeatMapBackgroundPainter extends CustomPainter {
  final List<DecorationLine> lines;
  final List<DecorationPolygon> polygons;
  final List<DecorationCircle> circles;
  final List<DecorationRect> decorationRects;
  final _ThemedColorMapper colors;

  _SeatMapBackgroundPainter({
    required this.lines,
    required this.polygons,
    required this.circles,
    required this.decorationRects,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()..style = PaintingStyle.stroke;

    for (final poly in polygons) {
      if (poly.points.length < 4) continue;

      final path = Path()..moveTo(poly.points[0], poly.points[1]);
      for (int i = 2; i < poly.points.length; i += 2) {
        path.lineTo(poly.points[i], poly.points[i + 1]);
      }
      path.close();

      canvas.drawPath(
        path,
        fillPaint..color = colors.fromColorString(poly.fill),
      );
      if (poly.strokeWidth > 0) {
        canvas.drawPath(
          path,
          strokePaint
            ..color = colors.fromColorString(poly.stroke)
            ..strokeWidth = poly.strokeWidth,
        );
      }
    }

    for (final rect in decorationRects) {
      final rectBox = Rect.fromLTWH(rect.x, rect.y, rect.width, rect.height);
      final rRect = RRect.fromRectAndRadius(
        rectBox,
        Radius.circular(rect.cornerRadius),
      );

      canvas.save();
      canvas.translate(rect.x + rect.width / 2, rect.y + rect.height / 2);
      canvas.rotate(rect.rotation);
      canvas.translate(-(rect.x + rect.width / 2), -(rect.y + rect.height / 2));

      canvas.drawRRect(
        rRect,
        fillPaint..color = colors.fromColorString(rect.color),
      );
      canvas.drawRRect(
        rRect,
        strokePaint
          ..color = colors.border
          ..strokeWidth = 1,
      );

      canvas.restore();
    }

    for (final c in circles) {
      canvas.drawCircle(
        Offset(c.x, c.y),
        c.radius,
        fillPaint..color = colors.fromColorString(c.fill),
      );

      if (c.strokeWidth > 0) {
        canvas.drawCircle(
          Offset(c.x, c.y),
          c.radius,
          strokePaint
            ..color = colors.fromColorString(c.stroke)
            ..strokeWidth = c.strokeWidth,
        );
      }
    }

    final linePaint = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;

    for (final line in lines) {
      if (line.points.length >= 4) {
        canvas.drawLine(
          Offset(line.points[0], line.points[1]),
          Offset(line.points[2], line.points[3]),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeatMapBackgroundPainter oldDelegate) => false;
}

class _ThemedColorMapper {
  final bool isDark;
  _ThemedColorMapper(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF111214) : const Color(0xFFF6F7F9);

  Color get gridLine => Colors.transparent;

  Color get border => isDark ? Colors.white24 : Colors.black12;

  Color fromColorString(String value, {bool isText = false}) {
    if (value.isEmpty) {
      return isText ? (isDark ? Colors.white : Colors.black) : Colors.grey;
    }

    final input = value.trim();

    final rgbaMatch = RegExp(
      r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)',
      caseSensitive: false,
    ).firstMatch(input);

    if (rgbaMatch != null) {
      final r = double.tryParse(rgbaMatch.group(1) ?? '0') ?? 0;
      final g = double.tryParse(rgbaMatch.group(2) ?? '0') ?? 0;
      final b = double.tryParse(rgbaMatch.group(3) ?? '0') ?? 0;
      final a = double.tryParse(rgbaMatch.group(4) ?? '1') ?? 1;

      final color = Color.fromRGBO(
        r.clamp(0, 255).toInt(),
        g.clamp(0, 255).toInt(),
        b.clamp(0, 255).toInt(),
        a.clamp(0.0, 1.0),
      );

      if (isText && color.opacity < 0.25) {
        return isDark ? Colors.white : Colors.black;
      }

      if (isDark && isText && color.computeLuminance() < 0.15) {
        return Colors.white;
      }

      return color;
    }

    String hex = input.replaceAll('#', '');
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length == 6) hex = 'FF$hex';

    try {
      final color = Color(int.parse('0x$hex'));
      if (isDark && isText && color.computeLuminance() < 0.15) {
        return Colors.white;
      }
      return color;
    } catch (_) {
      return isText ? (isDark ? Colors.white : Colors.black) : Colors.grey;
    }
  }

  Color getContrast(Color bg) =>
      bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

void _showSectionSheet(
  BuildContext context,
  WidgetRef ref,
  SectionEntity section,
  TicketDetailModel details,
) {
  // ── Ticket resolution ──
  final allTickets = details.tickets;
  final ticketsById = {for (final t in allTickets) t.id: t};
  final ticketsByName = {
    for (final t in allTickets) t.name.trim().toLowerCase(): t,
  };

  TicketCategoryModel? ticket;

  // 1. Direct ID match
  if (section.ticketId != null) {
    ticket = ticketsById[section.ticketId];
  }

  // 2. Name match fallback
  if (ticket == null) {
    final key = section.label.trim().toLowerCase();
    ticket = ticketsByName[key];
    if (ticket == null) {
      for (final entry in ticketsByName.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          ticket = entry.value;
          break;
        }
      }
    }
  }

  if (ticket == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No ticket found for "${section.label}" section.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final sectionTotalCapacity = section.capacity > 0 ? section.capacity : 999;
  final ticketMaxPerOrder = section.maxSale > 0 ? section.maxSale : 10;
  final maxAllowedForSection = ticketMaxPerOrder.clamp(1, 10);
  final symbol = details.symbol;
  final selectedBlocks = ref.read(selectedSectionBlocksProvider);
  final initialQty = selectedBlocks[section.id] ?? 0;
  final sectionColor = _parseHexColor(section.color);

  int tempQty = initialQty;
  String? errorMessage;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          void setError(String? msg) => setState(() => errorMessage = msg);

          bool canIncrease() {
            final totalCart = ref.read(totalCartCountProvider);
            final currentNet = totalCart - initialQty + tempQty;

            if (currentNet >= 10) {
              setError("Max 10 tickets total allowed.");
              return false;
            }
            if (tempQty >= maxAllowedForSection) {
              setError("Max $maxAllowedForSection tickets for this section.");
              return false;
            }
            if (tempQty >= sectionTotalCapacity) {
              setError("This section is sold out.");
              return false;
            }
            if (errorMessage != null) setError(null);
            return true;
          }

          final totalPrice = ticket!.price * tempQty;
          final isFree = ticket.price == 0;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Handle bar ──
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    // ── Section color banner ──
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sectionColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sectionColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color dot
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: sectionColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_seat_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(ctx).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ticket.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(ctx).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : AppTheme.primaryPink.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFree
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : AppTheme.primaryPink.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isFree
                                  ? 'FREE'
                                  : '$symbol${ticket.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? Colors.green
                                    : AppTheme.primaryPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Info row ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _InfoChip(
                            icon: Icons.people_rounded,
                            label: '${section.capacity} capacity',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.confirmation_number_rounded,
                            label: 'Max $maxAllowedForSection/order',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Quantity selector ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Theme.of(ctx).dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Minus
                                _QtyButton(
                                  icon: Icons.remove,
                                  enabled: tempQty > 0,
                                  onTap: () {
                                    setState(() {
                                      tempQty--;
                                      errorMessage = null;
                                    });
                                  },
                                ),
                                // Count
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '$tempQty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(ctx).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                // Plus
                                _QtyButton(
                                  icon: Icons.add,
                                  enabled: true,
                                  onTap: () {
                                    if (canIncrease()) {
                                      setState(() => tempQty++);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Error message ──
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Price summary + Apply button ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Price total
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$tempQty ${tempQty == 1 ? 'ticket' : 'tickets'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(ctx).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFree
                                      ? 'Free'
                                      : '$symbol${totalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isFree ? Colors.green : Theme.of(ctx).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Apply button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: tempQty == 0 && initialQty == 0
                                  ? null
                                  : () {
                                      final map = Map<String, int>.from(
                                        ref.read(selectedSectionBlocksProvider),
                                      );
                                      if (tempQty <= 0) {
                                        map.remove(section.id);
                                      } else {
                                        map[section.id] = tempQty;
                                      }
                                      ref
                                              .read(
                                                selectedSectionBlocksProvider
                                                    .notifier,
                                              )
                                              .state =
                                          map;
                                      Navigator.of(ctx).pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPink,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                tempQty == 0 && initialQty > 0
                                    ? 'Remove'
                                    : 'Add to Cart',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Helper: parse hex color safely ──
Color _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppTheme.primaryPink;
  try {
    String h = hex.replaceAll('#', '');
    if (h.length == 3) {
      h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
    }
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse('0x$h'));
  } catch (_) {
    return AppTheme.primaryPink;
  }
}

// ── Info chip widget ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantity button ──
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppTheme.primaryPink.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.primaryPink : Colors.grey[700],
        ),
      ),
    );
  }
}
