import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vrcwr/backend/appLogic.dart';

Widget appBar(BuildContext context, Applogic aL) {

    int? hoveredTab;

    return  StatefulBuilder( 
      builder: (BuildContext context, StateSetter setState) {
      return ClipRect(child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: 
        Container(
          decoration: BoxDecoration(color: const Color.fromARGB(114, 10, 10, 10)),
          width: 90,
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 10,),

              Text("VRC World Rating", style: TextStyle(fontFamily: "KaushanScript", fontSize: 20, color: Colors.amber)),

              SizedBox(width: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 120,
                  child: Material(
                      color: const Color.fromARGB(114, 10, 10, 10),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onHover: (value) {
                          setState(() {
                            hoveredTab = value ? 0 : null;
                          });
                        },
                      onTap: () {
                        aL.selectedTab = TabSelection.worlds;
                        
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Worlds", textAlign: TextAlign.center, style: TextStyle(color: hoveredTab == 0 || aL.selectedTab == TabSelection.worlds ? Colors.amber : Colors.white),),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 10,),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 120,
                  child: Material(
                      color: const Color.fromARGB(114, 10, 10, 10),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onHover: (value) {
                          setState(() {
                            hoveredTab = value ? 1 : null;
                          });
                        },
                      onTap: () {
                        aL.selectedTab = TabSelection.worldInfo;
                        
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Info", textAlign: TextAlign.center, style: TextStyle(color: hoveredTab == 1  || aL.selectedTab == TabSelection.worldInfo ? Colors.amber : Colors.white),),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10,),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 120,
                  child: Material(
                      color: const Color.fromARGB(114, 10, 10, 10),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onHover: (value) {
                          setState(() {
                            hoveredTab = value ? 2 : null;
                          });
                        },
                      onTap: () {
                        aL.selectedTab = TabSelection.voting;
                        
                      },
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Vote", textAlign: TextAlign.center, style: TextStyle(color: hoveredTab == 2 || aL.selectedTab == TabSelection.voting? Colors.amber : Colors.white),),
                      ),
                    ),
                  ),
                ),
              ),

              Spacer(),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 50,
                  child: Material(
                      color: const Color.fromARGB(255, 147, 34, 0),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text("Log out?"),
                            content: const Text("Are you sure you want to log out? This will clear your login information, if you don't want to log in again you can just close the app."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: const Text("Log Out"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: const Text("Just close the app"),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == null) return;

                        if (shouldLogout) {
                          exit(0);
                        }
                        else
                        {
                          await aL.vrcApi.logout();
                          await aL.voteApi.logout();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.logout),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10,),
            ],),
        )
      )
    );});
  }