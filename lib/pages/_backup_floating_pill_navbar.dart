// ══════════════════════════════════════════════════════════════════════
// BACKUP: Floating Pill Bottom Nav Bar (old design)
// ══════════════════════════════════════════════════════════════════════
//
// This is the original floating glassmorphism pill nav bar.
// To restore it:
//   1. In main_shell.dart, set `extendBody: true` on the Scaffold.
//   2. Replace the _GlassNavBar.build() method with the code below.
//   3. Make sure AppColors import is present:
//        import '../theme/app_colors.dart';
//
// ══════════════════════════════════════════════════════════════════════

/*

  // Inside _GlassNavBar — replace the entire build() method with this:

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              // Very low alpha — the blur does the frosting, not the fill
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenDark.withValues(
                    alpha: isDark ? 0.30 : 0.10,
                  ),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                return _NavBarItem(
                  item: items[i],
                  isSelected: currentIndex == i,
                  onTap: () => onTap(i),
                  isDark: isDark,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

*/
