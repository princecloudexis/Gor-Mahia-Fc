import 'package:eventsbooking/pages/create_post.dart';
import 'package:eventsbooking/pages/group_info.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GroupDetails extends StatefulWidget {
  final Map<String, Object> group;
  final bool isJoined;

  const GroupDetails({super.key, required this.group, this.isJoined = true});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late bool _hasJoined;

  @override
  void initState() {
    super.initState();
    _hasJoined = widget.isJoined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupColor = widget.group['color'] as Color;
    final groupName = widget.group['name'] as String;
    final members = widget.group['members'] as String;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: groupColor,
              iconTheme: const IconThemeData(color: Colors.white),
              titleSpacing: 0,
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfo(group: widget.group),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            members,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _buildPostsTab(isDark),
      ),
      floatingActionButton: _hasJoined
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePost(group: widget.group),
                  ),
                );
              },
              backgroundColor: groupColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit),
            )
          : null,
      bottomNavigationBar: !_hasJoined
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasJoined = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You have successfully joined $groupName!',
                          ),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
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
                      'Join Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPostsTab(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: 5,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (widget.group['color'] as Color).withValues(
                  alpha: 0.15,
                ),
                child: Icon(
                  Icons.person,
                  color: widget.group['color'] as Color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Member ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textOnLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@member${index + 1} · ${index + 2}h',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index == 1
                          ? 'Here\'s a concept for a smart app.\n-\nWould love to hear your thoughts & feedbacks about this🙏🏽\n-\nThank you ❤️'
                          : index == 3
                          ? 'Unbelievable goal! Watch the replay here 👇'
                          : 'This is a sample post for the ${widget.group['name']}. Here members can discuss matches, share updates, and connect with other fans!',
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (index == 1) _buildTwitterStyleImageGrid(isDark),
                    if (index == 3) _buildTwitterStyleVideo(isDark),
                    if (index == 1 || index == 3) const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionItem(Icons.favorite_border, '1.2k', isDark),
                        _buildActionItem(
                          Icons.chat_bubble_outline,
                          '34',
                          isDark,
                        ),
                        _buildActionItem(Icons.poll_outlined, '124', isDark),
                        _buildActionItem(Icons.share_outlined, '12', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwitterStyleImageGrid(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: bgColor,
                width: double.infinity,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: borderColor,
                    size: 32,
                  ),
                ),
              ),
            ),
            Container(height: 1.5, color: borderColor),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: bgColor,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: borderColor,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1.5, color: borderColor), // gap
                  Expanded(
                    child: Container(
                      color: bgColor,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: borderColor,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwitterStyleVideo(bool isDark) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Icon(
                Icons.smart_display_outlined,
                color: borderColor,
                size: 48,
              ),
            ),
            Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.9),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String count, bool isDark) {
    final color = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(count, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
