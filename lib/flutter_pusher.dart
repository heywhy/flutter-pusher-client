import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flutter_pusher.g.dart';

enum PusherConnectionState {
  CONNECTING,
  CONNECTED,
  DISCONNECTING,
  DISCONNECTED,
  RECONNECTING,
  RECONNECTING_WHEN_NETWORK_BECOMES_REACHABLE
}

class Channel {
  final String name;
  final FlutterPusher pusher;

  Channel({this.name, this.pusher});

  /// Bind to listen for events sent on the given channel
  Future bind(String eventName, void Function(Event) onEvent) async {
    await this.pusher._bind(name, eventName, onEvent: onEvent);
  }

  Future unbind(String eventName) async {
    await this.pusher._unbind(name, eventName);
  }

  /// Trigger [eventName] (will be prefixed with "client-" in case you have not) for [Channel].
  ///
  /// Client events can only be triggered on private and presence channels because they require authentication
  /// You can only trigger a client event once a subscription has been successfully registered with Channels.
  Future trigger(String eventName) async {
    if (!eventName.startsWith('client-')) {
      eventName = "client-$eventName";
    }

    await this.pusher._trigger(name, eventName);
  }
}

class FlutterPusher {
  static const MethodChannel _channel =
      const MethodChannel('com.github.heywhy/pusher');
  static const EventChannel _eventChannel =
      const EventChannel('com.github.heywhy/pusherStream');

  static Map<String, void Function(Event)> eventCallbacks =
      Map<String, void Function(Event)>();

  static void Function(ConnectionError) _onError;
  static void Function(ConnectionStateChange) _onConnectionStateChange;

  FlutterPusher(
    String appKey,
    PusherOptions options, {
    bool lazyConnect = false,
    bool enableLogging = false,
    void Function(ConnectionError) onError,
    void Function(ConnectionStateChange) onConnectionStateChange,
  })  : assert(appKey != null),
        assert(options != null) {
    _init(appKey, options, enableLogging: enableLogging);
    if (!lazyConnect) {
      connect(onError: onError, onConnectionStateChange: onConnectionStateChange);
    }
  }

  /// Connect the client to pusher
  Future connect({
    void Function(ConnectionStateChange) onConnectionStateChange,
    void Function(ConnectionError) onError,
  }) async {
    _onConnectionStateChange = onConnectionStateChange;
    _onError = onError;
    await _channel.invokeMethod('connect');
  }


  /// Disconnect the client from pusher
  Future disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  /// Subscribe to a channel
  /// Use the returned [Channel] to bind events
  Future<Channel> subscribe(String channelName) async {
    await _channel.invokeMethod('subscribe', channelName);
    return Channel(name: channelName, pusher: this);
  }

  /// Unsubscribe from a channel
  Future unsubscribe(String channelName) async {
    await _channel.invokeMethod('unsubscribe', channelName);
  }

  void _init(String appKey, PusherOptions options, {bool enableLogging}) async {
    _eventChannel.receiveBroadcastStream().listen(_handleEvent);

    final initArgs = jsonEncode(InitArgs(
      appKey,
      options,
      isLoggingEnabled: enableLogging,
    ).toJson());

    await _channel.invokeMethod('init', initArgs);
  }

  void _handleEvent([dynamic arguments]) {
    var message = PusherEventStreamMessage.fromJson(jsonDecode(arguments));

    if (message.isEvent) {
      var callback =
          eventCallbacks[message.event.channel + message.event.event];
      if (callback != null) {
        callback(message.event);
      }
    } else if (message.isConnectionStateChange) {
      if (_onConnectionStateChange != null) {
        _onConnectionStateChange(message.connectionStateChange);
      }
    } else if (message.isConnectionError) {
      if (_onError != null) {
        _onError(message.connectionError);
      }
    }
  }

  Future _bind(
    String channelName,
    String eventName, {
    void Function(Event) onEvent,
  }) async {
    final bindArgs = jsonEncode(BindArgs(
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    eventCallbacks[channelName + eventName] = onEvent;
    await _channel.invokeMethod('bind', bindArgs);
  }

  Future _unbind(String channelName, String eventName) async {
    final bindArgs = jsonEncode(BindArgs(
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    eventCallbacks.remove(channelName + eventName);
    await _channel.invokeMethod('unbind', bindArgs);
  }

  Future _trigger(String channelName, String eventName) async {
    final bindArgs = jsonEncode(BindArgs(
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    await _channel.invokeMethod('trigger', bindArgs);
  }
}


@JsonSerializable()
class BindArgs {
  final String channelName;
  final String eventName;

  BindArgs({this.channelName, this.eventName});

  factory BindArgs.fromJson(Map<String, dynamic> json) =>
      _$BindArgsFromJson(json);

  Map<String, dynamic> toJson() => _$BindArgsToJson(this);
}


@JsonSerializable()
class InitArgs {
  final String appKey;
  final PusherOptions options;
  final bool isLoggingEnabled;

  InitArgs(this.appKey, this.options, {this.isLoggingEnabled = false});

  factory InitArgs.fromJson(Map<String, dynamic> json) =>
      _$InitArgsFromJson(json);

  Map<String, dynamic> toJson() => _$InitArgsToJson(this);
}

@JsonSerializable(includeIfNull: false)
class PusherOptions {
  final PusherAuth auth;
  final String cluster;
  final String host;
  final int port;
  final bool encrypted;
  final int activityTimeout;

  PusherOptions({
    this.auth,
    this.cluster,
    this.host,
    this.port = 443,
    this.encrypted = true,
    this.activityTimeout = 30000,
  });

  factory PusherOptions.fromJson(Map<String, dynamic> json) =>
      _$PusherOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$PusherOptionsToJson(this);
}

@JsonSerializable()
class PusherAuth {
  final String endpoint;
  final Map<String, String> headers;

  PusherAuth(
    this.endpoint, {
    this.headers = const {'Content-Type': 'application/x-www-form-urlencoded'},
  });

  factory PusherAuth.fromJson(Map<String, dynamic> json) =>
      _$PusherAuthFromJson(json);

  Map<String, dynamic> toJson() => _$PusherAuthToJson(this);
}

@JsonSerializable()
class PusherEventStreamMessage {
  final Event event;
  final ConnectionStateChange connectionStateChange;
  final ConnectionError connectionError;

  bool get isEvent => event != null;

  bool get isConnectionStateChange => connectionStateChange != null;

  bool get isConnectionError => connectionError != null;

  PusherEventStreamMessage(
      {this.event, this.connectionStateChange, this.connectionError});

  factory PusherEventStreamMessage.fromJson(Map<String, dynamic> json) =>
      _$PusherEventStreamMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PusherEventStreamMessageToJson(this);
}

@JsonSerializable()
class Event {
  final String channel;
  final String event;
  final String data;

  Event({this.channel, this.event, this.data});

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}

@JsonSerializable()
class ConnectionStateChange {
  final String currentState;
  final String previousState;

  ConnectionStateChange({this.currentState, this.previousState});

  factory ConnectionStateChange.fromJson(Map<String, dynamic> json) =>
      _$ConnectionStateChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionStateChangeToJson(this);
}

@JsonSerializable()
class ConnectionError {
  final String message;
  final String code;
  final String exception;

  ConnectionError({this.message, this.code, this.exception});

  factory ConnectionError.fromJson(Map<String, dynamic> json) =>
      _$ConnectionErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionErrorToJson(this);
}
