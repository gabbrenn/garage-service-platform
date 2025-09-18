package com.garageservice.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "device_tokens", indexes = {
    @Index(name = "idx_device_token_user", columnList = "user_id"),
    @Index(name = "idx_device_token_token", columnList = "token", unique = true)
})
public class DeviceToken {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "token", nullable = false, unique = true, length = 255)
    private String token;

    @Column(name = "platform", length = 64)
    private String platform;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public DeviceToken() { }

    public DeviceToken(User user, String token, String platform) {
        this.user = user;
        this.token = token;
        this.platform = platform;
        this.updatedAt = LocalDateTime.now();
    }

    @PrePersist
    @PreUpdate
    public void touch() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
