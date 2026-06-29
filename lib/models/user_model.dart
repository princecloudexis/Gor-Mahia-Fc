class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int eventsAttended;
  final int upcomingEvents;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.image,
    this.createdAt,
    this.updatedAt,
    required this.eventsAttended,
    required this.upcomingEvents,
  });

  String get fullName => '$firstName $lastName';
  String? get cleanedImageUrl {
    if (image == null || image!.isEmpty) {
      return null;
    }
    const placeholder = 'PROTOCOL_PLACEHOLDER';
    String tempUrl = image!.replaceAll('://', placeholder);
    tempUrl = tempUrl.replaceAll(RegExp(r'//+'), '/');
    return tempUrl.replaceAll(placeholder, '://');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'events_attended': eventsAttended,
      'upcoming_events': upcomingEvents,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userData;

    if (json.containsKey('data') && json['data'] is Map) {
      userData = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('user') && json['user'] is Map) {
      userData = json['user'] as Map<String, dynamic>;
    } else {
      userData = json;
    }

    final eventCount =
        json['event_count'] ??
        json['events_attended'] ??
        userData['event_count'] ??
        userData['events_attended'] ??
        0;

    final upcomingEvent =
        json['upcoming_event'] ??
        json['upcoming_events'] ??
        userData['upcoming_event'] ??
        userData['upcoming_events'] ??
        0;

    return UserModel(
      id: userData['id'] as int,
      firstName: userData['first_name'] as String? ?? '',
      lastName: userData['last_name'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      phoneNumber: userData['phone_number'] as String? ?? '',
      image: userData['image'] as String?,
      createdAt: userData['created_at'] != null
          ? DateTime.tryParse(userData['created_at'].toString())
          : null,
      updatedAt: userData['updated_at'] != null
          ? DateTime.tryParse(userData['updated_at'].toString())
          : null,
      eventsAttended: int.tryParse(eventCount.toString()) ?? 0,
      upcomingEvents: int.tryParse(upcomingEvent.toString()) ?? 0,
    );
  }
}
