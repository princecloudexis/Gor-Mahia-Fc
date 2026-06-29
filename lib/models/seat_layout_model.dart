class SeatEntity {
  final String id;
  final String label;
  final String section;
  final double x;
  final double y;
  final double width;
  final double height;
  final String color;
  final double rotation;
  final bool isAvailable;
  final int? ticketId;
  final String? rawId;
  final String? groupId;
  final String shape;
  final int? groupLimit;

  SeatEntity({
    required this.id,
    required this.label,
    required this.section,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.rotation = 0.0,
    this.isAvailable = true,
    this.ticketId,
    this.rawId,
    this.groupId,
    this.shape = 'rect',
    this.groupLimit, // ← NEW
  });

  SeatEntity copyWith({
    String? id,
    String? label,
    String? section,
    double? x,
    double? y,
    double? width,
    double? height,
    String? color,
    double? rotation,
    bool? isAvailable,
    int? ticketId,
    String? rawId,
    String? groupId,
    String? shape,
    int? groupLimit,
  }) {
    return SeatEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      section: section ?? this.section,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      rotation: rotation ?? this.rotation,
      isAvailable: isAvailable ?? this.isAvailable,
      ticketId: ticketId ?? this.ticketId,
      rawId: rawId ?? this.rawId,
      groupId: groupId ?? this.groupId,
      shape: shape ?? this.shape,
      groupLimit: groupLimit ?? this.groupLimit,
    );
  }
}

class DecorationLine {
  final List<double> points;
  DecorationLine(this.points);
}

class DecorationRect {
  final double x;
  final double y;
  final double width;
  final double height;
  final String color;
  final double cornerRadius;
  final double rotation;

  DecorationRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    this.cornerRadius = 0,
    this.rotation = 0.0,
  });
}

class DecorationText {
  final String text;
  final double x;
  final double y;
  final String color;
  final double fontSize;
  final double rotation;
  final bool isBold;
  final double? width;
  final String align;

  DecorationText({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    required this.fontSize,
    this.rotation = 0.0,
    this.isBold = true,
    this.width,
    this.align = 'left',
  });
}

class DecorationPolygon {
  final List<double> points;
  final String fill;
  final String stroke;
  final double strokeWidth;

  DecorationPolygon({
    required this.points,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });
}

class DecorationCircle {
  final double x;
  final double y;
  final double radius;
  final String fill;
  final String stroke;
  final double strokeWidth;

  DecorationCircle({
    required this.x,
    required this.y,
    required this.radius,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });
}

class SeatLayoutData {
  final double stageWidth;
  final double stageHeight;
  final List<SeatEntity> seats;
  final List<DecorationLine> lines;
  final List<DecorationText> texts;
  final List<DecorationRect> decorationRects;
  final List<DecorationPolygon> polygons;
  final List<DecorationCircle> circles;
  final List<SectionEntity> sections;

  SeatLayoutData({
    required this.stageWidth,
    required this.stageHeight,
    required this.seats,
    required this.lines,
    required this.texts,
    required this.decorationRects,
    this.polygons = const [],
    this.circles = const [],
    this.sections = const [],
  });
}

class SectionEntity {
  final String id;
  final String label;
  final String type;
  final int? ticketId;
  final int capacity;
  final int maxSale;
  final String color;
  final List<double> polygonPoints;
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  SectionEntity({
    required this.id,
    required this.label,
    required this.type,
    required this.ticketId,
    required this.capacity,
    required this.maxSale,
    required this.color,
    required this.polygonPoints,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });
}
