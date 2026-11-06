
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';

class VotePage extends StatefulWidget {
  final VrchatApiHandler vrcApi;


  const VotePage(this.vrcApi, {super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}


class _VotePageState extends State<VotePage> {
  late VrchatApiHandler vrcApi;
  final _commentBoxController = TextEditingController();

  int generalVoteScore = 0;
  int clickbaitVoteScore = 0;
  int aiImagesVoteScore = 0;
  int aiMeshesVoteScore = 0;
  int aiVoiceVoteScore = 0;
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
    return Scaffold(backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        body:
          Center(child: 
            vrcApi.currentLocation != null ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: Column(children: [
                    Center(child: Text("Rate the current world", style: TextStyle(fontSize: 40, color: Colors.white),)),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Color.fromARGB(255, 43, 43, 43),),
                      child: 
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          if (vrcApi.currentLocation?.thumbnailImageUrl.isNotEmpty ?? false)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child:                         
                              Image.network(
                                vrcApi.currentLocation?.thumbnailImageUrl ?? "",
                                headers: vrcApi.imageHeaders,
                              ),
                          ),
                          SizedBox(width: 12,),
                          Expanded(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vrcApi.currentLocation?.name ?? "", style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                              Text(vrcApi.currentLocation?.authorName ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214), fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                              Text(vrcApi.currentLocation?.description ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214)), overflow: TextOverflow.fade, softWrap: true,maxLines: 4, textAlign: TextAlign.left,),
                            ],
                            ),
                          )
                          ],
                        ),
                    )
                    
                  ],),
                ),
                SizedBox(height: 10,),
                Text("   Rating:         Does this world contain:", style: TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.left,),
                Expanded(child: 
                  GridView.extent(
                    primary: false,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 150,
                    maxCrossAxisExtent: 90,
                    children: [
                      voteContainer(Icons.how_to_vote, "Quality", generalVoteScore, (score) {setState(() => generalVoteScore = score);}, upVoteIcon: Icons.thumb_up, downVoteIcon: Icons.thumb_down),
                      voteContainer(Icons.broken_image, "Clickbait", clickbaitVoteScore, (score) {setState(() => clickbaitVoteScore = score);}),
                      voteContainer(CupertinoIcons.paintbrush, "AI Images", aiImagesVoteScore, (score) {setState(() => aiImagesVoteScore = score);}),
                      voteContainer(CupertinoIcons.cube, "AI Meshes", aiMeshesVoteScore, (score) {setState(() => aiMeshesVoteScore = score);}),
                      voteContainer(CupertinoIcons.speaker_1_fill, "AI Voices", aiVoiceVoteScore, (score) {setState(() => aiVoiceVoteScore = score);}),
                      voteContainer(CupertinoIcons.arrow_right_arrow_left_circle, "Gambling", gamblingVoteScore, (score) {setState(() => gamblingVoteScore = score);}),
                      voteContainer(CupertinoIcons.creditcard, "P2W", p2wVoteScore, (score) {setState(() => p2wVoteScore = score);}),
                    ],
                  ),

                ),

                SizedBox(height: 30,),

                Padding(padding: const .symmetric(horizontal: 16), child: 
                  DecoratedBox(
                    decoration: BoxDecoration(color: Color.fromARGB(255, 66, 66, 66), borderRadius: BorderRadius.circular(12)),
                    child: Padding(padding: const .symmetric(horizontal: 16),
                    child: TextField(
                        controller: _commentBoxController,
                        decoration: const InputDecoration(
                          labelText: 'Leave a PUBLIC comment, your username will be shown. (optional)',
                          labelStyle: TextStyle(color: Colors.white),
                          
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.text,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 500,
                        
                        onSubmitted: (_) {worldComment = _commentBoxController.text;},
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30,),
              ]
            )
            :
            Center(child: Text("Waiting for you to join a world.", style: TextStyle(fontSize: 40, color: Colors.white),))
        )
    );
  }


  Widget voteContainer(
    IconData currentIcon,
    String text,
    int value,
    ValueChanged<int> onScoreChanged, {
    IconData upVoteIcon = Icons.check,
    IconData downVoteIcon = Icons.close,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color.fromARGB(255, 73, 73, 73)),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Spacer(),
          IconButton(onPressed: () => (value != 1) ? onScoreChanged(1) : onScoreChanged(0), icon: Icon(upVoteIcon, color: (value != 1) ? Colors.white : Colors.blue, )),
          Spacer(),
          Icon(currentIcon, size: 30, color: Colors.white),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.white)),
          Spacer(),
          IconButton(onPressed: ()  => (value != -1) ? onScoreChanged(-1) : onScoreChanged(0), icon: Icon(downVoteIcon, color: (value != -1) ? Colors.white : Colors.blue)),
          Spacer(),
        ],),
    );
  }

}