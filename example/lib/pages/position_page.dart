// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file may have been modified by Bytedance Inc.(“Bytedance Inc.'s
// Modifications”). All Bytedance Inc.'s Modifications are Copyright (2022)
// Bytedance Inc..

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scroll_kit/scroll_kit.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Position")),
      body:  OrientationBuilder(
        builder: (context, orientation) =>
            Column(
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
                          ],
                        ),
                      ],
                    )
                )
              ],
            ),
      ),
    );
  }

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
        delegate: SKSliverChildBuilderDelegate(
              (context, index) {
            return Container(
              height: 80,
              color: Colors.grey,
              child: Center(
                child: Text(data[index].index.toString()),
              ),
            );
          },
          childCount: data.length,
          reuseIdentifier: (i)=>""
        ),
      );
    }

    Widget get scrollControlButtons => Row(
      children: <Widget>[
        const SizedBox(child: Text('scroll to'), height: 40,),
        scrollButton(0),
        scrollButton(5),
        scrollButton(10),
        scrollButton(30),
      ],
    );

    Widget get jumpControlButtons => Row(
      children: <Widget>[
        const SizedBox(child: Text('jump to'), height: 40,),
        jumpButton(0),
        jumpButton(5),
        jumpButton(10),
        jumpButton(30),
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
