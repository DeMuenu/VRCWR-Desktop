import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';
import 'package:vrchat_dart_generated/src/model/create_instance_request_region.dart';

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
    return Container(color: const Color.fromARGB(255, 15, 15, 15),
        child:
          Center(child: 
            widget.aL.selectedWorldVrc != null ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // ignore: deprecated_member_use
                  child: Column(children: [
                    Center(child: Text("World Info", style: TextStyle(fontSize: 40, color: Colors.white),)),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
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
                    ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text("Create instance.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.left,),
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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

                        SizedBox(width: 10,),
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

                        SizedBox(width: 10,),

                        Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: SizedBox(
                          width: 150,
                          child: Material(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
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
                                child: Text("Create & Invite me", textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ],
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