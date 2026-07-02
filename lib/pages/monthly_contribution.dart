import 'package:eventsbooking/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MonthlyContribution extends StatelessWidget {
  const MonthlyContribution({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Monthly Contributions',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildCurrentMonthCard(context),
            const SizedBox(height: 24),
            _buildHistoryCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMonthCard(BuildContext context) {
    return Container(
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
            'CURRENT MONTH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'June 2024',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
                    'Amount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'KSh 100',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Not Paid',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Pay Now action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'PAY NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return Container(
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
            'CONTRIBUTION HISTORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryRow(context, 'May 2024', 'KSh 100', true),
          Divider(
            height: 32,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _buildHistoryRow(context, 'April 2024', 'KSh 100', true),
          Divider(
            height: 32,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _buildHistoryRow(context, 'March 2024', 'KSh 100', true),
          Divider(
            height: 32,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _buildHistoryRow(context, 'February 2024', 'KSh 100', true),
          Divider(
            height: 32,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _buildHistoryRow(context, 'January 2024', 'KSh 100', true),
          Divider(
            height: 32,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          _buildHistoryRow(context, 'December 2023', 'KSh 100', true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // TODO: View All History action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'VIEW ALL HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    String month,
    String amount,
    bool isPaid,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPaid
                ? AppColors.primaryGreen.withOpacity(0.15)
                : AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isPaid ? 'Paid' : 'Not Paid',
            style: TextStyle(
              color: isPaid ? AppColors.success : AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
