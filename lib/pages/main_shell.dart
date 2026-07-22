import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'matches.dart';
import 'shop.dart';
import 'community.dart';
import 'monthly_contribution.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _indicatorController;

  final List<Widget> _pages = const [
    Home(),
    Matches(),
    Community(),
    MonthlyContribution(),
    Shop(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.stadium_outlined,
      activeIcon: Icons.stadium_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer_rounded,
      label: 'Matches',
    ),
    _NavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Community',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Contributions',
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'Shop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();

    // Refresh community data if navigating to the Community tab (index 2)
    if (index == 2) {
      ref.invalidate(joinedGroupsProvider);
      ref.invalidate(exploreGroupsProvider);
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _GlassNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Navigation Bar
// ─────────────────────────────────────────────
class _GlassNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate approximate center of the nav bar for accurate magnification
    final centerX = size.width / 2;
    final centerY =
        size.height - (bottomPadding == 0 ? 24 : bottomPadding + 8) - 30;

    final matrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(1.06, 1.06, 1.6)
      ..translate(-centerX, -centerY);

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomPadding == 0 ? 24 : bottomPadding + 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            inner: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            outer: ImageFilter.matrix(matrix.storage),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (i) {
                  return Expanded(
                    child: _NavBarItem(
                      item: items[i],
                      isSelected: currentIndex == i,
                      onTap: () => onTap(i),
                      isDark: isDark,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual Nav Item
// ─────────────────────────────────────────────
class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bouncy pill highlight
                  Positioned.fill(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      scale: widget.isSelected ? 1.0 : 0.4,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: widget.isSelected ? 0.9 : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isSelected
                              ? widget.item.activeIcon
                              : widget.item.icon,
                          size: widget.isSelected ? 28 : 28,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.90)
                              : Colors.black.withValues(alpha: 0.80),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: widget.isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.90)
                                : Colors.black.withValues(alpha: 0.80),
                            letterSpacing: 0.1,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
