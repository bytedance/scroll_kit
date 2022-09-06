// Copyright (2022) Bytedance Inc.

import 'package:scroll_kit/scroll_kit.dart';
import 'package:scroll_kit/src/refresh/indicator/classic_indicator.dart';
import 'package:flutter/material.dart';

class LoadMorePage extends StatefulWidget {
  const LoadMorePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LoadMoreExampleState();
  }
}

class _LoadMoreExampleState extends State<LoadMorePage> {
  bool use = true;

  int fCount = 0;

  List<int> data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
  List<int> data2 = [1, 2, 3, 4, 5, 6, 7, 8];

  final _refreshController = RefreshController(initialRefresh: false);

  LoadMoreController loadMoreController = LoadMoreController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LoadMoreExample")),
      body: _getScrollView(),
      persistentFooterButtons: [
        FloatingActionButton(
          heroTag: null,
          onPressed: () {
            _positionController.jumpTo(5);
          },
          child: const Text("Jump5"),
        ),
        FloatingActionButton(
          heroTag: null,
          onPressed: () {
            _positionController.scrollTo(10);
          },
          child: const Text("scroll10"),
        ),
      ],
    );
  }

  Future<void> _onLoading() async {
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    data.addAll(data2);
    _refreshController.loadComplete();
    loadMoreController.loadMore();
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    _refreshController.refreshCompleted();
    loadMoreController.loadMore();
  }

  final SKPositionController _positionController = SKPositionController();

  Widget _getScrollView() {
    return SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: true,
        footer: const ClassicFooter(),
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        delegate: SKSliverChildBuilderDelegate(
              (c, i) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              color: i.isEven ? Colors.green : Colors.red,
              height: 100,
              width: double.infinity,
              child: Row(
                children: [Text(i.toString()), item, item, item],
              ),
            );
          },
          childCountGetter: ()=>data.length,
          reuseIdentifier: (i)=>""
        ), positionController: _positionController);
  }

  Widget get item => Container(
    width: 30,
    height: 20,
    child: const TextField(),
  );
}
