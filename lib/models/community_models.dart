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
  int totalVotes;
  bool hasVoted;

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      return DateTime.parse(expiresAt!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  CommunityPollData({
    required this.id,
    required this.options,
    this.expiresAt,
    required this.totalVotes,
    required this.hasVoted,
  });

  factory CommunityPollData.fromJson(Map<String, dynamic> json) {
    var optionsList = json['options'] as List? ?? [];
    return CommunityPollData(
      id: json['id']?.toString() ?? '',
      options: optionsList.map((e) => CommunityPollOption.fromJson(e)).toList(),
      expiresAt: json['expiresAt']?.toString(),
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
          ? CommunityPollData.fromJson(json['pollData'])
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
  final String content;
  final String? timestamp;
  String? updatedAt;
  final CommunityGif? gif;
  final String? parentId;
  final int repliesCount;
  final List<CommunityComment>? replies;

  CommunityComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    this.timestamp,
    this.updatedAt,
    this.gif,
    this.parentId,
    this.repliesCount = 0,
    this.replies,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Unknown',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
      gif: json['gif'] != null ? CommunityGif.fromJson(json['gif']) : null,
      parentId: json['parent_id']?.toString(),
      repliesCount: json['repliesCount'] != null ? int.tryParse(json['repliesCount'].toString()) ?? 0 : 0,
    );
  }

  CommunityComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? content,
    String? timestamp,
    String? updatedAt,
    CommunityGif? gif,
    String? parentId,
    int? repliesCount,
    List<CommunityComment>? replies,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      gif: gif ?? this.gif,
      parentId: parentId ?? this.parentId,
      repliesCount: repliesCount ?? this.repliesCount,
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

  PaginatedResponse({
    required this.data,
    this.nextCursor,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    var dataList = json['data'] as List? ?? [];
    List<T> data = dataList
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    var meta = json['meta'] as Map<String, dynamic>?;
    return PaginatedResponse(
      data: data,
      nextCursor: meta?['nextCursor']?.toString(),
      hasNextPage:
          meta?['hasNextPage'] == true ||
          meta?['hasNextPage']?.toString() == 'true',
    );
  }
}
