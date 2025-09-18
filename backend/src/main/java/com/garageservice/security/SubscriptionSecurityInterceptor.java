package com.garageservice.security;

import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.SimpMessageType;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.stereotype.Component;

import java.security.Principal;

@Component
public class SubscriptionSecurityInterceptor implements ChannelInterceptor {
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);
        if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            Principal user = accessor.getUser();
            String dest = accessor.getDestination();
            if (user instanceof StompPrincipal sp && dest != null) {
                String allowed = "/topic/notifications." + sp.getUserId();
                if (!dest.equals(allowed)) {
                    throw new IllegalArgumentException("Forbidden subscription to " + dest);
                }
            }
        }
        return message;
    }
}
