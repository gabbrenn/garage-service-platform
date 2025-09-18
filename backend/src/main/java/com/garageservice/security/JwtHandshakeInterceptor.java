package com.garageservice.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.socket.server.support.HttpSessionHandshakeInterceptor;

import com.garageservice.service.UserDetailsServiceImpl;

import java.util.Map;
import java.util.Optional;

@Component
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    @Override
    public boolean beforeHandshake(org.springframework.http.server.ServerHttpRequest request,
                                   org.springframework.http.server.ServerHttpResponse response,
                                   WebSocketHandler wsHandler,
                                   Map<String, Object> attributes) throws Exception {

        String authHeader = null;
        String token = null;

        // Try to get headers from request
        if (request instanceof org.springframework.http.server.ServletServerHttpRequest servletRequest) {
            var httpServletRequest = servletRequest.getServletRequest();
            authHeader = httpServletRequest.getHeader(HttpHeaders.AUTHORIZATION);

            if (authHeader != null && authHeader.toLowerCase().startsWith("bearer ")) {
                token = authHeader.substring(7);
            } else {
                // Look in query params: access_token or authorization
                String qToken = httpServletRequest.getParameter("access_token");
                if (qToken == null) {
                    String qAuth = httpServletRequest.getParameter("authorization");
                    if (qAuth != null && qAuth.toLowerCase().startsWith("bearer ")) {
                        qToken = qAuth.substring(7);
                    }
                }
                token = qToken;
            }

            if (token == null || token.isBlank()) {
                if (response instanceof org.springframework.http.server.ServletServerHttpResponse servletResponse) {
                    servletResponse.getServletResponse().setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                }
                return false;
            }

            if (!jwtUtils.validateJwtToken(token)) {
                if (response instanceof org.springframework.http.server.ServletServerHttpResponse servletResponse) {
                    servletResponse.getServletResponse().setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                }
                return false;
            }

            String email = jwtUtils.getUserNameFromJwtToken(token);
            var user = userDetailsService.loadUserByUsername(email);
            if (!(user instanceof UserPrincipal up)) {
                if (response instanceof org.springframework.http.server.ServletServerHttpResponse servletResponse) {
                    servletResponse.getServletResponse().setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                }
                return false;
            }

            // Attach our principal to attributes; Spring will expose it to StompHeaderAccessor.getUser()
            attributes.put("principal", new StompPrincipal(up.getId(), email));
            return true;
        }

        // If not a ServletServerHttpRequest, reject
        return false;
    }

    @Override
    public void afterHandshake(org.springframework.http.server.ServerHttpRequest request,
                               org.springframework.http.server.ServerHttpResponse response,
                               WebSocketHandler wsHandler,
                               Exception exception) {
        // no-op
    }
}
