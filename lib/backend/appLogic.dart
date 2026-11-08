
import 'package:flutter/material.dart';
import 'package:vrcworldvoterdesktop/backend/voteApiHandler.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';

enum TabSelection{
  worlds,
  voting,
  worldInfo,
}

class Applogic extends ChangeNotifier {
  TabSelection _selectedTab = TabSelection.worlds;
  late VoteApiHandler voteApi;
  late VrchatApiHandler vrcApi;
  TabSelection get selectedTab => _selectedTab;

  Applogic(this.voteApi, this.vrcApi);

  set selectedTab(TabSelection tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  void isExistingVotingUser(){
    voteApi.userExists(userId: vrcApi.currentUser?.id ?? "000");
  }
}