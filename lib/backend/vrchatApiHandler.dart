import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vrchat_dart/vrchat_dart.dart';

class VrchatApiHandler extends ChangeNotifier{
  late final VrchatDart api;

  late var authResponse;

  bool isLoggedIn = false;
  bool requires2FA = false;
  bool _isInitialized = false;

  World? currentLocation;


  static const userAgent = VrchatUserAgent(
    applicationName: 'VRChatWorldVoterDesktop',
    version: '0.0.1',
    contactInfo: 'appDeveloper@lunarlink.ch',
  );

  Map<String, String> get imageHeaders => {
    'User-Agent': userAgent.toString(),
  };

  VrchatApiHandler();

  Future<void> initVrchatClient() async {
    if (_isInitialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();

    api = VrchatDart(
      userAgent: userAgent,
      cookiePath: appDocDir.path,
    );
    _isInitialized = true;
  }

  Future<void> cookieLogin() async {
    final (loginSuccess, loginError) = await api.auth.login();

    authResponse = loginSuccess!.data;


    // Check if the account requires 2FA verification
    if (authResponse.requiresTwoFactorAuth) {
      requires2FA = true;
      return;
    }

    final currentUser = api.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    print('Successfully logged in as: ${currentUser.displayName} (${currentUser.id})');
    startRealtimeStream();
    isLoggedIn = true;
    requires2FA = false;
  }

  Future<bool> loginToVrchat(String username, String password) async {
    final (loginSuccess, loginError) = await api.auth.login(
      username: username,
      password: password,
    );

    if (loginError != null) {
      print('Login failed: ${loginError.error}');
      return false;
    }

    authResponse = loginSuccess!.data;

    // Check if the account requires 2FA verification
    if (authResponse.requiresTwoFactorAuth) {
      requires2FA = true;
      return true;
    }

    final currentUser = api.auth.currentUser;
    if (currentUser != null) {
      print(
        'Successfully logged in as: ${currentUser.displayName} (${currentUser.id})',
      );
      startRealtimeStream();
    }
    return true;
  }

  Future<bool> verify2FACode(String TFACode) async {
    if (authResponse.twoFactorAuthTypes.contains(TwoFactorAuthType.emailOtp)) {
      final (_, twoFactorError) = await api.auth.verify2fa(TFACode);
      if (twoFactorError != null) {
        print('Email 2FA failed: ${twoFactorError.error}');
        return false;
      }
    } else {
      // TOTP / Authenticator App 2FA:
      final (_, twoFactorError) = await api.auth.verify2fa(TFACode);
      if (twoFactorError != null) {
        print('TOTP 2FA failed: ${twoFactorError.error}');
        return false;
      }
    }

    final currentUser = api.auth.currentUser;
    if (currentUser != null) {
      print(
        'Successfully logged in as: ${currentUser.displayName} (${currentUser.id})',
      );
      startRealtimeStream();
    }
    return true;
  }

  void startRealtimeStream() {
    api.streaming.vrcEventStream.listen((Object event) async {
      switch (event) {
        case WebsocketFriendOnline():
          // Has: userId, location, platform, canRequestInvite
          print('Friend came online: ${event.userId} (Location: ${event.location})');
          break;

        case WebsocketFriendOffline():
          // Has: userId, platform
          print('Friend went offline: ${event.userId}');
          break;

        case WebsocketFriendLocation():
          // Has: user, userId, location, travelingToLocation, worldId, canRequestInvite
          print('${event.user.displayName} moved to world ID: ${event.worldId} (${event.location})');
          break;

        case WebsocketFriendUpdate():
          // Has: user, userId
          print('${event.user.displayName} updated their profile');
          break;

        case WebsocketUserLocation():
          // Has: user, userId, location, instance, travelingToLocation
          print('Current user (${event.user.displayName}) moved to ${event.location}');
          
          final worldId = event.location.split(':').first;

          if (worldId.startsWith('wrld_')) {
            try {
              final response = await api.rawApi.getWorldsApi().getWorld(worldId: worldId);
              currentLocation = response.data;
            } catch (e) {
              print('Failed to fetch world $worldId: $e');
              currentLocation = null;
            }
          }

          notifyListeners();
          break;

        case VrcStreamingError():
          // Has: message
          print('WebSocket pipeline error: ${event.message}');
          break;

        default:
          print('Received event (${event.runtimeType}): $event');
      }
    });
    print('Listening to Websocket...');
    api.streaming.start();
  }
}
