# Pusher Flutter Client

[![pub package](https://img.shields.io/pub/v/flutter_pusher_client.svg)](https://pub.dartlang.org/packages/flutter_pusher_client)

An unofficial Flutter plugin that wraps [pusher-websocket-java](https://github.com/pusher/pusher-websocket-java) on Android and [pusher-websocket-swift](https://github.com/pusher/pusher-websocket-swift) on iOS.

This package lets you consume events from a Pusher server. In order to use this library, you need to have a free account on <http://pusher.com>. After registering, you will need the application credentials for your app.


*Note*: This plugin is still under development, and some APIs might not be available yet. [Feedback](https://github.com/heywhy/flutter-pusher-client/issues) and [Pull Requests](https://github.com/heywhy/flutter-pusher-client/pulls) are most welcome!

# How to install
* Add to your pubspec.yaml
```
dependencies:
  flutter_pusher_client: ^0.1.0
```
<!-- * In `/ios/Podfile`, set global platform to at least 9.0
`platform :ios, '9.0'`

### For iOS Objective-C based Flutter apps
It is currently a bit difficult to get some Swift based Flutter plugins working in an Objective-C based Flutter app. See [here for info](https://github.com/flutter/flutter/issues/25676) and [here for a way to fix](https://github.com/fayeed/flutter_freshchat/issues/9#issuecomment-514329934).

This set of steps should work to fix this for your project.
* Add `use_frameworks!` to the end of the Runner section in `/ios/Podfile`
* Set Swift version in your iOS Runner project.
    * Open the project with Xcode.
    * In Runner, File -> New -> File -> Swift File. Name it anything.
    * Xcode will ask you if you wish to create Bridging Header, click yes.
    * Go to Runner `Build Settings` and set `SWIFT_VERSION` to either 4.2 or 5.0
    * Delete the Swift file created in step 2
    * Delete the Bridging Header created in step 3
* `flutter clean`
* In /ios `pod install --repo-update` -->

## Getting Started

```dart
import 'package:flutter_pusher_client/flutter_pusher.dart';

void main() {

  var options = PusherOptions(host: '10.0.2.2', port: 6001, encrypted: false);
  FlutterPusher pusher = FlutterPusher('app', options, enableLogging: true);

  pusher.subscribe('channel').bind('event', (event) => {});
}
```

### Lazy Connect

Connection to the server can be delayed, so set the **lazyConnect** prop on the client constructor.

## Development
Generate the models and the factories: `flutter packages pub run build_runner build --delete-conflicting-outputs`
