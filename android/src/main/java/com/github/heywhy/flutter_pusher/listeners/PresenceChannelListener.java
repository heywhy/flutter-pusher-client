package com.github.heywhy.flutter_pusher.listeners;

import com.pusher.client.channel.PresenceChannelEventListener;
import com.pusher.client.channel.User;

import java.util.Set;

public class PresenceChannelListener extends EventChannelListener implements PresenceChannelEventListener {

    @Override
    public void onSubscriptionSucceeded(String channelName) {
        this.onEvent(toPusherEvent(channelName, SUBSCRIPTION_SUCCESS_EVENT, null, null));
    }

    @Override
    public void onAuthenticationFailure(String message, Exception e) {
        onError(e);
    }

    @Override
    public void onUsersInformationReceived(String channelName, Set<User> users) {
        this.onEvent(toPusherEvent(channelName, SUBSCRIPTION_SUCCESS_EVENT, null, users.toString()));
    }

    @Override
    public void userSubscribed(String channelName, User user) {
        this.onEvent(toPusherEvent(channelName, MEMBER_ADDED_EVENT, user.getId(), null));
    }

    @Override
    public void userUnsubscribed(String channelName, User user) {
        this.onEvent(toPusherEvent(channelName, MEMBER_REMOVED_EVENT, user.getId(), null));
    }
}
