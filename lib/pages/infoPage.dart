import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
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

class CombinedInstanceType {
  final InstanceType instanceType;
  final bool ownerId;
  final bool canRequestInvite;

  const CombinedInstanceType(
    this.instanceType,
    this.ownerId,
    this.canRequestInvite,
  );
}

class _InfoPageState extends State<InfoPage> {
  late VrchatApiHandler vrcApi;
  CreateInstanceRequestRegion createInstanceRegion = CreateInstanceRequestRegion.us;
  int combinedInstanceTypeNumber = 0;

  late final _pagingController = PagingController<int, WorldReview>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async {
      final response = await widget.voteApi.loadWorldReviews(
        widget.aL.selectedWorldId,
        page: pageKey,
      );
      return response == null ? <WorldReview>[] : response.data;
    },
  );

  final List<MapEntry<String, CombinedInstanceType>> instanceOptions = [
    //MapEntry("Public", CombinedInstanceType(InstanceType.public, false, false)),
    MapEntry("Friends", CombinedInstanceType(InstanceType.friends, true, false)),
    MapEntry("Friends+", CombinedInstanceType(InstanceType.hidden, true, false)),
    MapEntry("Invite", CombinedInstanceType(InstanceType.private, true, false)),
    MapEntry("Invite+", CombinedInstanceType(InstanceType.private, true, true)),
  ];

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
    return Container(color: Colors.transparent,
        child:
          Center(child: 
            widget.aL.selectedWorldVrc != null ?
            
            Row(children: [

              Expanded(flex: 1, child: 
                Padding(padding: EdgeInsetsGeometry.all(20), child: 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 50,),
                      if (widget.aL.selectedWorldVrc?.imageUrl.isNotEmpty ?? false)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          
                          child:                         
                            Image.network(
                              widget.aL.selectedWorldVrc?.imageUrl ?? "",
                              headers: vrcApi.imageHeaders,
                            ),
                        ),
                        SizedBox(height: 10,),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            if (widget.aL.selectedWorldTags.isNotEmpty) ... [
                              for(int i = 0; i < widget.aL.selectedWorldTags.length; i++)
                                tagItem(widget.aL.selectedWorldTags[i].upvotes - widget.aL.selectedWorldTags[i].downvotes, widget.aL.selectedWorldTags[i].tag.replaceFirst('author_tag_', '').replaceFirst('vrcwr_tag_', '')),
                            ]
                            else ... [
                              for(int i = 0; i < (widget.aL.selectedWorldVrc?.tags.length ?? 0); i++)
                                if (widget.aL.selectedWorldVrc?.tags[i] != null && !widget.aL.selectedWorldVrc!.tags[i].startsWith("system") && !widget.aL.selectedWorldVrc!.tags[i].startsWith("admin") && !widget.aL.selectedWorldVrc!.tags[i].startsWith("content")) ... [
                                  tagItem(null, widget.aL.selectedWorldVrc?.tags[i].replaceFirst('author_tag_', '').replaceFirst('vrcwr_tag_', '') ?? ""),
                                ]
                                
                            ]
                          ],
                        ),

                        SizedBox(height: 10,),

                        DecoratedBox(
                          decoration: BoxDecoration(color: Color.fromARGB(100, 0, 0, 0), borderRadius: BorderRadius.circular(4)),
                          child: Padding(padding: EdgeInsetsGeometry.all(15),
                            child: 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                              SizedBox(
                                width: double.infinity,
                                child: Text("Create instance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,),
                              ),

                              Row(children: [
                                Text("Location: ", style: TextStyle(fontSize: 20), textAlign: TextAlign.left,),
                                DropdownButton<CreateInstanceRequestRegion>(
                                  value: createInstanceRegion,
                                  items: [
                                    for (CreateInstanceRequestRegion item in CreateInstanceRequestRegion.values)
                                      DropdownMenuItem<CreateInstanceRequestRegion>(
                                        value: item,
                                        child: Text(item.name),
                                        
                                      ),
                                  ],
                                  onChanged: (CreateInstanceRequestRegion? value) {
                                    if(value != null){
                                      setState(() {
                                        createInstanceRegion = value;
                                      });
                                    }
                                  },
                                ),

                              ]),

                              Row(children: [
                                Text("Type: ", style: TextStyle(fontSize: 20), textAlign: TextAlign.left,),
                                DropdownButton<int>(
                                  value: combinedInstanceTypeNumber,
                                  items: instanceOptions.asMap().entries.map((indexedEntry) {
                                    return DropdownMenuItem<int>(
                                      value: indexedEntry.key,
                                      child: Text(indexedEntry.value.key),
                                    );
                                  }).toList(),
                                  onChanged: (int? value) {
                                    if (value != null) {
                                      setState(() {
                                        combinedInstanceTypeNumber = value;
                                      });
                                    }
                                  },
                                ),
                              ]),

                              SizedBox(height: 5,),

                              Padding(
                                
                                padding: const EdgeInsets.all(0.0),
                                child: SizedBox(
                                  
                                  width: 150,
                                  child: Material(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                      onTap: () async {
                                        final bool success = await vrcApi.createInstance(
                                          createInstanceRegion,
                                          instanceOptions[combinedInstanceTypeNumber].value,
                                          vrcApi.aL.selectedWorldId,
                                        );

                                        if (!mounted) return;

                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Instance created!'),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Text("Create & Invite me", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                                      ),
                                    ),
                                  ),
                                ),
                              ),


                            ],)
                          )
                        
                        
                        ,),

                        
                      
                      ]
                  ),
                )
              ),




              Expanded(flex: 2, child: 
                Padding(padding: EdgeInsetsGeometry.all(20), child: 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 50),

                      Row(children: [
                        Text(widget.aL.selectedWorldVrc?.name ?? "", style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 2, textAlign: TextAlign.left,),
                        SizedBox(width: 10,),
                        Text(widget.aL.selectedWorldVrc?.authorName ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214), fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                      ],),
                      
                      Text(widget.aL.selectedWorldVrc?.description ?? "No description", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214)), overflow: TextOverflow.fade, softWrap: true,maxLines: 8, textAlign: TextAlign.left,),
                    
                      SizedBox(height: 10,),
                      Divider(
                        color: Colors.white
                      ),
                      SizedBox(height: 10,),

                      
                      Padding(padding: EdgeInsetsGeometry.all(4), child: 
                        Row(children: [
                          if (widget.aL.selectedWorldExistsOnServer) ... [
                            scoreContainer(Icons.thumb_up, widget.aL.selectedWorldVote?.likes.toString() ?? "0", "Like count"),
                            SizedBox(width: 5,),
                            scoreContainer(Icons.thumb_down, widget.aL.selectedWorldVote?.dislikes.toString() ?? "0", "Dislike count"),
                            SizedBox(width: 5,),
                          ],
                          scoreContainer(Icons.people, widget.aL.selectedWorldVrc?.occupants.toString() ?? "-", "Occupants"),
                          SizedBox(width: 5,),
                          scoreContainer(Icons.meeting_room_outlined, widget.aL.selectedWorldVrc?.capacity.toString() ?? "-", "Capacity"),
                          SizedBox(width: 5,),
                          scoreContainer(Icons.star, widget.aL.selectedWorldVrc?.favorites.toString() ?? "-", "Favorites", width: 80),
                          SizedBox(width: 5,),
                          scoreContainer(Icons.calendar_month, widget.aL.selectedWorldVrc?.updatedAt.toLocal().toString().split(' ').first ?? "-", "Release date", width: 100),
                        ],)
                      ,),

                      SizedBox(height: 10,),

                      Divider(
                        color: Colors.white
                      ),

                      SizedBox(height: 10,),

                      Text("Comments", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                      

                      Expanded(child:
                        Padding(padding: EdgeInsetsGeometry.all(4), child: PagingListener(
                          controller: _pagingController,
                          
                          builder: (context, state, fetchNextPage) => PagedListView<int, WorldReview>(
                            padding: EdgeInsets.all(0),
                            state: state,
                            fetchNextPage: fetchNextPage,
                            builderDelegate: PagedChildBuilderDelegate(
                              itemBuilder: (context, item, index) => worldItem(item),
                              noItemsFoundIndicatorBuilder: (context) => Center(
                                child: Text(
                                  widget.aL.voteApi.isLoggedIn ? "No comments found" : "Comments are only visible if you're logged in to VRCWR",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 214, 214, 214),
                                  ),
                                ),
                              ),
                            )
                            
                          ),
                        ),),
                      ),


                    ]
                  )
                )
              ),


              ])
              :
              Center(child: Text("Select a world", style: TextStyle(fontSize: 40, color: Colors.white),))
          
          )
          
    );
  }

  Widget tagItem(int? count, String tagName){
    return (count == null || count > 0 ) ? SizedBox(
      height: 30,
      child: DecoratedBox(decoration: 
        BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(4)), 
          child: 
            Padding(padding: EdgeInsetsGeometry.all(4), child: 
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                if (count != null && count != 0) ... [
                  Text(count > 0 ? "+" : "-", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  Text( count.abs().toString(), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  SizedBox(width: 5,),

                ],
                
                Text(tagName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],)
            
            ),
      
      )
    ) : SizedBox.shrink();
  }

  Widget worldItem(WorldReview wR){
  return Padding( padding: EdgeInsetsGeometry.all(5),
  child:
    DecoratedBox(
      decoration: BoxDecoration(color: const Color.fromARGB(100, 0, 0, 0), borderRadius: BorderRadius.circular(4)),
      child: Padding( padding: EdgeInsetsGeometry.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Column(
              children: [
                CircleAvatar(foregroundImage: NetworkImage(wR.user.userIcon),),
                Text(wR.user.username, overflow: TextOverflow.ellipsis, maxLines: 1,),
              ],),
            ),
            
            
            SizedBox(width: 15,),
            Expanded(
              child: Text(wR.comment ?? "Error loading comment.",
                maxLines: 5,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.left,
                softWrap: true,
                style: TextStyle(fontSize: 15),
                
              ),
            ),


            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(wR.like > 0 ? Icons.thumb_up : Icons.thumb_down),
                SizedBox(height: 5,),
                Text(wR.createdAt.toLocal().toString().split(' ').first, overflow: TextOverflow.ellipsis, maxLines: 1,),
              ],),

        ],),
      ),
    ));

  }


  Widget scoreContainer(
    IconData currentIcon,
    String text,
    String description,
    {double width = 70}
    ) {
    return Tooltip(message: description, child: 
      SizedBox(
        width: width,
        height: 90,
        child: 
          Material(
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.antiAlias,
            color: const Color.fromARGB(100, 0, 0, 0),
            child: 
              
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(currentIcon, size: 30, color: Colors.amber),
                  Text(text, style: TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
              
            )
            
            
      )
    );
  }


}