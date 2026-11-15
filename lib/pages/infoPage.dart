import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';

class InfoPage extends StatefulWidget {
  final VrchatApiHandler vrcApi;
  final VoteApiHandler voteApi;
  final Applogic aL;


  const InfoPage(this.vrcApi, this.voteApi, this.aL,{super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}


class _InfoPageState extends State<InfoPage> {
  late VrchatApiHandler vrcApi;



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
    return Container(color: const Color.fromARGB(255, 15, 15, 15),
        child:
          Center(child: 
            widget.aL.selectedWorldVrc != null ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const .symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: Column(children: [
                    Center(child: Text("World Info", style: TextStyle(fontSize: 40, color: Colors.white),)),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Color.fromARGB(255, 43, 43, 43),),
                      child: 
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          if (widget.aL.selectedWorldVrc?.thumbnailImageUrl.isNotEmpty ?? false)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child:                         
                              Image.network(
                                widget.aL.selectedWorldVrc?.thumbnailImageUrl ?? "",
                                headers: vrcApi.imageHeaders,
                              ),
                          ),
                          SizedBox(width: 12,),
                          Expanded(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.aL.selectedWorldVrc?.name ?? "", style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                              Text(widget.aL.selectedWorldVrc?.authorName ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214), fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                              Text(widget.aL.selectedWorldVrc?.description ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214)), overflow: TextOverflow.fade, softWrap: true,maxLines: 4, textAlign: TextAlign.left,),
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
            Center(child: Text("Select a world", style: TextStyle(fontSize: 40, color: Colors.white),))
        )
    );
  }

}