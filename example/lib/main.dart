// Copyright (2022) Bytedance Inc.

import 'package:example/pages/life_cycle_page.dart';
import 'package:example/pages/loadMore_page.dart';
import 'package:example/pages/jump_page.dart';
import 'package:example/pages/scroll_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scroll_kit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {

  final Map<String, Widget> m = {
    "JumpTo": const JumpToPage(),
    "loadMore": const LoadMorePage(),
    "ScrollTo": const ScrollToPage(),
    "LifeCycle": const LifeCyclePage()
  };

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScrollKit Example'),
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            height: 50,
            color: Colors.grey,
            child: GestureDetector(
              child: Text(
                m.keys.toList()[index],
                textScaleFactor: 2,
                textAlign: TextAlign.center,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute<void>(builder: (BuildContext context) {
                      if (index < m.keys.length) {
                        return m[m.keys.toList()[index]]!;
                      }
                      return Container();
                    }));
              },
            ),
          );
        },
        itemCount: m.keys.length,
      ),
    );
  }
}
