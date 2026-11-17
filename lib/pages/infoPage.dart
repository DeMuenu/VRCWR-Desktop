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

                        SizedBox(height: 30,),

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
                    children: [
                      SizedBox(height: 50),

                      Text(widget.aL.selectedWorldVrc?.name ?? "", style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 2, textAlign: TextAlign.left,),
                      SizedBox(height: 5,),

                      Text(widget.aL.selectedWorldVrc?.authorName ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214), fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),

                      SizedBox(height: 10,),
                      Divider(
                        color: Colors.white
                      ),
                      SizedBox(height: 10,),
                      Text(widget.aL.selectedWorldVrc?.description ?? "", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 214, 214, 214)), overflow: TextOverflow.fade, softWrap: true,maxLines: 8, textAlign: TextAlign.left,),
                    
                      SizedBox(height: 20,),
                      Text("Reviews", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.fade, maxLines: 1, textAlign: TextAlign.left,),
                      
                    ]
                  )
                )
              )])
              :
              Center(child: Text("Select a world", style: TextStyle(fontSize: 40, color: Colors.white),))
          
          )
          
    );
  }

}