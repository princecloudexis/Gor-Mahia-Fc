import 'package:flutter/foundation.dart';
class MatchLiveResponse {
  final bool status;
  final String message;
  final List<MatchModel> data;
  final PaginationData pagination;

  MatchLiveResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory MatchLiveResponse.fromJson(Map<String, dynamic> json) {
    return MatchLiveResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)?.map((e) => MatchModel.fromJson(e)).toList() ?? [],
      pagination: PaginationData.fromJson(json['pagination'] ?? {}),
    );
  }
}

class MatchResultsResponse {
  final bool status;
  final String message;
  final List<MatchModel> data;
  final PaginationData pagination;

  MatchResultsResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory MatchResultsResponse.fromJson(Map<String, dynamic> json) {
    return MatchResultsResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)?.map((e) => MatchModel.fromJson(e)).toList() ?? [],
      pagination: PaginationData.fromJson(json['pagination'] ?? {}),
    );
  }
}

class MatchFixturesResponse {
  final bool status;
  final String message;
  final MatchFixturesData data;
  final PaginationData pagination;

  MatchFixturesResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory MatchFixturesResponse.fromJson(Map<String, dynamic> json) {
    return MatchFixturesResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: MatchFixturesData.fromJson(json['data'] ?? {}),
      pagination: PaginationData.fromJson(json['pagination'] ?? {}),
    );
  }
}

class MatchFixturesData {
  final List<MatchModel> liveMatches;
  final List<MatchModel> upcomingFixtures;

  MatchFixturesData({
    required this.liveMatches,
    required this.upcomingFixtures,
  });

  factory MatchFixturesData.fromJson(Map<String, dynamic> json) {
    return MatchFixturesData(
      liveMatches: (json['live_matches'] as List?)?.map((e) => MatchModel.fromJson(e)).toList() ?? [],
      upcomingFixtures: (json['upcoming_fixtures'] as List?)?.map((e) => MatchModel.fromJson(e)).toList() ?? [],
    );
  }
}

class MatchModel {
  final int id;
  final String? competition;
  final String? status;
  final String? minuteLabel;
  final String? venue;
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int? homeScore;
  final int? awayScore;
  final List<GoalEventModel>? goalEvents;
  final String? matchDatetimeLabel;
  final String? matchDatetime;
  final bool? isLive;

  MatchModel({
    required this.id,
    this.competition,
    this.status,
    this.minuteLabel,
    this.venue,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.goalEvents,
    this.matchDatetimeLabel,
    this.matchDatetime,
    this.isLive,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? 0,
      competition: json['competition'],
      status: json['status'],
      minuteLabel: json['minute_label'],
      venue: json['venue'],
      homeTeam: TeamModel.fromJson(json['home_team'] ?? {}),
      awayTeam: TeamModel.fromJson(json['away_team'] ?? {}),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      goalEvents: (json['goal_events'] as List?)?.map((e) => GoalEventModel.fromJson(e)).toList(),
      matchDatetimeLabel: json['match_datetime_label'],
      matchDatetime: json['match_datetime'],
      isLive: json['is_live'],
    );
  }
}

class TeamModel {
  final int id;
  final String name;
  final String? shortCode;
  final String? logoUrl;

  TeamModel({
    required this.id,
    required this.name,
    this.shortCode,
    this.logoUrl,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      shortCode: json['short_code'],
      logoUrl: json['logo_url'],
    );
  }
}

class GoalEventModel {
  final int id;
  final String playerName;
  final int minute;
  final int? teamId;
  final String? minuteLabel;

  GoalEventModel({
    required this.id,
    required this.playerName,
    required this.minute,
    this.teamId,
    this.minuteLabel,
  });

  factory GoalEventModel.fromJson(Map<String, dynamic> json) {
    return GoalEventModel(
      id: json['id'] ?? 0,
      playerName: json['player_name'] ?? '',
      minute: json['minute'] ?? 0,
      teamId: json['team_id'],
      minuteLabel: json['minute_label'],
    );
  }
}

class PaginationData {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  PaginationData({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }
}

class MatchLineupResponse {
  final bool status;
  final String message;
  final LineupData data;

  MatchLineupResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MatchLineupResponse.fromJson(Map<String, dynamic> json) {
    return MatchLineupResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: LineupData.fromJson(json['data'] ?? {}),
    );
  }
}

class LineupData {
  final TeamLineup home;
  final TeamLineup away;

  LineupData({
    required this.home,
    required this.away,
  });

  factory LineupData.fromJson(Map<String, dynamic> json) {
    return LineupData(
      home: TeamLineup.fromJson(json['home'] ?? {}),
      away: TeamLineup.fromJson(json['away'] ?? {}),
    );
  }
}

class TeamLineup {
  final int teamId;
  final String teamName;
  final String? shortCode;
  final String? formation;
  final List<PlayerLineup> startingXi;

  TeamLineup({
    required this.teamId,
    required this.teamName,
    this.shortCode,
    this.formation,
    required this.startingXi,
  });

