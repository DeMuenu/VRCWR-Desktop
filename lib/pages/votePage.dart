import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';

class VotePage extends StatefulWidget {
  final VrchatApiHandler vrcApi;
  final VoteApiHandler voteApi;


  const VotePage(this.vrcApi, this.voteApi,{super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}


class _VotePageState extends State<VotePage> {
  late VrchatApiHandler vrcApi;
  bool _hasRequest = false;


  @override
  void initState(){
    super.initState();
    vrcApi = widget.vrcApi;
  }

  @override
  void dispose() {
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {

    final List<Color> inactiveColors = [
      Color.fromARGB(1, 0, 0, 0),
      Color.fromARGB(1, 0, 0, 0),
    ];

    final List<Color> upvoteColors = [
      const Color.fromARGB(40, 0, 110, 40),
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
    ];

    final List<Color> downvoteColors = [
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
      Color.fromARGB(10, 0, 0, 0),
      const Color.fromARGB(40, 130, 20, 20),
    ];

    return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 90,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.voteApi.generalVoteScore == 0
                ? inactiveColors
                : (widget.voteApi.generalVoteScore > 0 ? upvoteColors : downvoteColors),
          ),
        ),
        child: 
          Center(child: 
            vrcApi.currentLocation != null ?
            Row(children: [
              Expanded(flex: 1 ,child: 
                Padding(padding: EdgeInsetsGeometry.all(20), child: 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 50,),
                      if (vrcApi.currentLocation?.imageUrl.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          
                          child:                         
                            Image.network(
                              vrcApi.currentLocation?.imageUrl ?? "",
                              headers: vrcApi.imageHeaders,
                            ),
                        ),

                      SizedBox(height: 10,),
                      Text(vrcApi.currentLocation?.name ?? "", style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 2, textAlign: TextAlign.left,),
                      SizedBox(height: 5,),

                      Text(vrcApi.currentLocation?.authorName ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214), fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),

                      SizedBox(height: 10,),
                      Divider(
                        color: Colors.white
                      ),
                      SizedBox(height: 10,),
                      Text(vrcApi.currentLocation?.description ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214)), overflow: TextOverflow.fade, softWrap: true,maxLines: 8, textAlign: TextAlign.left,),
                    ]
                  ),
                )
              ),
              Expanded(flex: 2 ,child: 
                Padding(padding: EdgeInsetsGeometry.all(20), child: 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 50),
                      
                      if (widget.voteApi.worldExistsOnServer) ...([
                        SizedBox(height: 10,),
                        Text("Does this world contain", style: TextStyle(color: Colors.white,fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.left,),
                        GridView.extent(
                            primary: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 12, right: 12),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 160,
                            maxCrossAxisExtent: 90,
                            children: [
                              for (int i = widget.voteApi.currentWorldTags.length - 1; i >= 0 && i < 8; i--) 
                                
                                voteContainer(
                                  CupertinoIcons.tag, 
                                  widget.voteApi.currentWorldTags[i].tag.replaceFirst('author_tag_', '').replaceFirst('vrcwr_tag_', ''), 
                                  widget.voteApi.uiTags[widget.voteApi.currentWorldTags[i].id] ?? 0,
                                  (score) {setState(() => widget.voteApi.uiTags[widget.voteApi.currentWorldTags[i].id] = score);}
                                ),
                                
                            ],
                          ),
                        SizedBox(height: 15,),
                        Text("Review", style: TextStyle(color: Colors.white,fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.left,),

                        Padding(padding: const .all(10), child: 
                          Row(children: [
                            voteContainer(
                              Icons.how_to_vote,
                              "Like",
                              widget.voteApi.generalVoteScore,
                              (int score) { setState(() => widget.voteApi.generalVoteScore = score); },
                              upVoteIcon: Icons.thumb_up,
                              downVoteIcon: Icons.thumb_down,
                            ),
                            Expanded( child: 
                              Padding(padding: const .symmetric(horizontal: 10), child: 
                                DecoratedBox(
                                  decoration: BoxDecoration(color: Color.fromARGB(150, 30, 30, 30), borderRadius: BorderRadius.circular(4)),
                                  child: Padding(padding: const .symmetric(horizontal: 16),
                                  child: TextField(
                                      controller: widget.voteApi.commentBoxController,
                                      decoration: const InputDecoration(
                                        labelText: 'Leave a PUBLIC comment, your username will be shown. (optional)',
                                        labelStyle: TextStyle(color: Colors.white),
                                        
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.text,
                                      minLines: 4,
                                      maxLines: 4,
                                      maxLength: 500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],),
                        ),

                       
                        SizedBox(height: 30,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: 
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 120,
                                  child: Material(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                      onTap: () async{
                                        if (widget.voteApi.generalVoteScore == 0) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('You need to up/downvote the world.')),
                                          );
                                          return;
                                        }

                                        bool published = await widget.voteApi.publishReview(UpstreamWorldVoteInfo(
                                          worldId: widget.voteApi.currentWorld?.worldId ?? "000",
                                          userId: widget.vrcApi.currentUser?.id ?? "000",
                                          reviewUserName: widget.vrcApi.currentUser?.displayName ?? "Bugged User", 
                                          reviewUserIcon: widget.vrcApi.currentUser!.iconUrl ?? "", 
                                          vote: widget.voteApi.generalVoteScore,
                                          comment: widget.voteApi.commentBoxController.text,
                                          tags: widget.voteApi.uiTags,
                                          ),
                                        );

                                        if (published) {
                                          String action = widget.voteApi.hasOwnExistingReview ? "updated" : "published";
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Your review has been $action!')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to publish your review: ${widget.voteApi.lastErrorMessage}')),
                                          );
                                        }

                                        widget.voteApi.hasOwnExistingReview = published;

                                        setState(() {});

                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(!widget.voteApi.hasOwnExistingReview ? "Submit" : "Update Review", textAlign: TextAlign.center, style: TextStyle(color: Color.fromARGB(255, 26,26,26), fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.voteApi.hasOwnExistingReview) ...([
                              Expanded(child: 
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 120,
                                    child: Material(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(4),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(4),
                                        onTap: () async{
                                          await vrcApi.aL.setSelectedWorld(vrcApi.currentLocation?.id ?? "000");
                                          vrcApi.aL.selectedTab = TabSelection.worldInfo;
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text("See other's reviews", textAlign: TextAlign.center, style: TextStyle(color: Color.fromARGB(255, 26,26,26), fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                          ]
                          )
                      ]),
                      ])

                      else 
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 120,
                            child: Material(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                onTap: () async{
                                  if (_hasRequest) return;

                                  if(widget.vrcApi.currentLocation != null){
                                    _hasRequest = true;
                                    if (await widget.voteApi.addWorld(vrcApi.currentLocation?.id ?? "000")){
                                      await widget.voteApi.updateCurrentWorld();
                                    }
                                    _hasRequest = false;
                                  }
                                  setState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("Be the first to create a review.", textAlign: TextAlign.center, style: TextStyle(color: Color.fromARGB(255, 26,26,26), fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if(widget.voteApi.lastErrorMessage != null) ...{
                        Text(widget.voteApi.lastErrorMessage ?? "Error", style: TextStyle(color: Colors.red),)
                      },
                      Spacer(),
                      
                    ]
                  )
                )
              )

            ],)
            
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

    final List<Color> inactiveColors = [
      const Color.fromARGB(150, 30, 30, 30),
      const Color.fromARGB(150, 30, 30, 30),
    ];

    final List<Color> upvoteColors = [
      const Color.fromARGB(150, 0, 110, 40),
      const Color.fromARGB(150, 0, 33, 3),
      const Color.fromARGB(150, 0, 33, 3),
    ];

    final List<Color> downvoteColors = [
      const Color.fromARGB(150, 45, 0, 0),
      const Color.fromARGB(150, 45, 0, 0),
      const Color.fromARGB(150, 130, 20, 20),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 90,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: value == 0
              ? inactiveColors
              : (value > 0 ? upvoteColors : downvoteColors),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Spacer(),
          IconButton(onPressed: () => (value != 1) ? onScoreChanged(1) : onScoreChanged(0), icon: Icon(upVoteIcon, color: (value != 1) ? Colors.white : Colors.amber, )),
          Spacer(),
          Icon(currentIcon, size: 30, color: Colors.white),
          Text(text, style: TextStyle(fontSize: 15, color: Colors.white)),
          Spacer(),
          IconButton(onPressed: ()  => (value != -1) ? onScoreChanged(-1) : onScoreChanged(0), icon: Icon(downVoteIcon, color: (value != -1) ? Colors.white : Colors.amber)),
          Spacer(),
        ],),
    );
  }



}