class CommunityGroup {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? requiredMembershipTier;
  final int membersCount;
  final String? createdAt;
  final String? type;
  bool isJoined;
  String? joinStatus;

  bool get isPending => joinStatus == 'pending';

  CommunityGroup({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.requiredMembershipTier,
    required this.membersCount,
    this.createdAt,
    this.type,
    this.isJoined = false,
    this.joinStatus,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      requiredMembershipTier: json['requiredMembershipTier']?.toString(),
      membersCount: json['membersCount'] is int
          ? json['membersCount']
          : int.tryParse(json['membersCount']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt']?.toString(),
      type: json['type']?.toString(),
      isJoined: json['isJoined'] == true || json['isJoined']?.toString() == 'true',
      joinStatus: json['joinStatus']?.toString(),
    );
  }

  String getFullImageUrl(String storageBaseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    return _buildFullUrl(imageUrl!, storageBaseUrl);
  }
}

class CommunityMedia {
  final String url;
  final String type; // 'image' or 'video'

  CommunityMedia({required this.url, required this.type});

  factory CommunityMedia.fromJson(Map<String, dynamic> json) {
    return CommunityMedia(
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'image',
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type};
  }

  String getFullUrl(String storageBaseUrl) {
    if (url.isEmpty) return '';
    return _buildFullUrl(url, storageBaseUrl);
  }
}

String _buildFullUrl(String path, String storageBaseUrl) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('file:///')) {
    path = path.replaceFirst('file:///', '');
  }

  final baseUrl = storageBaseUrl.endsWith('/')
      ? storageBaseUrl.substring(0, storageBaseUrl.length - 1)
      : storageBaseUrl;

  if (path.startsWith('/')) {
    return '$baseUrl$path';
  }
  if (path.contains('storage/')) {
    return '$baseUrl/$path';
  }
  // Try to formulate a generic storage path if missing
  return '$baseUrl/storage/$path';
}

class CommunityPollOption {
  final String id;
  final String text;
  int votes;

  CommunityPollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  factory CommunityPollOption.fromJson(Map<String, dynamic> json) {
    return CommunityPollOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      votes: json['votes'] is int
          ? json['votes']
          : int.tryParse(json['votes']?.toString() ?? '0') ?? 0,
    );
  }
}

class CommunityPollData {
  final String id;
  final List<CommunityPollOption> options;
  final String? expiresAt;
  final String? postTimestamp; // The post creation time — used to detect server bug where expiresAt == createdAt
  int totalVotes;
  bool hasVoted;

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      final expiry = DateTime.parse(expiresAt!);
      final now = DateTime.now();

      // Server bug guard: if expiresAt is within 60 seconds of the post's
      // own creation timestamp, the server set expiresAt = createdAt by mistake.
      // Treat this as "no expiry" so the poll appears active.
      if (postTimestamp != null) {
        try {
          final created = DateTime.parse(postTimestamp!);
          if (expiry.difference(created).inSeconds.abs() < 60) {
            return false;
          }
        } catch (_) {}
      }

