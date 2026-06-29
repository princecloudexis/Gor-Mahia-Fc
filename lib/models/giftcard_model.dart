class GiftCardModel {
  final int id;
  final String name;
  final String image;
  final String description;

  GiftCardModel({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });

  factory GiftCardModel.fromJson(Map<String, dynamic> json) {
    return GiftCardModel(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
    );
  }
}