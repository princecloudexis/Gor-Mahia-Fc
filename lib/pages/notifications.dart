import 'dart:ui';
import 'package:kogalo_network/providers/notifications_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/apptheme.dart';
import '../models/notification_model.dart';
import '../repositories/community_repository.dart';
import 'group_details.dart';

class Notifications extends ConsumerStatefulWidget {
  const Notifications({super.key});

  @override
  ConsumerState<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<Notifications> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isNotificationsPageVisibleProvider.notifier).state = true;
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
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
    final notificationState = ref.watch(notificationsProvider);
    final notifications = notificationState.notifications;
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── App Bar ──
          _AppBar(
            hasNotifications: notifications.isNotEmpty,
            unreadCount: unreadCount,
          ),

          // ── Unread badge bar ──
          if (unreadCount > 0) _UnreadBar(unreadCount: unreadCount),

          // ── Content ──
          if (notifications.isEmpty)
            const _EmptyState()
          else
            _NotificationList(notifications: notifications),

          if (notificationState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR — minimal flat
// ─────────────────────────────────────────────
class _AppBar extends ConsumerWidget {
  final bool hasNotifications;
  final int unreadCount;
  const _AppBar({required this.hasNotifications, required this.unreadCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          if (unreadCount > 0)
            Text(
              '$unreadCount unread',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryPink,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'All caught up',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
        ],
      ),
      actions: [
        if (hasNotifications)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showClearDialog(context, ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentRed,
                  ),
                ),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear All?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'All notifications will be removed. This cannot be undone.',
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
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: Text(
              'Clear All',
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

// ─────────────────────────────────────────────
// UNREAD BAR — slim sticky indicator
// ─────────────────────────────────────────────
class _UnreadBar extends StatelessWidget {
  final int unreadCount;
  const _UnreadBar({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primaryPink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'You have $unreadCount unread '
              'notification${unreadCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION LIST
// ─────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverList.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _NotificationTile(
                notification: notifications[index],
                index: index,
              )
              .animate()
              .fadeIn(duration: 350.ms, delay: (60 * (index % 10)).ms)
              .slideY(begin: 0.08, end: 0);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFICATION TILE — clean card
// ─────────────────────────────────────────────
class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final int index;
  const _NotificationTile({required this.notification, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref
            .read(notificationsProvider.notifier)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Notification removed'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.accentRed,
          size: 22,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (isUnread) {
            ref
                .read(notificationsProvider.notifier)
                .markAsRead(notification.id);
          }

          // Parse the backend target_url for precise navigation
          final nav = notification.parsedTargetUrl;
          final parsedGroupId = nav['groupId'] ?? notification.groupId;
          final parsedPostId = nav['postId'] ?? notification.postId;

          if (notification.eventSlug != null) {
            Navigator.pushNamed(
              context,
              '/event-details',
              arguments: notification.eventSlug,
            );
          } else if (parsedGroupId != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            try {
              final group = await ref
                  .read(communityRepositoryProvider)
                  .fetchGroupDetails(parsedGroupId);
              if (context.mounted) {
                Navigator.pop(context); // hide loading
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetails(
                      group: group,
                      isJoined: group.isJoined,
                      initialPostId: parsedPostId,
                      initialCommentId: nav['commentId'],
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); // hide loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to load group details'),
                  ),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnread
                ? AppTheme.primaryPink.withValues(alpha: 0.04)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? AppTheme.primaryPink.withValues(alpha: 0.25)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon / Avatar ──
              if (notification.senderAvatar != null && notification.senderAvatar!.isNotEmpty)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(notification.senderAvatar!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                _TypeIcon(type: notification.type),
              const SizedBox(width: 12),

              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + unread dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryPink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      formatTimestamp(notification.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Arrow if tappable ──
              if (notification.eventSlug != null ||
                  notification.groupId != null ||
                  notification.targetUrl != null) ...[ 
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TYPE ICON — compact colored square
// ─────────────────────────────────────────────
class _TypeIcon extends StatelessWidget {
  final NotificationType type;
  const _TypeIcon({required this.type});

  IconData get _icon {
    switch (type) {
      case NotificationType.event:
        return Icons.event_available_rounded;
      case NotificationType.reminder:
        return Icons.alarm_on_rounded;
      case NotificationType.offer:
        return Icons.local_offer_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
      case NotificationType.reply:
        return Icons.comment_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case NotificationType.event:
        return AppTheme.primaryPink;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.offer:
        return Colors.green;
      case NotificationType.system:
        return Colors.blueGrey;
      case NotificationType.like:
        return Colors.redAccent;
      case NotificationType.comment:
      case NotificationType.reply:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Icon(_icon, color: _color, size: 18),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "You're all caught up!\nWe'll notify you when something's new.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.5),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TIMESTAMP HELPER
// ─────────────────────────────────────────────
String formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}
