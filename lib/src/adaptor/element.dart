// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file may have been modified by Bytedance Inc.(“Bytedance Inc.'s
// Modifications”). All Bytedance Inc.'s Modifications are Copyright (2022)
// Bytedance Inc..

import 'dart:collection';
import 'package:scroll_kit/scroll_kit.dart';

import 'widget.dart';
import 'ro.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class SKSliverMultiBoxAdaptorElement extends RenderObjectElement implements RenderSliverBoxChildManager {
  /// Creates an element that lazily builds children for the given widget.
  ///
  /// If `replaceMovedChildren` is set to true, a new child is proactively
  /// inflate for the index that was previously occupied by a child that moved
  /// to a new index. The layout offset of the moved child is copied over to the
  /// new child. RenderObjects, that depend on the layout offset of existing
  /// children during [RenderObject.performLayout] should set this to true
  /// (example: [RenderSliverList]). For RenderObjects that figure out the
  /// layout offset of their children without looking at the layout offset of
  /// existing children this should be set to false (example:
  /// [RenderSliverFixedExtentList]) to avoid inflating unnecessary children.
  SKSliverMultiBoxAdaptorElement(SKSliverMultiBoxAdaptorWidget super.widget, {bool replaceMovedChildren = false})
      : _replaceMovedChildren = replaceMovedChildren;

  final bool _replaceMovedChildren;

  @override
  SKRenderSliverMultiBoxAdaptor get renderObject => super.renderObject as SKRenderSliverMultiBoxAdaptor;

  @override
  void update(covariant SKSliverMultiBoxAdaptorWidget newWidget) {
    final SKSliverMultiBoxAdaptorWidget oldWidget = widget as SKSliverMultiBoxAdaptorWidget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate))) {
      performRebuild();
    }
  }

  final SplayTreeMap<int, Element?> _childElements = SplayTreeMap<int, Element?>();
  RenderBox? _currentBeforeChild;

  @override
  void performRebuild() {
    super.performRebuild();
    _currentBeforeChild = null;
    bool childrenUpdated = false;
    assert(_currentlyUpdatingChildIndex == null);
    try {
      final SplayTreeMap<int, Element?> newChildren = SplayTreeMap<int, Element?>();
      final Map<int, double> indexToLayoutOffset = HashMap<int, double>();
      final SKSliverMultiBoxAdaptorWidget adaptorWidget = widget as SKSliverMultiBoxAdaptorWidget;
      final forwardRefreshCount = adaptorWidget.forwardRefreshCount;
      void processElement(int index) {
        _currentlyUpdatingChildIndex = index;
        if (_childElements[index] != null && _childElements[index] != newChildren[index]) {
          // This index has an old child that isn't used anywhere and should be deactivated.
          _childElements[index] = updateChild(_childElements[index], null, index);
          childrenUpdated = true;
        }
        final Element? newChild = updateChild(newChildren[index], _build(index, adaptorWidget), index);
        if (newChild != null) {
          childrenUpdated = childrenUpdated || _childElements[index] != newChild;
          _childElements[index] = newChild;
          final SKSliverMultiBoxAdaptorParentData parentData = newChild.renderObject!.parentData! as SKSliverMultiBoxAdaptorParentData;
          // MOD
          if (index == (forwardRefreshCount ?? 0)) {
            parentData.layoutOffset = 0.0;
          // END
          } else if (indexToLayoutOffset.containsKey(index)) {
            parentData.layoutOffset = indexToLayoutOffset[index];
          }
          if (!parentData.keptAlive) {
            _currentBeforeChild = newChild.renderObject as RenderBox?;
          }
        } else {
          childrenUpdated = true;
          _childElements.remove(index);
        }
      }

      // ADD
      assert(!(forwardRefreshCount != null && forwardRefreshCount != 0 && !_childElements.keys.contains(0)),
      "ScrollKit: forwardRefresh failed when child(0) is not created");

      final i = List<int>.from(
          _childElements.keys.where((e) => e < (forwardRefreshCount ?? 0)));
      if (i.length == _childElements.keys.length) {
        for (var i = 0; i < _childElements.keys.length; i++) {
          _childElements[i + forwardRefreshCount!] = _childElements[i]!;
          _childElements.remove(i);
        }
      } else {
        for (var index in i) {
          _currentlyUpdatingChildIndex = index;
          _childElements[index] =
              updateChild(_childElements[index]!, null, index);
          _childElements.remove(index);
        }
      }
      // END

      for (final int index in _childElements.keys.toList()) {
        final Key? key = _childElements[index]!.widget.key;
        final int? newIndex = key == null ? null : adaptorWidget.delegate.findIndexByKey(key);
        final SKSliverMultiBoxAdaptorParentData? childParentData =
        _childElements[index]!.renderObject?.parentData as SKSliverMultiBoxAdaptorParentData?;

        if (childParentData != null && childParentData.layoutOffset != null) {
          indexToLayoutOffset[index] = childParentData.layoutOffset!;
        }

        if (newIndex != null && newIndex != index) {
          // The layout offset of the child being moved is no longer accurate.
          if (childParentData != null) {
            childParentData.layoutOffset = null;
          }

          newChildren[newIndex] = _childElements[index];
          if (_replaceMovedChildren) {
            // We need to make sure the original index gets processed.
            newChildren.putIfAbsent(index, () => null);
          }
          // We do not want the remapped child to get deactivated during processElement.
          _childElements.remove(index);
        } else {
          newChildren.putIfAbsent(index, () => _childElements[index]);
        }
      }

      renderObject.debugChildIntegrityEnabled = false; // Moving children will temporary violate the integrity.

      // MOD
      newChildren.keys.where((e) => e >= (forwardRefreshCount ?? 0))
          .toList()
          .forEach((e) {
        processElement(e);
      });
      // END

      // An element rebuild only updates existing children. The underflow check
      // is here to make sure we look ahead one more child if we were at the end
      // of the child list before the update. By doing so, we can update the max
      // scroll offset during the layout phase. Otherwise, the layout phase may
      // be skipped, and the scroll view may be stuck at the previous max
      // scroll offset.
      //
      // This logic is not needed if any existing children has been updated,
      // because we will not skip the layout phase if that happens.
      if (!childrenUpdated && _didUnderflow) {
        final int lastKey = _childElements.lastKey() ?? -1;
        final int rightBoundary = lastKey + 1;
        newChildren[rightBoundary] = _childElements[rightBoundary];
        processElement(rightBoundary);
      }

    } finally {
      _currentlyUpdatingChildIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  Widget? _build(int index, SKSliverMultiBoxAdaptorWidget widget) {
    return widget.delegate.build(this, index);
  }

  // ADD

  final Map<String, List<Element>> _reuseBucket = <String, List<Element>>{};

  Element? childOfReuseBucket(String? type) {
    if (type == null || _reuseBucket[type] == null ||
        _reuseBucket[type]!.isEmpty) {
      return null;
    }
    return _reuseBucket[type]!.removeAt(0);
  }

  bool reusableChildAvailable(String? type) {
    if (_reuseBucket[type] != null && _reuseBucket[type]!.isNotEmpty) {
      if(_reuseBucket[type]![0].renderObject != null) {
        return true;
      }else{
        _reuseBucket[type]!.removeAt(0);
        return false;
      }
    }else{
      return false;
    }
  }

  bool isReuseBucketOverflow(String? type) {
    if (_reuseBucket[type] != null && _reuseBucket.length >= 5) {
      return true;
    }
    return false;
  }

  void throwIntoReuseBucket(Element element, String type) {
    if (!_reuseBucket.containsKey(type)) {
      _reuseBucket[type] = [element];
    } else {
      _reuseBucket[type]!.insert(0, element);
    }
  }

  void deactiveReuseBucket() {
    for (final values in _reuseBucket.values) {
      for (var child in values) {
        if(child.renderObject == null) {
          continue;
        }
        _currentlyUpdatingChildIndex = child.slot as int;
        child.renderObject!.detach();
        (child.renderObject!.parentData as SKSliverMultiBoxAdaptorParentData)
            .isInReusePool = true;
        deactivateChild(child);
        _currentlyUpdatingChildIndex = null;
      }
    }
  }

  @override
  void deactivate() {
    deactiveReuseBucket();
    super.deactivate();
  }

  String? typeOf(int index) {
    if (((widget as SKSliverMultiBoxAdaptorWidget).delegate).reuseIdentifier != null) {
      return ((widget as SKSliverMultiBoxAdaptorWidget).delegate).reuseIdentifier!(index);
    }
    return null;
  }

  // END

  @override
  void createChild(int index, { required RenderBox? after }) {
    assert(_currentlyUpdatingChildIndex == null);
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index-1] != null);
      _currentBeforeChild = insertFirst ? null : (_childElements[index-1]!.renderObject as RenderBox?);
      Element? newChild;
      try {
        final SKSliverMultiBoxAdaptorWidget adaptorWidget = widget as SKSliverMultiBoxAdaptorWidget;
        _currentlyUpdatingChildIndex = index;
        final newWidget = _build(index, adaptorWidget);
        if (newWidget != null &&
            typeOf(index) != null &&
            reusableChildAvailable(typeOf(index))) {
          final oldChild = childOfReuseBucket(typeOf(index))!;
          assert(oldChild.widget.runtimeType == newWidget.runtimeType);
          final oldRenderObject = oldChild.renderObject as RenderBox;
          renderObject.dropChild(oldRenderObject);
          renderObject.insert(oldRenderObject, after: after);
          oldChild.update(newWidget);
          newChild = oldChild;
        } else {
          newChild = updateChild(_childElements[index], newWidget, index);
        }
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) {
    final SKSliverMultiBoxAdaptorParentData? oldParentData = child?.renderObject?.parentData as SKSliverMultiBoxAdaptorParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final SKSliverMultiBoxAdaptorParentData? newParentData = newChild?.renderObject?.parentData as SKSliverMultiBoxAdaptorParentData?;

    // Preserve the old layoutOffset if the renderObject was swapped out.
    if (oldParentData != newParentData && oldParentData != null && newParentData != null) {
      newParentData.layoutOffset = oldParentData.layoutOffset;
    }
    return newChild;
  }

  @override
  void forgetChild(Element child) {
    assert(child != null);
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void removeChild(RenderBox child) {
    final index = renderObject.indexOf(child);
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final type = typeOf(index);
        if (type == null || isReuseBucketOverflow(type)) {
          final result = updateChild(_childElements[index], null, index);
          assert(result == null);
        } else {
          final box = _childElements[index]!.renderObject as RenderBox;
          renderObject.remove(box);
          renderObject.adoptChild(box);
          throwIntoReuseBucket(_childElements[index]!, type);
        }
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  static double _extrapolateMaxScrollOffset(
      int firstIndex,
      int lastIndex,
      double leadingScrollOffset,
      double trailingScrollOffset,
      int childCount,
      ) {
    if (lastIndex == childCount - 1)
      return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent = (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(
      SliverConstraints? constraints, {
        int? firstIndex,
        int? lastIndex,
        double? leadingScrollOffset,
        double? trailingScrollOffset,
      }) {
    final int? childCount = estimatedChildCount;
    if (childCount == null)
      return double.infinity;
    return (widget as SKSliverMultiBoxAdaptorWidget).estimateMaxScrollOffset(
      constraints,
      firstIndex!,
      lastIndex!,
      leadingScrollOffset!,
      trailingScrollOffset!,
    ) ?? _extrapolateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
      childCount,
    );
  }

  /// The best available estimate of [childCount], or null if no estimate is available.
  ///
  /// This differs from [childCount] in that [childCount] never returns null (and must
  /// not be accessed if the child count is not yet available, meaning the [createChild]
  /// method has not been provided an index that does not create a child).
  ///
  /// See also:
  ///
  ///  * [SliverChildDelegate.estimatedChildCount], to which this getter defers.
  int? get estimatedChildCount => (widget as SKSliverMultiBoxAdaptorWidget).delegate.estimatedChildCount;

  @override
  int get childCount {
    int? result = estimatedChildCount;
    if (result == null) {
      // Since childCount was called, we know that we reached the end of
      // the list (as in, _build return null once), so we know that the
      // list is finite.
      // Let's do an open-ended binary search to find the end of the list
      // manually.
      int lo = 0;
      int hi = 1;
      final SKSliverMultiBoxAdaptorWidget adaptorWidget = widget as SKSliverMultiBoxAdaptorWidget;
      const int max = kIsWeb
          ? 9007199254740992 // max safe integer on JS (from 0 to this number x != x+1)
          : ((1 << 63) - 1);
      while (_build(hi - 1, adaptorWidget) != null) {
        lo = hi - 1;
        if (hi < max ~/ 2) {
          hi *= 2;
        } else if (hi < max) {
          hi = max;
        } else {
          throw FlutterError(
            'Could not find the number of children in ${adaptorWidget.delegate}.\n'
                "The childCount getter was called (implying that the delegate's builder returned null "
                'for a positive index), but even building the child with index $hi (the maximum '
                'possible integer) did not return null. Consider implementing childCount to avoid '
                'the cost of searching for the final child.',
          );
        }
      }
      while (hi - lo > 1) {
        final int mid = (hi - lo) ~/ 2 + lo;
        if (_build(mid - 1, adaptorWidget) == null) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      result = lo;
    }
    return result;
  }

  @override
  void didStartLayout() {
    assert(debugAssertChildListLocked());
  }

  @override
  void didFinishLayout() {
    assert(debugAssertChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    (widget as SKSliverMultiBoxAdaptorWidget).delegate.didFinishLayout(firstIndex, lastIndex);
  }

  int? _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SKSliverMultiBoxAdaptorParentData childParentData = child.parentData! as SKSliverMultiBoxAdaptorParentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  bool _didUnderflow = false;

  @override
  void setDidUnderflow(bool value) {
    _didUnderflow = value;
  }

  @override
  void insertRenderObjectChild(covariant RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox, after: _currentBeforeChild);
    assert(() {
      final SKSliverMultiBoxAdaptorParentData childParentData = child.parentData! as SKSliverMultiBoxAdaptorParentData;
      assert(slot == childParentData.index);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(covariant RenderObject child, int oldSlot, int newSlot) {
    assert(newSlot != null);
    assert(_currentlyUpdatingChildIndex == newSlot);
    renderObject.move(child as RenderBox, after: _currentBeforeChild);
  }

  @override
  void removeRenderObjectChild(covariant RenderObject child, int slot) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // The toList() is to make a copy so that the underlying list can be modified by
    // the visitor:
    assert(!_childElements.values.any((Element? child) => child == null));
    _childElements.values.cast<Element>().toList().forEach(visitor);
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    _childElements.values.cast<Element>().where((Element child) {
      final SKSliverMultiBoxAdaptorParentData parentData = child.renderObject!.parentData! as SKSliverMultiBoxAdaptorParentData;
      final double itemExtent;
      switch (renderObject.constraints.axis) {
        case Axis.horizontal:
          itemExtent = child.renderObject!.paintBounds.width;
          break;
        case Axis.vertical:
          itemExtent = child.renderObject!.paintBounds.height;
          break;
      }

      return parentData.layoutOffset != null &&
          parentData.layoutOffset! < renderObject.constraints.scrollOffset + renderObject.constraints.remainingPaintExtent &&
          parentData.layoutOffset! + itemExtent > renderObject.constraints.scrollOffset;
    }).forEach(visitor);
  }
}