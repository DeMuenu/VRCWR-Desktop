import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';
import 'package:vrcwr/pages/appBar.dart';
import 'package:vrcwr/pages/infoPage.dart';
import 'package:vrcwr/pages/loginVrc.dart';
import 'package:vrcwr/pages/loginVoting.dart';
import 'package:vrcwr/pages/votePage.dart';
import 'dart:io';
import 'dart:convert';

import 'package:vrcwr/pages/worlds.dart';

class VrchatHttpOverrides extends HttpOverrides {
  VrchatHttpOverrides(this.appVersion);

  final String appVersion;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent =
          'VRChatWorldRatingDesktop/$appVersion appDeveloper@lunarlink.ch';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Needed for secure storage
  final packageInfo = await PackageInfo.fromPlatform();
  final fullVersion = packageInfo.buildNumber.isNotEmpty ? '${packageInfo.version}+${packageInfo.buildNumber}' : packageInfo.version;

  HttpOverrides.global = VrchatHttpOverrides(fullVersion);

  runApp(
    MyApp(
      packageVersion: fullVersion,
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.packageVersion});

  final String packageVersion;
  late final vrchatApi = VrchatApiHandler(packageVersion);
  late final voteApi = VoteApiHandler(vrchatApi);
  late final appLogic = Applogic(voteApi, vrchatApi);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await widget.vrchatApi.initVrchatClient();
    
    widget.vrchatApi.setAL(widget.appLogic);

    await widget.vrchatApi.cookieLogin();
    setState(() {
    });

  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
    listenable: Listenable.merge([
      widget.vrchatApi,
      widget.voteApi,
      widget.appLogic,
    ]),
      builder: (context, child) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          appBar: widget.vrchatApi.isLoggedIn
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Builder(
                    builder: (context) => appBar(context, widget.appLogic),
                  ),
                )
              : null,
          body: Stack(
            children: [
              Positioned.fill(
                child: !widget.vrchatApi.isLoggedIn
                    ? VRCLoginScreen(api: widget.vrchatApi)
                    : switch (widget.appLogic.selectedTab) {
                        TabSelection.worlds => RecommendationScreen(widget.vrchatApi, widget.voteApi),
                        TabSelection.voting => !widget.voteApi.isLoggedIn
                            ? VoteLoginScreen(
                                voteApi: widget.voteApi,
                                vrchatApi: widget.vrchatApi,
                              )
                            : VotePage(widget.vrchatApi, widget.voteApi),
                        TabSelection.worldInfo => InfoPage(widget.vrchatApi, widget.voteApi),
                      },
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: UpdatWidget(
                    currentVersion: widget.packageVersion,
                    getLatestVersion: () async {
                      final client = HttpClient();
                      try {
                        String releaseLoc = "";
                        if (Platform.isWindows) {
                          releaseLoc = "https://vrcwr.lunar-appupdater.download/winVersion.json";
                        } else if (Platform.isLinux) {
                          releaseLoc = "https://vrcwr.lunar-appupdater.download/winVersion.json"; //TODO add linux link
                        }

                        final request = await client.getUrl(
                          Uri.parse(releaseLoc),
                        );
                        final response = await request.close();
                        final body = await response.transform(utf8.decoder).join();

                        if (response.statusCode != HttpStatus.ok) {
                          throw HttpException(
                            'Could not fetch latest version: HTTP ${response.statusCode}',
                          );
                        }

                        final json = jsonDecode(body) as Map<String, dynamic>;
                        return json['version'] as String;
                          } finally {
                            client.close();
                          }
                        },

                    getBinaryUrl: (latestVersion) async {
                      if (Platform.isWindows) {
                        return "https://vrcwr.lunar-appupdater.download/win/VRChatWorldRatingDesktop-x86_64-$latestVersion-Installer.exe";
                      } else if (Platform.isLinux) {
                        return "https://github.com/latest/release/bin-linux"; //TODO add linux link
                      } 
                      throw UnsupportedError('Unsupported platform');
                    },

                    getChangelog: (latestVersion, appVersion) async {
                      final client = HttpClient();
                      try {
                        String changelogLoc = "https://vrcwr.lunar-appupdater.download/changelog.json";

                        final request = await client.getUrl(
                          Uri.parse(changelogLoc),
                        );
                        final response = await request.close();
                        final body = await response.transform(utf8.decoder).join();

                        if (response.statusCode != HttpStatus.ok) {
                          throw HttpException(
                            'Could not fetch latest version: HTTP ${response.statusCode}',
                          );
                        }

                        final json = jsonDecode(body) as Map<String, dynamic>;
                        return json['text'] as String;
                      } finally {
                        client.close();
                      }
                    },
                    
                    appName: "VRCWR",
                      ),
                    ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }
}
