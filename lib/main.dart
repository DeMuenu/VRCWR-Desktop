import 'dart:async';

import 'package:desktop_updater/updater_controller.dart';
import 'package:desktop_updater/widget/update_direct_card.dart';
import 'package:desktop_updater/widget/update_widget.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:VRCWR/backend/updateHandler.dart';
import 'package:VRCWR/backend/appLogic.dart';
import 'package:VRCWR/backend/voteApiHandler.dart';
import 'package:VRCWR/backend/vrchatApiHandler.dart';
import 'package:VRCWR/pages/appBar.dart';
import 'package:VRCWR/pages/loginVrc.dart';
import 'package:VRCWR/pages/loginVoting.dart';
import 'package:VRCWR/pages/votePage.dart';
import 'dart:io';

import 'package:VRCWR/pages/worlds.dart';

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
  final updaterController = await createDesktopUpdaterController();
  unawaited(updaterController.checkForUpdates());
  runApp(
    MyApp(
      packageVersion: packageInfo.version,
      updaterController: updaterController,
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.packageVersion, required this.updaterController,});

  final String packageVersion;
  final DesktopUpdaterController updaterController;
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
    await widget.vrchatApi.cookieLogin();
    widget.vrchatApi.setAL(widget.appLogic);
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
      widget.updaterController,
    ]),
      builder: (context, child) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          appBar: widget.vrchatApi.isLoggedIn
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: appBar(widget.appLogic),
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

              // 2. Top layer: Floating update card overlaid on top
              Positioned(
                top: 16,
                right: 16,
                // Optional: Constrain the width so it looks like a floating toast/notification
                width: 420,
                child: DesktopUpdateDirectCard(
                  controller: widget.updaterController,
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
