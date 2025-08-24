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

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody AuthRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserPrincipal userDetails = (UserPrincipal) authentication.getPrincipal();

        return ResponseEntity.ok(new AuthResponse(jwt,
                userDetails.getId(),
                userDetails.getEmail(),
                userDetails.getFirstName(),
                userDetails.getLastName(),
                userRepository.findById(userDetails.getId()).get().getUserType()));
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
}