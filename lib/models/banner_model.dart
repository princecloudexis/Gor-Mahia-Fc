class BannerModel {
  final String id;
  final String image;
  final String title;
  final String subtitle;

  BannerModel({
    required this.id,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
    );
  }
}