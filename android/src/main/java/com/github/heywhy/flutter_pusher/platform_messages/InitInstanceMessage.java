package com.github.heywhy.flutter_pusher.platform_messages;

import java.util.Collections;
import java.util.Map;

public class InitInstanceMessage extends InstanceMessage {

    private String appKey;
    private InitOptions options;
    private boolean isLoggingEnabled = false;

    public String getAppKey() {
        return appKey;
    }

    public void setAppKey(String appKey) {
        this.appKey = appKey;
    }

    public boolean getIsLoggingEnabled() {
        return isLoggingEnabled;
    }

    public void setLoggingEnabled(boolean loggingEnabled) {
        isLoggingEnabled = loggingEnabled;
    }

    public InitOptions getOptions() {
        return options;
    }

    public void setOptions(InitOptions options) {
        this.options = options;
    }

    public static class InitOptions {
        private int port;
        private String host;
        private String cluster;
        private AuthOption auth;
        private boolean encrypted = true;
        private int activityTimeout;

        public int getPort() {
            return port;
        }

        public void setPort(int port) {
            this.port = port;
        }

        public String getHost() {
            return host;
        }

        public void setHost(String host) {
            this.host = host;
        }

        public String getCluster() {
            return cluster;
        }

        public void setCluster(String cluster) {
            this.cluster = cluster;
        }

        public AuthOption getAuth() {
            return auth;
        }

        public void setAuth(AuthOption auth) {
            this.auth = auth;
        }

        public boolean getEncrypted() {
            return encrypted;
        }

        public void setEncrypted(boolean encrypted) {
            this.encrypted = encrypted;
        }

        public int getActivityTimeout() {
            return activityTimeout;
        }

        public void setActivityTimeout(int activityTimeout) {
            this.activityTimeout = activityTimeout;
        }
    }

    public static class AuthOption {
        private String endpoint;
        private Map<String, String> headers = Collections.emptyMap();

        public String getEndpoint() {
            return endpoint;
        }

        public void setEndpoint(String endpoint) {
            this.endpoint = endpoint;
        }

        public Map<String, String> getHeaders() {
            return headers;
        }

        public void setHeaders(Map<String, String> headers) {
            this.headers = headers;
        }
    }
}
