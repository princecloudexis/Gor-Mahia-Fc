import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gormahiafc/controllers/auth_controller.dart';
import 'package:gormahiafc/models/user_model.dart';
import 'package:gormahiafc/pages/editprofile.dart';
import 'package:gormahiafc/pages/favorites.dart';
import 'package:gormahiafc/pages/help_and_support.dart';
import 'package:gormahiafc/pages/login.dart';
import 'package:gormahiafc/pages/my_membership.dart';
import 'package:gormahiafc/pages/policy.dart';
import 'package:gormahiafc/pages/settings.dart';
import 'package:gormahiafc/pages/signup.dart';
import 'package:gormahiafc/pages/tickets.dart';
import 'package:gormahiafc/pages/shop_orders.dart';
import 'package:gormahiafc/pages/reels/my_reels_page.dart';
import 'package:gormahiafc/providers/policy_provider.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/theme/app_colors.dart';
import 'package:gormahiafc/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: authState.status != AuthStatus.authenticated || authState.isGuest
          ? const _GuestView()
          : const _AuthenticatedView(),
    );
  }
}

// ─────────────────────────────────────────────
// AUTHENTICATED VIEW
// ─────────────────────────────────────────────
class _AuthenticatedView extends ConsumerWidget {
  const _AuthenticatedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final authState = ref.watch(authControllerProvider);

    if (user == null) {
      if (authState.status == AuthStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Failed to load profile"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(userProvider.notifier).fetchUser(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _ProfileHeader(user: user),
        // _StatsRow(user: user), // Hidden because ticket booking is not implemented yet
        _MenuSection(),
        // Extra bottom padding so content clears the floating glass nav bar
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 30),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE HEADER — minimal compact design
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = user.cleanedImageUrl;

    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // ── Top bar ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      _IconBtn(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Title
                    Expanded(
                      child: Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    // Edit button
                    _IconBtn(
                      icon: Icons.edit_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfile(user: user),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Avatar + name ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryPink.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: fullImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: fullImageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _AvatarFallback(name: user.fullName),
                            )
                          : _AvatarFallback(name: user.fullName),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}



// ─────────────────────────────────────────────
// AVATAR FALLBACK — initials
// ─────────────────────────────────────────────
class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS ROW — compact pills
// ─────────────────────────────────────────────
class _StatsRow extends ConsumerWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-watch the provider to ensure fresh data in release mode
    final freshUser = ref.watch(userProvider) ?? user;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _StatPill(
                icon: Icons.event_available_outlined,
                label: 'Attended',
                value: (freshUser.eventsAttended ?? 0).toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatPill(
                icon: Icons.upcoming_outlined,
                label: 'Upcoming',
                value: (freshUser.upcomingEvents ?? 0).toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final iconColor = isDark
                  ? AppColors.greenLight
                  : AppColors.greenMain;
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              );
            },
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1);
  }
}

// ─────────────────────────────────────────────
// MENU SECTION — grouped classic list
// ─────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  static final _menuItems = [
    MenuItem(
      icon: Icons.video_library_outlined,
      title: 'My Reels',
      destination: const MyReelsPage(),
    ),
    MenuItem(
      icon: Icons.card_membership_outlined,
      title: 'My Membership',
      destination: const MyMembership(),
    ),
    MenuItem(
      icon: Icons.favorite_outline,
      title: 'Favorites',
      destination: const Favorites(),
    ),
    MenuItem(
      icon: Icons.inventory_2_outlined,
      title: 'My Orders',
      destination: const ShopOrdersPage(),
    ),
    // MenuItem(
    //   icon: Icons.confirmation_number_outlined,
    //   title: 'Your Tickets',
    //   destination: const Tickets(),
    // ),
    MenuItem(
      icon: Icons.settings_outlined,
      title: 'Settings',
      destination: const Settings(),
    ),
    MenuItem(
      icon: Icons.privacy_tip_outlined,
      title: 'Privacy Policy',
      destination: PolicyPage(
        title: 'Privacy Policy',
        contentProvider: privacyPolicyProvider,
      ),
    ),
    MenuItem(
      icon: Icons.description_outlined,
      title: 'Terms of Service',
      destination: PolicyPage(
        title: 'Terms of Service',
        contentProvider: termsOfServiceProvider,
      ),
    ),
    MenuItem(
      icon: Icons.help_outline,
      title: 'Help & Support',
      destination: const HelpAndSupport(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _menuItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 56,
              thickness: 0.5,
              endIndent: 0,
              color: Theme.of(context).dividerColor,
            ),
            itemBuilder: (context, index) {
              return _MenuTile(
                item: _menuItems[index],
                isFirst: index == 0,
                isLast: index == _menuItems.length - 1,
              );
            },
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MENU TILE — clean minimal row
// ─────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final MenuItem item;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.destination != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.destination!),
            )
          : null,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Icon(
              item.icon,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────


// ─────────────────────────────────────────────
// GUEST VIEW — clean minimal
// ─────────────────────────────────────────────
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            if (Navigator.canPop(context))
              Align(
                alignment: Alignment.centerLeft,
                child: _IconBtn(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            const SizedBox(height: 16),

            // Avatar placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPink.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: AppTheme.primaryPink,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to view your profile,\ntickets and favourites.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 40),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Log In',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sign up button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Signup()),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppTheme.primaryPink,
                  side: BorderSide(
                    color: AppTheme.primaryPink.withOpacity(0.5),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SMALL ICON BUTTON — top bar
// ─────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MENU ITEM MODEL
// ─────────────────────────────────────────────
class MenuItem {
  final IconData icon;
  final String title;
  final Widget? destination;

  const MenuItem({required this.icon, required this.title, this.destination});
}
