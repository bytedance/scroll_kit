// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file may have been modified by Bytedance Inc.(“Bytedance Inc.'s
// Modifications”). All Bytedance Inc.'s Modifications are Copyright (2022)
// Bytedance Inc..

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:scroll_kit/scroll_kit.dart';

import 'element.dart';
import 'ro.dart';

abstract class SKSliverMultiBoxAdaptorWidget extends SliverWithKeepAliveWidget {
  /// Initializes fields for subclasses.
  const SKSliverMultiBoxAdaptorWidget({
  super.key,
  required this.delegate,
  this.forwardRefreshCount
  }) : assert(delegate != null);

  final int? forwardRefreshCount;

  /// {@template flutter.widgets.SliverMultiBoxAdaptorWidget.delegate}
  /// The delegate that provides the children for this widget.
  ///
  /// The children are constructed lazily using this delegate to avoid creating
  /// more children than are visible through the [Viewport].
  ///
  /// ## Using more than one delegate in a [Viewport]
  ///
  /// If multiple delegates are used in a single scroll view, the first child of
  /// each delegate will always be laid out, even if it extends beyond the
  /// currently viewable area. This is because at least one child is required in
  /// order to estimate the max scroll offset for the whole scroll view, as it
  /// uses the currently built children to estimate the remaining children's
  /// extent.
  ///
  /// See also:
  ///
  ///  * [SliverChildBuilderDelegate] and [SliverChildListDelegate], which are
  ///    commonly used subclasses of [SliverChildDelegate] that use a builder
  ///    callback and an explicit child list, respectively.
  /// {@endtemplate}
  final SKSliverChildBuilderDelegate delegate;

  @override
  SKSliverMultiBoxAdaptorElement createElement() => SKSliverMultiBoxAdaptorElement(this);

  @override
  SKRenderSliverMultiBoxAdaptor createRenderObject(BuildContext context);

  /// Returns an estimate of the max scroll extent for all the children.
  ///
  /// Subclasses should override this function if they have additional
  /// information about their max scroll extent.
  ///
  /// This is used by [SliverMultiBoxAdaptorElement] to implement part of the
  /// [RenderSliverBoxChildManager] API.
  ///
  /// The default implementation defers to [delegate] via its
  /// [SliverChildDelegate.estimateMaxScrollOffset] method.
  double? estimateMaxScrollOffset(
      SliverConstraints? constraints,
      int firstIndex,
      int lastIndex,
      double leadingScrollOffset,
      double trailingScrollOffset,
      ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverChildDelegate>('delegate', delegate));
  }
}

class SKChild extends StatefulWidget {
  const SKChild(this.child, {super.key});
  final Widget child;
  @override
  State<StatefulWidget> createState() {
    return _SKChildState();
  }
}

class _SKChildState extends State<SKChild> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}