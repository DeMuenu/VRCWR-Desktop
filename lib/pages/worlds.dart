
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:ribbon_widget/ribbon_widget.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/appLogic.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';


class RecommendationScreen extends StatefulWidget {
  final VrchatApiHandler vrcApi;
  final VoteApiHandler voteApi;
  final Applogic aL;
  const RecommendationScreen(this.vrcApi, this.voteApi, this.aL,{super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PagingListener(
      controller: widget.aL.worldListPagingController,
      builder: (context, state, fetchNextPage) => PagedGridView<int, LimitedWorld>(
        state: state,
        fetchNextPage: fetchNextPage,
        padding: const EdgeInsets.only(
          top: 16 + 50, //50 for the app bar to not be hidden
          left: 16,
          right: 16,
          bottom: 16,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300, // Maximum width of each world card in pixels
          mainAxisExtent: 250,
          mainAxisSpacing: 16,     // Vertical spacing between rows
          crossAxisSpacing: 16,    // Horizontal spacing between columns
        ),
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, item, index) => WorldItem(
            world: item,
            voteApi: widget.voteApi,
            aL: widget.aL,
          ),
        ),
      ),
    );
}

class WorldItem extends StatefulWidget {
  final LimitedWorld world;
  final VoteApiHandler voteApi;
  final Applogic aL;

  const WorldItem({
    super.key,
    required this.world,
    required this.voteApi,
    required this.aL,
  });

  @override
  State<WorldItem> createState() => _WorldItemState();
}

class _WorldItemState extends State<WorldItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovered ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 150),
      filterQuality: FilterQuality.medium,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: _isHovered
              ? [
                
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.7),
                    blurRadius: 12,
                    spreadRadius: 0,
                    blurStyle: BlurStyle.outer,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: Material(
            color: const Color.fromARGB(100, 0, 0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: _isHovered ? Colors.amberAccent : Colors.blueGrey,
                width: _isHovered ? 2 : 1,
              ),
            ),
            child: InkWell(
              onHover: (hovering) => setState(() => _isHovered = hovering),
              onTap: () async {
                await widget.aL.setSelectedWorld(widget.world.id);
                widget.aL.selectedTab = TabSelection.worldInfo;
              },
              child: 

              FutureBuilder<DownstreamWorldVoteInfo?>(
                future: widget.voteApi.getCachedWorldVoteInfo(widget.world.id),
                builder: (context, snapshot) {
                  double ratingNum = 50;
                  String rating = "";
                  if (snapshot.data?.dislikes != null &&
                      snapshot.data?.likes != null) {
                    if (snapshot.data?.dislikes != 0) {
                      ratingNum = (snapshot.data?.likes ?? 0.5) /
                          max(snapshot.data?.dislikes ?? 1, 1) *
                          100;
                      rating = "$ratingNum%";
                    } else {
                      ratingNum = 100;
                      rating = "100%";
                    }
                  }


                  final cardContent = Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: 
                            Image.network(
                              widget.world.thumbnailImageUrl,
                              fit: BoxFit.cover,
                            ),

                          
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              widget.world.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textScaler: const TextScaler.linear(1.2),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),               

                        Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 10,),
                                  Icon(Icons.star),
                                  Text(widget.world.favorites.toString()),
                                  SizedBox(width: 10,),
                                  Icon(Icons.person),
                                  Text(widget.world.occupants.toString()),

                                  if(snapshot.data != null) ... [
                                    SizedBox(width: 10,),
                                    Icon(Icons.thumb_up, color: Colors.amber,),
                                    SizedBox(width: 2,),
                                    Text(snapshot.data!.likes.toString()),
                                    SizedBox(width: 10,),
                                    Icon(Icons.thumb_down, color: Colors.amber),
                                    SizedBox(width: 2,),
                                    Text(snapshot.data!.dislikes.toString()),
                                    
                                  ]

                              ],
                              
                              /*Row(
                                children: [
                                  const Spacer(),
                                  if ((snapshot.data?.aiScore ?? 0) > 0)
                                    const Icon(CupertinoIcons.flag),
                                  Text(
                                    rating,
                                    style: TextStyle(
                                      color: ratingNum > 50
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textScaler: const TextScaler.linear(1.2),
                                    overflow: TextOverflow.fade,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              */
                            
                          
                        ),
                        
                      ],
                    );

                  return ((snapshot.data?.aiScore ?? 0) > 0)
                    ? Ribbon(
                        title: 'AI gen',
                        nearLength: 50,
                        farLength: 90,
                        
                        location: RibbonLocation.topEnd,
                        titleStyle: TextStyle(fontSize: 16),
                        
                        color: Colors.red,
                        child: cardContent,
                      )
                    : cardContent;

                }
              ),
            ),
          ),
        ),
      ),
    );
  }
}