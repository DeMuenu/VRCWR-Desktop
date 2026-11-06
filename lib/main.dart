import 'package:flutter/material.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';
import 'package:vrcworldvoterdesktop/pages/login.dart';
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
  MyApp({super.key}) : api = VrchatApiHandler();

  final VrchatApiHandler api;

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
    await widget.api.initVrchatClient();
    await widget.api.cookieLogin();
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  
        ListenableBuilder(
          listenable: widget.api,
          builder: (context, child) {return !widget.api.isLoggedIn ? LoginScreen(api: widget.api) : VotePage(widget.api);},
        )
    );
  }
}
