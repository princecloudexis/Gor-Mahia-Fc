import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventsbooking/repositories/event_repositories.dart';
import '../models/seat_layout_model.dart';

final selectedSeatsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);

final selectedSectionBlocksProvider =
    StateProvider.autoDispose<Map<String, int>>((ref) => {});

final totalCartCountProvider = Provider.autoDispose<int>((ref) {
  final seats = ref.watch(selectedSeatsProvider).length;
  final blocks = ref
      .watch(selectedSectionBlocksProvider)
      .values
      .fold<int>(0, (sum, qty) => sum + qty);
  return seats + blocks;
});

final seatMapFutureProvider = FutureProvider.family<Map<String, dynamic>?, int>(
  (ref, eventId) async {
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), () => link.close());

    final repo = ref.watch(eventRepositoryProvider);
    debugPrint("🚀 [Network] Fetching Seat Map for Event ID: $eventId");
    return repo.getSeatMap(eventId);
  },
);

final seatLayoutParserProvider =
    FutureProvider.family<SeatLayoutData?, dynamic>((ref, rawInput) async {
      if (rawInput == null) return null;

      final link = ref.keepAlive();
      Timer(const Duration(minutes: 5), () => link.close());

      return await compute(_parseSeatLayoutBackground, rawInput);
    });

class SeatSelectionController {
  final WidgetRef ref;
  final BuildContext context;

  SeatSelectionController(this.ref, this.context);

