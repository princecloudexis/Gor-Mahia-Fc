import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'coming_soon.dart';
import 'group_details.dart';
import 'search_groups.dart';

class Community extends StatelessWidget {
  const Community({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
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
              Tab(text: 'Groups'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroupsTab(),
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

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final groups = [
      {
        'name': 'Nairobi Group',
        'members': '1,245 members',
        'color': Colors.green.shade700,
        'type': 'public',
      },
      {
        'name': 'Kisumu Group',
        'members': '892 members',
        'color': Colors.green.shade900,
        'type': 'private',
      },
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: group['color'] as Color,
                    radius: 22,
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    group['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      group['members'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (group['type'] == 'private') ...[
                        Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetails(group: group),
                      ),
                    );
                  },
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchGroups(),
                  ),
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
              child: const Text(
                '+ EXPLORE MORE GROUPS',
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
