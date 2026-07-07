import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'group_details.dart';

class SearchGroups extends StatefulWidget {
  const SearchGroups({super.key});

  @override
  State<SearchGroups> createState() => _SearchGroupsState();
}

class _SearchGroupsState extends State<SearchGroups> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, Object>> _filteredGroups = [];

  // Mock list of all groups (excluding the ones already joined like Nairobi/Kisumu)
  final List<Map<String, Object>> _allGroups = [
    {
      'name': 'Mombasa Group',
      'members': '678 members',
      'color': Colors.purple.shade700,
      'type': 'public',
    },
    {
      'name': 'Eldoret Group',
      'members': '543 members',
      'color': Colors.lightGreen.shade700,
      'type': 'private',
    },
    {
      'name': 'Nakuru Group',
      'members': '512 members',
      'color': Colors.blueGrey.shade700,
      'type': 'public',
    },
    {
      'name': 'Kakamega Branch',
      'members': '450 members',
      'color': Colors.orange.shade700,
      'type': 'public',
    },
    {
      'name': 'Siaya Branch',
      'members': '320 members',
      'color': Colors.teal.shade700,
      'type': 'private',
    },
    {
      'name': 'Diaspora Branch (UK)',
      'members': '850 members',
      'color': Colors.indigo.shade700,
      'type': 'public',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(_allGroups);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_allGroups);
      } else {
        _filteredGroups = _allGroups.where((group) {
          final name = (group['name'] as String).toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  void _showJoinBottomSheet(
    BuildContext context,
    Map<String, Object> group,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDark : AppColors.bgLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                backgroundColor: (group['color'] as Color).withValues(
                  alpha: 0.15,
                ),
                radius: 36,
                child: Icon(
                  Icons.lock_person,
                  color: group['color'] as Color,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Join ${group['name']}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is a private group. You need to request access to join and view its members and activities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Join request sent for ${group['name']}!',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Request to Join',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textOnDark
                        : AppColors.textOnLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
        ),
        title: Text(
          'Search Groups',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search for groups or branches...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primaryGreen,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Search Results List
          Expanded(
            child: _filteredGroups.isEmpty
                ? Center(
                    child: Text(
                      'No groups found matching "${_searchController.text}"',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: _filteredGroups.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = _filteredGroups[index];
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
                            if (group['type'] == 'private') {
                              _showJoinBottomSheet(context, group, isDark);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupDetails(
                                    group: group,
                                    isJoined: false,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
