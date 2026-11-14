
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcwr/backend/voteApiHandler.dart';
import 'package:vrcwr/backend/vrchatApiHandler.dart';


class RecommendationScreen extends StatefulWidget {
  final VrchatApiHandler vrcApi;
  final VoteApiHandler voteApi;
  const RecommendationScreen(this.vrcApi, this.voteApi, {super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final int pageSize = 60;
  SortOption sortOption = SortOption.hotness;
  String worldTag = 'system_published_recently';
  late final _pagingController = PagingController<int, LimitedWorld>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) async => await widget.vrcApi.getRecommendations(sortOption, (pageKey - 1) * pageSize, tag: worldTag, reqCount: pageSize),
  );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsetsGeometry.all(8), child:  PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) => PagedGridView<int, LimitedWorld>(
        state: state,
        fetchNextPage: fetchNextPage,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300, // Maximum width of each world card in pixels
          mainAxisSpacing: 16,     // Vertical spacing between rows
          crossAxisSpacing: 16,    // Horizontal spacing between columns
          childAspectRatio: 4 / 3, // Width-to-height ratio of each grid item
        ),
        builderDelegate: PagedChildBuilderDelegate(
          itemBuilder: (context, item, index) => worldItem(item, widget.voteApi),
        )
      ),
    ),);
}

Widget worldItem(LimitedWorld world, VoteApiHandler vA){
  return ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.network(
          world.thumbnailImageUrl,
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          
          child: Container(
            color: const Color.fromARGB(156, 0, 0, 0)
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: 
          FutureBuilder<DownstreamWorldVoteInfo?>(
            future: vA.getCachedWorldVoteInfo(world.id),
            builder: (context, snapshot) {
              double ratingNum = 50;
              String rating = "";
              if(snapshot.data?.dislikes != null && snapshot.data?.likes != null){
                if(snapshot.data?.dislikes != null && snapshot.data?.dislikes != 0){
                  ratingNum = (snapshot.data?.likes ?? 0.5) / max(snapshot.data?.dislikes ?? 1, 1) * 100;
                  rating = "$ratingNum%";
                }
                else{
                  ratingNum = 100;
                  rating = "100%";
                }                
              }
              else{
                return Text("");
              }

              
              return SafeArea(
                minimum: const EdgeInsets.all(5),
                child: Row(children: [
                  Spacer(),
                  if ((snapshot.data?.aiScore ?? 0) > 0) ... [
                    Icon(CupertinoIcons.flag),
                  ],
                  Text(
                    rating,
                    style: TextStyle(color: (ratingNum > 50) ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    textScaler: TextScaler.linear(1.2),
                    overflow: TextOverflow.fade,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ],)
                
                
              );
            },
          ),
          
          
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.all(5),
            child: Text(
              world.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textScaler: TextScaler.linear(1.2),
              overflow: TextOverflow.fade,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
               //print('Tapped on ${world.name}');
              },
            ),
          ),
        ),
      ],
    ),
  );
}