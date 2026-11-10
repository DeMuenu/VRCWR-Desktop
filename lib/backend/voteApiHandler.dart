import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:VRCWR/backend/secureStorage.dart';

class DownstreamWorldVoteInfo {
  final int id;
  final String worldId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorId;
  final String authorName;
  final int capacity;
  final String description;
  final int favorites;
  final String imageUrl;
  final String name;
  final DateTime publicationDate;
  final int recommendedCapacity;
  final String releaseStatus;
  final String thumbnailImageUrl;
  final int version;
  final int visits;
  final int likes;
  final int dislikes;
  final int comments;
  final num aiScore;
  final DateTime lastBaseDataSync;

  DownstreamWorldVoteInfo({
    required this.id,
    required this.worldId,
    required this.createdAt,
    required this.updatedAt,
    required this.authorId,
    required this.authorName,
    required this.capacity,
    required this.description,
    required this.favorites,
    required this.imageUrl,
    required this.name,
    required this.publicationDate,
    required this.recommendedCapacity,
    required this.releaseStatus,
    required this.thumbnailImageUrl,
    required this.version,
    required this.visits,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.aiScore,
    required this.lastBaseDataSync,
  });

  factory DownstreamWorldVoteInfo.fromJson(Map<String, dynamic> json) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return DownstreamWorldVoteInfo(
      id: json['id'] as int? ?? 0,
      worldId: json['world_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? epoch,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? epoch,
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      favorites: json['favorites'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      name: json['name'] as String? ?? '',
      publicationDate:
          DateTime.tryParse(json['publication_date'] as String? ?? '') ?? epoch,
      recommendedCapacity: json['recommended_capacity'] as int? ?? 0,
      releaseStatus: json['release_status'] as String? ?? '',
      thumbnailImageUrl: json['thumbnail_image_url'] as String? ?? '',
      version: json['version'] as int? ?? 0,
      visits: json['visits'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      dislikes: json['dislikes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      aiScore: json['ai_score'] as num? ?? 0,
      lastBaseDataSync:
          DateTime.tryParse(json['last_base_data_sync'] as String? ?? '') ?? epoch,
    );
  }
}

class UpstreamWorldVoteInfo {
  final String worldId;
  final String reviewUserName;
  final String reviewUserIcon;
  final int vote;
  final String? comment;
  final Map<int, int>? tags;

  UpstreamWorldVoteInfo({
    required this.worldId,
    required this.reviewUserName,
    required this.reviewUserIcon,
    required this.vote,
    this.comment,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'world_id': worldId,
      'review_usr_name': reviewUserName,
      'review_usr_icon': reviewUserIcon,
      'review_value': vote,
      if (comment != null && comment!.isNotEmpty) 'review_comment': comment,
      if (tags != null && tags!.isNotEmpty)
        'review_tags': tags!.entries
          .map((entry) => {'id': entry.key, 'value': entry.value})
            .toList(),
    };
  }
}

class WorldTag {
  final int id;
  final String worldId;
  final String tag;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorldTag({
    required this.id,
    required this.worldId,
    required this.tag,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorldTag.fromJson(Map<String, dynamic> json) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return WorldTag(
      id: json['id'] as int? ?? 0,
      worldId: json['world_id'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? epoch,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? epoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'world_id': worldId,
        'tag': tag,
        'upvotes': upvotes,
        'downvotes': downvotes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class VoteApiHandler extends ChangeNotifier {
  static const String _baseUrl = 'https://vrcwr.kokos-labs.at';

  String? sessionToken;
  String? lastErrorMessage;
  bool isLoggedIn = false;
  bool isRegisteredUser = true;

  //World bools
  String currentWorldId = "000";
  DownstreamWorldVoteInfo? currentWorld = DownstreamWorldVoteInfo.fromJson({
    'world_id': '000',
  });
  List<WorldTag> currentWorldTags = [];
  bool worldExistsOnServer = false;

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders => {
        ..._defaultHeaders,
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
      };

  VoteApiHandler() {
    initVoting();
  }

  Future<void> initVoting() async {
    final secureStorage = SecureStorage();
    sessionToken = await secureStorage.read("vote_token");
    print(sessionToken);
    isLoggedIn = sessionToken != null && sessionToken!.isNotEmpty;
    notifyListeners();
  }

  Future<bool> userExists({required String userId}) async{
    final Uri url = Uri.parse('$_baseUrl/api/user_exists?user_id=$userId');

    try {
      final response = await http.get(
        url,
      );

      print(response.statusCode);
      if (response.statusCode == 200) {
        isRegisteredUser = true;
        notifyListeners();
        return true;
      }
      if (response.statusCode == 404) {
        isRegisteredUser = false; //TODO make better
        notifyListeners();
        return true;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
    return false;
  }

  //Register a User (POST api/user_register)
  Future<bool> createAccount({
    required String username,
    required String userId,
    required String eMail,
    required String password,
    required String registrationToken,
    required String iconLink,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/api/user_register');

    try {
      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode({
          'username': username,
          'userId': userId,
          'email': eMail,
          'password': password,
          'productKey': registrationToken,
          'icon_link': iconLink,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        sessionToken = data['api_token'];
        SecureStorage secureStorage = SecureStorage();
        secureStorage.write("vote_token", sessionToken ?? "Invalid");
        isRegisteredUser = true;
        isLoggedIn = true;
        lastErrorMessage = null;
        notifyListeners();
        return true;
      } else {
        lastErrorMessage = data['message'] ?? 'Registration failed (${response.statusCode})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  //Log in a User (POST api/user_login)
  Future<bool> login(String email, String password) async {
    final Uri url = Uri.parse('$_baseUrl/api/user_login');

    try {
      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Replaces any previously stored API token
        sessionToken = data['api_token'];
        SecureStorage secureStorage = SecureStorage();
        secureStorage.write("vote_token", sessionToken ?? "Invalid");
        isLoggedIn = true;
        isRegisteredUser = true;
        lastErrorMessage = null;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        lastErrorMessage = 'Invalid email or password.';
        isLoggedIn = false;
        notifyListeners();
        return false;
      } else {
        lastErrorMessage = data['message'] ?? 'Login failed (${response.statusCode})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinNewWorld(String worldId) async{
    currentWorldId = worldId;
    worldExistsOnServer = await worldExist(worldId = worldId);
    print(worldExistsOnServer);
    if (worldExistsOnServer){
      await updateCurrentWorld();
    }
    return true;
  }



  Future<bool> updateCurrentWorld() async{
    currentWorld = await loadWorldData(currentWorldId);
    worldExistsOnServer = currentWorld != null;
    currentWorldTags = await loadWorldTags(currentWorldId) ?? [];
    print(currentWorld);
    print(currentWorld?.authorName ?? "");
    return currentWorld != null;
  }

  Future<bool> worldExist(String worldId) async {
    final Uri url = Uri.parse('$_baseUrl/api/world_exists?world_id=$worldId');
    try {
      final response = await http.get(
        url,
      );
      print(worldId);
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      if (response.statusCode == 404) {
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
    return false;
  }

  //Add a World (PUT api/world_add) - Requires Auth
  Future<bool> addWorld(String worldId) async {
    if (sessionToken == null) {
      lastErrorMessage = 'You must be logged in to add a world.';
      notifyListeners();
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl/api/world_add');

    try {
      final response = await http.put(
        url,
        headers: _authHeaders,
        body: jsonEncode({
          'world_id': worldId,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        lastErrorMessage = null;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        lastErrorMessage = data['message'] ?? 'Failed to add world (${response.statusCode})';
        notifyListeners();
        return false;
      } else if (response.statusCode == 403) {
        lastErrorMessage = "The world is not public yet and can't be reviewed";
        notifyListeners();
        return false;
      } else {
        lastErrorMessage = data['message'] ?? 'Failed to add world (${response.statusCode})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  //Add a World Review (POST api/world_add_review) - Requires Auth
  Future<bool> publishReview(UpstreamWorldVoteInfo reviewInfo) async {
    if (sessionToken == null) {
      lastErrorMessage = 'You must be logged in to publish a review.';
      notifyListeners();
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl/api/world_reviews_add');

    try {
      final response = await http.put(
        url,
        headers: _authHeaders,
        body: jsonEncode(reviewInfo.toJson()),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        lastErrorMessage = null;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        lastErrorMessage = data['message'] ?? 'Failed to publish review (${response.statusCode})';
        print(data['message']);
        notifyListeners();
        return false;
      } else {
        lastErrorMessage = data['message'] ?? 'Failed to publish review (${response.statusCode})';
        print(data['message']);
        notifyListeners();
        return false;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  //4. Load World Data (No Auth Required)
  Future<DownstreamWorldVoteInfo?> loadWorldData(String worldId) async {
    final Uri url = Uri.parse('$_baseUrl/api/world_get?world_id=$worldId').replace(
      queryParameters: {'world_id': worldId},
    );

    try {
      final response = await http.get(url, headers: _defaultHeaders);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        lastErrorMessage = null;
        return DownstreamWorldVoteInfo.fromJson(data);
      } else {
        lastErrorMessage = data['message'] ?? 'Failed to load world (${response.statusCode})';
        notifyListeners();
        return null;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return null;
    }
  }



  // Load world tags
  Future<List<WorldTag>?> loadWorldTags(String worldId) async {
    final Uri url = Uri.parse('$_baseUrl/api/world_tags_get').replace(
      queryParameters: {'world_id': worldId},
    );

    try {
      final response = await http.get(url, headers: _defaultHeaders);
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decoded is! List) {
          lastErrorMessage = 'Unexpected world tags response format.';
          notifyListeners();
          return null;
        }

        lastErrorMessage = null;
        final worldTags = decoded
            .map((item) => WorldTag.fromJson(item as Map<String, dynamic>))
            .toList();
        return worldTags;
      } else {
        final message = decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'Failed to load world tags (${response.statusCode})';
        lastErrorMessage = message;
        notifyListeners();
        return null;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return null;
    }
  }

  // Load world tags
  Future<List<WorldTag>?> getMyReview(String worldId) async {
    final Uri url = Uri.parse('$_baseUrl/api/world_reviews_self_get').replace(
      queryParameters: {'world_id': worldId},
    );

    try {
      final response = await http.get(url, headers: _defaultHeaders);
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decoded is! List) {
          lastErrorMessage = 'Unexpected world tags response format.';
          notifyListeners();
          return null;
        }

        lastErrorMessage = null;
        final worldTags = decoded
            .map((item) => WorldTag.fromJson(item as Map<String, dynamic>))
            .toList();
        return worldTags;
      } else {
        final message = decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'Failed to load world tags (${response.statusCode})';
        lastErrorMessage = message;
        notifyListeners();
        return null;
      }
    } catch (e) {
      lastErrorMessage = 'Network error: $e';
      notifyListeners();
      return null;
    }
  }
}