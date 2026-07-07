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
  final String membershipStatus;
  final String membershipPlan;
  final bool isPaidMember;
  final DateTime? membershipExpiry;

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
    this.membershipStatus = 'Active',
    this.membershipPlan = 'Free Plan',
    this.isPaidMember = false,
    this.membershipExpiry,
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
      'membership_status': membershipStatus,
      'membership_plan': membershipPlan,
      'is_paid_member': isPaidMember,
      'membership_expiry': membershipExpiry?.toIso8601String(),
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

    final mPlan =
        json['membership_plan'] ?? userData['membership_plan'] ?? 'Free Plan';
    final isPaid =
        json['is_paid_member'] ?? userData['is_paid_member'] ?? false;

    DateTime? mExpiry;
    final expiryRaw =
        json['membership_expiry'] ?? userData['membership_expiry'];
    if (expiryRaw != null) {
      mExpiry = DateTime.tryParse(expiryRaw.toString());
    }

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
      membershipStatus: userData['membership_status'] as String? ?? 'Active',
      membershipPlan: mPlan?.toString() ?? 'Free Plan',
      isPaidMember: isPaid == true || isPaid == 1 || isPaid == 'true',
      membershipExpiry: mExpiry,
    );
  }
}

class MembershipDetails {
  final String memberName;
  final String membershipType;
  final String? memberId;
  final String? since;
  final String? validUntil;
  final String? branch;
  final String? status;

  MembershipDetails({
    required this.memberName,
    required this.membershipType,
    this.memberId,
    this.since,
    this.validUntil,
    this.branch,
    this.status,
  });

  factory MembershipDetails.fromJson(Map<String, dynamic> json) {
    return MembershipDetails(
      memberName: json['member_name'] as String? ?? '',
      membershipType: json['membership_type'] as String? ?? 'Free Plan',
      memberId: json['member_id'] as String?,
      since: json['since'] as String?,
      validUntil: json['valid_until'] as String?,
      branch: json['branch'] as String?,
      status: json['status'] as String?,
    );
  }
}
