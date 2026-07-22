import 'dart:async';
import 'package:eventsbooking/models/contribution_models.dart';
import 'package:eventsbooking/providers/contribution_providers.dart';
import 'package:eventsbooking/repositories/contribution_repository.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile.dart';
import 'search.dart';
import '../widgets/top_action_btn.dart';

class MonthlyContribution extends ConsumerStatefulWidget {
  const MonthlyContribution({super.key});

  @override
  ConsumerState<MonthlyContribution> createState() => _MonthlyContributionState();
}

class _MonthlyContributionState extends ConsumerState<MonthlyContribution> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPaymentDialog(Contribution contribution) {
    final TextEditingController phoneController = TextEditingController();
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
                'Enter Phone Number',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 0712345678',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (phoneController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _processPayment(contribution, phoneController.text);
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

  Future<void> _processPayment(Contribution contribution, String phone) async {
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
      final response = await repo.payContribution(contribution.participantId, phone);
      final checkoutId = response.checkoutRequestId;

      if (!mounted) return;
      Navigator.pop(context); // Close initiating dialog
      
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
                Text('Awaiting M-Pesa pin...'),
              ],
            ),
          );
        },
      );

      // Polling loop
      bool isSuccess = false;
      PaymentStatusResponse? statusResponse;
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final status = await repo.checkPaymentStatus(checkoutId);
          if (status.payment == 'success') {
            isSuccess = true;
            statusResponse = status;
            break;
          } else if (status.payment == 'failed') {
            break;
          }
        } catch (_) {} // Ignore polling errors and continue
      }

      if (!mounted) return;
      Navigator.pop(context); // Close polling dialog

      if (isSuccess && statusResponse?.participant != null) {
        // Update local state
        ref.read(contributionsProvider('pending').notifier).updateItemAsPaid(statusResponse!.participant!);
        // Refresh counts
        ref.invalidate(contributionCountProvider);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Column(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Congratulations!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                'Your payment was successful.',
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Great',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed or timed out.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(contributionCountProvider);
    final pendingAsync = ref.watch(contributionsProvider('pending'));
    final paidAsync = ref.watch(contributionsProvider('paid'));

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: countAsync.when(
              data: (data) => _buildSummaryCard(context, isDark, data.totalContributed, data.pending),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Paid'),
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
                      onRefresh: () => ref.read(contributionsProvider('pending').notifier).fetch(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          ...items.map((contribution) => _buildContributionCard(
                            context: context,
                            isDark: isDark,
                            contribution: contribution,
                            isPaid: false,
                            onPayNow: () => _showPaymentDialog(contribution),
                          )),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: Text('No pending contributions.')),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
                // Paid Tab
                paidAsync.when(
                  data: (data) {
                    final items = data.items;
                    return RefreshIndicator(
                      onRefresh: () => ref.read(contributionsProvider('paid').notifier).fetch(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          ...items.map((contribution) => _buildContributionCard(
                            context: context,
                            isDark: isDark,
                            contribution: contribution,
                            isPaid: true,
                          )),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: Text('No paid contributions.')),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDark, int totalContributed, int totalPending) {
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
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
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
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
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
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Pending Items',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalPending',
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

  Widget _buildContributionCard({
    required BuildContext context,
    required bool isDark,
    required Contribution contribution,
    required bool isPaid,
    VoidCallback? onPayNow,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark.withOpacity(0.6) : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
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
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.description,
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        fontSize: 11,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.success.withOpacity(0.12) : Colors.orangeAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'PENDING',
                  style: TextStyle(
                    color: isPaid ? AppColors.success : Colors.orangeAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${contribution.currency} ${contribution.amountPaid}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${contribution.currency} ${contribution.amountPaid + contribution.amountDue}',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (contribution.amountPaid + contribution.amountDue) > 0 
                  ? contribution.amountPaid / (contribution.amountPaid + contribution.amountDue) 
                  : 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.success : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
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
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${contribution.dueDate}',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isPaid && contribution.canPay)
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
    );
  }
}
