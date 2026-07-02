class CategoryModel {
  final int id;
  final String name;
  final String iconUrl; 

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl, 
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String rawIconUrl = json['icon'] ?? '';
    
    // Sometimes the API returns malformed URLs like "http:https://"
    if (rawIconUrl.startsWith('http:https://')) {
      rawIconUrl = rawIconUrl.replaceFirst('http:https://', 'https://');
    }

    // Fix double slashes in the path which can cause the server to return an HTML 404 page
    if (rawIconUrl.startsWith('http')) {
      try {
        final uri = Uri.parse(rawIconUrl);
        final fixedPath = uri.path.replaceAll(RegExp(r'/{2,}'), '/');
        rawIconUrl = '${uri.scheme}://${uri.host}$fixedPath';
      } catch (_) {}
    }

    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['type_name'] ?? 'Unknown',
      iconUrl: rawIconUrl, 
    );
  }
}