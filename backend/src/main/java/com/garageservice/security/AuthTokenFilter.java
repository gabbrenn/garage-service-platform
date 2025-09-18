package com.garageservice.security;

import com.garageservice.service.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class AuthTokenFilter extends OncePerRequestFilter {
    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getServletPath();
        if (path.startsWith("/api/auth/") || path.startsWith("/h2-console") || path.startsWith("/api/garages/nearby")) {
            filterChain.doFilter(request, response);
            return;
        }
        try {
            logger.debug("[AuthTokenFilter] Path: {}", path);
            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                String headerAuth = request.getHeader("Authorization");
                String jwt = parseJwt(request);
                if (jwt == null) {
                    logger.trace("[AuthTokenFilter] No JWT found. Authorization header value: {}", headerAuth);
                } else if (jwtUtils.validateJwtToken(jwt)) {
                    String username = jwtUtils.getUserNameFromJwtToken(jwt);
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    logger.debug("[AuthTokenFilter] Authenticated user: {} roles={} ", username, userDetails.getAuthorities());
                } else {
                    logger.info("[AuthTokenFilter] Invalid JWT for path {}", path);
                }
            } else {
                logger.trace("[AuthTokenFilter] Existing authentication detected, skipping token parse");
            }
        } catch (Exception e) {
            logger.error("[AuthTokenFilter] Cannot set user authentication: {}", e.getMessage(), e);
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");

        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }

        return null;
    }
}