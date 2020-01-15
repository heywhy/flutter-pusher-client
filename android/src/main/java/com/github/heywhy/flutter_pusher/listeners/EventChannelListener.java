package com.github.heywhy.flutter_pusher.listeners;

import android.os.Handler;
import android.util.Log;
import android.os.Looper;

import com.pusher.client.channel.ChannelEventListener;
import com.pusher.client.channel.PusherEvent;

import java.util.HashMap;
import java.util.Map;

import org.json.JSONObject;

import static com.github.heywhy.flutter_pusher.FlutterPusherPlugin.TAG;
import static com.github.heywhy.flutter_pusher.FlutterPusherPlugin.eventSink;

public class EventChannelListener implements ChannelEventListener {
    static final String SUBSCRIPTION_SUCCESS_EVENT = "pusher:subscription_succeeded";
    static final String MEMBER_ADDED_EVENT = "pusher:member_added";
    static final String MEMBER_REMOVED_EVENT = "pusher:member_removed";

    private String instanceId;
    private boolean isLoggingEnabled;

    public EventChannelListener(String instanceId, boolean isLoggingEnabled) {
        this.instanceId = instanceId;
        this.isLoggingEnabled = isLoggingEnabled;
    }

    static PusherEvent toPusherEvent(String channel, String event, String userId, String data) {
        final Map<String, Object> eventData = new HashMap<>();

        eventData.put("channel", channel);
        eventData.put("event", event);
        eventData.put("data", data != null ? data : "");
        if (userId != null) {
            eventData.put("user_id", userId);
        }

        return new PusherEvent(eventData);
    }

    @Override
    public void onEvent(final PusherEvent pusherEvent) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                try {
                    final JSONObject eventStreamMessageJson = new JSONObject();
                    final JSONObject eventJson = new JSONObject();
                    final String channel = pusherEvent.getChannelName();
                    final String event = pusherEvent.getEventName();
                    final String data = pusherEvent.getData();

                    eventJson.put("channel", channel);
                    eventJson.put("event", event);
                    eventJson.put("data", data);
                    eventStreamMessageJson.put("isEvent", true);
                    eventStreamMessageJson.put("event", eventJson);
                    eventStreamMessageJson.put("instanceId", instanceId);

                    eventSink.success(eventStreamMessageJson.toString());

                    if (isLoggingEnabled) {
                        Log.d(TAG, String.format("onEvent: \nCHANNEL: %s \nEVENT: %s \nDATA: %s", channel, event, data));
                    }
                } catch (Exception e) {
                    onError(e);
                }
            }
        });

    }

    void onError(final Exception e) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject eventStreamMessageJson = new JSONObject();
                    JSONObject connectionErrorJson = new JSONObject();
                    connectionErrorJson.put("message", e.getMessage());
                    connectionErrorJson.put("code", "Channel error");
                    connectionErrorJson.put("exception", e);
                    eventStreamMessageJson.put("connectionError", connectionErrorJson);
                    eventStreamMessageJson.put("instanceId", instanceId);

                    eventSink.success(eventStreamMessageJson.toString());

                    if (isLoggingEnabled) {
                        Log.d(TAG, "onError : " + e.getMessage());
                        e.printStackTrace();
                    }
                } catch (Exception ex) {
                    if (isLoggingEnabled) {
                        Log.d(TAG, "onError exception: " + e.getMessage());
                        ex.printStackTrace();
                    }
                }
            }
        });
    }

    @Override
    public void onSubscriptionSucceeded(String channelName) {
        this.onEvent(toPusherEvent(channelName, SUBSCRIPTION_SUCCESS_EVENT, null, null));
    }
}
