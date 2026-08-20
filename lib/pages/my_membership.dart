import 'package:cached_network_image/cached_network_image.dart';
import 'package:kogalo_network/models/user_model.dart';
import 'package:kogalo_network/pages/monthly_contribution.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:kogalo_network/theme/app_colors.dart';
import 'package:kogalo_network/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/pages/membership_signup.dart';
import 'package:kogalo_network/pages/membership_history.dart';
import 'package:kogalo_network/controllers/membership_controller.dart';

class MyMembership extends ConsumerWidget {
  const MyMembership({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final detailsAsync = ref.watch(membershipDetailsProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            'My Membership',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'My Membership',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: detailsAsync.when(
        data: (details) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                _MembershipCard(user: user, details: details),
                const SizedBox(height: 24),
                _MembershipDetails(details: details),
                const SizedBox(height: 24),
                _QuickActions(details: details),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load membership details.'),
              TextButton(
                onPressed: () => ref.invalidate(membershipDetailsProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
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
  final MembershipDetails details;
  const _MembershipCard({required this.user, required this.details});

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = user.cleanedImageUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.2),
              isDark ? AppColors.bgDark : Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
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
                  color: AppColors.primaryGreen.withValues(alpha: 0.5),
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
                    details.memberName.isNotEmpty
                        ? details.memberName
                        : user.fullName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.membershipType,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (details.memberId != null &&
                      details.memberId!.isNotEmpty &&
                      details.memberId != 'null') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Member ID: ${details.memberId}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (details.since != null &&
                      details.since!.isNotEmpty &&
                      details.since != 'null') ...[
                    const SizedBox(height: 2),
                    Text(
                      'Since: ${details.since}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
  final MembershipDetails details;
  const _MembershipDetails({required this.details});

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
            Text(
              'MEMBERSHIP DETAILS',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Membership Type', details.membershipType),
            if (details.validUntil != null &&
                details.validUntil!.isNotEmpty &&
                details.validUntil != 'null') ...[
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, 'Valid Until', details.validUntil!),
            ],
            if (details.branch != null &&
                details.branch!.isNotEmpty &&
                details.branch != 'null') ...[
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, 'Branch', details.branch!),
            ],
            if (details.status != null &&
                details.status!.isNotEmpty &&
                details.status != 'null') ...[
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    details.status!,
                    style: TextStyle(
                      color: details.status!.toLowerCase() == 'active'
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
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
class _QuickActions extends ConsumerWidget {
  final MembershipDetails details;
  const _QuickActions({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFreePlan =
        details.memberId == null ||
        details.memberId!.isEmpty ||
        details.memberId == 'null' ||
        details.status == null ||
        details.status!.toLowerCase() != 'active';

    final renewalStatusAsync = ref.watch(membershipRenewalStatusProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
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
                if (isFreePlan) ...[
                  _buildActionTile(
                    context,
                    icon: Icons.workspace_premium_outlined,
                    title: 'Purchase Membership',
                    subtitle: 'Upgrade to a premium plan',
                    isFirst: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MembershipSignup(isStandalone: true),
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
                ],
                _buildActionTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Monthly Contributions',
                  subtitle: 'Pay and manage contributions',
                  isFirst: !isFreePlan,
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
                  isLast: isFreePlan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MembershipHistoryPage(),
                      ),
                    );
                  },
                ),
                if (!isFreePlan) ...[
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 64,
                    color: Theme.of(context).dividerColor,
                  ),
                  renewalStatusAsync.when(
                    data: (status) {
                      String subtitle = 'Renew your membership';
                      if (status.needsRenewal) {
                        subtitle =
                            'Needs Renewal! Expired ${status.validUntil}';
                      } else if (status.daysRemaining != null) {
                        subtitle =
                            'Valid until ${status.validUntil} (${status.daysRemaining} days left)';
                      } else if (status.validUntil != null) {
                        subtitle = 'Valid until ${status.validUntil}';
                      }

                      return _buildActionTile(
                        context,
                        icon: Icons.autorenew_outlined,
                        title: 'Membership Renewal',
                        subtitle: subtitle,
                        isLast: true,
                        onTap: () {
                          if (status.needsRenewal ||
                              (status.daysRemaining != null &&
                                  status.daysRemaining! <=
                                      (status.renewalWindowDays ?? 7))) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MembershipSignup(
                                  isStandalone: true,
                                  isRenewal: true,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your membership is active and does not require renewal right now.',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                    loading: () => _buildActionTile(
                      context,
                      icon: Icons.autorenew_outlined,
                      title: 'Membership Renewal',
                      subtitle: 'Loading status...',
                      isLast: true,
                    ),
                    error: (err, stack) => _buildActionTile(
                      context,
                      icon: Icons.autorenew_outlined,
                      title: 'Membership Renewal',
                      subtitle: 'Failed to load status',
                      isLast: true,
                    ),
                  ),
                ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: AppColors.greenLight.withValues(alpha: 0.15),
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
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
