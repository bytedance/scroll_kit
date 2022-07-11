import 'package:example/position_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
    "Position": const PositionedListPage(),
  };

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
