package com.garageservice.config;

import com.garageservice.security.JwtHandshakeInterceptor;
import com.garageservice.security.StompPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import java.security.Principal;
import org.springframework.messaging.simp.config.ChannelRegistration;
import com.garageservice.security.SubscriptionSecurityInterceptor;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Autowired
    private JwtHandshakeInterceptor jwtHandshakeInterceptor;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .addInterceptors(jwtHandshakeInterceptor)
                .setHandshakeHandler(new DefaultHandshakeHandler() {
                    @Override
                    protected Principal determineUser(org.springframework.http.server.ServerHttpRequest request,
                                                       WebSocketHandler wsHandler,
                                                       java.util.Map<String, Object> attributes) {
                        Object p = attributes.get("principal");
                        if (p instanceof Principal principal) return principal;
                        return super.determineUser(request, wsHandler, attributes);
                    }
                })
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Autowired
    private SubscriptionSecurityInterceptor subscriptionSecurityInterceptor;

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(subscriptionSecurityInterceptor);
    }
}
