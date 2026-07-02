import 'package:eventsbooking/controllers/membership_controller.dart';
import 'package:eventsbooking/models/membership_models.dart';
import 'package:eventsbooking/pages/main_shell.dart';
import 'package:eventsbooking/pages/membership_payment.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/widgets/breadcrumb_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipSignup extends ConsumerStatefulWidget {
  const MembershipSignup({super.key});

  @override
  ConsumerState<MembershipSignup> createState() => _MembershipSignupState();
}

class _MembershipSignupState extends ConsumerState<MembershipSignup> {
  final _countryController = TextEditingController(text: 'Kenya');
  int? selectedBranchId;
  int? selectedPackageId;

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipControllerProvider);

    ref.listen<MembershipState>(membershipControllerProvider, (previous, next) {
      if (next.status == MembershipStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(membershipControllerProvider.notifier).resetStatus();
      } else if (next.status == MembershipStatus.success && next.submitResponse != null) {
        final response = next.submitResponse!;
        String period = 'Monthly Membership';
        if (state.data != null) {
           final pkg = state.data!.packages.where((p) => p.id == selectedPackageId).firstOrNull;
           if (pkg != null) {
             period = pkg.type.toLowerCase() == 'year' ? 'Annual Membership' : 'Monthly Membership';
           }
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MembershipPayment(
              title: response.packageName,
              price: 'KSh ${response.amount}',
              rawAmount: response.amount,
              period: period,
              membershipId: response.membershipId.toString(),
            ),
          ),
        );
        ref.read(membershipControllerProvider.notifier).resetStatus();
      }
    });

    final isLoading = state.status == MembershipStatus.loading && state.data == null;
    final isSubmitting = state.status == MembershipStatus.submitting;

    if (state.data != null) {
      if (selectedBranchId == null && state.data!.branches.isNotEmpty) {
        selectedBranchId = state.data!.branches.first.id;
      }
      if (selectedPackageId == null && state.data!.packages.isNotEmpty) {
        selectedPackageId = state.data!.packages.first.id;
      }
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
          'Membership',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BreadcrumbTabBar(activeStep: 3),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildCountryTextField(),
                          const SizedBox(height: 16),
                          if (state.data != null && state.data!.branches.isNotEmpty)
                            _buildDropdownField<int>(
                              label: 'Select Branch',
                              value: selectedBranchId,
                              items: state.data!.branches
                                  .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => selectedBranchId = val);
                              },
                              delay: 2,
                            ),
                          const SizedBox(height: 32),
                          const Text(
                                'MEMBERSHIP TYPE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 16),
                          if (state.data != null && state.data!.packages.isNotEmpty)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: state.data!.packages.asMap().entries.map((entry) {
                                int idx = entry.key;
                                MembershipPackage pkg = entry.value;
                                return FractionallySizedBox(
                                  widthFactor: state.data!.packages.length > 1 ? 0.47 : 1.0,
                                  child: _buildMembershipCard(
                                    package: pkg,
                                    delay: 4 + idx,
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 48),
                          _buildContinueButton(isSubmitting),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Country',
            style: TextStyle(
              color: AppColors.textSecondaryDark.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: _countryController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your country',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms, delay: 100.ms)
    .slideY(begin: 0.05);
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required int delay,
  }) {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondaryDark.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  dropdownColor: AppColors.bgSurfaceDark,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: onChanged,
                  items: items,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (delay * 100).ms)
        .slideY(begin: 0.05);
  }

  Widget _buildMembershipCard({
    required MembershipPackage package,
    required int delay,
  }) {
    final isSelected = selectedPackageId == package.id;
    IconData icon = Icons.shield_outlined;
    if (package.name.toLowerCase().contains('premium')) {
      icon = Icons.workspace_premium_outlined;
    }

    return GestureDetector(
          onTap: () => setState(() => selectedPackageId = package.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.greenMedium.withOpacity(0.1)
                  : AppColors.bgSurfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.white.withOpacity(0.05),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  package.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'KSh ${package.price} / ${package.type}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ).animate().scale(duration: 300.ms, curve: Curves.elasticOut)
                else
                  const SizedBox(
                    height: 24,
                  ), 
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (delay * 100).ms)
        .slideY(begin: 0.1);
  }

  Widget _buildContinueButton(bool isSubmitting) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () {
                    if (selectedBranchId == null || selectedPackageId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select branch and package')),
                      );
                      return;
                    }

                    ref.read(membershipControllerProvider.notifier).submitMembership(
                          country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'Kenya',
                          branchId: selectedBranchId.toString(),
                          packageId: selectedPackageId.toString(),
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'CONTINUE TO PAYMENT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Skip option directly to dashboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          },
          child: Text(
            'Skip for Now',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
      ],
    );
  }
}
