import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventsbooking/models/user_model.dart';
import 'package:eventsbooking/pages/monthly_contribution.dart';
import 'package:eventsbooking/providers/user_providers.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyMembership extends ConsumerWidget {
  const MyMembership({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'My Membership',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Membership',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            _MembershipCard(user: user),
            const SizedBox(height: 24),
            _MembershipDetails(user: user),
            const SizedBox(height: 24),
            const _QuickActions(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MEMBERSHIP CARD
// ─────────────────────────────────────────────
class _MembershipCard extends StatelessWidget {
  final UserModel user;
  const _MembershipCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = user.cleanedImageUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen.withOpacity(0.2), AppColors.bgDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.5),
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
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Green Army Member', // Mock data, should come from user model in the future
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member ID: GM1968-000123',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Since: May 2024',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Logo
            Container(
              width: 72,
              height: 92,
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/Gor-Mahia-FC-logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
    );
  }
}

// ─────────────────────────────────────────────
// AVATAR FALLBACK
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
// MEMBERSHIP DETAILS
// ─────────────────────────────────────────────
class _MembershipDetails extends StatelessWidget {
  final UserModel user;
  const _MembershipDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MEMBERSHIP DETAILS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Membership Type', 'Green Army Member'),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Valid Until', '31 May 2025'),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Branch', 'Kisumu Branch'),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.membershipStatus,
                  style: TextStyle(
                    color: user.membershipStatus.toLowerCase() == 'active'
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// QUICK ACTIONS
// ─────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Monthly Contributions',
                  subtitle: 'Pay and manage contributions',
                  isFirst: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MonthlyContribution(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 64,
                  color: Theme.of(context).dividerColor,
                ),
                _buildActionTile(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Payment History',
                  subtitle: 'View all payments and receipts',
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 64,
                  color: Theme.of(context).dividerColor,
                ),
                _buildActionTile(
                  context,
                  icon: Icons.autorenew_outlined,
                  title: 'Membership Renewal',
                  subtitle: 'Renew your membership',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.greenLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.greenLight, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
