import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GroupInfo extends StatelessWidget {
  final Map<String, Object> group;

  const GroupInfo({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupColor = group['color'] as Color? ?? AppColors.primaryGreen;
    final groupName = group['name'] as String? ?? 'Group Name';
    final membersStr = group['members'] as String? ?? '0 members';
    
    // Fallback data since it's not in the mock maps yet
    final description = group['description'] as String? ?? 
        'Welcome to the official branch of Gor Mahia fans! Here we discuss matchday events, share updates, and connect with other passionate supporters. Join us to be part of the vibrant community!';
    final createdAt = group['createdAt'] as String? ?? 'Created October 12, 2024';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
        ),
        title: Text(
          'Group Info',
          style: TextStyle(
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Big Group Icon
            CircleAvatar(
              radius: 50,
              backgroundColor: groupColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.groups,
                size: 54,
                color: groupColor,
              ),
            ),
            const SizedBox(height: 16),
            // Group Name
            Text(
              groupName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
            ),
            const SizedBox(height: 8),
            // Creation Date
            Text(
              createdAt,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            
            const SizedBox(height: 24),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),

            // Description Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About this Group',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 24),

            // Members List Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    membersStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Mock Member List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 15, // Display 15 mock members
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.black.withValues(alpha: 0.05),
                    child: Icon(
                      Icons.person,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  title: Text(
                    index == 0 ? 'You' : 'Member $index',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                    ),
                  ),
                  subtitle: Text(
                    index == 0 ? 'Admin' : 'Fan',
                    style: TextStyle(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
