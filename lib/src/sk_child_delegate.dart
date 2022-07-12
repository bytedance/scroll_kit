import 'package:flutter/cupertino.dart';

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

abstract class SKLifeCycleManager {

  /// child is visible in the screen.
  void onAppear(int index);

  /// For example, exposedRatio = 0.3 and validExposedTime = 100(ms)
  /// 'onAppear' will be called when the percentage of A exposed to the screen
  /// exceeds 30% and the time exceeds 100 milliseconds.
  /// And these two values only relate to [SKLifeCycleManager.onAppear].
  double get exposedRatio;
  int get validExposedTime;

  /// child will be invisible in the screen.
  void onDisAppear(int index);

  /// child has been destroyed, we can destroy the resource used like image safely.
  void onRemove(int index);
}

class SliverChildBuilderDelegate extends SliverChildDelegate implements SKLifeCycleManager {
  /// Creates a delegate that supplies children for slivers using the given
  /// builder callback.
  ///
  /// The [builder], [addAutomaticKeepAlives], [addRepaintBoundaries],
  /// [addSemanticIndexes], and [semanticIndexCallback] arguments must not be
  /// null.
  ///
  /// If the order in which [builder] returns children ever changes, consider
  /// providing a [findChildIndexCallback]. This allows the delegate to find the
  /// new index for a child that was previously located at a different index to
  /// attach the existing state to the [Widget] at its new location.
  const SliverChildBuilderDelegate(
      this.builder, {
        this.findChildIndexCallback,
        this.childCount,
        this.addAutomaticKeepAlives = true,
        this.addRepaintBoundaries = true,
        this.addSemanticIndexes = true,
        // ADD
        void Function(int index)? onAppear,
        void Function(int index)? onDisAppear,
        void Function(int index)? onRemove,
        String Function(int index)? reuseIdentifier,
        double? exposedRatio,
        int? validExposedTime,
        // END
        this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
        this.semanticIndexOffset = 0,
      }) :
  _onAppear = onAppear,
  _onDisappear = onDisAppear,
  _onRemove = onRemove,
  _reuseIdentifier = reuseIdentifier,
  _exposedRatio = exposedRatio ?? 0.0,
  _validExposedTime = validExposedTime ?? 0;

  // ADD

  /// life cycle.

  final double _exposedRatio;

  final int _validExposedTime;

  final void Function(int index)? _onAppear;

  final void Function(int index)? _onDisappear;

  final void Function(int index)? _onRemove;

  final String Function(int index)? _reuseIdentifier;

  @override
  double get exposedRatio => _exposedRatio;

  @override
  int get validExposedTime => _validExposedTime;

  @override
  void onAppear(int index) {
    if(_onAppear == null) return;
    _onAppear!(index);
  }

  @override
  void onDisAppear(int index) {
    if(_onDisappear == null) return;
    _onDisappear!(index);
  }

  @override
  void onRemove(int index) {
    if(_onRemove == null) return;
    _onRemove!(index);
  }

  // END

  /// Called to build children for the sliver.
  ///
  /// Will be called only for indices greater than or equal to zero and less
  /// than [childCount] (if [childCount] is non-null).
  ///
  /// Should return null if asked to build a widget with a greater index than
  /// exists.
  ///
  /// The delegate wraps the children returned by this builder in
  /// [RepaintBoundary] widgets.
  final NullableIndexedWidgetBuilder builder;

  /// The total number of children this delegate can provide.
  ///
  /// If null, the number of children is determined by the least index for which
  /// [builder] returns null.
  final int? childCount;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// Typically, children in lazy list are wrapped in [AutomaticKeepAlive]
  /// widgets so that children can use [KeepAliveNotification]s to preserve
  /// their state when they would otherwise be garbage collected off-screen.
  ///
  /// This feature (and [addRepaintBoundaries]) must be disabled if the children
  /// are going to manually maintain their [KeepAlive] state. It may also be
  /// more efficient to disable this feature if it is known ahead of time that
  /// none of the children will ever try to keep themselves alive.
  ///
  /// Defaults to true.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// Typically, children in a scrolling container are wrapped in repaint
  /// boundaries so that they do not need to be repainted as the list scrolls.
  /// If the children are easy to repaint (e.g., solid color blocks or a short
  /// snippet of text), it might be more efficient to not add a repaint boundary
  /// and simply repaint the children during scrolling.
  ///
  /// Defaults to true.
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics].
  ///
  /// Typically, children in a scrolling container must be annotated with a
  /// semantic index in order to generate the correct accessibility
  /// announcements. This should only be set to false if the indexes have
  /// already been provided by an [IndexedSemantics] widget.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///  * [IndexedSemantics], for an explanation of how to manually
  ///    provide semantic indexes.
  final bool addSemanticIndexes;

  /// An initial offset to add to the semantic indexes generated by this widget.
  ///
  /// Defaults to zero.
  final int semanticIndexOffset;

  /// A [SemanticIndexCallback] which is used when [addSemanticIndexes] is true.
  ///
  /// Defaults to providing an index for each widget.
  final SemanticIndexCallback semanticIndexCallback;

  /// {@template flutter.widgets.SliverChildBuilderDelegate.findChildIndexCallback}
  /// Called to find the new index of a child based on its key in case of reordering.
  ///
  /// If not provided, a child widget may not map to its existing [RenderObject]
  /// when the order of children returned from the children builder changes.
  /// This may result in state-loss.
  ///
  /// This callback should take an input [Key], and it should return the
  /// index of the child element with that associated key, or null if not found.
  /// {@endtemplate}
  final ChildIndexGetter? findChildIndexCallback;

  @override
  int? findIndexByKey(Key key) {
    if (findChildIndexCallback == null) {
      return null;
    }
    final Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return findChildIndexCallback!(childKey);
  }

  @override
  @pragma('vm:notify-debugger-on-exception')
  Widget? build(BuildContext context, int index) {
    if (index < 0 || (childCount != null && index >= childCount!)) {
      return null;
    }
    Widget? child;
    try {
      child = builder(context, index);
    } catch (exception, stackTrace) {
      child = _createErrorWidget(exception, stackTrace);
    }
    if (child == null) {
      return null;
    }
    final Key? key = child.key != null ? _SaltedValueKey(child.key!) : null;
    if (addRepaintBoundaries)
      child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int? semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives)
      child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(key: key, child: child);
  }

  @override
  int? get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant SliverChildBuilderDelegate oldDelegate) => true;
}

// Return a Widget for the given Exception
Widget _createErrorWidget(Object exception, StackTrace stackTrace) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stackTrace,
    library: 'widgets library',
    context: ErrorDescription('building'),
  );
  FlutterError.reportError(details);
  return ErrorWidget.builder(details);
}

class _SaltedValueKey extends ValueKey<Key> {
  const _SaltedValueKey(super.key);
}