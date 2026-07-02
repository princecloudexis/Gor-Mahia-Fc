import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Community extends StatelessWidget {
  const Community({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          elevation: 0,
          title: Center(
            child: Text(
              'Community',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            labelColor: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            unselectedLabelColor: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Branches'),
              Tab(text: 'Groups'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BranchesTab(),
            Center(
              child: Text(
                'Groups functionality coming soon!',
                style: TextStyle(fontSize: 16),
              ),
            ),
            Center(
              child: Text(
                'Members functionality coming soon!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchesTab extends StatelessWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final branches = [
      {'name': 'Nairobi Branch', 'members': '1,245 members', 'color': Colors.green.shade700},
      {'name': 'Kisumu Branch', 'members': '892 members', 'color': Colors.green.shade900},
      {'name': 'Mombasa Branch', 'members': '678 members', 'color': Colors.purple.shade700},
      {'name': 'Eldoret Branch', 'members': '543 members', 'color': Colors.lightGreen.shade700},
      {'name': 'Nakuru Branch', 'members': '512 members', 'color': Colors.blueGrey.shade700},
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: branches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final branch = branches[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: branch['color'] as Color,
                    radius: 22,
                    child: const Icon(Icons.diversity_3, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    branch['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      branch['members'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  onTap: () {},
                ),
              );
            },
          ),
        ),
        // Join Button
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ JOIN A BRANCH',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
