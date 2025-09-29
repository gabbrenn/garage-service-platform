package com.garageservice.controller;

import com.garageservice.dto.AuthRequest;
import com.garageservice.dto.AuthResponse;
import com.garageservice.dto.SignupRequest;
import com.garageservice.model.User;
import com.garageservice.repository.UserRepository;
import com.garageservice.security.JwtUtils;
import com.garageservice.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.UUID;
import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Value;
import com.garageservice.service.EmailService;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    UserRepository userRepository;

    @Autowired
    PasswordEncoder encoder;

    @Autowired
    JwtUtils jwtUtils;

    @Autowired
    EmailService emailService;

    @Value("${app.mail.reset.base-url:https://example.com/reset-password}")
    private String resetBaseUrl;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody AuthRequest loginRequest) {
        System.out.println("Login attempt: "+ loginRequest.getEmail());
        Authentication authentication;
        try{
            authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));
        }catch(Exception e){
            e.printStackTrace();
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", "Error: Invalid email or password"));
        }
        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);
        String refresh = jwtUtils.generateRefreshToken(authentication);

        UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();

        return ResponseEntity.ok(new AuthResponse(jwt,
                userDetails.getId(),
                userDetails.getEmail(),
                userDetails.getFirstName(),
                userDetails.getLastName(),
                userRepository.findById(userDetails.getId()).get().getUserType(),
                refresh));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> body){
        String token = body.get("refreshToken");
        if(token == null){
            return ResponseEntity.badRequest().body(Map.of("message","refreshToken is required"));
        }
        if(!jwtUtils.validateJwtToken(token) || !jwtUtils.isRefreshToken(token)){
            return ResponseEntity.status(401).body(Map.of("message","Invalid refresh token"));
        }
        String username = jwtUtils.getUserNameFromJwtToken(token);
        User user = userRepository.findByEmail(username).orElse(null);
        if(user == null){
            return ResponseEntity.status(401).body(Map.of("message","User not found"));
        }
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                new UserPrincipal(user.getId(), user.getFirstName(), user.getLastName(), user.getEmail(), user.getPassword(),
                        List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_"+user.getUserType().name()))),
                null,
                List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_"+user.getUserType().name()))
        );
        String newAccess = jwtUtils.generateJwtToken(authentication);
        return ResponseEntity.ok(Map.of("accessToken", newAccess));
    }

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signUpRequest) {
        Map<String, String> response = new HashMap<>();

        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            response.put("message", "Error: Email is already in use!");
            return ResponseEntity.badRequest().body(response);
        }

        if (userRepository.existsByPhoneNumber(signUpRequest.getPhoneNumber())) {
            response.put("message", "Error: Phone number is already in use!");
            return ResponseEntity.badRequest().body(response);
        }

        // Create new user's account
        User user = new User(signUpRequest.getFirstName(),
                signUpRequest.getLastName(),
                signUpRequest.getEmail(),
                signUpRequest.getPhoneNumber(),
                encoder.encode(signUpRequest.getPassword()),
                signUpRequest.getUserType());

        userRepository.save(user);

        response.put("message", "User registered successfully!");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Email is required"));
        }
        var opt = userRepository.findByEmail(email);
        if (opt.isEmpty()) {
            // Don't reveal that the email doesn't exist
            return ResponseEntity.ok(Map.of("message", "If an account exists, a reset email has been sent"));
        }
        User user = opt.get();
        String token = UUID.randomUUID().toString();
        user.setResetToken(token);
        user.setResetTokenExpiry(LocalDateTime.now().plusHours(1));
        userRepository.save(user);

    // Send reset email with token code (no link) – do not reveal account existence in response
    try {
        String subject = "Your password reset code";
        String text = "Hello " + user.getFirstName() + ",\n\n" +
            "We received a request to reset your password.\n" +
            "Use the code below in the app to set a new password. This code expires in 1 hour.\n\n" +
            "Reset code: " + token + "\n\n" +
            "If you didn't request this, you can ignore this email.";
        String html = "<p>Hello " + user.getFirstName() + ",</p>" +
            "<p>We received a request to reset your password.</p>" +
            "<p>Use the code below in the app to set a new password. This code expires in <strong>1 hour</strong>.</p>" +
            "<p style='font-size:16px'><strong>Reset code:</strong> <code>" + token + "</code></p>" +
            "<p>If you didn't request this, you can ignore this email.</p>";
        // Send both HTML (preferred) and ensure clients without HTML still receive content
        emailService.sendHtml(user.getEmail(), subject, html);
    } catch (Exception ignore) {}

    return ResponseEntity.ok(Map.of("message", "If an account exists, a reset email has been sent"));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> body) {
        String token = body.get("token");
        String newPassword = body.get("newPassword");
        if (token == null || token.isBlank() || newPassword == null || newPassword.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Token and newPassword are required"));
        }
        var opt = userRepository.findByResetToken(token);
        if (opt.isEmpty()) {
            return ResponseEntity.status(400).body(Map.of("message", "Invalid or expired token"));
        }
        User user = opt.get();
        if (user.getResetTokenExpiry() == null || user.getResetTokenExpiry().isBefore(LocalDateTime.now())) {
            return ResponseEntity.status(400).body(Map.of("message", "Invalid or expired token"));
        }
        user.setPassword(encoder.encode(newPassword));
        user.setResetToken(null);
        user.setResetTokenExpiry(null);
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Password has been reset successfully"));
    }
}