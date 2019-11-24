package com.github.heywhy.flutter_pusher;

import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.pusher.client.util.ConnectionFactory;

public class JsonEncodedConnectionFactory extends ConnectionFactory {

    @Override
    public String getCharset() {
        return "UTF-8";
    }

    @Override
    public String getContentType() {
        return "application/json";
    }

    public String getBody() {
        JsonObject payload = new JsonObject();
        payload.add("channel_name", new JsonPrimitive(getChannelName()));
        payload.add("socket_id", new JsonPrimitive(getSocketId()));

        return payload.toString();
    }

}
