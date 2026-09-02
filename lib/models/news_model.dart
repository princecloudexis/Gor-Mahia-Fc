class NewsModel {
  final int id;
  final String title;
  final String description;
  final String? image;
  final String postedBy;
  final int authorId;
  final String? authorName;
  final DateTime? createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.postedBy,
    required this.authorId,
    this.authorName,
    this.createdAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      postedBy: json['posted_by'] ?? '',
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Lightweight related-article preview returned inside the detail response
class RelatedNewsItem {
  final int id;
  final String title;
  final String? image;
  final DateTime? createdAt;

  RelatedNewsItem({
    required this.id,
    required this.title,
    this.image,
    this.createdAt,
  });

  factory RelatedNewsItem.fromJson(Map<String, dynamic> json) {
    return RelatedNewsItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class NewsMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasNextPage;

  NewsMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasNextPage,
  });

  factory NewsMeta.fromJson(Map<String, dynamic> json) {
    return NewsMeta(
      currentPage: json['currentPage'] ?? 1,
      lastPage: json['lastPage'] ?? 1,
      perPage: json['perPage'] ?? 10,
      total: json['total'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}

/// Used by GET /api/user/news/latest (no pagination)
class NewsResponse {
  final int status;
  final bool success;
  final String message;
  final List<NewsModel> data;

  NewsResponse({
    required this.status,
    required this.success,
    required this.message,
    required this.data,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      status: json['status'] ?? 200,
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => NewsModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Used by GET /api/user/news (paginated)
class PaginatedNewsResponse {
  final int status;
  final bool success;
  final String message;
  final List<NewsModel> data;
  final NewsMeta meta;

  PaginatedNewsResponse({
    required this.status,
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory PaginatedNewsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedNewsResponse(
      status: json['status'] ?? 200,
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((e) => NewsModel.fromJson(e))
              .toList() ??
          [],
      meta: NewsMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

/// Used by GET /api/user/news/{id}
class NewsDetailResponse {
  final int status;
  final bool success;
  final String message;
  final NewsModel data;
  final List<RelatedNewsItem> related;

  NewsDetailResponse({
    required this.status,
    required this.success,
    required this.message,
    required this.data,
    required this.related,
  });

  factory NewsDetailResponse.fromJson(Map<String, dynamic> json) {
    return NewsDetailResponse(
      status: json['status'] ?? 200,
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: NewsModel.fromJson(json['data'] ?? {}),
      related: (json['related'] as List?)
              ?.map((e) => RelatedNewsItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
