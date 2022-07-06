import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scroll_kit/src/sliver_list.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// ignore: must_be_immutable
class SKPositionedList extends StatefulWidget {
  SKPositionedList(
      {Key? key,
      required this.delegate,
      this.forwardRefreshCount,
      required this.controller})
      : super(key: key);

  final SKPositionController controller;
  SliverChildBuilderDelegate delegate;
  final int? forwardRefreshCount;

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    final state = _SKPositionedListState();
    controller.delegate = state;
    return state;
  }
}

class _SKPositionedListState extends State<SKPositionedList>
    with SKPositionDelegate {
  int _forwardRefreshCount = 0;

  int? get forwardRefreshCount =>
      _isPositioning ? _forwardRefreshCount : widget.forwardRefreshCount;

  bool _isPositioning = false;

  bool _isInSecondRefresh = false;

  late SliverChildBuilderDelegate previousDelegate;

  /// 使用UniqueKey强制Rebuild.
  Key _k = UniqueKey();

  SliverChildBuilderDelegate blockPrefix(
      int i, SliverChildBuilderDelegate delegate) {
    return SliverChildBuilderDelegate((context, index) {
      return delegate.builder(context, i + index);
    },
        childCount:
            delegate.childCount == null ? null : delegate.childCount! - i);
  }

  // Widget _wrapScrollTag(int index, Widget child) {
  //   return AutoScrollTag(
  //     key: ValueKey(index),
  //     controller: widget.controller.scrollController,
  //     index: index,
  //     highlightColor: Colors.black.withOpacity(0.1),
  //     child: child,
  //   );
  // }
  //
  // bool hasWrapped = false;

  @override
  Widget build(BuildContext context) {
    int? forwardRefreshCount = 0;
    if (_isPositioning) {
      /// 判断是否是两次刷新
      ///
      /// 第一次刷新时只将前面的数据block，所以会呈现出jumpTo的效果，但是实际上此时对于
      /// 列表而言前面的数据是缺失的。
      ///
      /// 第二次刷新再把前面的数据都加载进来，使得可以继续向前滑动。
      if (_isInSecondRefresh) {
        widget.delegate = previousDelegate;
        forwardRefreshCount = _forwardRefreshCount;
      } else {
        previousDelegate = widget.delegate;
        widget.delegate = blockPrefix(_forwardRefreshCount, previousDelegate);
      }
    } else {
      forwardRefreshCount = widget.forwardRefreshCount;
    }

    // TODO
    // assert here is a scrollTag.

    // if (!hasWrapped) {
    //   /// wrap child for auto scroll
    //   var builder = widget.delegate.builder;
    //   widget.delegate.builder = (BuildContext c, int i) {
    //     var w = builder(c, i);
    //     return _wrapScrollTag(i, w);
    //   };
    //   hasWrapped = true;
    // }

    var scrollView = CustomScrollView(
      key: _k,
      controller: widget.controller.scrollController,
      slivers: <Widget>[
        SKSliverList(
          delegate: widget.delegate,
          forwardRefreshCount: forwardRefreshCount,
        )
      ],
    );

    if (_isInSecondRefresh) {
      _isPositioning = false;
      _isInSecondRefresh = false;
    }

    return scrollView;
  }

  @override
  bool get isPositioning => _isPositioning;

  @override
  Future<void> jumpTo(int index) async {
    if (_isPositioning) {
      return;
    }
    _isPositioning = true;
    _isInSecondRefresh = false;
    _k = UniqueKey();
    widget.controller.scrollController.jumpTo(0);
    setState(() {
      _forwardRefreshCount = index;
    });
    final completer = Completer<void>();
    SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        _isInSecondRefresh = true;
        // TODO: completer结束的时机不对.
        completer.complete();
      });
    });
    return completer.future;
  }

  @override
  Future<void> scrollTo(int index) async {
    return widget.controller.scrollController
        .scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
  }
}

mixin SKPositionDelegate {
  bool get isPositioning;
  Future<void> scrollTo(int index);
  Future<void> jumpTo(int index);
}

class SKPositionController {
  SKPositionController(
      {double initialScrollOffset = 0.0,
      bool keepScrollOffset: true,
      double? suggestedRowHeight,
      ViewportBoundaryGetter viewportBoundaryGetter:
          defaultViewportBoundaryGetter,
      Axis? axis,
      String? debugLabel,
      AutoScrollController? copyTagsFrom}) {
    scrollController = SimpleAutoScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        suggestedRowHeight: suggestedRowHeight,
        viewportBoundaryGetter: viewportBoundaryGetter,
        beginGetter: axis == Axis.horizontal ? (r) => r.left : (r) => r.top,
        endGetter: axis == Axis.horizontal ? (r) => r.right : (r) => r.bottom,
        copyTagsFrom: copyTagsFrom,
        debugLabel: debugLabel);
  }

  bool get attached => _delegate != null;

  late SKPositionDelegate _delegate;

  set delegate(SKPositionDelegate delegate) => _delegate = delegate;

  late AutoScrollController scrollController;

  /// when [isPositioning] is false, a layout may be coming.
  bool get isPositioning {
    return _delegate.isPositioning;
  }

  Future<void> scrollTo(int index) async {
    return _delegate.scrollTo(index);
  }

  Future<void> jumpTo(int index) async {
    return _delegate.jumpTo(index);
  }
}
