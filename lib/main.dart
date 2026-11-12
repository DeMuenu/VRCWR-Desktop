import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';
import 'package:vrcwr/pages/appBar.dart';
import 'package:vrcwr/pages/loginVrc.dart';
import 'package:vrcwr/pages/loginVoting.dart';
import 'package:vrcwr/pages/votePage.dart';
import 'dart:io';

import 'package:vrcwr/pages/worlds.dart';

class VrchatHttpOverrides extends HttpOverrides {
  VrchatHttpOverrides(this.appVersion);

  final String appVersion;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent =
          'VRChatWorldVoterDesktop/$appVersion appDeveloper@lunarlink.ch';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Needed for secure storage
  final packageInfo = await PackageInfo.fromPlatform();
  HttpOverrides.global = VrchatHttpOverrides(packageInfo.version);

  runApp(
    MyApp(
      packageVersion: packageInfo.version,
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.packageVersion});

  final String packageVersion;
  late final vrchatApi = VrchatApiHandler(packageVersion);
  final voteApi = VoteApiHandler();
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
                        TabSelection.worlds => ListViewScreen(widget.vrchatApi),
                        TabSelection.voting => !widget.voteApi.isLoggedIn
                            ? VoteLoginScreen(
                                voteApi: widget.voteApi,
                                vrchatApi: widget.vrchatApi,
                              )
                            : VotePage(widget.vrchatApi, widget.voteApi),
                        TabSelection.worldInfo => const Text("Worldinfo"),
                      },
              ),
              UpdatWidget(
                currentVersion: "1.0.0",
                getLatestVersion: () async {
                  // Here you should fetch the latest version. It must be semantic versioning for update detection to work properly.
                  return "1.0.1";
                },
                getBinaryUrl: (latestVersion) async {
                  // Here you provide the link to the binary the user should download. Make sure it is the correct one for the platform!
                  return "https://github.com/latest/release/bin.exe";
                },
                // Lastly, enter your app name so we know what to call your files.
                appName: "Updat Example",
              ),
            ],
          ),
        ),
      );
      },
    );
  }
}
