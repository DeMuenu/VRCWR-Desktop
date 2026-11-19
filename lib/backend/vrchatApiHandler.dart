import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/secureStorage.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio/dio.dart';
import 'package:vrcwr/pages/infoPage.dart';


class VrchatApiHandler extends ChangeNotifier{

  ////Important variables START
  late final VrchatDart api;

  late var authResponse;

  late Applogic aL;

  String packageVersion;

  bool isLoggedIn = false;
  bool requires2FA = false;
  bool _isInitialized = false;

  World? currentLocation;
  CurrentUser? currentUser;
  ////Important variables END




  ///Helper functions START
  late VrchatUserAgent userAgent = VrchatUserAgent(
    applicationName: 'VRChatWorldRatingDesktop',
    version: packageVersion,
    contactInfo: 'appDeveloper@lunarlink.ch',
  );

  Map<String, String> get imageHeaders => {
    'User-Agent': userAgent.toString(),
  };

  Map<WorldListSortOrder, List<LimitedWorld>> cachedRecommendations = {};

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

  ///Helper functions END




//////////////////////////////////////////// API calls ////////////////////////////////////////////

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

   //print('Successfully logged in as: ${currentUser!.displayName} (${currentUser!.id})');
    startRealtimeStream();
    isLoggedIn = true;
    requires2FA = false;

    await getCurrentWorld();

    notifyListeners();
  }
  
  Future<void> getCurrentWorld() async{
    //Grab users current location so they don't have to respawn
    final locationResponse = await api.rawApi.getUsersApi().getUser(userId: currentUser!.id);
    final location = locationResponse.data?.location;
    if (location != null && location.isNotEmpty) {
      final worldId = location.split(':').first;
      if (worldId.startsWith('wrld_')) {
        final worldResponse = await api.rawApi.getWorldsApi().getWorld(worldId: worldId);
        currentLocation = worldResponse.data;
      }
    }

    if (currentLocation != null){
      await aL.voteApi.joinNewWorld(currentLocation!.id);
    }
  }

  Future<bool> loginToVrchat(String username, String password) async {
    final (loginSuccess, loginError) = await api.auth.login(
      username: username,
      password: password,
    );

    if (loginError != null) {
     //print('Login failed: ${loginError.error}');
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
      //print(
      //  'Successfully logged in as: ${currentUser!.displayName} (${currentUser!.id})',
      //);
      startRealtimeStream();
      isLoggedIn = true;

      await getCurrentWorld();

      notifyListeners();
    }
    return true;
  }

  Future<bool> verify2FACode(String TFACode) async {
    if (authResponse.twoFactorAuthTypes.contains(TwoFactorAuthType.emailOtp)) {
      final (_, twoFactorError) = await api.auth.verify2fa(TFACode);
      if (twoFactorError != null) {
       //print('Email 2FA failed: ${twoFactorError.error}');
        return false;
      }
    } else {
      // TOTP / Authenticator App 2FA:
      final (_, twoFactorError) = await api.auth.verify2fa(TFACode);
      if (twoFactorError != null) {
       //print('TOTP 2FA failed: ${twoFactorError.error}');
        return false;
      }
    }

    currentUser = api.auth.currentUser;
    if (currentUser != null) {
     //print(
      //  'Successfully logged in as: ${currentUser.displayName} (${currentUser.id})',
      //);
      startRealtimeStream();
      isLoggedIn = true;
      requires2FA = false;

      await getCurrentWorld();


      notifyListeners();
    }
    return true;
  }

  Future<List<LimitedWorld>> getRecommendations(SortOption sortOption, WorldListSortOrder worldListSortOrder, int offset, {tag = null, reqCount = 60}) async {
    if (!isLoggedIn){
     //print("Not logged in.");
      return [];
    }

    if((cachedRecommendations[worldListSortOrder]?.length ?? 0) < offset + reqCount)
    {
      offset = max(offset, cachedRecommendations[worldListSortOrder]?.length ?? 0);
      final worlds = (await api.rawApi.getWorldsApi().searchWorlds(sort: sortOption, n: reqCount, offset: offset, tag: tag)).data ?? <LimitedWorld>[];
     int len = worlds.length;
     print('Recommendations not cached requesting more. Got: $len');
      cachedRecommendations.putIfAbsent(worldListSortOrder, () => <LimitedWorld>[]).addAll(worlds);
      return worlds;
    }
    else{
      return cachedRecommendations[worldListSortOrder]!.sublist(offset, (offset + reqCount) as int?);
    }
    
  }

  Future<bool> createInstance(CreateInstanceRequestRegion region, CombinedInstanceType instanceType, String worldId) async {
    try {
      final response = await api.rawApi.getInstancesApi().createInstance(
            createInstanceRequest: CreateInstanceRequest(
              region: region,
              type: instanceType.instanceType,
              ownerId: instanceType.ownerId ? currentUser!.id : null,
              canRequestInvite: instanceType.canRequestInvite,
              worldId: worldId,
            ),
          );
      
      Instance? instance = response.data;

      //await Future.delayed(Duration(seconds: 5));
      print(instance);
      if (instance != null) {
        await api.rawApi.getInviteApi().inviteMyselfTo(
              worldId: worldId,
              instanceId: instance.instanceId,
            );
        return true;
      }
    } on DioException catch (e) {
      // Print the exact validation error message from VRChat's API
      print('Failed to create instance: ${e.response?.statusCode} - ${e.response?.data}');
    } catch (e) {
      print('Unexpected error creating instance: $e');
    }
    return false;
  }


  Future<bool> logout() async {
    await api.auth.logout();
    currentUser = null;
    isLoggedIn = false;

    notifyListeners();

    return true;
  }

  void startRealtimeStream() {
    api.streaming.vrcEventStream.listen((Object event) async {
      switch (event) {

        case WebsocketUserLocation():
          // Has: user, userId, location, instance, travelingToLocation
         //print('Current user (${event.user.displayName}) moved to ${event.location}');
          
          final worldId = event.location.split(':').first;

          if (worldId.startsWith('wrld_')) {
            try {
              final response = await api.rawApi.getWorldsApi().getWorld(worldId: worldId);
              currentLocation = response.data;

              if (currentLocation != null){
                await aL.voteApi.joinNewWorld(currentLocation!.id);
              }
              


            } catch (e) {
             //print('Failed to fetch world $worldId: $e');
              currentLocation = null;
            }
          }

          notifyListeners();
          break;

        default:
         //print('Received event (${event.runtimeType}): $event');
      }
    });
   //print('Listening to Websocket...');
    api.streaming.start();
  }
}
