
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';

enum TabSelection{
  worlds,
  voting,
  worldInfo,
}

enum WorldListSortOrder{
  newAndNoteworthy,
  popularity,
}

class Applogic extends ChangeNotifier {
  TabSelection _selectedTab = TabSelection.worlds;
  late VoteApiHandler voteApi;
  late VrchatApiHandler vrcApi;
  TabSelection get selectedTab => _selectedTab;

  WorldListSortOrder listSortOrder = WorldListSortOrder.newAndNoteworthy;
  SortOption currentWorldListSortOption = SortOption.hotness;
  String? currentWorldListTag = "system_published_recently";
  final int pageSize = 60;
  late final worldListPagingController = PagingController<int, LimitedWorld>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async => await vrcApi.getRecommendations(currentWorldListSortOption, listSortOrder, (pageKey - 1) * pageSize, tag: currentWorldListTag, reqCount: pageSize),
  );

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

  void setListSortOrder(WorldListSortOrder order){
    switch(order){
      case WorldListSortOrder.newAndNoteworthy:
        listSortOrder = WorldListSortOrder.newAndNoteworthy;
        currentWorldListSortOption = SortOption.hotness;
        currentWorldListTag = "system_published_recently";
      case WorldListSortOrder.popularity:
        listSortOrder = WorldListSortOrder.popularity;
        currentWorldListSortOption = SortOption.popularity;
        currentWorldListTag = null;
    }

    worldListPagingController.refresh();

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