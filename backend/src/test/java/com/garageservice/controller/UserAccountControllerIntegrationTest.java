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
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
        "app.jwtSecret=testSecretKeyThatIsLongEnoughForHS256",
        "app.jwtExpirationMs=60000",
        "app.jwtRefreshExpirationMs=120000",
        "app.mail.provider=noop",
        "app.mail.enabled=false"
})
public class UserAccountControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private ObjectMapper objectMapper;

    private String accessToken;
    private String email;

    @BeforeEach
    void setup() throws Exception {
        email = "delete_me@example.com";
        userRepository.findByEmail(email).ifPresent(u -> userRepository.delete(u));
        User user = new User("Del","User", email, "0000000000", passwordEncoder.encode("Password1!"), User.UserType.CUSTOMER);
        userRepository.save(user);

        String body = objectMapper.writeValueAsString(java.util.Map.of(
                "email", email,
                "password", "Password1!"
        ));
        String response = mockMvc.perform(post("/api/auth/signin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        accessToken = objectMapper.readTree(response).get("token").asText();
        assertThat(accessToken).isNotBlank();
    }

    @Test
    void deleteAccount_deletesAuthenticatedUser() throws Exception {
        // Call DELETE /api/account
        mockMvc.perform(delete("/api/account")
                        .header("Authorization", "Bearer " + accessToken))
                .andExpect(status().isOk());

        // Ensure user no longer exists
        assertThat(userRepository.findByEmail(email)).isEmpty();
    }
}
