package com.garageservice.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Base64;

@Configuration
public class FirebaseConfig {

    @Value("${fcm.serviceAccountPath:}")
    private String serviceAccountPath;

    @Value("${fcm.serviceAccountBase64:}")
    private String serviceAccountBase64;

    @PostConstruct
    public void init() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return; // already initialized
        }
        try (InputStream credStream = resolveCredentialsStream()) {
            if (credStream == null) {
                // No credentials provided; skip initialization. Sender will guard against this.
                return;
            }
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(credStream))
                    .build();
            FirebaseApp.initializeApp(options);
            System.out.println("[FirebaseConfig] FirebaseApp initialized successfully");
        } catch (Exception e) {
            // Log and continue without FCM initialized
            System.err.println("[FirebaseConfig] Failed to initialize FirebaseApp: " + e.getMessage());
        }
    }

    private InputStream resolveCredentialsStream() {
        try {
            if (serviceAccountPath != null && !serviceAccountPath.isBlank()) {
                if (serviceAccountPath.startsWith("classpath:")) {
                    String cp = serviceAccountPath.substring("classpath:".length());
                    ClassPathResource resource = new ClassPathResource(cp.startsWith("/") ? cp.substring(1) : cp);
                    if (resource.exists()) {
                        return resource.getInputStream();
                    }
                } else {
                    return new FileInputStream(serviceAccountPath);
                }
            } else if (serviceAccountBase64 != null && !serviceAccountBase64.isBlank()) {
                byte[] decoded = Base64.getDecoder().decode(serviceAccountBase64);
                return new ByteArrayInputStream(decoded);
            }
        } catch (Exception e) {
            System.err.println("[FirebaseConfig] Unable to read credentials: " + e.getMessage());
        }
        return null;
    }
}
