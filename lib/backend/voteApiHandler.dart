import 'package:flutter/material.dart';

class DownstreamWorldVoteInfo {
  late String worldId;
  late int votes;
  late Map<String, int> tags;
  late List<String> comments;

  DownstreamWorldVoteInfo(this.worldId, this.votes, this.tags, this.comments);
}

class UpstreamWorldVoteInfo {
  late String worldId;
  late int vote;
  late Map<String, int> tags;
  late String comment;


  UpstreamWorldVoteInfo(this.worldId, this.vote, this.tags, this.comment);
}



class VoteApiHandler extends ChangeNotifier{

  late String sessionToken;
  bool isLoggedIn = false;
  bool isRegisteredUser = true;

  Future<bool> doesAccountExists() async {
    await Future.delayed(const Duration(seconds: 3));
    isRegisteredUser = false; // TODO Real function
    notifyListeners();
    return true;
  }

  Future<bool> login(String userId, String password) async{

    //Todo 
    await Future.delayed(const Duration(seconds: 3));
    isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> createAccount(String userId, String password, String eMail, String registrationToken) async{
    notifyListeners();
    return true;
  }

  Future<bool> publishReview() async{
    notifyListeners();
    return true;
  }
 
}
