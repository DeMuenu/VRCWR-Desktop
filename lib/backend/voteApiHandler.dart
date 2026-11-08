import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vrcworldvoterdesktop/backend/secureStorage.dart';

class DownstreamWorldVoteInfo {
  final String worldId;
  final int votes;
  final Map<String, int> tags;
  final List<String> comments;

  DownstreamWorldVoteInfo({
    required this.worldId,
    required this.votes,
    required this.tags,
    required this.comments,
  });

  factory DownstreamWorldVoteInfo.fromJson(Map<String, dynamic> json) {
    return DownstreamWorldVoteInfo(
      worldId: json['world_id'] ?? '',
      votes: json['votes'] ?? 0,
      tags: Map<String, int>.from(json['tags'] ?? {}),
      comments: List<String>.from(json['comments'] ?? []),
    );
  }
}

class UpstreamWorldVoteInfo {
  final String worldId;
  final String reviewUserName;
  final int vote;
  final List<String>? tags;
  final String? comment;

  UpstreamWorldVoteInfo({
    required this.worldId,
    required this.reviewUserName,
    required this.vote,
    this.tags,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'world_id': worldId,
      'review_usr_name': reviewUserName,
      'review_value': vote,
      if (comment != null && comment!.isNotEmpty) 'review_comment': comment,
      if (tags != null && tags!.isNotEmpty) 'review_tags': tags,
    };
  }
}

class VoteApiHandler extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:8000';

  String? sessionToken;
  String? lastErrorMessage;
  bool isLoggedIn = false; //Todo revert
  bool isRegisteredUser = false;

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders => {
        ..._defaultHeaders,
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
      };

  Future<void> init() async {
    final secureStorage = SecureStorage();
    sessionToken = await secureStorage.read("vote_token");
    isLoggedIn = sessionToken != null && sessionToken!.isNotEmpty;
    isRegisteredUser = isLoggedIn;
    notifyListeners();
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

      if (response.statusCode == 201) {
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

      if (response.statusCode == 201) {
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

  //Add a World Review (POST api/world_add_review) - Requires Auth
  Future<bool> publishReview(UpstreamWorldVoteInfo reviewInfo) async {
    if (sessionToken == null) {
      lastErrorMessage = 'You must be logged in to publish a review.';
      notifyListeners();
      return false;
    }

    final Uri url = Uri.parse('$_baseUrl/api/world_add_review');

    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(reviewInfo.toJson()),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        lastErrorMessage = null;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Token expired or was replaced by another login
        SecureStorage secureStorage = SecureStorage();
        secureStorage.delete("vote_token");
        isLoggedIn = false;
        sessionToken = null;
        lastErrorMessage = 'Session expired. Please log in again.';
        notifyListeners();
        return false;
      } else {
        lastErrorMessage = data['message'] ?? 'Failed to publish review (${response.statusCode})';
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
    final Uri url = Uri.parse('$_baseUrl/api/world_load').replace(
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
}