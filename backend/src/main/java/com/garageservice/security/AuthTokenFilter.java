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
        // skip for auth for public endpoint
        if (request.getServletPath().startsWith("/api/auth/") || request.getServletPath().startsWith("/h2-console") || request.getServletPath().startsWith("/api/garages/nearby")) {
            filterChain.doFilter(request, response);
            return;
        }
        try {
            // 1️⃣ Print request path
            System.out.println("Request path: " + request.getServletPath());

            String jwt = parseJwt(request);

            // 2️⃣ Print extracted JWT
            System.out.println("Extracted JWT: " + jwt);
            if (jwt != null && jwtUtils.validateJwtToken(jwt)) {

                 // 3️⃣ JWT is valid
                System.out.println("JWT is valid");

                String username = jwtUtils.getUserNameFromJwtToken(jwt);

                    // 4️⃣ Print extracted username  
                System.out.println("Extracted username: " + username);

                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                // 5️⃣ Print user details
                System.out.println("User details: " + userDetails);
                System.out.println("Authorities: " + userDetails.getAuthorities());

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(userDetails,
                                null,
                                userDetails.getAuthorities());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authentication);

                // 6️⃣ Print authentication details
                System.out.println("Authentication set in context: " + SecurityContextHolder.getContext().getAuthentication());
            }
        } catch (Exception e) {
            logger.error("Cannot set user authentication: {}", e);
            e.printStackTrace(); // Print stack trace for debugging
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