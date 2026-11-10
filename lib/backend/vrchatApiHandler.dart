import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:VRCWR/backend/appLogic.dart';
import 'package:VRCWR/backend/secureStorage.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:VRCWR/backend/voteApiHandler.dart';

class VrchatApiHandler extends ChangeNotifier{
  late final VrchatDart api;

  late var authResponse;

  late Applogic aL;

  String packageVersion;

  bool isLoggedIn = false;
  bool requires2FA = false;
  bool _isInitialized = false;

  World? currentLocation;
  CurrentUser? currentUser;


  late VrchatUserAgent userAgent = VrchatUserAgent(
    applicationName: 'VRChatWorldVoterDesktop',
    version: packageVersion,
    contactInfo: 'appDeveloper@lunarlink.ch',
  );

  Map<String, String> get imageHeaders => {
    'User-Agent': userAgent.toString(),
  };

  Map<SortOption, List<LimitedWorld>> cachedRecommendations = {};

  VrchatApiHandler(this.packageVersion);

  void setAL(Applogic appLogic){
    aL = appLogic;
  }

  Future<void> initVrchatClient() async {
    if (_isInitialized) return;

    api = VrchatDart(
      userAgent: userAgent,

    );
    _isInitialized = true;


    final secureCookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: SecureStorage(),
    );
    

    final interceptors = api.rawApi.dio.interceptors;
    interceptors.removeWhere((i) => i is CookieManager);
    interceptors.add(CookieManager(secureCookieJar));
  }

  Future<void> cookieLogin() async {
    final (loginSuccess, loginError) = await api.auth.login();

    authResponse = loginSuccess?.data;

    if (authResponse == null){
      return;
    }

    // Check if the account requires 2FA verification
    if (authResponse.requiresTwoFactorAuth) {
      requires2FA = true;
      return;
    }

    currentUser = api.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    print('Successfully logged in as: ${currentUser!.displayName} (${currentUser!.id})');
    startRealtimeStream();
    isLoggedIn = true;
    requires2FA = false;
    notifyListeners();
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

    currentUser = api.auth.currentUser;
    if (currentUser != null) {
      print(
        'Successfully logged in as: ${currentUser!.displayName} (${currentUser!.id})',
      );
      startRealtimeStream();
      isLoggedIn = true;
      notifyListeners();
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
      isLoggedIn = true;
      requires2FA = false;
      notifyListeners();
    }
    return true;
  }

  Future<List<LimitedWorld>> getRecommendations(SortOption sortOption, int offset, {tag = null, reqCount = 60}) async {
    if (!isLoggedIn){
      print("Not logged in.");
      return [];
    }

    if((cachedRecommendations[sortOption]?.length ?? 0) < offset + reqCount)
    {
      offset = max(offset, cachedRecommendations[sortOption]?.length ?? 0);
      final worlds = (await api.rawApi.getWorldsApi().searchWorlds(sort: sortOption, n: reqCount, offset: offset, tag: tag)).data ?? <LimitedWorld>[];
      int len = worlds.length;
      print('Recommendations not cached requesting more. Got: $len');
      cachedRecommendations.putIfAbsent(sortOption, () => <LimitedWorld>[]).addAll(worlds);
      return worlds;
    }
    else{
      return cachedRecommendations[sortOption]!.sublist(offset, (offset + reqCount) as int?);
    }
    
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

              if (currentLocation != null){
                await aL.voteApi.joinNewWorld(currentLocation!.id);
              }
              


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
