package com.github.heywhy.flutter_pusher;

import android.util.Log;
import com.github.heywhy.flutter_pusher.platform_messages.InstanceMessage;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;

/**
 * FlutterPusherPlugin
 */
public class FlutterPusherPlugin implements MethodCallHandler {

    public static String TAG = "FlutterPusherPlugin";
    public static EventChannel.EventSink eventSink;

    private Map<String, PusherInstance> pusherInstanceMap = new HashMap<>();

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.github.heywhy/pusher");
        final EventChannel eventStream = new EventChannel(registrar.messenger(), "com.github.heywhy/pusherStream");

        channel.setMethodCallHandler(new FlutterPusherPlugin());
        eventStream.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, final EventChannel.EventSink eventSink) {
                FlutterPusherPlugin.eventSink = eventSink;
            }

            @Override
            public void onCancel(Object args) {
                Log.d(TAG, String.format("onCancel args: %s", args != null ? args.toString() : "null"));
            }
        });
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Type type = new TypeToken<InstanceMessage>(){}.getType();
        InstanceMessage instanceMessage = new Gson().fromJson(call.arguments.toString(), type);
        String instanceId = instanceMessage.getInstanceId();
        PusherInstance instance = getPusherInstance(instanceId);
        if (instance == null) {
            String message = String.format("Instance with id %s not found", instanceId);
            throw new IllegalArgumentException(message);
        }

        instance.onMethodCall(call, result);
    }

    private PusherInstance getPusherInstance(String instanceId) {
        if (instanceId != null && !pusherInstanceMap.containsKey(instanceId)) {
            pusherInstanceMap.put(instanceId, new PusherInstance(instanceId));
        }
        return pusherInstanceMap.get(instanceId);
    }
}
