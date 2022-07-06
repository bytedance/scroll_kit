// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scroll_kit/scroll_kit.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

const numberOfItems = 5001;
const minItemHeight = 20.0;
const maxItemHeight = 150.0;
const scrollDuration = Duration(seconds: 2);

const randomMax = 1 << 32;

class PositionedListPage extends StatefulWidget {
  const PositionedListPage({Key? key}) : super(key: key);

  @override
  _ScrollablePositionedListPageState createState() =>
      _ScrollablePositionedListPageState();
}

class _ScrollablePositionedListPageState
    extends State<PositionedListPage> {
  /// Controller to scroll or jump to a particular item.
  // final ItemScrollController itemScrollController = ItemScrollController();

  /// Listener that reports the position of items when the list is scrolled.
  // final ItemPositionsListener itemPositionsListener =
  // ItemPositionsListener.create();
  late List<double> itemHeights;
  late List<Color> itemColors;
  bool reversed = false;

  /// The alignment to be used next time the user scrolls or jumps to an item.
  double alignment = 0;

  @override
  void initState() {
    super.initState();
    final heightGenerator = Random(328902348);
    final colorGenerator = Random(42490823);
    itemHeights = List<double>.generate(
        numberOfItems,
            (int _) =>
        heightGenerator.nextDouble() * (maxItemHeight - minItemHeight) +
            minItemHeight);
    itemColors = List<Color>.generate(numberOfItems,
            (int _) => Color(colorGenerator.nextInt(randomMax)).withOpacity(1));
  }

  @override
  Widget build(BuildContext context) => Material(
    child: OrientationBuilder(
      builder: (context, orientation) => Column(
        children: <Widget>[
          Expanded(
            child: list1(),
            // child: list(orientation),
          ),
          Container(
              height: 100,
              child: Row(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      scrollControlButtons,
                      jumpControlButtons,
                      // alignmentControl,
                    ],
                  ),
                ],
              )
          )
        ],
      ),
    ),
  );

  Widget get alignmentControl => Row(
    mainAxisSize: MainAxisSize.max,
    children: <Widget>[
      const Text('Alignment: '),
      SizedBox(
        width: 100,
        child: SliderTheme(
          data: SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: Slider(
            value: alignment,
            label: alignment.toStringAsFixed(2),
            onChanged: (double value) => setState(() => alignment = value),
          ),
        ),
      ),
    ],
  );

  late SKPositionController controller;

  // = SKPositionController();
  //
  // AutoScrollController autoScrollController = AutoScrollController();

  List<TempData> data = () {
    List<TempData> data = [];
    for (var i = -40; i < -10; i++) {
      data.add(TempData()..index = i);
    }
    for (var i = -10; i < 0; i++) {
      data.add(TempData()..index = i);
    }
    for (var i = 0; i < 10; i++) {
      data.add(TempData()..index = i);
    }
    return data;
  }();

  Widget list1() {
    controller = SKPositionController(
        viewportBoundaryGetter: () =>
            Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
        axis: Axis.vertical
    );

    return SKPositionedList(
      controller: controller,
      delegate: SliverChildBuilderDelegate(
              (context, index) {
            // if(useMore) assert(index != 0);
            final c = Container(
              height: 80,
              color: Colors.grey,
              child: Center(
                child: Text(data[index].index.toString()),
              ),
            );

            return  AutoScrollTag(
              key: ValueKey(index),
              controller: controller.scrollController,
              index: index,
              highlightColor: Colors.black.withOpacity(0.1),
              child: c,
            );
          },
          childCount: data.length,
      ),
    );
  }

  Widget get scrollControlButtons => Row(
    children: <Widget>[
      const Text('scroll to'),
      scrollButton(0),
      scrollButton(5),
      scrollButton(10),
      scrollButton(100),
      scrollButton(1000),
    ],
  );

  Widget get jumpControlButtons => Row(
    children: <Widget>[
      const Text('jump to'),
      jumpButton(0),
      jumpButton(5),
      jumpButton(10),
      jumpButton(100),
      jumpButton(1000),
    ],
  );

  final _scrollButtonStyle = ButtonStyle(
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    ),
    minimumSize: MaterialStateProperty.all(Size.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget scrollButton(int value) => TextButton(
    key: ValueKey<String>('Scroll$value'),
    onPressed: () => scrollTo(value),
    child: Text('$value'),
    style: _scrollButtonStyle,
  );

  Widget jumpButton(int value) => TextButton(
    key: ValueKey<String>('Jump$value'),
    onPressed: () async {
      await jumpTo(value);
    },
    child: Text('$value'),
    style: _scrollButtonStyle,
  );

  Future<void> scrollTo(int index) {
    return controller.scrollTo(index);
  }

  Future<void> jumpTo(int index) {
    return controller.jumpTo(index);
  }

  /// Generate item number [i].
  Widget item(int i, Orientation orientation) {
    print('DONG:: create widget($i)');
    return SizedBox(
      height: orientation == Orientation.portrait ? itemHeights[i] : null,
      width: orientation == Orientation.landscape ? itemHeights[i] : null,
      child: Container(
        color: itemColors[i],
        child: Center(
          child: Text('Item $i'),
        ),
      ),
    );
  }
}

class TempData {
  int? index;
}
