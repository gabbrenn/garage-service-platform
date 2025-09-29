package com.garageservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.garageservice.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;MODE=MYSQL",
        "spring.datasource.driverClassName=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false",
        // Shorten JWT expirations for tests if needed
        "app.jwtSecret=testSecretKeyThatIsLongEnoughForHS256",
        "app.jwtExpirationMs=60000",
        "app.jwtRefreshExpirationMs=120000",
        // Disable external email sending during tests
        "app.mail.provider=noop",
        "app.mail.enabled=false"
})
class AuthControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

        @Autowired
        private UserRepository userRepository;

    private String asJson(Object o) throws Exception {
        return objectMapper.writeValueAsString(o);
    }

    @Test
    void forgotPassword_unknownEmail_isOkAndNoToken() throws Exception {
        var resp = mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(java.util.Map.of("email", "unknown@example.com"))))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(resp.getResponse().getContentAsString());
        assertThat(json.get("message").asText()).contains("reset");
        // For unknown email, we should not leak a token
        assertThat(json.has("resetToken")).isFalse();
    }

    @Test
    void fullResetFlow_signup_forgot_reset_then_signin_with_new_password() throws Exception {
        // 1) Sign up a user
        var signupBody = java.util.Map.of(
                "firstName", "Jane",
                "lastName", "Doe",
                "email", "jane@example.com",
                "phoneNumber", "1234567890",
                // Must meet policy: upper, lower, digit, special, 8-40 chars
                "password", "Oldpass1!",
                "userType", "CUSTOMER"
        );
        mockMvc.perform(post("/api/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(signupBody)))
                .andExpect(status().isOk());

        // 2) Request forgot-password
        var forgot = mockMvc.perform(post("/api/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(java.util.Map.of("email", "jane@example.com"))))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode forgotJson = objectMapper.readTree(forgot.getResponse().getContentAsString());
        // New behavior: do not expose token in API response
        assertThat(forgotJson.has("resetToken")).isFalse();
        // Retrieve the token from the database (what the email would contain)
        var userOpt = userRepository.findByEmail("jane@example.com");
        assertThat(userOpt).isPresent();
        var user = userOpt.get();
        String token = user.getResetToken();
        assertThat(token).isNotBlank();

        // 3) Reset password using token
        var reset = mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(java.util.Map.of("token", token, "newPassword", "newpass123"))))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode resetJson = objectMapper.readTree(reset.getResponse().getContentAsString());
        assertThat(resetJson.get("message").asText()).contains("reset");

        // 4) Sign in with new password should succeed
        var signin = mockMvc.perform(post("/api/auth/signin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(java.util.Map.of("email", "jane@example.com", "password", "newpass123"))))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode signinJson = objectMapper.readTree(signin.getResponse().getContentAsString());
        assertThat(signinJson.has("token")).isTrue();
        assertThat(signinJson.get("email").asText()).isEqualTo("jane@example.com");
    }

    @Test
    void resetPassword_withInvalidToken_returnsBadRequest() throws Exception {
        var resp = mockMvc.perform(post("/api/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(asJson(java.util.Map.of("token", "invalid-token", "newPassword", "whatever123"))))
                .andExpect(status().isBadRequest())
                .andReturn();
        JsonNode json = objectMapper.readTree(resp.getResponse().getContentAsString());
        assertThat(json.get("message").asText()).contains("Invalid");
    }
}
