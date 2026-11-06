
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
    return Scaffold(backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        body:
          Center(child: 
            vrcApi.currentLocation != null ?
            Column(
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: Column(children: [
                    Center(child: Text("Rate your current world", style: TextStyle(fontSize: 40, color: Colors.white),)),
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
              ]
            )
            :
            Center(child: Text("Waiting for you to join a world.", style: TextStyle(fontSize: 40, color: Colors.white),))
        )
    );
  }

}