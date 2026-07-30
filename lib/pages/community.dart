import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../theme/app_colors.dart';
import 'group_details.dart';
import '../providers/community_providers.dart';
import '../models/community_models.dart';
import '../api/api_client.dart';
import '../repositories/community_repository.dart';
import 'profile.dart';
import 'search.dart';
import '../widgets/top_action_btn.dart';

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
          title: Text(
            'Community',
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
              Tab(text: 'My Groups'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/footballbg.png'),
              fit: BoxFit.cover,
              opacity: isDark ? 0.15 : 0.10,
            ),
          ),
          child: const TabBarView(children: [_MyGroupsTab(), _DiscoverTab()]),
        ),
      ),
    );
  }
}

class _MyGroupsTab extends ConsumerStatefulWidget {
  const _MyGroupsTab();

  @override
  ConsumerState<_MyGroupsTab> createState() => _MyGroupsTabState();
}

class _MyGroupsTabState extends ConsumerState<_MyGroupsTab>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(joinedGroupsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final joinedGroupsAsync = ref.watch(joinedGroupsProvider);
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return joinedGroupsAsync.when(
      loading: () => _buildSkeleton(isDark),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load groups',
              style: TextStyle(
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(joinedGroupsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(joinedGroupsProvider.future),
            color: AppColors.primaryGreen,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Groups Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textOnLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join a group to connect with other fans.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            DefaultTabController.of(context).animateTo(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Discover Groups',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(joinedGroupsProvider.future),
          color: AppColors.primaryGreen,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildGroupCard(
                context,
                group,
                isDark,
                storageBaseUrl,
                isJoined: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        color: isDark ? Colors.white : Colors.black,
        colorOpacity: 0.1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaveConfirmationSheet(
    BuildContext context,
    CommunityGroup group,
    bool isDark,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(sheetCtx).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Leave Group?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to leave "${group.name}"? You will no longer have access to group posts and activities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Yes, Leave Group',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetCtx, false),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final message = await ref
          .read(communityRepositoryProvider)
          .leaveGroup(group.id);
      ref.invalidate(joinedGroupsProvider);
      ref.invalidate(exploreGroupsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildGroupCard(
    BuildContext context,
    CommunityGroup group,
    bool isDark,
    String storageBaseUrl, {
    required bool isJoined,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgCardDark.withValues(alpha: 0.8)
            : AppColors.bgCardLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GroupDetails(group: group, isJoined: isJoined),
              ),
            );
          },
          onLongPress: isJoined
              ? () => _showLeaveConfirmationSheet(context, group, isDark)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'group_avatar_${group.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: group.imageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                group.getFullImageUrl(storageBaseUrl),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: group.imageUrl == null
                        ? Icon(
                            Icons.groups,
                            color: AppColors.primaryGreen,
                            size: 32,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textOnLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.type == 'private') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.lock_open_outlined,
                              size: 16,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.membersCount} members',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(exploreGroupsProvider.notifier)
          .fetchInitial(_searchController.text);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(exploreGroupsProvider.notifier)
          .fetchInitial(_searchController.text);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(exploreGroupsProvider.notifier).fetchNextPage();
    }
  }

  void _showJoinBottomSheet(
    BuildContext context,
    CommunityGroup group,
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
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                radius: 36,
                child: const Icon(
                  Icons.lock_person,
                  color: AppColors.primaryGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Join ${group.name}',
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
                  onPressed: () async {
                    try {
                      await ref
                          .read(exploreGroupsProvider.notifier)
                          .requestJoinGroup(group.id);
                      if (mounted) Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Join request sent for ${group.name}!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
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
                    'Request to Join',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    final state = ref.watch(exploreGroupsProvider);
    final storageBaseUrl = ref.watch(storageBaseUrlProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search for groups...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                prefixIcon: const Icon(
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
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        // Search Results List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(exploreGroupsProvider.notifier)
                .fetchInitial(_searchController.text),
            color: AppColors.primaryGreen,
            child: state.groups.isEmpty && state.isLoading
                ? _buildSkeleton(isDark)
                : state.groups.isEmpty
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No groups found',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textOnDark
                                      : AppColors.textOnLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount:
                        state.groups.length + (state.hasNextPage ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == state.groups.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      }
                      final group = state.groups[index];
                      return _buildGroupCard(
                        context,
                        group,
                        isDark,
                        storageBaseUrl,
                        isJoined: false,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        color: isDark ? Colors.white : Colors.black,
        colorOpacity: 0.1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    CommunityGroup group,
    bool isDark,
    String storageBaseUrl, {
    required bool isJoined,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgCardDark.withValues(alpha: 0.8)
            : AppColors.bgCardLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (group.isPending) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your request to join this private group is pending approval.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            if (group.type == 'private') {
              _showJoinBottomSheet(context, group, isDark);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupDetails(group: group, isJoined: false),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'group_avatar_${group.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: group.imageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                group.getFullImageUrl(storageBaseUrl),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: group.imageUrl == null
                        ? const Icon(
                            Icons.groups,
                            color: AppColors.primaryGreen,
                            size: 32,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textOnLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.type == 'private') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.membersCount} members',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: group.isPending
                        ? Colors.grey.withValues(alpha: 0.1)
                        : AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.isPending ? 'Requested' : 'View',
                    style: TextStyle(
                      color: group.isPending
                          ? (isDark ? Colors.grey[400] : Colors.grey[700])
                          : AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
