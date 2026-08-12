import 'package:gormahiafc/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BreadcrumbTabBar extends StatelessWidget {
  final int activeStep; // 1, 2, or 3

  const BreadcrumbTabBar({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const double height = 48.0;
    const double arrowWidth = 16.0;
    const double gap = 1.5; // Small gap to act as a separator line

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgDark, // Gap color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10), // Rounds the outermost corners
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            // Total visual width = 3 * tabWidth - 2 * arrowWidth + 2 * gap
            // tabWidth = (totalWidth + 2 * arrowWidth - 2 * gap) / 3
            final tabWidth = (totalWidth + 2 * arrowWidth - 2 * gap) / 3;

            return Stack(
              children: [
                // Step 3
                Positioned(
                  left: 2 * (tabWidth - arrowWidth + gap),
                  width: tabWidth,
                  top: 0,
                  bottom: 0,
                  child: _BreadcrumbItem(
                    title: '3. Membership',
                    isActive: activeStep >= 3,
                    isFirst: false,
                    isLast: true,
                    arrowWidth: arrowWidth,
                  ),
                ),
                // Step 2
                Positioned(
                  left: tabWidth - arrowWidth + gap,
                  width: tabWidth,
                  top: 0,
                  bottom: 0,
                  child: _BreadcrumbItem(
                    title: '2. OTP',
                    isActive: activeStep >= 2,
                    isFirst: false,
                    isLast: false,
                    arrowWidth: arrowWidth,
                  ),
                ),
                // Step 1
                Positioned(
                  left: 0,
                  width: tabWidth,
                  top: 0,
                  bottom: 0,
                  child: _BreadcrumbItem(
                    title: '1. Details',
                    isActive: activeStep >= 1,
                    isFirst: true,
                    isLast: false,
                    arrowWidth: arrowWidth,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final double arrowWidth;

  const _BreadcrumbItem({
    required this.title,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.arrowWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ChevronClipper(
        isFirst: isFirst,
        isLast: isLast,
        arrowWidth: arrowWidth,
      ),
      child: Container(
        color: isActive ? AppColors.greenMedium : const Color(0xFF162B1C),
        padding: EdgeInsets.only(
          left: isFirst ? 12 : 12 + arrowWidth * 0.5,
          right: isLast ? 12 : 12 + arrowWidth * 0.5,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMutedLight,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ChevronClipper extends CustomClipper<Path> {
  final bool isFirst;
  final bool isLast;
  final double arrowWidth;

  _ChevronClipper({
    required this.isFirst,
    required this.isLast,
    required this.arrowWidth,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (isFirst) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(arrowWidth, size.height / 2);
      path.lineTo(0, size.height);
    }

    path.lineTo(size.width - (isLast ? 0 : arrowWidth), size.height);

    if (isLast) {
      path.lineTo(size.width, 0);
    } else {
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - arrowWidth, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ChevronClipper oldClipper) {
    return oldClipper.isFirst != isFirst ||
        oldClipper.isLast != isLast ||
        oldClipper.arrowWidth != arrowWidth;
  }
}
