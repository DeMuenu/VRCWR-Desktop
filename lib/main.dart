import 'package:flutter/material.dart';
import 'package:vrcworldvoterdesktop/backend/appLogic.dart';
import 'package:vrcworldvoterdesktop/backend/voteApiHandler.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';
import 'package:vrcworldvoterdesktop/pages/appBar.dart';
import 'package:vrcworldvoterdesktop/pages/loginVrc.dart';
import 'package:vrcworldvoterdesktop/pages/loginVoting.dart';
import 'package:vrcworldvoterdesktop/pages/votePage.dart';
import 'dart:io';

class VrchatHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'VRChatWorldVoterDesktop/0.0.1 appDeveloper@lunarlink.ch';
  }
}

void main() {
  HttpOverrides.global = VrchatHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized(); //Needed for secure storage
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final vrchatApi = VrchatApiHandler();
  
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
            body: !widget.vrchatApi.isLoggedIn
                ? VRCLoginScreen(api: widget.vrchatApi)
                : switch (widget.appLogic.selectedTab) {
                    TabSelection.worlds => const Text("Worlds"),
                    TabSelection.voting => !widget.voteApi.isLoggedIn
                        ? VoteLoginScreen(
                            voteApi: widget.voteApi,
                            vrchatApi: widget.vrchatApi,
                          )
                        : VotePage(widget.vrchatApi, widget.voteApi),
                    TabSelection.worldInfo => const Text("Worldinfo"),
                  },
          ),
        );
      },
    );
  }
}