  void toggleSeat(String seatId, {SeatEntity? seat}) {
    final currentSeats = ref.read(selectedSeatsProvider);
    final totalCount = ref.read(totalCartCountProvider);

    // ── Deselect if already selected ──
    if (currentSeats.contains(seatId)) {
      ref.read(selectedSeatsProvider.notifier).state = {...currentSeats}
        ..remove(seatId);
      return;
    }

    // ── Global max 10 tickets check ──
    if (totalCount >= 10) {
      _showSnackBar('You can only book a maximum of 10 tickets.');
      return;
    }

    // ── Group limit check ──
    if (seat != null && seat.groupLimit != null && seat.groupLimit! > 0) {
      final groupId = seat.groupId;
      if (groupId != null && groupId.isNotEmpty) {
        final selectedInGroup = currentSeats.length;
      }
    }

    ref.read(selectedSeatsProvider.notifier).state = {...currentSeats}
      ..add(seatId);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Helper: is this group a stage? ──
bool _isStageGroup(Map<String, dynamic> attrs) {
  final type = (attrs['type']?.toString() ?? '').toLowerCase().trim();
  final label = (attrs['label']?.toString() ?? '').toLowerCase().trim();
  final name = (attrs['name']?.toString() ?? '').toLowerCase().trim();

  // Explicit stage type
  if (type == 'stage') return true;

  // Name/label contains stage but no ticket info
  final hasTicket =
      attrs['ticket'] != null ||
      attrs['ticket_id'] != null ||
      attrs['ticketId'] != null;

  if (!hasTicket) {
    if (label == 'stage' || name == 'stage') return true;
    if (label.contains('stage') && label.length < 12) return true;
  }

  return false;
}

SeatLayoutData? _parseSeatLayoutBackground(dynamic rawInput) {
  try {
    Map<String, dynamic> json;
    if (rawInput is String) {
      json = jsonDecode(rawInput) as Map<String, dynamic>;
    } else {
      json = rawInput as Map<String, dynamic>;
    }
    final List<
      ({
        String text,
        String groupId,
        String color,
        double fontSize,
        double rot,
        double scaledWidth,
      })
    >
    pendingGaLabels = [];
    final Map<String, SeatEntity> tempSeatMap = {};
    final List<DecorationLine> lines = [];
    final List<DecorationText> texts = [];
    final List<DecorationRect> decRects = [];
    final List<DecorationRect> stageDecRects = [];
    final List<DecorationText> stageDecTexts = [];
    final List<DecorationPolygon> polygons = [];
    final List<DecorationCircle> circles = [];
    final List<SectionEntity> sections = [];

    int globalUniqueCounter = 0;

    List<double> multiplyMatrix(List<double> m1, List<double> m2) {
      return [
        m1[0] * m2[0] + m1[2] * m2[1],
        m1[1] * m2[0] + m1[3] * m2[1],
        m1[0] * m2[2] + m1[2] * m2[3],
        m1[1] * m2[2] + m1[3] * m2[3],
        m1[0] * m2[4] + m1[2] * m2[5] + m1[4],
        m1[1] * m2[4] + m1[3] * m2[5] + m1[5],
      ];
    }

    Offset applyTransform(double x, double y, List<double> m) {
      return Offset(x * m[0] + y * m[2] + m[4], x * m[1] + y * m[3] + m[5]);
    }

    bool isGridLine(Map<String, dynamic> attrs) {
      if (attrs['listening'] == false) return true;
      final ptsRaw = attrs['points'];
      if (ptsRaw is List && ptsRaw.length >= 4) {
        int huge = 0;
        for (final pt in ptsRaw) {
          final val = (double.tryParse(pt.toString()) ?? 0).abs();
          if (val >= 2000) huge++;
        }
        if (huge >= 2) return true;
      }
      final name = (attrs['name']?.toString() ?? '').toLowerCase();
      if (name.contains('grid')) return true;
      return false;
    }

    bool isGridLayer(Map<String, dynamic> node) {
      final attrs = (node['attrs'] as Map<String, dynamic>?) ?? {};
      final layerName = (attrs['name']?.toString() ?? '').toLowerCase();
      if (layerName.contains('grid')) return true;
      final children = node['children'];
      if (children is! List || children.isEmpty) return false;

      // Scan ALL children — if ANY non-Line bookable element exists (Group,
      // Circle, or Rect with seatId), the layer has real content and must NOT
      // be skipped, regardless of how many grid lines it also contains.
      for (final child in children) {
        if (child is! Map<String, dynamic>) continue;
        final cn = child['className']?.toString() ?? '';
        if (cn == 'Group' || cn == 'Circle') return false;
        if (cn == 'Rect') {
          final cAttrs = (child['attrs'] as Map<String, dynamic>?) ?? {};
          if (cAttrs['seatId'] != null ||
              cAttrs['rowIndex'] != null ||
              cAttrs['colIndex'] != null) {
            return false;
          }
        }
      }

      // No bookable elements found — treat as grid-only if all children
      // are grid lines.
      int gridLike = 0;
      for (final child in children) {
        if (child is! Map<String, dynamic>) continue;
        if (child['className'] != 'Line') {
          return false;
        }
        final cAttrs = (child['attrs'] as Map<String, dynamic>?) ?? {};
        if (isGridLine(cAttrs)) gridLike++;
      }
      return gridLike > 0;
    }

    void addSeat({
      required String proposedId,
      required String label,
      required String section,
      required double x,
      required double y,
      required double width,
      required double height,
      required String color,
      required double rotation,
      required int? ticketId,
      required String? rawId,
      required String? groupId,
      required String shape,
      int? groupLimit, // ← NEW
    }) {
      globalUniqueCounter++;
      String finalId = proposedId;
      if (finalId.isEmpty) {
        finalId =
            '${_normalizeIdPart(groupId ?? section)}_'
            '${_normalizeIdPart(rawId ?? label)}_$globalUniqueCounter';
      }
      if (tempSeatMap.containsKey(finalId)) {
        finalId = '${finalId}_dup_$globalUniqueCounter';
      }
      tempSeatMap[finalId] = SeatEntity(
        id: finalId,
        label: label,
        section: _normalizeLabel(section),
        x: x,
        y: y,
        width: width,
        height: height,
        color: color,
        rotation: rotation,
        isAvailable: true,
        ticketId: ticketId,
        rawId: rawId,
        groupId: groupId,
        shape: shape,
        groupLimit: groupLimit,
      );
    }

    void parseChildren(
      List<dynamic> children,
      List<double> currentMatrix,
      String currentSection,
      int? currentTicketId, {
      String? currentGroupType,
      String? currentGroupId,
      String? currentGroupLabel,
      int? currentCapacity,
      int? currentMaxSale,
      String? currentColor,
      int? currentGroupLimit,
    }) {
      for (final child in children) {
        if (child is! Map<String, dynamic>) continue;

        final cAttrs = (child['attrs'] as Map<String, dynamic>?) ?? {};
        final className = child['className']?.toString() ?? '';

        // ── Skip invisible elements ──
        if (cAttrs['visible'] == false) continue;
        if (className == 'Transformer') continue;
        if (className == 'Line' && isGridLine(cAttrs)) continue;

        if (className == 'Stage') {
          if (child['children'] is List) {
            parseChildren(
              child['children'],
              currentMatrix,
              currentSection,
              currentTicketId,
              currentGroupType: currentGroupType,
              currentGroupId: currentGroupId,
              currentGroupLabel: currentGroupLabel,
              currentCapacity: currentCapacity,
              currentMaxSale: currentMaxSale,
              currentColor: currentColor,
              currentGroupLimit: currentGroupLimit,
            );
          }
          continue;
        }

        if (className == 'Layer') {
          if (isGridLayer(child)) continue;
          final layerMatrix = _buildLocalMatrix(cAttrs);
          final combinedMatrix = multiplyMatrix(currentMatrix, layerMatrix);
          if (child['children'] is List) {
            parseChildren(
              child['children'],
              combinedMatrix,
              currentSection,
              currentTicketId,
              currentGroupType: currentGroupType,
              currentGroupId: currentGroupId,
              currentGroupLabel: currentGroupLabel,
              currentCapacity: currentCapacity,
              currentMaxSale: currentMaxSale,
              currentColor: currentColor,
              currentGroupLimit: currentGroupLimit,
            );
          }
          continue;
        }

        final localMatrix = _buildLocalMatrix(cAttrs);
        final globalMatrix = multiplyMatrix(currentMatrix, localMatrix);

        if (className == 'Group') {
          if (_isStageGroup(cAttrs)) {
            final hasBookable = _groupHasBookableChildren(child['children']);
            if (!hasBookable) {
              debugPrint('🎭 Skipping stage group: ${cAttrs['label']}');
              _parseStageAsDecoration(
                child['children'],
                globalMatrix,
                stageDecRects,
                stageDecTexts, // ← use stageDecTexts
                (x, y, w, h, color, rot) => stageDecRects.add(
                  DecorationRect(
                    x: x,
                    y: y,
                    width: w,
                    height: h,
                    color: color,
                    rotation: rot,
                  ),
                ),
              );
              continue;
            }
          }

          String newSection = currentSection;
          final rawName = _normalizeLabel(cAttrs['name']?.toString());
          final rawLabel = _normalizeLabel(cAttrs['label']?.toString());
          final rawTicketName = _normalizeLabel(cAttrs['ticket']?.toString());

          if (rawName.isNotEmpty) {
            newSection = rawName;
          } else if (rawLabel.isNotEmpty) {
            newSection = rawLabel;
          } else if (rawTicketName.isNotEmpty &&
              int.tryParse(rawTicketName) == null) {
            newSection = rawTicketName;
          }

          int? newTicketId = currentTicketId;
          final rawTicketId = cAttrs['ticket_id'] ?? cAttrs['ticketId'];
          final rawTicketVal = cAttrs['ticket'];

          if (rawTicketId != null) {
            newTicketId = int.tryParse(rawTicketId.toString());
          }
          if (newTicketId == null && rawTicketVal != null) {
            final asInt = int.tryParse(rawTicketVal.toString());
            if (asInt != null) newTicketId = asInt;
          }

          final groupType = cAttrs['type']?.toString() ?? currentGroupType;
          final groupId =
              cAttrs['id']?.toString() ??
              rawName.ifEmptyNull ??
              rawLabel.ifEmptyNull ??
              currentGroupId;

          final cap =
              int.tryParse(cAttrs['capacity']?.toString() ?? '') ??
              currentCapacity ??
              0;

          final maxRaw = cAttrs['maxSale'] ?? cAttrs['max'];
          final max =
              int.tryParse(maxRaw?.toString() ?? '') ?? currentMaxSale ?? cap;

          // ── NEW: parse limit from group attrs ──
          final limitRaw = cAttrs['limit'];
          final groupLimit = int.tryParse(limitRaw?.toString() ?? '');

          final groupColor = cAttrs['color']?.toString() ?? currentColor;

          if (child['children'] is List) {
            parseChildren(
              child['children'],
              globalMatrix,
              newSection,
              newTicketId,
              currentGroupType: groupType,
              currentGroupId: groupId,
              currentGroupLabel: rawLabel.isNotEmpty
                  ? rawLabel
                  : currentGroupLabel,
              currentCapacity: cap,
              currentMaxSale: max,
              currentColor: groupColor,
              currentGroupLimit: groupLimit, // ← NEW
            );
          }
          continue;
        }

        // ── Leaf node position (matrix already handles x,y,offsetX,offsetY) ──
        final globalPos = applyTransform(0, 0, globalMatrix);
        final globalRot = math.atan2(globalMatrix[1], globalMatrix[0]);
        final globalScaleX = math.sqrt(
          globalMatrix[0] * globalMatrix[0] + globalMatrix[1] * globalMatrix[1],
        );
        final globalScaleY = math.sqrt(
          globalMatrix[2] * globalMatrix[2] + globalMatrix[3] * globalMatrix[3],
        );

        final rawShapeTicket =
            cAttrs['ticket_id'] ?? cAttrs['ticketId'] ?? cAttrs['ticket'];
        int? ticketId;
        if (rawShapeTicket != null) {
          ticketId = int.tryParse(rawShapeTicket.toString());
        }
        ticketId ??= currentTicketId;

        if (className == 'Rect') {
          final w =
              (double.tryParse(cAttrs['width']?.toString() ?? '0') ?? 0) *
              globalScaleX;
          final h =
              (double.tryParse(cAttrs['height']?.toString() ?? '0') ?? 0) *
              globalScaleY;

          // ── globalPos is TOP-LEFT (matrix includes offsetX/offsetY correction) ──
          final posX = globalPos.dx;
          final posY = globalPos.dy;

          final color = cAttrs['fill']?.toString().isNotEmpty == true
              ? cAttrs['fill'].toString()
              : cAttrs['stroke']?.toString().isNotEmpty == true
              ? cAttrs['stroke'].toString()
              : currentColor ?? '#007bff';

          final isGASection =
              (currentGroupType == 'ga' || currentGroupType == 'custom') &&
              (currentCapacity != null && currentCapacity > 0);

          bool isSeat =
              !isGASection &&
              (cAttrs['seatId'] != null ||
                  cAttrs['rowIndex'] != null ||
                  cAttrs['colIndex'] != null ||
                  ticketId != null ||
                  currentGroupType == 'assigned');

          final label = _extractSeatNumber(cAttrs['seatId']?.toString());

          if (!isSeat && !isGASection && w > 8 && h > 8 && w < 80 && h < 80) {
            if (currentGroupId != null && currentGroupType == 'assigned') {
              isSeat = true;
            }
          }

          if (isGASection) {
            final rectPoints = <double>[
              posX,
              posY,
              posX + w,
              posY,
              posX + w,
              posY + h,
              posX,
              posY + h,
            ];
            final sectionId = currentGroupId ?? 'sec_rect_${sections.length}';
            final alreadyExists = sections.any((s) => s.id == sectionId);
            if (!alreadyExists) {
              sections.add(
                SectionEntity(
                  id: sectionId,
                  label: _normalizeLabel(currentGroupLabel ?? currentSection),
                  type: currentGroupType ?? 'ga',
                  ticketId: currentTicketId,
                  capacity: currentCapacity ?? 0,
                  maxSale: currentMaxSale ?? 0,
                  color: currentColor ?? color,
                  polygonPoints: rectPoints,
                  minX: posX,
                  minY: posY,
                  maxX: posX + w,
                  maxY: posY + h,
                ),
              );
            }
            decRects.add(
              DecorationRect(
                x: posX,
                y: posY,
                width: w,
                height: h,
                color: currentColor ?? color,
                cornerRadius:
                    (double.tryParse(
                          cAttrs['cornerRadius']?.toString() ?? '0',
                        ) ??
                        0) *
                    globalScaleX,
                rotation: globalRot,
              ),
            );
          } else if (isSeat) {
            final rawId =
                cAttrs['fullSeatId']?.toString() ??
                cAttrs['seatId']?.toString() ??
                cAttrs['id']?.toString();
            final proposedId = rawId != null && rawId.isNotEmpty
                ? '${_normalizeIdPart(currentGroupId ?? currentSection)}_$rawId'
                : '';
            addSeat(
              proposedId: proposedId,
              label: label.isNotEmpty
                  ? label
                  : (cAttrs['label']?.toString() ??
                        cAttrs['colIndex']?.toString() ??
                        ''),
              section: currentSection,
              x: posX,
              y: posY,
              width: w,
              height: h,
              color: color,
              rotation: globalRot,
              ticketId: ticketId,
              rawId: rawId,
              groupId: currentGroupId,
              shape: 'rect',
              groupLimit: currentGroupLimit,
            );
          } else {
            decRects.add(
              DecorationRect(
                x: posX,
                y: posY,
                width: w,
                height: h,
                color: color,
                cornerRadius:
                    (double.tryParse(
                          cAttrs['cornerRadius']?.toString() ?? '0',
                        ) ??
                        0) *
                    globalScaleX,
                rotation: globalRot,
              ),
            );
          }
        } else if (className == 'Circle') {
          final r =
              (double.tryParse(cAttrs['radius']?.toString() ?? '0') ?? 0) *
              globalScaleX;
          if (r <= 0) continue;

          final looksLikeSeat =
              cAttrs['seatId'] != null ||
              cAttrs['rowIndex'] != null ||
              cAttrs['colIndex'] != null ||
              ticketId != null ||
              currentGroupType == 'assigned';

          if (looksLikeSeat) {
            final rawId =
                cAttrs['fullSeatId']?.toString() ??
                cAttrs['seatId']?.toString() ??
                cAttrs['id']?.toString();
            final circleLabel = _extractSeatNumber(
              cAttrs['seatId']?.toString(),
            );
            final proposedId = rawId != null && rawId.isNotEmpty
                ? '${_normalizeIdPart(currentGroupId ?? currentSection)}_$rawId'
                : '';
            final seatColor = cAttrs['fill']?.toString().isNotEmpty == true
                ? cAttrs['fill'].toString()
                : cAttrs['stroke']?.toString().isNotEmpty == true
                ? cAttrs['stroke'].toString()
                : currentColor ?? '#007bff';
            addSeat(
              proposedId: proposedId,
              label: circleLabel.isNotEmpty
                  ? circleLabel
                  : (cAttrs['label']?.toString() ??
                        cAttrs['colIndex']?.toString() ??
                        ''),
              section: currentSection,
              x: globalPos.dx - r,
              y: globalPos.dy - r,
              width: r * 2,
              height: r * 2,
              color: seatColor,
              rotation: 0,
              ticketId: ticketId,
              rawId: rawId,
              groupId: currentGroupId,
              shape: 'circle',
              groupLimit: currentGroupLimit,
            );
          } else {
            circles.add(
              DecorationCircle(
                x: globalPos.dx,
                y: globalPos.dy,
                radius: r,
                fill: cAttrs['fill'] ?? '#cccccc',
                stroke: cAttrs['stroke'] ?? '#000000',
                strokeWidth:
                    (double.tryParse(
                          cAttrs['strokeWidth']?.toString() ?? '1',
                        ) ??
                        1) *
                    globalScaleX,
              ),
            );
          }
        } else if (className == 'Text') {
          if (cAttrs['isSeatLabel'] == true) continue;

          final text = _normalizeLabel(cAttrs['text']?.toString());
          if (text.isEmpty) continue;
          if (RegExp(r'^\d{1,3}$').hasMatch(text)) continue;

          final name = cAttrs['name']?.toString() ?? '';
          if (name == 'edit-handle') continue;
          final isPolygonLabel = name == 'polygonLabel';
          final isGaLabel = name == 'gaLabelText';

          final isRowLabel = cAttrs['isRowLabel'] == true;
          final isSectionTitle = cAttrs['isSectionTitle'] == true;

          final localX = double.tryParse(cAttrs['x']?.toString() ?? '0') ?? 0.0;
          final localY = double.tryParse(cAttrs['y']?.toString() ?? '0') ?? 0.0;
          final rawOffX =
              double.tryParse(cAttrs['offsetX']?.toString() ?? '0') ?? 0.0;
          final rawOffY =
              double.tryParse(cAttrs['offsetY']?.toString() ?? '0') ?? 0.0;
          final rawWidth =
              double.tryParse(cAttrs['width']?.toString() ?? '') ?? 0.0;
          final align = cAttrs['align']?.toString() ?? 'left';

          final scaleX = math.sqrt(
            currentMatrix[0] * currentMatrix[0] +
                currentMatrix[1] * currentMatrix[1],
          );
          final scaleY = math.sqrt(
            currentMatrix[2] * currentMatrix[2] +
                currentMatrix[3] * currentMatrix[3],
          );
          final rot = math.atan2(currentMatrix[1], currentMatrix[0]);

          final fontSize =
              (double.tryParse(cAttrs['fontSize']?.toString() ?? '10') ??
                  10.0) *
              scaleX;
          if (fontSize < 4) continue;

          final worldPos = applyTransform(localX, localY, currentMatrix);
          final finalX = worldPos.dx - rawOffX * scaleX;
          final finalY = worldPos.dy - rawOffY * scaleY;

          final scaledWidth = rawWidth > 0
              ? (rawWidth * scaleX).clamp(20.0, 800.0)
              : (text.length * fontSize * 0.65).clamp(20.0, 400.0);

          if (isPolygonLabel || isGaLabel) {
            // Store for later positioning after all sections are parsed
            if (currentGroupId != null) {
              pendingGaLabels.add((
                text: text,
                groupId: currentGroupId!,
                color: cAttrs['fill']?.toString() ?? '#ffffff',
                fontSize: fontSize.clamp(8, 32),
                rot: rot,
                scaledWidth: scaledWidth,
              ));
            }
            continue;
          }

          texts.add(
            DecorationText(
              text: text,
              x: finalX,
              y: finalY,
              color: cAttrs['fill']?.toString() ?? '#000000',
              fontSize: fontSize.clamp(8, 32),
              rotation: rot,
              isBold:
                  isSectionTitle || isRowLabel || isGaLabel || isPolygonLabel,
              width: scaledWidth,
              align: align,
            ),
          );
        } else if (className == 'Line') {
          final ptsRaw = cAttrs['points'];
          if (ptsRaw is List && ptsRaw.length >= 4) {
            final pts = ptsRaw
                .map((e) => double.tryParse(e.toString()) ?? 0.0)
                .toList();
            final absPts = <double>[];
            for (int i = 0; i < pts.length; i += 2) {
              final p = applyTransform(pts[i], pts[i + 1], globalMatrix);
              absPts.add(p.dx);
              absPts.add(p.dy);
            }

            final isClosed = cAttrs['closed'] == true;
            final fill = cAttrs['fill']?.toString();

            if (isClosed && fill != null && fill.isNotEmpty) {
              polygons.add(
                DecorationPolygon(
                  points: absPts,
                  fill: fill,
                  stroke: cAttrs['stroke'] ?? '#000000',
                  strokeWidth:
                      (double.tryParse(
                            cAttrs['strokeWidth']?.toString() ?? '1',
                          ) ??
                          1) *
                      globalScaleX,
                ),
              );

              if (currentGroupType == 'ga' || currentGroupType == 'custom') {
                double sMinX = double.infinity, sMinY = double.infinity;
                double sMaxX = double.negativeInfinity,
                    sMaxY = double.negativeInfinity;
                for (int i = 0; i < absPts.length; i += 2) {
                  if (absPts[i] < sMinX) sMinX = absPts[i];
                  if (absPts[i] > sMaxX) sMaxX = absPts[i];
                  if (absPts[i + 1] < sMinY) sMinY = absPts[i + 1];
                  if (absPts[i + 1] > sMaxY) sMaxY = absPts[i + 1];
                }
                final sectionId = currentGroupId ?? 'sec_${sections.length}';
                if (!sections.any((s) => s.id == sectionId)) {
                  sections.add(
                    SectionEntity(
                      id: sectionId,
                      label: _normalizeLabel(
                        currentGroupLabel ?? currentSection,
                      ),
                      type: currentGroupType ?? 'ga',
                      ticketId: currentTicketId,
                      capacity: currentCapacity ?? 0,
                      maxSale: currentMaxSale ?? 0,
                      color: fill,
                      polygonPoints: absPts,
                      minX: sMinX,
                      minY: sMinY,
                      maxX: sMaxX,
                      maxY: sMaxY,
                    ),
                  );
                  debugPrint(
                    'GA Polygon Section added: ${currentGroupLabel ?? currentSection} ticketId=$currentTicketId cap=$currentCapacity',
                  );
                }
              }
            } else {
              lines.add(
                DecorationLine(
                  absPts.length >= 4
                      ? [absPts[0], absPts[1], absPts[2], absPts[3]]
                      : [],
                ),
              );
            }
          }
        }
      }
    }

    final identity = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0];
    if (json['className'] == 'Stage') {
      if (json['children'] is List) {
        parseChildren(json['children'], identity, 'General', null);
      }
    } else if (json['children'] != null) {
      parseChildren(json['children'], identity, 'General', null);
    } else {
      parseChildren([json], identity, 'General', null);
    }
    // Now ALL sections are parsed - position GA labels correctly
    for (final label in pendingGaLabels) {
      final matchSec = sections.where((s) => s.id == label.groupId).firstOrNull;

      if (matchSec != null) {
        final pts = matchSec.polygonPoints;

        // True centroid
        double sumX = 0, sumY = 0;
        int count = 0;
        for (int i = 0; i < pts.length; i += 2) {
          sumX += pts[i];
          sumY += pts[i + 1];
          count++;
        }
        final cx = count > 0
            ? sumX / count
            : (matchSec.minX + matchSec.maxX) / 2;
        final cy = count > 0
            ? sumY / count
            : (matchSec.minY + matchSec.maxY) / 2;

        texts.add(
          DecorationText(
            text: label.text,
            x: cx - (label.scaledWidth / 2),
            y: cy - (label.fontSize / 2),
            color: label.color,
            fontSize: label.fontSize,
            rotation: label.rot,
            isBold: true,
            width: label.scaledWidth,
            align: 'center',
          ),
        );

        debugPrint(
          '✅ GA Label "${label.text}" → '
          'centroid: (${cx.toStringAsFixed(0)}, ${cy.toStringAsFixed(0)}) | '
          'bounds: (${matchSec.minX.toStringAsFixed(0)},${matchSec.minY.toStringAsFixed(0)})'
          '→(${matchSec.maxX.toStringAsFixed(0)},${matchSec.maxY.toStringAsFixed(0)})',
        );
      }
    }
    if (tempSeatMap.isEmpty && sections.isEmpty) {
      if (decRects.isEmpty &&
          polygons.isEmpty &&
          texts.isEmpty &&
          circles.isEmpty) {
        return null;
      }
    }

    // ── Bounds: EXCLUDE stageDecRects to avoid huge offsets ──
    double? minX, minY, maxX, maxY;

    void updateBounds(double x, double y) {
      minX = minX == null ? x : math.min(minX!, x);
      minY = minY == null ? y : math.min(minY!, y);
      maxX = maxX == null ? x : math.max(maxX!, x);
      maxY = maxY == null ? y : math.max(maxY!, y);
    }

    for (final s in tempSeatMap.values) {
      updateBounds(s.x, s.y);
      updateBounds(s.x + s.width, s.y + s.height);
    }
    for (final s in sections) {
      for (int i = 0; i < s.polygonPoints.length; i += 2) {
        updateBounds(s.polygonPoints[i], s.polygonPoints[i + 1]);
      }
    }
    for (final r in decRects) {
      updateBounds(r.x, r.y);
      updateBounds(r.x + r.width, r.y + r.height);
    }
    for (final c in circles) {
      updateBounds(c.x - c.radius, c.y - c.radius);
      updateBounds(c.x + c.radius, c.y + c.radius);
    }
    for (final t in texts) {
      updateBounds(t.x, t.y);
      updateBounds(t.x + (t.fontSize * t.text.length * 0.6), t.y + t.fontSize);
    }
    for (final p in polygons) {
      for (int i = 0; i < p.points.length; i += 2) {
        updateBounds(p.points[i], p.points[i + 1]);
      }
    }
    for (final l in lines) {
      if (l.points.length >= 4) {
        updateBounds(l.points[0], l.points[1]);
        updateBounds(l.points[2], l.points[3]);
      }
    }

    if (minX == null) {
      minX = 0;
      minY = 0;
      maxX = 1000;
      maxY = 1000;
    }

    const padding = 80.0;
    final dx = -minX! + padding;
    final dy = -minY! + padding;
    final stageWidth = (maxX! - minX!) + padding * 2;
    final stageHeight = (maxY! - minY!) + padding * 2;

    final finalSeats = tempSeatMap.values
        .map((s) => s.copyWith(x: s.x + dx, y: s.y + dy))
        .toList();

    final finalSections = sections.map((s) {
      final newPts = <double>[];
      for (int i = 0; i < s.polygonPoints.length; i += 2) {
        newPts.add(s.polygonPoints[i] + dx);
        newPts.add(s.polygonPoints[i + 1] + dy);
      }
      return SectionEntity(
        id: s.id,
        label: s.label,
        type: s.type,
        ticketId: s.ticketId,
        capacity: s.capacity,
        maxSale: s.maxSale,
        color: s.color,
        polygonPoints: newPts,
        minX: s.minX + dx,
        minY: s.minY + dy,
        maxX: s.maxX + dx,
        maxY: s.maxY + dy,
      );
    }).toList();

    // ── Merge stage rects WITH offset so they render at correct position ──
    final allDecRects = [
      ...decRects.map(
        (r) => DecorationRect(
          x: r.x + dx,
          y: r.y + dy,
          width: r.width,
          height: r.height,
          color: r.color,
          cornerRadius: r.cornerRadius,
          rotation: r.rotation,
        ),
      ),
      ...stageDecRects.map(
        (r) => DecorationRect(
          x: r.x + dx,
          y: r.y + dy,
          width: r.width,
          height: r.height,
          color: r.color,
          cornerRadius: r.cornerRadius,
          rotation: r.rotation,
        ),
      ),
    ];

    final finalTexts = [
      ...texts.map(
        (t) => DecorationText(
          text: t.text,
          x: t.x + dx,
          y: t.y + dy,
          color: t.color,
          fontSize: t.fontSize,
          rotation: t.rotation,
          isBold: t.isBold,
          width: t.width,
          align: t.align,
        ),
      ),
      // ── Stage texts excluded from bounds but included in render ──
      ...stageDecTexts.map(
        (t) => DecorationText(
          text: t.text,
          x: t.x + dx,
          y: t.y + dy,
          color: t.color,
          fontSize: t.fontSize,
          rotation: t.rotation,
          isBold: t.isBold,
          width: t.width,
          align: t.align,
        ),
      ),
    ];
    final finalCircles = circles
        .map(
          (c) => DecorationCircle(
            x: c.x + dx,
            y: c.y + dy,
            radius: c.radius,
            fill: c.fill,
            stroke: c.stroke,
            strokeWidth: c.strokeWidth,
          ),
        )
        .toList();

    final finalPolys = polygons.map((p) {
      final pts = <double>[];
      for (int i = 0; i < p.points.length; i += 2) {
        pts.add(p.points[i] + dx);
        pts.add(p.points[i + 1] + dy);
      }
      return DecorationPolygon(
        points: pts,
        fill: p.fill,
        stroke: p.stroke,
        strokeWidth: p.strokeWidth,
      );
    }).toList();

    final finalLines = lines.map((l) {
      if (l.points.length < 4) return l;
      return DecorationLine([
        l.points[0] + dx,
        l.points[1] + dy,
        l.points[2] + dx,
        l.points[3] + dy,
      ]);
    }).toList();

    debugPrint(
      'Parsed seat map: ${finalSeats.length} seats, ${finalSections.length} sections',
    );

    return SeatLayoutData(
      stageWidth: stageWidth,
      stageHeight: stageHeight,
      seats: finalSeats,
      lines: finalLines,
      texts: finalTexts,
      decorationRects: allDecRects,
      polygons: finalPolys,
      circles: finalCircles,
      sections: finalSections,
    );
  } catch (e, st) {
    debugPrint('❌ Background Parse Error: $e');
    debugPrint('$st');
    return null;
  }
}

void _parseStageAsDecoration(
  dynamic children,
  List<double> groupMatrix,
  List<DecorationRect> decRects,
  List<DecorationText> texts,
  Function(double, double, double, double, String, double) addRect,
) {
  if (children is! List) return;

  Offset applyT(double x, double y, List<double> m) =>
      Offset(x * m[0] + y * m[2] + m[4], x * m[1] + y * m[3] + m[5]);

  final scaleX = math.sqrt(
    groupMatrix[0] * groupMatrix[0] + groupMatrix[1] * groupMatrix[1],
  );
  final scaleY = math.sqrt(
    groupMatrix[2] * groupMatrix[2] + groupMatrix[3] * groupMatrix[3],
  );
  final rot = math.atan2(groupMatrix[1], groupMatrix[0]);

  for (final child in children) {
    if (child is! Map<String, dynamic>) continue;
    final attrs = (child['attrs'] as Map<String, dynamic>?) ?? {};
    final cn = child['className']?.toString() ?? '';
    final name = attrs['name']?.toString() ?? '';

    // Skip edit handles
    if (name == 'edit-handle') continue;

    if (cn == 'Rect') {
      final w =
          (double.tryParse(attrs['width']?.toString() ?? '0') ?? 0) * scaleX;
      final h =
          (double.tryParse(attrs['height']?.toString() ?? '0') ?? 0) * scaleY;
      if (w <= 0 || h <= 0) continue;
      final origin = applyT(0, 0, groupMatrix);
      final color = attrs['fill']?.toString().isNotEmpty == true
          ? attrs['fill'].toString()
          : '#cccccc';
      final cr =
          (double.tryParse(attrs['cornerRadius']?.toString() ?? '0') ?? 0) *
          scaleX;
      decRects.add(
        DecorationRect(
          x: origin.dx,
          y: origin.dy,
          width: w,
          height: h,
          color: color,
          cornerRadius: cr,
          rotation: rot,
        ),
      );
    } else if (cn == 'Circle') {
      final r =
          (double.tryParse(attrs['radius']?.toString() ?? '0') ?? 0) * scaleX;
      if (r <= 0) continue;
      final cx = double.tryParse(attrs['x']?.toString() ?? '0') ?? 0.0;
      final cy = double.tryParse(attrs['y']?.toString() ?? '0') ?? 0.0;
      final center = applyT(cx, cy, groupMatrix);
      final color = attrs['fill']?.toString().isNotEmpty == true
          ? attrs['fill'].toString()
          : '#ffcc00';
      decRects.add(
        DecorationRect(
          x: center.dx - r,
          y: center.dy - r,
          width: r * 2,
          height: r * 2,
          color: color,
          cornerRadius: r,
          rotation: rot,
        ),
      );
    } else if (cn == 'Text') {
      final text = attrs['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;

      final localX = double.tryParse(attrs['x']?.toString() ?? '0') ?? 0.0;
      final localY = double.tryParse(attrs['y']?.toString() ?? '0') ?? 0.0;
      final rawOffX =
          double.tryParse(attrs['offsetX']?.toString() ?? '0') ?? 0.0;
      final rawOffY =
          double.tryParse(attrs['offsetY']?.toString() ?? '0') ?? 0.0;
      final rawWidth = double.tryParse(attrs['width']?.toString() ?? '') ?? 0.0;
      final align = attrs['align']?.toString() ?? 'center';

      final fontSize =
          (double.tryParse(attrs['fontSize']?.toString() ?? '12') ?? 12.0) *
          scaleX;
      if (fontSize < 4) continue;

      final worldPos = applyT(localX, localY, groupMatrix);
      final finalX = worldPos.dx - rawOffX * scaleX;
      final finalY = worldPos.dy - rawOffY * scaleY;

      final scaledWidth = rawWidth > 0
          ? (rawWidth * scaleX).clamp(20.0, 400.0)
          : (text.length * fontSize * 0.65).clamp(20.0, 200.0);

      texts.add(
        DecorationText(
          text: text,
          x: finalX,
          y: finalY,
          color: attrs['fill']?.toString() ?? '#000000',
          fontSize: fontSize.clamp(8, 32),
          rotation: rot,
          isBold: true,
          width: scaledWidth,
          align: align,
        ),
      );
    }
  }
}

List<double> _buildLocalMatrix(Map<String, dynamic> attrs) {
  final x = double.tryParse(attrs['x']?.toString() ?? '0') ?? 0;
  final y = double.tryParse(attrs['y']?.toString() ?? '0') ?? 0;
  final scaleX = double.tryParse(attrs['scaleX']?.toString() ?? '1') ?? 1;
  final scaleY = double.tryParse(attrs['scaleY']?.toString() ?? '1') ?? 1;
  final rotDeg = double.tryParse(attrs['rotation']?.toString() ?? '0') ?? 0;
  final rotRad = rotDeg * (math.pi / 180.0);
  final offX = double.tryParse(attrs['offsetX']?.toString() ?? '0') ?? 0;
  final offY = double.tryParse(attrs['offsetY']?.toString() ?? '0') ?? 0;

  final cos = math.cos(rotRad);
  final sin = math.sin(rotRad);

  final a = cos * scaleX;
  final b = sin * scaleX;
  final c = -sin * scaleY;
  final d = cos * scaleY;
  final tx = x - (offX * a + offY * c);
  final ty = y - (offX * b + offY * d);

  return [a, b, c, d, tx, ty];
}

String _extractSeatNumber(String? seatId) {
  if (seatId == null || seatId.isEmpty) return '';
  final match = RegExp(r'(\d+)$').firstMatch(seatId);
  return match?.group(1) ?? seatId;
}

String _normalizeLabel(String? input) {
  if (input == null) return '';
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _normalizeIdPart(String? input) {
  final s = _normalizeLabel(input);
  if (s.isEmpty) return 'unknown';
  return s.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
}

bool _groupHasBookableChildren(dynamic children) {
  if (children is! List) return false;
  for (final child in children) {
    if (child is! Map<String, dynamic>) continue;
    final attrs = (child['attrs'] as Map<String, dynamic>?) ?? {};
    final className = child['className']?.toString() ?? '';
    if (attrs['visible'] == false) continue;
    if (className == 'Transformer') continue;
    if (attrs['ticket_id'] != null ||
        attrs['ticketId'] != null ||
        attrs['seatId'] != null ||
        attrs['rowIndex'] != null) {
      return true;
    }
    if (child['children'] is List) {
      if (_groupHasBookableChildren(child['children'])) return true;
    }
  }
  return false;
}

extension on String {
  String? get ifEmptyNull => trim().isEmpty ? null : this;
}

final bookedSeatsByDateProvider =
    FutureProvider.family<Set<String>, (int, DateTime)>((ref, args) async {
      final (eventId, date) = args;
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getBookedSeatsByDate(eventId: eventId, date: date);
    });
