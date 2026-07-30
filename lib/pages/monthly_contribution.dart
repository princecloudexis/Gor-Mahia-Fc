import 'dart:async';
import 'package:eventsbooking/models/contribution_models.dart';
import 'package:eventsbooking/providers/contribution_providers.dart';
import 'package:eventsbooking/repositories/contribution_repository.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile.dart';
import 'search.dart';
import '../widgets/top_action_btn.dart';

class MonthlyContribution extends ConsumerStatefulWidget {
  const MonthlyContribution({super.key});

  @override
  ConsumerState<MonthlyContribution> createState() =>
      _MonthlyContributionState();
}

class _MonthlyContributionState extends ConsumerState<MonthlyContribution>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _paymentLaunched = false;
  bool _isCheckingStatus = false;
  Contribution? _currentPayingContribution;
  String? _currentPaymentReference;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _paymentLaunched &&
        !_isCheckingStatus) {
      _verifyPaymentStatus();
    }
  }

  Future<void> _verifyPaymentStatus() async {
    setState(() {
      _isCheckingStatus = true;
      _paymentLaunched = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text('Verifying payment...'),
            ],
          ),
        );
      },
    );

    // Give backend time to process the webhook
    await Future.delayed(const Duration(seconds: 2));

    // Refresh counts
    ref.invalidate(contributionCountProvider);
    ref.invalidate(contributionsProvider);

    try {
      final repo = ref.read(contributionRepositoryProvider);
      final statusResponse = await repo.checkPaymentStatus(
        _currentPaymentReference!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      if (statusResponse.payment == 'success' ||
          statusResponse.payment.toLowerCase() == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment Successful! Thank you for your contribution.',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Switch to the 'Paid' tab
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not completed or still processing.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment status checked. Pull to refresh to update.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _currentPayingContribution = null;
          _currentPaymentReference = null;
        });
      }
    }
  }

  void _showPaymentDialog(Contribution contribution) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController amountController = TextEditingController(
      text: contribution.minimumAmount > 0
          ? contribution.minimumAmount.toString()
          : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Amount (${contribution.currency})',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  helperText: contribution.minimumAmount > 0
                      ? 'Minimum: ${contribution.currency} ${contribution.minimumAmount}'
                      : null,
                  helperStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (emailController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _processPayment(
                        contribution,
                        emailController.text,
                        amountController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Confirm Payment',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPayment(
    Contribution contribution,
    String email,
    String amount,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text('Initiating payment... Please wait'),
            ],
          ),
        );
      },
    );

    try {
      final repo = ref.read(contributionRepositoryProvider);
      final response = await repo.payContribution(
        contribution.participantId,
        email,
        amount,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close initiating dialog

      final Uri url = Uri.parse(response.authorizationUrl);
      if (await canLaunchUrl(url)) {
        setState(() {
          _paymentLaunched = true;
          _currentPayingContribution = contribution;
          _currentPaymentReference = response.reference;
        });
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch payment page.')),
        );
      }

      // We no longer refresh counts or show a SnackBar immediately.
      // Verification happens in didChangeAppLifecycleState when the user returns.
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(contributionCountProvider);
    final pendingAsync = ref.watch(contributionsProvider('pending'));
    final paidAsync = ref.watch(contributionsProvider('paid'));
    final historyAsync = ref.watch(contributionHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Contributions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
          ),
        ),
        centerTitle: false,
        actions: [
          TopActionBtn(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
              );
            },
          ),
          TopActionBtn(
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Profile()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      floatingActionButton: const SizedBox.shrink(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/footballbg.png'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.15 : 0.10,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: countAsync.when(
                data: (data) => _buildSummaryCard(
                  context,
                  isDark,
                  data.totalContributed,
                  data.contributedThisMonth,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryGreen,
              indicatorWeight: 3,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Paid'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending Tab
                  pendingAsync.when(
                    data: (data) {
                      final items = data.items;
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(contributionsProvider('pending').notifier)
                            .fetch(),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            ...items.map((contribution) {
                              final isFullyPaid =
                                  contribution.amountPaid >=
                                  contribution.amountDue;
                              return _buildContributionCard(
                                context: context,
                                isDark: isDark,
                                contribution: contribution,
                                isPaid: isFullyPaid,
                                onPayNow: contribution.isFullyFunded
                                    ? null
                                    : () => _showPaymentDialog(contribution),
                              );
                            }),
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text('No pending contributions.'),
                                ),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                  // Paid Tab
                  paidAsync.when(
                    data: (data) {
                      final items = data.items;
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(contributionsProvider('paid').notifier)
                            .fetch(),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            ...items.map((contribution) {
                              final isFullyPaid =
                                  contribution.amountPaid >=
                                  contribution.amountDue;
                              return _buildContributionCard(
                                context: context,
                                isDark: isDark,
                                contribution: contribution,
                                isPaid: isFullyPaid,
                                onPayNow: contribution.isFullyFunded
                                    ? null
                                    : () => _showPaymentDialog(contribution),
                              );
                            }),
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text('No paid contributions.'),
                                ),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                  // History Tab
                  historyAsync.when(
                    data: (data) {
                      final items = data.items;
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(contributionHistoryProvider.notifier)
                            .fetch(),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            ...items.map(
                              (item) =>
                                  _buildHistoryCard(context, isDark, item),
                            ),
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text('No contribution history.'),
                                ),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    bool isDark,
    int totalContributed,
    int contributedThisMonth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.bgCardDark, AppColors.bgCardDark.withOpacity(0.8)]
              : [AppColors.bgCardLight, AppColors.bgCardLight.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Total Contributed',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KSh $totalContributed',
                  style: const TextStyle(
                    color: AppColors.greenLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'This Month',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KSh $contributedThisMonth',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContributionDetails(
    BuildContext context,
    Contribution contribution,
    bool isDark,
    bool isPaid,
    VoidCallback? onPayNow,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark
              ? AppColors.bgCardDark
              : AppColors.bgCardLight,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        contribution.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            contribution.status.toLowerCase() == 'paid' ||
                                contribution.status.toLowerCase() == 'completed'
                            ? AppColors.success.withOpacity(0.12)
                            : (contribution.status.toLowerCase() == 'partial'
                                  ? Colors.blueAccent.withOpacity(0.12)
                                  : Colors.orangeAccent.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        contribution.status.isNotEmpty
                            ? contribution.status.toUpperCase()
                            : 'PENDING',
                        style: TextStyle(
                          color:
                              contribution.status.toLowerCase() == 'paid' ||
                                  contribution.status.toLowerCase() ==
                                      'completed'
                              ? AppColors.success
                              : (contribution.status.toLowerCase() == 'partial'
                                    ? Colors.blueAccent
                                    : Colors.orangeAccent),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contribution.description,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Due',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contribution.currency} ${contribution.amountDue}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaid ? 'Paid Date' : 'Due Date',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid
                              ? (contribution.paidAt ?? contribution.dueDate)
                              : contribution.dueDate,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!contribution.isFullyFunded && contribution.canPay)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onPayNow != null) onPayNow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContributionCard({
    required BuildContext context,
    required bool isDark,
    required Contribution contribution,
    required bool isPaid,
    VoidCallback? onPayNow,
  }) {
    return GestureDetector(
      onTap: () => _showContributionDetails(
        context,
        contribution,
        isDark,
        isPaid,
        onPayNow,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.bgCardDark.withOpacity(0.6)
              : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contribution.title,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contribution.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.75)
                              : Colors.black.withOpacity(0.75),
                          fontSize: 12.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        contribution.status.toLowerCase() == 'paid' ||
                            contribution.status.toLowerCase() == 'completed'
                        ? AppColors.success.withOpacity(0.12)
                        : (contribution.status.toLowerCase() == 'partial'
                              ? Colors.blueAccent.withOpacity(0.12)
                              : Colors.orangeAccent.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contribution.status.isNotEmpty
                        ? contribution.status.toUpperCase()
                        : 'PENDING',
                    style: TextStyle(
                      color:
                          contribution.status.toLowerCase() == 'paid' ||
                              contribution.status.toLowerCase() == 'completed'
                          ? AppColors.success
                          : (contribution.status.toLowerCase() == 'partial'
                                ? Colors.blueAccent
                                : Colors.orangeAccent),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Fund goal: ${contribution.currency} ${contribution.totalAmount} • Collected so far: ${contribution.currency} ${contribution.amountCollected}',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: contribution.totalAmount > 0
                      ? (contribution.amountCollected /
                                contribution.totalAmount)
                            .clamp(0.0, 1.0)
                      : 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${contribution.currency} ${contribution.amountPaid} ',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'paid by you',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Minimum: ${contribution.currency} ${contribution.minimumAmount}',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle_outline
                          : Icons.calendar_today_outlined,
                      size: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid
                          ? 'Paid: ${contribution.paidAt ?? contribution.dueDate}'
                          : 'Due: ${contribution.dueDate}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!contribution.isFullyFunded && contribution.canPay)
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onPayNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    bool isDark,
    ContributionHistoryItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${item.currency} ${item.amount}',
                style: TextStyle(
                  color: isDark ? AppColors.greenLight : AppColors.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${item.paidAt ?? item.createdAt}',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status == 'success'
                      ? (isDark
                            ? AppColors.greenLight.withOpacity(0.15)
                            : AppColors.primaryGreen.withOpacity(0.1))
                      : Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: item.status == 'success'
                        ? (isDark
                              ? AppColors.greenLight
                              : AppColors.primaryGreen)
                        : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (item.paymentMethod.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Method: ${item.paymentMethod.toUpperCase()}',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
