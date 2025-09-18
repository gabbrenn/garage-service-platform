package com.garageservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.garageservice.model.User;
import com.garageservice.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@SpringBootTest
@AutoConfigureMockMvc
public class ReportControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    private String accessToken;

    @BeforeEach
    void setup() throws Exception {
        String email = "report_owner@example.com";
        userRepository.findByEmail(email).ifPresent(u -> userRepository.delete(u));
        User user = new User("Owner","Report", email, "0000000000", passwordEncoder.encode("password"), User.UserType.GARAGE_OWNER);
        userRepository.save(user);

        String body = objectMapper.writeValueAsString(Map.of(
                "email", email,
                "password", "password"
        ));
        String response = mockMvc.perform(post("/api/auth/signin")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        accessToken = objectMapper.readTree(response).get("token").asText();
    }

    @Test
    void reportsDailyRequiresGarage() throws Exception {
        mockMvc.perform(get("/api/reports/daily")
                .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("No garage found for this user"));
    }
}