  factory TeamLineup.fromJson(Map<String, dynamic> json) {
    return TeamLineup(
      teamId: json['team_id'] ?? 0,
      teamName: json['team_name'] ?? '',
      shortCode: json['short_code'],
      formation: json['formation'],
      startingXi: (json['starting_xi'] as List?)
              ?.map((e) => PlayerLineup.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PlayerLineup {
  final int id;
  final int playerId;
  final String name;
  final String position;
  final int? jerseyNumber;

  PlayerLineup({
    required this.id,
    required this.playerId,
    required this.name,
    required this.position,
    this.jerseyNumber,
  });

  factory PlayerLineup.fromJson(Map<String, dynamic> json) {
    return PlayerLineup(
      id: json['id'] ?? 0,
      playerId: json['player_id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      jerseyNumber: json['jersey_number'],
    );
  }
}

class MatchStatsResponse {
  final bool status;
  final String message;
  final MatchStatsData data;

  MatchStatsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MatchStatsResponse.fromJson(Map<String, dynamic> json) {
    return MatchStatsResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: MatchStatsData.fromJson(json['data'] ?? {}),
    );
  }
}

class MatchStatsData {
  final List<MatchStatItem> stats;

  MatchStatsData({
    required this.stats,
  });

  factory MatchStatsData.fromJson(Map<String, dynamic> json) {
    return MatchStatsData(
      stats: (json['stats'] as List?)
              ?.map((e) => MatchStatItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MatchStatItem {
  final String key;
  final int home;
  final int away;

  MatchStatItem({
    required this.key,
    required this.home,
    required this.away,
  });

  factory MatchStatItem.fromJson(Map<String, dynamic> json) {
    return MatchStatItem(
      key: json['key'] ?? '',
      home: json['home'] ?? 0,
      away: json['away'] ?? 0,
    );
  }
}

class MatchChatResponse {
  final bool status;
  final String message;
  final List<MatchChatMessage> data;
  final PaginationData? pagination;

  MatchChatResponse({
    required this.status,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory MatchChatResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('DEBUG CHAT: Full JSON response keys: ${json.keys}');
    final dataField = json['data'];
    debugPrint('DEBUG CHAT: dataField type: ${dataField.runtimeType}');

    List<dynamic> rawList = [];
    if (dataField is List) {
      rawList = dataField;
      debugPrint('DEBUG CHAT: dataField is a List of length ${rawList.length}');
    } else if (dataField is Map && dataField['data'] is List) {
      rawList = dataField['data'];
      debugPrint('DEBUG CHAT: dataField is a Map containing a List of length ${rawList.length}');
    } else {
      debugPrint('DEBUG CHAT: dataField is neither a List nor a Map containing a List! It is: $dataField');
    }

    final parsedList = rawList.map((e) {
      try {
        return MatchChatMessage.fromJson(e);
      } catch (err) {
        debugPrint('DEBUG CHAT: Error parsing message: $err. Raw data: $e');
        rethrow;
      }
    }).toList();

    // Ensure chronological order by sorting by ID ascending (oldest at top, newest at bottom)
    parsedList.sort((a, b) => a.id.compareTo(b.id));
    debugPrint('DEBUG CHAT: Successfully parsed and sorted ${parsedList.length} messages');

    return MatchChatResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: parsedList,
      pagination: json['pagination'] != null ? PaginationData.fromJson(json['pagination']) : null,
    );
  }
}

class MatchChatMessage {
  final int id;
  final String message;
  final MatchChatUser user;
  final String? createdAt;
  final String? createdLabel;

  MatchChatMessage({
    required this.id,
    required this.message,
    required this.user,
    this.createdAt,
    this.createdLabel,
  });

  factory MatchChatMessage.fromJson(Map<String, dynamic> json) {
    return MatchChatMessage(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      user: MatchChatUser.fromJson(json['user'] ?? {}),
      createdAt: json['created_at'],
      createdLabel: json['created_label'],
    );
  }
}

class MatchChatUser {
  final int id;
  final String name;
  final String? initial;
  final String? avatarUrl;

  MatchChatUser({
    required this.id,
    required this.name,
    this.initial,
    this.avatarUrl,
  });

  factory MatchChatUser.fromJson(Map<String, dynamic> json) {
    return MatchChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      initial: json['initial'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class MatchSummaryResponse {
  final bool status;
  final String message;
  final MatchModel data;

  MatchSummaryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MatchSummaryResponse.fromJson(Map<String, dynamic> json) {
    return MatchSummaryResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: MatchModel.fromJson(json['data'] ?? {}),
    );
  }
}

class MatchOverviewResponse {
  final bool status;
  final String message;
  final MatchOverviewData data;

  MatchOverviewResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MatchOverviewResponse.fromJson(Map<String, dynamic> json) {
    return MatchOverviewResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: MatchOverviewData.fromJson(json['data'] ?? {}),
    );
  }
}

class MatchOverviewData {
  final int id;
  final String? venue;
  final List<GoalEventModel> goalEvents;
  final String? referee;
  final int? attendance;
  final String? weatherTempC;
  final String? weatherCondition;

  MatchOverviewData({
    required this.id,
    this.venue,
    required this.goalEvents,
    this.referee,
    this.attendance,
    this.weatherTempC,
    this.weatherCondition,
  });

  factory MatchOverviewData.fromJson(Map<String, dynamic> json) {
    return MatchOverviewData(
      id: json['id'] ?? 0,
      venue: json['venue'],
      goalEvents: (json['goal_events'] as List?)
              ?.map((e) => GoalEventModel.fromJson(e))
              .toList() ??
          [],
      referee: json['referee'],
      attendance: json['attendance'],
      weatherTempC: json['weather_temp_c']?.toString(),
      weatherCondition: json['weather_condition'],
    );
  }
}
