class Reel {
  final String id;
  final String authorId;
  final String postedBy;
  final String authorName;
  final String? authorAvatarUrl;
  final String videoUrl;
  final String? caption;
  final int? durationSeconds;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLikedByMe;
  final DateTime? timestamp;
  // Location fields
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;

  // Ad specific fields
  final String? type;
  final String? mediaType;
  final String? mediaUrl;
  final String? linkUrl;
  final String? ctaLabel;

  Reel({
    required this.id,
    required this.authorId,
    required this.postedBy,
    required this.authorName,
    this.authorAvatarUrl,
    required this.videoUrl,
    this.caption,
    this.durationSeconds,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLikedByMe = false,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.type,
    this.mediaType,
    this.mediaUrl,
    this.linkUrl,
    this.ctaLabel,
  });

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      type: json['type']?.toString(),
      id: json['id']?.toString() ?? '',
      authorId: (json['author_id'] ?? json['authorId'])?.toString() ?? '',
      postedBy: (json['posted_by'] ?? json['postedBy'])?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      authorAvatarUrl: json['authorAvatarUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? '',
      caption: (json['caption'] ?? json['description'])?.toString(),
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] : int.tryParse(json['durationSeconds']?.toString() ?? ''),
      viewsCount: json['viewsCount'] is int ? json['viewsCount'] : int.tryParse(json['viewsCount']?.toString() ?? '0') ?? 0,
      likesCount: json['likesCount'] is int ? json['likesCount'] : int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0,
      commentsCount: json['commentsCount'] is int ? json['commentsCount'] : int.tryParse(json['commentsCount']?.toString() ?? '0') ?? 0,
      sharesCount: json['sharesCount'] is int ? json['sharesCount'] : int.tryParse(json['sharesCount']?.toString() ?? '0') ?? 0,
      isLikedByMe: json['isLikedByMe'] == true || json['isLikedByMe'] == 'true' || json['isLikedByMe'] == 1 || json['isLikedByMe'] == '1' || json['liked'] == true || json['liked'] == 'true' || json['liked'] == 1 || json['isLiked'] == true || json['isLiked'] == 'true' || json['is_liked'] == true || json['is_liked'] == 'true' || json['is_liked'] == 1,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      mediaType: json['mediaType']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      ctaLabel: json['ctaLabel']?.toString(),
    );
  }

  Reel copyWith({
    String? id,
    String? authorId,
    String? postedBy,
    String? authorName,
    String? authorAvatarUrl,
    String? videoUrl,
    String? caption,
    int? durationSeconds,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLikedByMe,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? type,
    String? mediaType,
    String? mediaUrl,
    String? linkUrl,
    String? ctaLabel,
  }) {
    return Reel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      postedBy: postedBy ?? this.postedBy,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      type: type ?? this.type,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      ctaLabel: ctaLabel ?? this.ctaLabel,
    );
  }
}

class ReelPagination {
  final String? nextCursor;
  final bool hasNextPage;
  final int nextCount;
  final int? position;

  ReelPagination({
    this.nextCursor,
    this.hasNextPage = false,
    this.nextCount = 0,
    this.position,
  });

  factory ReelPagination.fromJson(Map<String, dynamic> json) {
    bool hasNext = json['hasNextPage'] == true || json['hasNextPage'] == 'true';
    if (json.containsKey('currentPage') && json.containsKey('lastPage')) {
      int current = int.tryParse(json['currentPage'].toString()) ?? 1;
      int last = int.tryParse(json['lastPage'].toString()) ?? 1;
      hasNext = current < last;
    }

    int nxtCount = json['nextCount'] is int ? json['nextCount'] : int.tryParse(json['nextCount']?.toString() ?? '0') ?? 0;
    if (json.containsKey('total') && json.containsKey('currentPage') && json.containsKey('perPage')) {
      int total = int.tryParse(json['total'].toString()) ?? 0;
      int current = int.tryParse(json['currentPage'].toString()) ?? 1;
      int perPage = int.tryParse(json['perPage'].toString()) ?? 1;
      nxtCount = total - (current * perPage);
      if (nxtCount < 0) nxtCount = 0;
    }

    return ReelPagination(
      nextCursor: json['nextCursor']?.toString(),
      hasNextPage: hasNext,
      nextCount: nxtCount,
      position: json['position'] is int ? json['position'] : int.tryParse(json['position']?.toString() ?? ''),
    );
  }
}

