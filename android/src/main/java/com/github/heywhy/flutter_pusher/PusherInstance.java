package com.github.heywhy.flutter_pusher;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import com.github.heywhy.flutter_pusher.listeners.EventChannelListener;
import com.github.heywhy.flutter_pusher.listeners.PresenceChannelListener;
import com.github.heywhy.flutter_pusher.listeners.PrivateChannelListener;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.pusher.client.Pusher;
import com.pusher.client.PusherOptions;
import com.pusher.client.channel.Channel;
import com.pusher.client.connection.ConnectionEventListener;
import com.pusher.client.connection.ConnectionState;
import com.pusher.client.connection.ConnectionStateChange;
import com.pusher.client.util.ConnectionFactory;
import com.pusher.client.util.HttpAuthorizer;
import com.pusher.client.util.UrlEncodedConnectionFactory;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONObject;

import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;

import static com.github.heywhy.flutter_pusher.FlutterPusherPlugin.TAG;
import static com.github.heywhy.flutter_pusher.FlutterPusherPlugin.eventSink;

public class PusherInstance implements MethodChannel.MethodCallHandler {

    private Pusher pusher;
    private String instanceId;
    private boolean isLoggingEnabled = false;
    private Map<String, Channel> channels = new HashMap<>();

    private EventChannelListener eventListener;
    private PrivateChannelListener eventListenerPrivate;
    private PresenceChannelListener eventListenerPresence;

