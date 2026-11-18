
import 'package:flutter/material.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';

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


  ///Seleced world info START
  String selectedWorldId = "000";
  World? selectedWorldVrc;
  DownstreamWorldVoteInfo? selectedWorldVote = DownstreamWorldVoteInfo.fromJson({
    'world_id': '000',
  });
  List<WorldTag> selectedWorldTags = [];
  // selectedWorldReviews;
  bool selectedWorldExistsOnServer = false;
  ///Seleced world info END

  Future<void> setSelectedWorld(String worldId) async {
    selectedWorldId = worldId;
    selectedWorldVrc = (await vrcApi.api.rawApi.getWorldsApi().getWorld(worldId: worldId)).data;
    selectedWorldExistsOnServer = await voteApi.worldExist(worldId);
    if (selectedWorldExistsOnServer){
      selectedWorldVote = await voteApi.getCachedWorldVoteInfo(worldId, forceRefresh: true);
      selectedWorldTags = await voteApi.loadWorldTags(worldId) ?? [];
      print(selectedWorldTags[0].upvotes);
      print(selectedWorldTags[0].downvotes);
    }
    else{
      selectedWorldVote = DownstreamWorldVoteInfo.fromJson({
        'world_id': '000',
      });
      selectedWorldTags.clear();
    }
    notifyListeners();
  }


  set selectedTab(TabSelection tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  void isExistingVotingUser(){
    voteApi.userExists(userId: vrcApi.currentUser?.id ?? "000");
  }

  void getWorldRecommendations(){

  }

}