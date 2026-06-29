import 'category_model.dart';
import 'event_model.dart';

class SearchResponseModel {
  final List<EventModel> events;
  final List<CategoryModel> availableCategories;

  SearchResponseModel({
    required this.events,
    required this.availableCategories,
  });

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> eventData = json['data'] ?? [];
    final List<dynamic> categoryData = json['category'] ?? [];

    return SearchResponseModel(
      events: eventData.map((e) => EventModel.fromJson(e)).toList(),
      availableCategories: categoryData.map((c) => CategoryModel.fromJson(c)).toList(),
    );
  }
}