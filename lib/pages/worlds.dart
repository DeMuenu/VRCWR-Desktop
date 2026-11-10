
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vrchat_dart/vrchat_dart.dart';
import 'package:vrcworldvoterdesktop/backend/vrchatApiHandler.dart';


class ListViewScreen extends StatefulWidget {
  final VrchatApiHandler vrcApi;
  const ListViewScreen(this.vrcApi, {super.key});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
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
  Widget build(BuildContext context) => PagingListener(
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
        itemBuilder: (context, item, index) => Text(item.name),
      )
    ),
  );
}