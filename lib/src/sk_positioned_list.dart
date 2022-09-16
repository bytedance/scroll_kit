// Copyright (2022) Bytedance Inc.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scroll_kit/src/sk_sliver_list.dart';
import 'utils/auto_scroll.dart';
import 'sk_child_delegate.dart';

// ignore: must_be_immutable
class SKPositionedList extends StatefulWidget {
  SKPositionedList(
      {Key? key,
      required this.delegate,
      this.forwardRefreshCount,
      required this.controller})
      : super(key: key);

  final SKPositionController controller;
  SKSliverChildBuilderDelegate delegate;
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

  late SKSliverChildBuilderDelegate previousDelegate;

  Key _k = UniqueKey();

  SKSliverChildBuilderDelegate blockPrefix(
      int i, SKSliverChildBuilderDelegate delegate) {
    return SKSliverChildBuilderDelegate((context, index) {
      return delegate.builder(context, i + index);
    }, childCount: delegate.childCount! - i);
  }

  Widget _wrapScrollTag(int index, Widget child) {
    return AutoScrollTag(
      key: ValueKey(index),
      controller: widget.controller.scrollController,
      index: index,
      highlightColor: Colors.black.withOpacity(0.1),
      child: child,
    );
  }

  bool hasWrapped = false;

  @override
  Widget build(BuildContext context) {
    int? forwardRefreshCount = 0;

    /// To ForwardRefresh we need to do setState two times.
    if (_isPositioning) {
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

    if (!hasWrapped) {
      /// wrap child for auto scroll
      var builder = widget.delegate.builder;
      widget.delegate.builder = (BuildContext c, int i) {
        var w = builder(c, i);
        return _wrapScrollTag(i, w!);
      };
      hasWrapped = true;
    }

    var scrollView = CustomScrollView(
      key: _k,
      controller: widget.controller.scrollController,
      slivers: <Widget>[
        SKSliverList(
          delegate: widget.delegate,
          forwardRefreshCount: forwardRefreshCount,
          scrollController: widget.controller.scrollController,
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
