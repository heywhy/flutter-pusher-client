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
  MethodChannel _channel;

  Channel({this.name, this.pusher, MethodChannel channel}) {
    this._channel = channel;
    this._subscribe();
  }

  void _subscribe() async {
    await _channel.invokeMethod('subscribe',
        {'channelName': this.name, 'instanceId': pusher._instanceId});
  }

  /// Bind to listen for events sent on the given channel
  Future bind(String eventName, Function onEvent) async {
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
  final EventChannel _eventChannel =
      const EventChannel('com.github.heywhy/pusherStream');
  static num _instances = 0;

  num _instanceId;
  String _socketId;
  Map<String, Function> _eventCallbacks = Map<String, Function>();
  void Function(ConnectionError) _onError;
  void Function(ConnectionStateChange) _onConnectionStateChange;

  FlutterPusher(
    String appKey,
    PusherOptions options, {
    bool lazyConnect = false,
    bool enableLogging = false,
    void Function(ConnectionError) onError,
    void Function(ConnectionStateChange) onConnectionStateChange,
  })  : assert(appKey != null),
        assert(options != null) {
    _instanceId = _instances++;
    _onError = onError;
    _onConnectionStateChange = onConnectionStateChange;
    _init(appKey, options, enableLogging: enableLogging);
    if (!lazyConnect) {
      connect(
          onError: onError, onConnectionStateChange: onConnectionStateChange);
    }
  }

  /// Connect the client to pusher
  Future connect({
    void Function(ConnectionStateChange) onConnectionStateChange,
    void Function(ConnectionError) onError,
  }) async {
    _onConnectionStateChange = onConnectionStateChange != null
        ? onConnectionStateChange
        : _onConnectionStateChange;
    _onError = onError != null ? onError : _onError;

    await _channel.invokeMethod(
        'connect', jsonEncode({'instanceId': _instanceId}));
  }

  /// Disconnect the client from pusher
  Future disconnect() async {
    await _channel.invokeMethod(
        'disconnect', jsonEncode({'instanceId': _instanceId}));
  }

  /// Subscribe to a channel
  /// Use the returned [Channel] to bind events
  Channel subscribe(String channelName) {
    return Channel(name: channelName, pusher: this, channel: _channel);
  }

  /// Unsubscribe from a channel
  Future unsubscribe(String channelName) async {
    await _channel.invokeMethod(
        'unsubscribe', {'channelName': channelName, 'instanceId': _instanceId});
  }

  String getSocketId() {
    return _socketId;
  }

  void _init(String appKey, PusherOptions options, {bool enableLogging}) async {
    _eventChannel.receiveBroadcastStream().listen(_handleEvent);

    final initArgs = jsonEncode(InitArgs(
      _instanceId,
      appKey,
      options,
      isLoggingEnabled: enableLogging,
    ).toJson());

    await _channel.invokeMethod('init', initArgs);
  }

  void _handleEvent([dynamic arguments]) async {
    var message = PusherEventStreamMessage.fromJson(jsonDecode(arguments));

    if (message.instanceId != _instanceId.toString()) {
      return;
    }

    if (message.isEvent) {
      var callback =
          _eventCallbacks[message.event.channel + message.event.event];
      if (callback != null) {
        callback(jsonDecode(message.event.data));
      }
    } else if (message.isConnectionStateChange) {
      _socketId = await _channel.invokeMethod('getSocketId', {'instanceId': _instanceId});
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
    Function onEvent,
  }) async {
    final bindArgs = jsonEncode(BindArgs(
      instanceId: _instanceId,
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    _eventCallbacks[channelName + eventName] = onEvent;
    await _channel.invokeMethod('bind', bindArgs);
  }

  Future _unbind(String channelName, String eventName) async {
    final bindArgs = jsonEncode(BindArgs(
      instanceId: _instanceId,
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    _eventCallbacks.remove(channelName + eventName);
    await _channel.invokeMethod('unbind', bindArgs);
  }

  Future _trigger(String channelName, String eventName) async {
    final bindArgs = jsonEncode(BindArgs(
      instanceId: _instanceId,
      channelName: channelName,
      eventName: eventName,
    ).toJson());

    await _channel.invokeMethod('trigger', bindArgs);
  }
}

class PusherClient extends FlutterPusher {
  PusherClient(
    String appKey,
    PusherOptions options, {
    bool lazyConnect = false,
    bool enableLogging = false,
    void Function(ConnectionError) onError,
    void Function(ConnectionStateChange) onConnectionStateChange,
  }) : super(
          appKey,
          options,
          onError: onError,
          lazyConnect: lazyConnect,
          enableLogging: enableLogging,
          onConnectionStateChange: onConnectionStateChange,
        );
}

@JsonSerializable()
class BindArgs {
  final int instanceId;
  final String channelName;
  final String eventName;

  BindArgs({this.channelName, this.eventName, this.instanceId})
      : assert(instanceId != null);

  factory BindArgs.fromJson(Map<String, dynamic> json) =>
      _$BindArgsFromJson(json);

  Map<String, dynamic> toJson() => _$BindArgsToJson(this);
}

@JsonSerializable()
class InitArgs {
  final int instanceId;
  final String appKey;
  final PusherOptions options;
  final bool isLoggingEnabled;

  InitArgs(this.instanceId, this.appKey, this.options,
      {this.isLoggingEnabled = false});

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
  final String instanceId;
  final ConnectionStateChange connectionStateChange;
  final ConnectionError connectionError;

  bool get isEvent => event != null;

  bool get isConnectionStateChange => connectionStateChange != null;

  bool get isConnectionError => connectionError != null;

  PusherEventStreamMessage(
      {this.event,
      this.instanceId,
      this.connectionStateChange,
      this.connectionError});

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
