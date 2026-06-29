class PolicyModel {
  final int id;
  final String title;
  final String description;
  final String? mainDescription; 

  PolicyModel({
    required this.id,
    required this.title,
    required this.description,
    this.mainDescription,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mainDescription: json['main_description'],
    );
  }
}