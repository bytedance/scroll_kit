// Copyright (2022) Bytedance Inc.

import 'package:flutter/material.dart';
import 'package:scroll_kit/scroll_kit.dart';

class LifeCyclePage extends StatefulWidget {
  const LifeCyclePage({super.key});
  @override
  State<StatefulWidget> createState() {
    return LifeCyclePageState();
  }
}

class LifeCyclePageState extends State<LifeCyclePage> {
  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      slivers: [
        SKSliverList(
            delegate: SKSliverChildBuilderDelegate((c, i) {
          if (i % 2 == 0) {
            return Container(
              height: 100,
              child: Text(i.toString()),
              color: Colors.grey,
              margin: EdgeInsets.only(top: 3),
            );
          } else {
            return Container(
              height: 100,
              child: Text(i.toString()),
              color: Colors.red,
              margin: EdgeInsets.only(top: 3),
            );
          }
        }, onAppear: (i) {
          print("Appear: $i");
        }, onDisAppear: (i) {
          print("Disappear: $i");
        }, reuseIdentifier: (i) {
          if (i % 2 == 0) {
            return "type1";
          } else {
            return "type2";
          }
        }, childCount: 100))
      ],
    );
    return Scaffold(appBar: AppBar(title: Text("LifeCycle")), body: scrollView);
  }
}
