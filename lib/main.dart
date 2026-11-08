import 'package:flutter/material.dart';
import 'package:vrcworldvoterdesktop/backend/voteApiHandler.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';
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
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key}) : vrchatApi = VrchatApiHandler();

  final VrchatApiHandler vrchatApi;
  final voteApi = VoteApiHandler();

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
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      
      home:  
        ListenableBuilder(
          listenable: Listenable.merge([
            widget.vrchatApi,
            widget.voteApi,
          ]),
          builder: (context, child) {return !widget.vrchatApi.isLoggedIn ? 
              VRCLoginScreen(api: widget.vrchatApi) 
            : 
              ((!widget.voteApi.isLoggedIn) ? 
                  VoteLoginScreen(voteApi: widget.voteApi, vrchatApi: widget.vrchatApi,) 
                : 
                  VotePage(widget.vrchatApi));},
        )
    );
  }
}
