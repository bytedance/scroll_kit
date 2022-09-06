scroll_kit
---

ScrollKit provides additional features for list in Flutter Apps.

## Features

- [✓] JumpTo(int index).
- [✓] ScrollTo(int index).
- [✓] Load list content from both leading and trailing direction.
- [✓] Reuse the Element and RenderObject of list item.
- [✓] Provide life-cycle callbacks of list item.
- [✓] Load more list items without refreshing the whole list.
- [✓] Provides JumpTo, ScrollTo with compatibility of refresh components(SmartRefresher).

## Getting started

```yaml
scroll_kit: ^1.0.0
```

## Usage

```dart
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
          print("Appear: " + i.toString());
        }, onDisAppear: (i) {
          print("Disappear: " + i.toString());
        }, reuseIdentifier: (i) {
          if (i % 2 == 0) {
            return "type1";
          } else {
            return "type2";
          }
        }, childCount: 100))
  ],
);
```

## Reference
- [scroll_to_index](https://pub.dev/packages/scroll_to_index)
- [pull_to_refresh](https://pub.dev/packages/pull_to_refresh)

## Contributing
- This project is licensed under the MIT License.
- Welcome to [Join the ByteDance Flutter Exchange Group](https://applink.feishu.cn/client/chat/chatter/add_by_link?link_token=b07u55bb-68f0-4a4b-871d-687637766a68).
- Any questions or suggestions, please feel free to contact me at dongjiajian@bytedance.com.