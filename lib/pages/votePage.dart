
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
  String? _lastWorldId;
  final _commentBoxController = TextEditingController();

  int generalVoteScore = 0;

  Map<String, bool> tags = {}; 

  String worldComment = "";


  @override
  void initState(){
    super.initState();
    vrcApi = widget.vrcApi;
    _lastWorldId = vrcApi.currentLocation?.id;
    vrcApi.addListener(_handleWorldChange);
  }

  void _handleWorldChange() {
    final worldId = vrcApi.currentLocation?.id;
    if (worldId == null || worldId == _lastWorldId) return;

    _lastWorldId = worldId;
    resetFields();
  }

  void resetFields() {
    _commentBoxController.clear();
    setState(() {
      generalVoteScore = 0;
      tags.clear();
      worldComment = "";
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
                Text("   Rating:          Does this world contain:", style: TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.left,),
                Expanded(child: 
                  GridView.extent(
                    primary: false,
                    padding: const EdgeInsets.only(left: 12, right: 12),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 150,
                    maxCrossAxisExtent: 90,
                    children: [
                      voteContainer(
                        Icons.how_to_vote,
                        "Like",
                        generalVoteScore,
                        (int score) { setState(() => generalVoteScore = score); },
                        upVoteIcon: Icons.thumb_up,
                        downVoteIcon: Icons.thumb_down,
                      ),
                      tagContainer(
                        CupertinoIcons.paintbrush,
                        "AI Images",
                        tags["aiImagesVoteScore"] ?? false,
                        (bool score) {
                          setState(() => tags["aiImagesVoteScore"] = score);
                        },
                      ),
                      tagContainer(
                        CupertinoIcons.cube,
                        "AI World",
                        tags["aiMeshesVoteScore"] ?? false,
                        (bool score) {
                          setState(() => tags["aiMeshesVoteScore"] = score);
                        },
                      ),
                      for (int i = 0; i < (vrcApi.currentLocation?.tags.length ?? 0); i++) 
                        if ((vrcApi.currentLocation?.tags[i] ?? '').startsWith('author_tag_')) ...{
                          tagContainer(
                            CupertinoIcons.tag,
                            (vrcApi.currentLocation?.tags[i] ?? '').replaceFirst('author_tag_', ''),
                            tags[vrcApi.currentLocation?.tags[i] ?? ''] ?? false,
                            (bool score) {
                              setState(() => tags[vrcApi.currentLocation?.tags[i] ?? ''] = score);
                            },
                          ),
                        }
                        
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
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color.fromARGB(255, 73, 73, 73)),
      width: 90,
      height: 150,
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

  Widget tagContainer(
    IconData currentIcon,
    String text,
    bool value,
    ValueChanged<bool> onScoreChanged
    ) {
    return SizedBox(
      width: 90,
      height: 90,
      child: 
          Material(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            color: (value != true) ? Color.fromARGB(255, 73, 73, 73) : Color.fromARGB(255, 0, 33, 3),
            child: 
              InkWell(
                onTap: () {
                  onScoreChanged(!value);
                },
                child: 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(currentIcon, size: 30, color: (value != true) ? Colors.white : Colors.blue),
                      Text(text, style: TextStyle(fontSize: 15, color: (value != true) ? Colors.white : Colors.blue)),
                    ],
                  ),
              ),
            )
          
          
    );
  }

}