    PusherInstance(String instanceId) {
        this.instanceId = instanceId;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "init":
                init(call, result);
                break;
            case "connect":
                connect(call, result);
                break;
            case "disconnect":
                disconnect(call, result);
                break;
            case "subscribe":
                subscribe(call, result);
                break;
            case "unsubscribe":
                unsubscribe(call, result);
                break;
            case "bind":
                bind(call, result);
                break;
            case "unbind":
                unbind(call, result);
                break;
            case "trigger":
                // trigger(call, result);
                break;
            case "getSocketId":
                getSocketId(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void initListeners() {
        eventListener = new EventChannelListener(instanceId, isLoggingEnabled);
        eventListenerPrivate = new PrivateChannelListener(instanceId, isLoggingEnabled);
        eventListenerPresence = new PresenceChannelListener(instanceId, isLoggingEnabled);
    }

    private void init(MethodCall call, MethodChannel.Result result) {
        if (pusher != null) {
            for (Map.Entry<String, Channel> entry : channels.entrySet()) {
                String name = entry.getKey();
                pusher.unsubscribe(name);
                channels.remove(name);
            }
        }

        try {
            final JSONObject json = new JSONObject(call.arguments.toString());
            final JSONObject options = json.getJSONObject("options");

            if (json.has("isLoggingEnabled")) {
                isLoggingEnabled = json.getBoolean("isLoggingEnabled");
            }

            // setup options
            final PusherOptions pusherOptions = new PusherOptions();

            if (options.has("auth")) {
                final JSONObject auth = options.getJSONObject("auth");
                final String endpoint = auth.getString("endpoint");
                final Type mapType = new TypeToken<Map<String, String>>() {}.getType();
                final Map<String, String> headers = new Gson().fromJson(auth.get("headers").toString(), mapType);

                pusherOptions.setAuthorizer(getAuthorizer(endpoint, headers));
            }

            if (options.has("activityTimeout")) {
                pusherOptions.setActivityTimeout(options.getInt("activityTimeout"));
            }
            if (options.has("cluster")) {
                pusherOptions.setCluster(options.getString("cluster"));
            }
            if (options.has("host")) {
                pusherOptions.setHost(options.getString("host"));
            }

            // defaults to encrypted connection on port 443
            final int port = options.has("port") ? options.getInt("port") : 443;
            final boolean encrypted = !options.has("encrypted") || options.getBoolean("encrypted");

            if (encrypted) {
                pusherOptions.setWssPort(port);
            } else {
                pusherOptions.setWsPort(port);
            }
            pusherOptions.setEncrypted(encrypted);


            // create client
            pusher = new Pusher(json.getString("appKey"), pusherOptions);
            initListeners();

            if (isLoggingEnabled) {
                Log.d(TAG, "init");
            }
            result.success(null);
        } catch (Exception e) {
            if (isLoggingEnabled) {
                Log.d(TAG, "init error: " + e.getMessage());
                e.printStackTrace();
            }
        }
    }

    private void connect(MethodCall call, MethodChannel.Result result) {
        pusher.connect(new ConnectionEventListener() {
            @Override
            public void onConnectionStateChange(final ConnectionStateChange change) {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            final JSONObject eventStreamMessageJson = new JSONObject();
                            final JSONObject connectionStateChangeJson = new JSONObject();

                            connectionStateChangeJson.put("currentState", change.getCurrentState().toString());
                            connectionStateChangeJson.put("previousState", change.getPreviousState().toString());
                            eventStreamMessageJson.put("connectionStateChange", connectionStateChangeJson);
                            eventStreamMessageJson.put("instanceId", instanceId);
                            eventSink.success(eventStreamMessageJson.toString());
                        } catch (Exception e) {
                            if (isLoggingEnabled) {
                                Log.d(TAG, "onConnectionStateChange error: " + e.getMessage());
                                e.printStackTrace();
                            }
                        }
                    }
                });
            }

            @Override
            public void onError(final String message, final String code, final Exception ex) {
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            final String exMessage = ex != null ? ex.getMessage() : null;
                            final JSONObject eventStreamMessageJson = new JSONObject();
                            final JSONObject connectionErrorJson = new JSONObject();

                            connectionErrorJson.put("instanceId", instanceId);
                            connectionErrorJson.put("message", message);
                            connectionErrorJson.put("code", code);
                            connectionErrorJson.put("exception", exMessage);
                            eventStreamMessageJson.put("connectionError", connectionErrorJson);
                            eventStreamMessageJson.put("instanceId", instanceId);

                            eventSink.success(eventStreamMessageJson.toString());

                        } catch (Exception e) {
                            if (isLoggingEnabled) {
                                Log.d(TAG, "onError exception: " + e.getMessage());
                                e.printStackTrace();
                            }
                        }
                    }
                });
            }

        }, ConnectionState.ALL);

        if (isLoggingEnabled) {
            Log.d(TAG, "connect");
        }
        result.success(null);
    }


    private void getSocketId(MethodCall call, MethodChannel.Result result) {
        result.success(pusher.getConnection().getSocketId());
    }

    private void disconnect(MethodCall call, MethodChannel.Result result) {
        pusher.disconnect();
        if (isLoggingEnabled) {
            Log.d(TAG, "disconnect");
        }
        result.success(null);
    }

    private void subscribe(MethodCall call, MethodChannel.Result result) {

        try {
            final JSONObject json = new JSONObject(call.arguments.toString());
            final String channelName = json.getString("channelName");
            final String channelType = channelName.split("-")[0];
            Channel channel = channels.get(channelName);

            if (channel != null && channel.isSubscribed()) {
                if (isLoggingEnabled) {
                    Log.d(TAG, "Already subscribed, ignoring ...");
                }
                result.success(null);
                return;
            }

            switch (channelType) {
                case "private":
                    channel = pusher.subscribePrivate(channelName, eventListenerPrivate);
                    if (isLoggingEnabled) {
                        Log.d(TAG, "subscribe (private)");
                    }
                    break;
                case "presence":
                    channel = pusher.subscribePresence(channelName, eventListenerPresence);
                    if (isLoggingEnabled) {
                        Log.d(TAG, "subscribe (presence)");
                    }
                    break;
                default:
                    channel = pusher.subscribe(channelName, eventListener);

                    if (isLoggingEnabled) {
                        Log.d(TAG, "subscribe");
                    }
                    break;
            }

            channels.put(channelName, channel);
            result.success(null);
        } catch (Exception e) {
            if (isLoggingEnabled) {
                Log.d(TAG, "subscribe error: " + e.getMessage());
                e.printStackTrace();
            }
        }

    }

    private void unsubscribe(MethodCall call, MethodChannel.Result result) {
        try {
            final JSONObject json = new JSONObject(call.arguments.toString());
            final String channelName = json.getString("channelName");
            pusher.unsubscribe(channelName);
            channels.remove(channelName);

            if (isLoggingEnabled) {
                Log.d(TAG, String.format("unsubscribe (%s)", channelName));
            }
            result.success(null);
        } catch (Exception e) {
            if (isLoggingEnabled) {
                Log.d(TAG, "unsubscribe error: " + e.getMessage());
                e.printStackTrace();
            }
        }

    }

    private void bind(MethodCall call, MethodChannel.Result result) {
        try {
            final JSONObject json = new JSONObject(call.arguments.toString());
            final String channelName = json.getString("channelName");
            final String channelType = channelName.split("-")[0];
            final String eventName = json.getString("eventName");

            Channel channel = channels.get(channelName);

            switch (channelType) {
                case "private":
                    channel.bind(eventName, eventListenerPrivate);
                    break;
                case "presence":
                    channel.bind(eventName, eventListenerPresence);
                    break;
                default:
                    channel.bind(eventName, eventListener);
                    break;
            }

            if (isLoggingEnabled) {
                Log.d(TAG, String.format("bind (%s)", eventName));
            }
            result.success(null);
        } catch (Exception e) {
            if (isLoggingEnabled) {
                Log.d(TAG, String.format("bind exception: %s", e.getMessage()));
                e.printStackTrace();
            }
        }
    }

    private void unbind(MethodCall call, MethodChannel.Result result) {
        try {
            final JSONObject json = new JSONObject(call.arguments.toString());
            final String channelName = json.getString("channelName");
            final String channelType = channelName.split("-")[0];
            final String eventName = json.getString("eventName");

            Channel channel = channels.get(channelName);
            switch (channelType) {
                case "private":
                    channel.unbind(eventName, eventListenerPrivate);
                    break;
                case "presence":
                    channel.unbind(eventName, eventListenerPresence);
                    break;
                default:
                    channel.unbind(eventName, eventListener);
                    break;
            }

            if (isLoggingEnabled) {
                Log.d(TAG, String.format("unbind (%s)", eventName));
            }
            result.success(null);
        } catch (Exception e) {
            if (isLoggingEnabled) {
                Log.d(TAG, String.format("unbind exception: %s", e.getMessage()));
                e.printStackTrace();
            }
        }
    }

    private HttpAuthorizer getAuthorizer(String endpoint, Map<String, String> headers) {
        final ConnectionFactory connection = headers.containsValue("application/json")
            ? new JsonEncodedConnectionFactory()
            : new UrlEncodedConnectionFactory();

        final HttpAuthorizer authorizer = new HttpAuthorizer(endpoint, connection);
        authorizer.setHeaders(headers);

        return authorizer;

    }
}
