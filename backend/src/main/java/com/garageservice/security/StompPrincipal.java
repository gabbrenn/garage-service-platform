package com.garageservice.security;

import java.security.Principal;

public class StompPrincipal implements Principal {
    private final Long userId;
    private final String name; // typically email

    public StompPrincipal(Long userId, String name) {
        this.userId = userId;
        this.name = name;
    }

    public Long getUserId() { return userId; }

    @Override
    public String getName() { return name; }
}
