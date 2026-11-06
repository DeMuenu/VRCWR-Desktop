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

  Future<bool> login() async{

    //Todo 

    return false;
  }

  
  


 
}
