
import 'package:flutter/material.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';

class VotePage extends StatefulWidget {
  final VrchatApiHandler vrcApi;


  const VotePage(this.vrcApi, {super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}


class _VotePageState extends State<VotePage> {
  late VrchatApiHandler vrcApi;

  int aiImagesVoteScore = 0;
  int aiMeshesVoteScore = 0;
  int gamblingVoteScore = 0;
  int p2wVoteScore = 0;
  String worldComment = "";


  @override
  void initState(){
    super.initState();
    vrcApi = widget.vrcApi;

  }

  void resetFields(){
    aiImagesVoteScore = 0;
    aiMeshesVoteScore = 0;
    gamblingVoteScore = 0;
    p2wVoteScore = 0;
    worldComment = "";
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color.fromARGB(255, 20, 20, 20),
        child:
          Center(child: 
            vrcApi.currentLocation != null ?
            Column(
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: Column(children: [
                    Text("Vote for your current location:"),
                    Row(children: [
                      if (vrcApi.currentLocation?.thumbnailImageUrl.isNotEmpty ?? false)
                        Image.network(
                          vrcApi.currentLocation?.thumbnailImageUrl ?? "",
                          headers: vrcApi.imageHeaders,
                        ),
                    ],)
                  ],),
                ),
              ]
            )
            :
            Text("Waiting for you to join a world.")
        )
    );
  }

}