class ReelResponse {
  final List<Reel> data;
  final ReelPagination? meta;

  ReelResponse({
    required this.data,
    this.meta,
  });

  factory ReelResponse.fromJson(Map<String, dynamic> json) {
    return ReelResponse(
      data: json['data'] != null ? (json['data'] as List).map((i) => Reel.fromJson(i)).toList() : [],
      meta: json['meta'] != null ? ReelPagination.fromJson(json['meta']) : null,
    );
  }
}

class ReelComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime? timestamp;
  final String? parentId;
  final String? replyingToAuthorName;
  final int repliesCount;
  final bool hasMoreReplies;
  final int nextRepliesCount;
  final List<ReelComment> replies;
  final int likesCount;
  final bool isLikedByMe;

  ReelComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.timestamp,
    this.parentId,
    this.replyingToAuthorName,
    this.repliesCount = 0,
    this.hasMoreReplies = false,
    this.nextRepliesCount = 0,
    this.replies = const [],
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  factory ReelComment.fromJson(Map<String, dynamic> json) {
    return ReelComment(
      id: json['id']?.toString() ?? '',
      authorId: (json['authorId'] ?? (json['author'] != null ? json['author']['id'] : null))?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 
                  (json['author'] != null 
                    ? '${json['author']['first_name'] ?? ''} ${json['author']['last_name'] ?? ''}'.trim() 
                    : 'User'),
      authorAvatarUrl: json['authorAvatarUrl']?.toString() ?? (json['author'] != null ? json['author']['image']?.toString() : null),
      content: json['content']?.toString() ?? '',
      timestamp: (json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null) ??
                 (json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null),
      parentId: json['parentId']?.toString(),
      replyingToAuthorName: json['replyingToAuthorName']?.toString(),
      repliesCount: json['repliesCount'] is int ? json['repliesCount'] : int.tryParse(json['repliesCount']?.toString() ?? '0') ?? 0,
      hasMoreReplies: json['hasMoreReplies'] == true || json['hasMoreReplies'] == 'true',
      nextRepliesCount: json['nextRepliesCount'] is int ? json['nextRepliesCount'] : int.tryParse(json['nextRepliesCount']?.toString() ?? '0') ?? 0,
      replies: json['replies'] != null ? (json['replies'] as List).map((i) => ReelComment.fromJson(i)).toList() : [],
      likesCount: json['likesCount'] is int ? json['likesCount'] : int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0,
      isLikedByMe: json['isLikedByMe'] == true || json['isLikedByMe'] == 'true' || json['isLikedByMe'] == 1 || json['isLikedByMe'] == '1' || json['liked'] == true || json['liked'] == 'true' || json['liked'] == 1,
    );
  }

  ReelComment copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    DateTime? timestamp,
    String? parentId,
    String? replyingToAuthorName,
    int? repliesCount,
    bool? hasMoreReplies,
    int? nextRepliesCount,
    List<ReelComment>? replies,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return ReelComment(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      parentId: parentId ?? this.parentId,
      replyingToAuthorName: replyingToAuthorName ?? this.replyingToAuthorName,
      repliesCount: repliesCount ?? this.repliesCount,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      nextRepliesCount: nextRepliesCount ?? this.nextRepliesCount,
      replies: replies ?? this.replies,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

class ReelCommentResponse {
  final List<ReelComment> data;
  final ReelPagination? meta;

  ReelCommentResponse({
    required this.data,
    this.meta,
  });

  factory ReelCommentResponse.fromJson(Map<String, dynamic> json) {
    return ReelCommentResponse(
      data: json['data'] != null ? (json['data'] as List).map((i) => ReelComment.fromJson(i)).toList() : [],
      meta: json['meta'] != null ? ReelPagination.fromJson(json['meta']) : null,
    );
  }
}
