package com.garageservice.dto;

import com.garageservice.model.User;

public class AuthResponse {
    private String token;
    private String type = "Bearer";
    private Long id;
    private String email;
    private String firstName;
    private String lastName;
    private User.UserType userType;
    private String refreshToken;

    public AuthResponse(String accessToken, Long id, String email, String firstName, String lastName, User.UserType userType, String refreshToken) {
        this.token = accessToken;
        this.id = id;
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.userType = userType;
        this.refreshToken = refreshToken;
    }

    // Getters and Setters
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public User.UserType getUserType() { return userType; }
    public void setUserType(User.UserType userType) { this.userType = userType; }
    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
}