      // Also guard against server returning expiresAt only a few seconds in the past
      // (e.g. clock skew or immediate expiry bug) — require at least 60s past expiry.
      return expiry.isBefore(now.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return false;
    }
  }

  CommunityPollData({
    required this.id,
    required this.options,
    this.expiresAt,
    this.postTimestamp,
    required this.totalVotes,
    required this.hasVoted,
  });

  factory CommunityPollData.fromJson(Map<String, dynamic> json, {String? postTimestamp}) {
    var optionsList = json['options'] as List? ?? [];
    return CommunityPollData(
      id: json['id']?.toString() ?? '',
      options: optionsList.map((e) => CommunityPollOption.fromJson(e)).toList(),
      expiresAt: json['expiresAt']?.toString(),
      postTimestamp: postTimestamp,
      totalVotes: json['totalVotes'] is int
          ? json['totalVotes']
          : int.tryParse(json['totalVotes']?.toString() ?? '0') ?? 0,
      hasVoted:
          json['hasVoted'] == true || json['hasVoted']?.toString() == 'true',
    );
  }
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<CommunityMedia> media;
  final String? timestamp;
  String? updatedAt;
  final bool isPoll;
  final CommunityPollData? pollData;
  int likesCount;
  int commentsCount;
  int sharesCount;
  int pollVotesCount;
  bool isLikedByMe;
  final String? shareUrl;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.media,
    this.timestamp,
    this.updatedAt,
    required this.isPoll,
    this.pollData,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.pollVotesCount,
    required this.isLikedByMe,
    this.shareUrl,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    var mediaList = json['media'] as List? ?? [];
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Unknown',
      authorAvatar: json['authorAvatar']?.toString(),
      content: json['content']?.toString() ?? '',
      media: mediaList.map((e) => CommunityMedia.fromJson(e)).toList(),
      timestamp: json['timestamp']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      isPoll: json['isPoll'] == true || json['isPoll']?.toString() == 'true',
      pollData: json['pollData'] != null
          ? CommunityPollData.fromJson(
              json['pollData'],
              postTimestamp: json['timestamp']?.toString(),
            )
          : null,
      likesCount: json['likesCount'] is int
          ? json['likesCount']
          : int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0,
      commentsCount: json['commentsCount'] is int
          ? json['commentsCount']
          : int.tryParse(json['commentsCount']?.toString() ?? '0') ?? 0,
      sharesCount: json['sharesCount'] is int
          ? json['sharesCount']
          : int.tryParse(json['sharesCount']?.toString() ?? '0') ?? 0,
      pollVotesCount: json['pollVotesCount'] != null 
          ? (json['pollVotesCount'] is int ? json['pollVotesCount'] : int.tryParse(json['pollVotesCount'].toString()) ?? 0)
          : (json['pollData'] != null && json['pollData']['totalVotes'] != null
              ? (json['pollData']['totalVotes'] is int ? json['pollData']['totalVotes'] : int.tryParse(json['pollData']['totalVotes'].toString()) ?? 0)
              : 0),
      isLikedByMe:
          json['isLikedByMe'] == true ||
          json['isLikedByMe']?.toString() == 'true',
      shareUrl: json['shareUrl']?.toString(),
    );
  }

  String getFullAuthorAvatar(String storageBaseUrl) {
    if (authorAvatar == null || authorAvatar!.isEmpty) return '';
    return _buildFullUrl(authorAvatar!, storageBaseUrl);
  }
}

class CommunityGif {
  final String id;
  final String? title;
  final String? category;
  final String url;

  CommunityGif({
    required this.id,
    this.title,
    this.category,
    required this.url,
  });

  factory CommunityGif.fromJson(Map<String, dynamic> json) {
    return CommunityGif(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      category: json['category']?.toString(),
      url: json['url']?.toString() ?? '',
    );
  }
}

class CommunityComment {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String content;
  final String? timestamp;
  String? updatedAt;
  final CommunityGif? gif;
  final String? parentId;
  final String? replyingToUserName;
  final int repliesCount;
  final bool hasMoreReplies;
  final int nextRepliesCount;
  final String? nextRepliesCursor;
  final List<CommunityComment>? replies;

  CommunityComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.content,
    this.timestamp,
    this.updatedAt,
    this.gif,
    this.parentId,
    this.replyingToUserName,
    this.repliesCount = 0,
    this.hasMoreReplies = false,
    this.nextRepliesCount = 0,
    this.nextRepliesCursor,
    this.replies,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Unknown',
      userImage: json['userImage']?.toString(),
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      gif: json['gif'] != null ? CommunityGif.fromJson(json['gif']) : null,
      parentId: json['parent_id']?.toString(),
      replyingToUserName: json['replyingToUserName']?.toString(),
      repliesCount: json['repliesCount'] != null ? int.tryParse(json['repliesCount'].toString()) ?? 0 : 0,
      hasMoreReplies: json['hasMoreReplies'] == true,
      nextRepliesCount: json['nextRepliesCount'] != null ? int.tryParse(json['nextRepliesCount'].toString()) ?? 0 : 0,
      nextRepliesCursor: json['nextRepliesCursor']?.toString(),
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => CommunityComment.fromJson(e))
              .toList()
          : null,
    );
  }

  CommunityComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    String? timestamp,
    String? updatedAt,
    CommunityGif? gif,
    String? parentId,
    String? replyingToUserName,
    int? repliesCount,
    bool? hasMoreReplies,
    int? nextRepliesCount,
    String? nextRepliesCursor,
    List<CommunityComment>? replies,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      gif: gif ?? this.gif,
      parentId: parentId ?? this.parentId,
      replyingToUserName: replyingToUserName ?? this.replyingToUserName,
      repliesCount: repliesCount ?? this.repliesCount,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      nextRepliesCount: nextRepliesCount ?? this.nextRepliesCount,
      nextRepliesCursor: nextRepliesCursor ?? this.nextRepliesCursor,
      replies: replies ?? this.replies,
    );
  }
}

class CommunityMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final String role;

  CommunityMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'member',
    );
  }

  String getFullAvatarUrl(String storageBaseUrl) {
    if (avatarUrl == null || avatarUrl!.isEmpty) return '';
    return _buildFullUrl(avatarUrl!, storageBaseUrl);
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final String? nextCursor;
  final bool hasNextPage;
  final int nextCount;

  PaginatedResponse({
    required this.data,
    this.nextCursor,
    required this.hasNextPage,
    this.nextCount = 0,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT, {
    int? limit,
  }) {
    // Some APIs wrap pagination data in 'data' object (standard Laravel LengthAwarePaginator)
    List<dynamic> dynamicDataList = [];
    Map<String, dynamic> paginationInfo = {};

    if (json['data'] is List) {
      dynamicDataList = json['data'] as List;
      paginationInfo = json['meta'] as Map<String, dynamic>? ?? json;
    } else if (json['data'] is Map && json['data']['data'] is List) {
      dynamicDataList = json['data']['data'] as List;
      paginationInfo = json['data'] as Map<String, dynamic>;
    } else {
      dynamicDataList = [];
      paginationInfo = json;
    }

    List<T> data = dynamicDataList
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    bool hasNext = false;
    String? cursor;
    int nextCount = 0;

    if (paginationInfo.containsKey('nextCount')) {
      nextCount = int.tryParse(paginationInfo['nextCount'].toString()) ?? 0;
    }

    // Check for explicit hasNextPage flag (custom API pattern)
    if (paginationInfo.containsKey('hasNextPage')) {
      hasNext = paginationInfo['hasNextPage'] == true ||
          paginationInfo['hasNextPage']?.toString() == 'true';
    } else if (paginationInfo.containsKey('hasMore')) {
      hasNext = paginationInfo['hasMore'] == true ||
          paginationInfo['hasMore']?.toString() == 'true';
    } else if (paginationInfo.containsKey('has_more')) {
      hasNext = paginationInfo['has_more'] == true ||
          paginationInfo['has_more']?.toString() == 'true';
    }
    // Check for standard Laravel paginator
    else if (paginationInfo.containsKey('current_page') &&
        paginationInfo.containsKey('last_page')) {
      int currentPage =
          int.tryParse(paginationInfo['current_page'].toString()) ?? 1;
      int lastPage =
          int.tryParse(paginationInfo['last_page'].toString()) ?? 1;
      hasNext = currentPage < lastPage;
    }
    // Check for next_page_url
    else if (paginationInfo.containsKey('next_page_url')) {
      hasNext = paginationInfo['next_page_url'] != null;
    }

    // Determine cursor
    if (paginationInfo.containsKey('nextCursor') &&
        paginationInfo['nextCursor'] != null) {
      cursor = paginationInfo['nextCursor'].toString();
    } else if (paginationInfo.containsKey('next_cursor') &&
        paginationInfo['next_cursor'] != null) {
      cursor = paginationInfo['next_cursor'].toString();
    } else if (paginationInfo.containsKey('next_page_url') &&
        paginationInfo['next_page_url'] != null) {
      final urlString = paginationInfo['next_page_url'].toString();
      final uri = Uri.tryParse(urlString);
      if (uri != null && uri.queryParameters.containsKey('cursor')) {
        cursor = uri.queryParameters['cursor'];
      } else if (uri != null && uri.queryParameters.containsKey('page')) {
        cursor = uri.queryParameters['page'];
      }
    } else if (paginationInfo.containsKey('current_page')) {
      int currentPage =
          int.tryParse(paginationInfo['current_page'].toString()) ?? 1;
      cursor = (currentPage + 1).toString();
    }

    // Failsafe: if data is empty, we don't have a next page
    if (data.isEmpty) {
      hasNext = false;
    }
    
    // Failsafe 2: if we got fewer items than the requested limit, we are at the end
    if (limit != null && data.length < limit) {
      hasNext = false;
    }

    return PaginatedResponse<T>(
      data: data,
      nextCursor: cursor,
      hasNextPage: hasNext,
      nextCount: nextCount,
    );
  }
}
