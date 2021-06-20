// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_pusher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BindArgs _$BindArgsFromJson(Map<String, dynamic> json) {
  return BindArgs(
    channelName: json['channelName'] as String,
    eventName: json['eventName'] as String,
    instanceId: json['instanceId'] as int,
  );
}

Map<String, dynamic> _$BindArgsToJson(BindArgs instance) => <String, dynamic>{
      'instanceId': instance.instanceId,
      'channelName': instance.channelName,
      'eventName': instance.eventName,
    };

InitArgs _$InitArgsFromJson(Map<String, dynamic> json) {
  return InitArgs(
    json['instanceId'] as int,
    json['appKey'] as String,
    json['options'] == null
        ? null
        : PusherOptions.fromJson(json['options'] as Map<String, dynamic>),
    isLoggingEnabled: json['isLoggingEnabled'] as bool,
  );
}

Map<String, dynamic> _$InitArgsToJson(InitArgs instance) => <String, dynamic>{
      'instanceId': instance.instanceId,
      'appKey': instance.appKey,
      'options': instance.options,
      'isLoggingEnabled': instance.isLoggingEnabled,
    };

PusherOptions _$PusherOptionsFromJson(Map<String, dynamic> json) {
  return PusherOptions(
    auth: json['auth'] == null
        ? null
        : PusherAuth.fromJson(json['auth'] as Map<String, dynamic>),
    cluster: json['cluster'] as String,
    host: json['host'] as String,
    port: json['port'] as int,
    encrypted: json['encrypted'] as bool,
    activityTimeout: json['activityTimeout'] as int,
  );
}

Map<String, dynamic> _$PusherOptionsToJson(PusherOptions instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('auth', instance.auth);
  writeNotNull('cluster', instance.cluster);
  writeNotNull('host', instance.host);
  writeNotNull('port', instance.port);
  writeNotNull('encrypted', instance.encrypted);
  writeNotNull('activityTimeout', instance.activityTimeout);
  return val;
}

PusherAuth _$PusherAuthFromJson(Map<String, dynamic> json) {
  return PusherAuth(
    json['endpoint'] as String,
    headers: (json['headers'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, e as String),
    ),
  );
}

Map<String, dynamic> _$PusherAuthToJson(PusherAuth instance) =>
    <String, dynamic>{
      'endpoint': instance.endpoint,
      'headers': instance.headers,
    };

PusherEventStreamMessage _$PusherEventStreamMessageFromJson(
    Map<String, dynamic> json) {
  return PusherEventStreamMessage(
    event: json['event'] == null
        ? null
        : Event.fromJson(json['event'] as Map<String, dynamic>),
    instanceId: json['instanceId'] as String,
    connectionStateChange: json['connectionStateChange'] == null
        ? null
        : ConnectionStateChange.fromJson(
            json['connectionStateChange'] as Map<String, dynamic>),
    connectionError: json['connectionError'] == null
        ? null
        : ConnectionError.fromJson(
            json['connectionError'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$PusherEventStreamMessageToJson(
        PusherEventStreamMessage instance) =>
    <String, dynamic>{
      'event': instance.event,
      'instanceId': instance.instanceId,
      'connectionStateChange': instance.connectionStateChange,
      'connectionError': instance.connectionError,
    };

Event _$EventFromJson(Map<String, dynamic> json) {
  return Event(
    channel: json['channel'] as String,
    event: json['event'] as String,
    data: json['data'] as String,
  );
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'channel': instance.channel,
      'event': instance.event,
      'data': instance.data,
    };

ConnectionStateChange _$ConnectionStateChangeFromJson(
    Map<String, dynamic> json) {
  return ConnectionStateChange(
    currentState: json['currentState'] as String,
    previousState: json['previousState'] as String,
  );
}

Map<String, dynamic> _$ConnectionStateChangeToJson(
        ConnectionStateChange instance) =>
    <String, dynamic>{
      'currentState': instance.currentState,
      'previousState': instance.previousState,
    };

ConnectionError _$ConnectionErrorFromJson(Map<String, dynamic> json) {
  return ConnectionError(
    message: json['message'] as String,
    code: json['code'] as String,
    exception: json['exception'] as String,
  );
}

Map<String, dynamic> _$ConnectionErrorToJson(ConnectionError instance) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'exception': instance.exception,
    };
