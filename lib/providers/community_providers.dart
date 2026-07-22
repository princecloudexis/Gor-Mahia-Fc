import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';
import '../repositories/community_repository.dart';

// 1. Fetch Joined Groups
final joinedGroupsProvider = FutureProvider.autoDispose<List<CommunityGroup>>((
  ref,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.fetchJoinedGroups();
});

// 1.5 Fetch GIFs
class GifState {
  final List<CommunityGif> gifs;
  final bool isLoading;
  final String? nextCursor;
  final bool hasNextPage;

  GifState({
    this.gifs = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasNextPage = true,
  });

  GifState copyWith({
    List<CommunityGif>? gifs,
    bool? isLoading,
    String? nextCursor,
    bool? hasNextPage,
  }) {
    return GifState(
      gifs: gifs ?? this.gifs,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class GifNotifier extends StateNotifier<GifState> {
  final CommunityRepository repo;
  final String query;

  GifNotifier(this.repo, this.query) : super(GifState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    if (state.gifs.isEmpty) {
      state = GifState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, nextCursor: null, hasNextPage: true);
    }
    try {
      final response = await repo.fetchGifs(search: query.isEmpty ? null : query);
      if (!mounted) return;
      state = state.copyWith(
        gifs: response.data,
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchInitial gifs: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await repo.fetchGifs(
        search: query.isEmpty ? null : query,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      state = state.copyWith(
        gifs: [...state.gifs, ...response.data],
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchNextPage gifs: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }
}

final gifProvider = StateNotifierProvider.autoDispose.family<GifNotifier, GifState, String>((ref, query) {
  final repo = ref.watch(communityRepositoryProvider);
  return GifNotifier(repo, query);
});

// 2. Explore Groups Pagination Notifier
class ExploreGroupsState {
  final List<CommunityGroup> groups;
  final bool isLoading;
  final String? nextCursor;
  final bool hasNextPage;

  ExploreGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasNextPage = true,
  });

  ExploreGroupsState copyWith({
    List<CommunityGroup>? groups,
    bool? isLoading,
    String? nextCursor,
    bool? hasNextPage,
  }) {
    return ExploreGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class ExploreGroupsNotifier extends StateNotifier<ExploreGroupsState> {
  final CommunityRepository repo;
  String _currentQuery = '';

  ExploreGroupsNotifier(this.repo) : super(ExploreGroupsState()) {
    fetchInitial('');
  }

  Future<void> fetchInitial(String query) async {
    final isNewSearch = _currentQuery != query || state.groups.isEmpty;
    _currentQuery = query;
    if (isNewSearch) {
      state = ExploreGroupsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, nextCursor: null, hasNextPage: true);
    }
    try {
      final response = await repo.exploreGroups(query: query);
      if (!mounted) return;
      state = state.copyWith(
        groups: response.data,
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchInitial explore: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await repo.exploreGroups(
        query: _currentQuery,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      state = state.copyWith(
        groups: [...state.groups, ...response.data],
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchNextPage explore: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await repo.joinGroup(groupId);
      // Remove from explore list if joined immediately
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestJoinGroup(String groupId) async {
    try {
      await repo.requestJoinGroup(groupId);
      // Mark as pending instead of removing
      final groupIndex = state.groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        state.groups[groupIndex].joinStatus = 'pending';
        state = state.copyWith(groups: [...state.groups]);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final exploreGroupsProvider =
    StateNotifierProvider.autoDispose<
      ExploreGroupsNotifier,
      ExploreGroupsState
    >((ref) {
      final repo = ref.watch(communityRepositoryProvider);
      return ExploreGroupsNotifier(repo);
    });

// 3. Group Posts Pagination Notifier
class GroupPostsState {
  final List<CommunityPost> posts;
  final bool isLoading;
  final String? nextCursor;
  final bool hasNextPage;

  GroupPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasNextPage = true,
  });

  GroupPostsState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    String? nextCursor,
    bool? hasNextPage,
  }) {
    return GroupPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class GroupPostsNotifier extends StateNotifier<GroupPostsState> {
  final CommunityRepository repo;
  final String groupId;

  GroupPostsNotifier(this.repo, this.groupId) : super(GroupPostsState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    if (state.posts.isEmpty) {
      state = GroupPostsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, nextCursor: null, hasNextPage: true);
    }
    try {
      final response = await repo.fetchGroupPosts(groupId);
      if (!mounted) return;
      state = state.copyWith(
        posts: response.data,
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchInitial posts: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await repo.fetchGroupPosts(
        groupId,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...response.data],
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchNextPage posts: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleLike(String postId) async {
    // Optimistic update
    final prevPosts = [...state.posts];
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = state.posts[postIndex];
      final wasLiked = post.isLikedByMe;

      // Update state locally
      post.isLikedByMe = !wasLiked;
      post.likesCount = wasLiked ? post.likesCount - 1 : post.likesCount + 1;
      state = state.copyWith(posts: [...state.posts]);

      // Call API
      try {
        final result = await repo.toggleLikePost(postId);
        // Sync with API result if needed
        post.isLikedByMe = result['liked'] == true;
        post.likesCount = result['likesCount'] as int? ?? post.likesCount;
        if (mounted) {
          state = state.copyWith(posts: [...state.posts]);
        }
      } catch (e) {
        // Revert on error
        post.isLikedByMe = wasLiked;
        post.likesCount = wasLiked ? post.likesCount + 1 : post.likesCount - 1;
        if (mounted) {
          state = state.copyWith(posts: [...state.posts]);
        }
        rethrow;
      }
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await repo.deletePost(postId);
      // Remove locally
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> editPost(String postId, String content, {List<CommunityMedia>? media, int? gifId}) async {
    try {
      final updatedPost = await repo.editPost(postId, content, media ?? [], gifId: gifId);
      final postIndex = state.posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        if (updatedPost.updatedAt == null) {
          updatedPost.updatedAt = DateTime.now().toIso8601String();
        }
        final newPosts = [...state.posts];
        newPosts[postIndex] = updatedPost;
        state = state.copyWith(posts: newPosts);
      }
    } catch (e) {
      debugPrint('Error editing post: $e');
      rethrow;
    }
  }

  void incrementCommentCount(String postId) {
    final prevPosts = [...state.posts];
    final postIndex = prevPosts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      prevPosts[postIndex].commentsCount += 1;
      state = state.copyWith(posts: prevPosts);
    }
  }

  Future<String?> voteOnPoll(String postId, int optionIndex) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = state.posts[postIndex];
      
      // Optimistic update
      if (post.pollData != null) {
        post.pollVotesCount += 1;
        post.pollData!.totalVotes += 1;
        post.pollData!.hasVoted = true;
        if (optionIndex >= 0 && optionIndex < post.pollData!.options.length) {
          post.pollData!.options[optionIndex].votes += 1;
        }

        state = state.copyWith(posts: [...state.posts]);

        try {
          await repo.votePoll(post.pollData!.id, optionIndex);
          return null;
        } catch (e) {
          // Revert on error
          post.pollVotesCount -= 1;
          post.pollData!.totalVotes -= 1;
          post.pollData!.hasVoted = false;
          if (optionIndex >= 0 && optionIndex < post.pollData!.options.length) {
            post.pollData!.options[optionIndex].votes -= 1;
          }
          if (mounted) {
            state = state.copyWith(posts: [...state.posts]);
          }
          return e.toString().replaceAll('Exception: ', '');
        }
      }
    }
    return 'Post not found';
  }

  Future<void> incrementShare(String postId) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = state.posts[postIndex];
      post.sharesCount += 1;
      state = state.copyWith(posts: [...state.posts]);

      try {
        await repo.sharePost(postId);
      } catch (e) {
        post.sharesCount -= 1;
        if (mounted) {
          state = state.copyWith(posts: [...state.posts]);
        }
        debugPrint('Error sharing post: $e');
      }
    }
  }
}

final groupPostsProvider = StateNotifierProvider.family
    .autoDispose<GroupPostsNotifier, GroupPostsState, String>((ref, groupId) {
      final repo = ref.watch(communityRepositoryProvider);
      return GroupPostsNotifier(repo, groupId);
    });

// 4. Fetch Group Members Pagination
class GroupMembersState {
  final List<CommunityMember> members;
  final bool isLoading;
  final String? nextCursor;
  final bool hasNextPage;

  GroupMembersState({
    this.members = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasNextPage = true,
  });

  GroupMembersState copyWith({
    List<CommunityMember>? members,
    bool? isLoading,
    String? nextCursor,
    bool? hasNextPage,
  }) {
    return GroupMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class GroupMembersNotifier extends StateNotifier<GroupMembersState> {
  final CommunityRepository repo;
  final String groupId;

  GroupMembersNotifier(this.repo, this.groupId) : super(GroupMembersState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    if (state.members.isEmpty) {
      state = GroupMembersState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, nextCursor: null, hasNextPage: true);
    }
    try {
      final response = await repo.fetchGroupMembers(groupId);
      if (!mounted) return;
      state = state.copyWith(
        members: response.data,
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchInitial members: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await repo.fetchGroupMembers(
        groupId,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      state = state.copyWith(
        members: [...state.members, ...response.data],
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchNextPage members: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }
}

final groupMembersProvider = StateNotifierProvider.family
    .autoDispose<GroupMembersNotifier, GroupMembersState, String>((
      ref,
      groupId,
    ) {
      final repo = ref.watch(communityRepositoryProvider);
      return GroupMembersNotifier(repo, groupId);
    });

// 4. Post Comments Pagination Notifier
class PostCommentsState {
  final List<CommunityComment> comments;
  final bool isLoading;
  final String? nextCursor;
  final bool hasNextPage;

  PostCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasNextPage = true,
  });

  PostCommentsState copyWith({
    List<CommunityComment>? comments,
    bool? isLoading,
    String? nextCursor,
    bool? hasNextPage,
  }) {
    return PostCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class PostCommentsNotifier extends StateNotifier<PostCommentsState> {
  final CommunityRepository repo;
  final String postId;

  PostCommentsNotifier(this.repo, this.postId) : super(PostCommentsState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    if (state.comments.isEmpty) {
      state = PostCommentsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, nextCursor: null, hasNextPage: true);
    }
    try {
      final response = await repo.fetchComments(postId);
      if (!mounted) return;
      state = state.copyWith(
        comments: response.data,
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
      // Auto-fetch replies for comments that have replies
      for (final comment in response.data) {
        if (comment.repliesCount > 0) {
          fetchReplies(comment.id);
        }
      }
    } catch (e) {
      debugPrint('Error fetchInitial comments: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasNextPage) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await repo.fetchComments(
        postId,
        cursor: state.nextCursor,
      );
      if (!mounted) return;
      state = state.copyWith(
        comments: [...state.comments, ...response.data],
        isLoading: false,
        nextCursor: response.nextCursor,
        hasNextPage: response.hasNextPage,
      );
    } catch (e) {
      debugPrint('Error fetchNextPage comments: $e');
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  List<CommunityComment> _updateCommentInTree(
      List<CommunityComment> comments,
      String targetId,
      CommunityComment Function(CommunityComment) updateFn) {
    return comments.map((c) {
      if (c.id == targetId) {
        return updateFn(c);
      }
      if (c.replies != null && c.replies!.isNotEmpty) {
        return c.copyWith(
            replies: _updateCommentInTree(c.replies!, targetId, updateFn));
      }
      return c;
    }).toList();
  }

  List<CommunityComment> _deleteCommentInTree(
      List<CommunityComment> comments, String targetId) {
    return comments.where((c) => c.id != targetId).map((c) {
      if (c.replies != null && c.replies!.isNotEmpty) {
        return c.copyWith(replies: _deleteCommentInTree(c.replies!, targetId));
      }
      return c;
    }).toList();
  }

  Future<void> addComment(String content, {int? gifId, String? parentId}) async {
    try {
      final newComment = await repo.addComment(postId, content, gifId: gifId, parentId: parentId);
      if (!mounted) return;
      
      if (parentId != null) {
        state = state.copyWith(
          comments: _updateCommentInTree(state.comments, parentId, (parent) {
            return parent.copyWith(
              repliesCount: parent.repliesCount + 1,
              replies: [...(parent.replies ?? []), newComment],
            );
          }),
        );
      } else {
        state = state.copyWith(
          comments: [newComment, ...state.comments],
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Always fetches fresh replies from the server (used on tap and auto-load).
  Future<void> fetchReplies(String commentId) async {
    try {
      final response = await repo.fetchReplies(commentId, limit: 20);
      if (!mounted) return;

      state = state.copyWith(
        comments: _updateCommentInTree(state.comments, commentId, (parent) {
          return parent.copyWith(
            replies: response.data,
            // Update count to match server truth
            repliesCount: response.data.length > parent.repliesCount
                ? response.data.length
                : parent.repliesCount,
          );
        }),
      );
    } catch (e) {
      debugPrint('Error fetching replies: $e');
    }
  }

  Future<void> editComment(String commentId, String content, {int? gifId}) async {
    try {
      final updatedComment = await repo.editComment(commentId, content, gifId: gifId);
      if (!mounted) return;
      
      state = state.copyWith(
        comments: _updateCommentInTree(state.comments, commentId, (comment) {
          if (updatedComment.updatedAt == null) {
            updatedComment.updatedAt = DateTime.now().toIso8601String();
          }
          // Preserve existing replies since the API doesn't return them on edit
          return updatedComment.copyWith(replies: comment.replies, repliesCount: comment.repliesCount);
        }),
      );
    } catch (e) {
      debugPrint('Error editing comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await repo.deleteComment(commentId);
      if (!mounted) return;
      state = state.copyWith(
        comments: _deleteCommentInTree(state.comments, commentId),
      );
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }
}

final postCommentsProvider = StateNotifierProvider.family<
    PostCommentsNotifier, PostCommentsState, String>((ref, postId) {
  final repo = ref.watch(communityRepositoryProvider);
  return PostCommentsNotifier(repo, postId);
});

/// Signal bus: set to the postId whose comments should be refreshed.
/// FCM service writes here when it receives a comment/reply notification.
/// PostCommentsSheet watches this and re-fetches if it matches its own postId.
final commentsRefreshSignalProvider = StateProvider<String?>((ref) => null);
