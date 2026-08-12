import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gormahiafc/providers/theme_provider.dart';
import 'package:gormahiafc/theme/apptheme.dart';
import 'package:gormahiafc/controllers/auth_controller.dart';
import 'package:gormahiafc/pages/login.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColorDark
          : AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildThemeSection(context, ref, currentTheme, isDark),
          const SizedBox(height: 16),
          _LogoutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    ThemeModeOption currentTheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: isDark ? AppTheme.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDarkInDarkMode : AppTheme.textDark,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildThemeOption(
                context: context,
                ref: ref,
                title: 'Light',
                subtitle: 'Always use light theme',
                icon: Icons.light_mode,
                value: ThemeModeOption.light,
                groupValue: currentTheme,
                isDark: isDark,
              ),
              _buildThemeOption(
                context: context,
                ref: ref,
                title: 'Dark',
                subtitle: 'Always use dark theme',
                icon: Icons.dark_mode,
                value: ThemeModeOption.dark,
                groupValue: currentTheme,
                isDark: isDark,
              ),
              _buildThemeOption(
                context: context,
                ref: ref,
                title: 'System Default',
                subtitle: 'Follow system settings',
                icon: Icons.settings_brightness,
                value: ThemeModeOption.system,
                groupValue: currentTheme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeModeOption value,
    required ThemeModeOption groupValue,
    required bool isDark,
  }) {
    final isSelected = value == groupValue;

    return RadioListTile<ThemeModeOption>(
      title: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.accentRed
                : (isDark ? AppTheme.textLightInDarkMode : AppTheme.textLight),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isDark ? AppTheme.textDarkInDarkMode : AppTheme.textDark,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textLightInDarkMode : AppTheme.textLight,
          ),
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppTheme.accentRed,
      onChanged: (ThemeModeOption? newValue) {
        if (newValue != null) {
          ref.read(themeProvider.notifier).setThemeMode(newValue);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// LOGOUT BUTTON
// ─────────────────────────────────────────────
class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        icon: const Icon(Icons.logout, size: 18, color: AppTheme.accentRed),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: AppTheme.accentRed,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: AppTheme.accentRed.withOpacity(0.5),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
              );
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}