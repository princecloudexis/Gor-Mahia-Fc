import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/community_models.dart';
import '../providers/community_providers.dart';
import '../api/api_client.dart';

class GroupInfo extends ConsumerStatefulWidget {
  final CommunityGroup group;

  const GroupInfo({super.key, required this.group});

  @override
  ConsumerState<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends ConsumerState<GroupInfo> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(groupMembersProvider(widget.group.id).notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupColor = AppColors.primaryGreen;
    final groupName = widget.group.name;
    final membersStr = '${widget.group.membersCount} members';
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    final description =
        widget.group.description ??
        'Welcome to the official branch of Gor Mahia fans! Here we discuss matchday events, share updates, and connect with other passionate supporters. Join us to be part of the vibrant community!';

    String createdAt = 'Created October 12, 2024';
    if (widget.group.createdAt != null) {
      try {
        final date = DateTime.parse(widget.group.createdAt!);
        createdAt = 'Created ${DateFormat('MMMM d, yyyy').format(date)}';
      } catch (e) {
        // Fallback if parsing fails
      }
    }

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
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Big Group Icon
            CircleAvatar(
              radius: 50,
              backgroundColor: groupColor.withValues(alpha: 0.2),
              backgroundImage: widget.group.imageUrl != null
                  ? CachedNetworkImageProvider(widget.group.getFullImageUrl(storageBaseUrl))
                  : null,
              child: widget.group.imageUrl == null
                  ? Icon(Icons.groups, size: 54, color: groupColor)
                  : null,
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
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
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
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
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
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textOnLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    membersStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Real Member List from API
            Builder(
              builder: (context) {
                final state = ref.watch(groupMembersProvider(widget.group.id));
                if (state.isLoading && state.members.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  );
                }
                if (state.members.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No members found.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: state.members.length,
                  itemBuilder: (context, index) {
                    final member = state.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        backgroundImage: member.avatarUrl != null
                            ? NetworkImage(member.getFullAvatarUrl(storageBaseUrl))
                            : null,
                        child: member.avatarUrl == null
                            ? Icon(
                                Icons.person,
                                color: isDark ? Colors.white54 : Colors.black54,
                              )
                            : null,
                      ),
                      title: Text(
                        member.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textOnLight,
                        ),
                      ),
                      subtitle: Text(
                        member.role,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            Builder(
              builder: (context) {
                final state = ref.watch(groupMembersProvider(widget.group.id));
                if (state.isLoading && state.members.isNotEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                }
                return const SizedBox();
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
