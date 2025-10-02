package com.garageservice.controller;

import com.garageservice.security.UserPrincipal;
import com.garageservice.service.AccountDeletionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/account")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UserAccountController {
    private final AccountDeletionService accountDeletionService;

    public UserAccountController(AccountDeletionService accountDeletionService) {
        this.accountDeletionService = accountDeletionService;
    }

    @DeleteMapping
    public ResponseEntity<?> deleteMyAccount(@AuthenticationPrincipal UserPrincipal me) {
        if (me == null) return ResponseEntity.status(401).body(java.util.Map.of("message","Unauthorized"));
        accountDeletionService.deleteUserAndCleanup(me.getId());
        return ResponseEntity.ok(java.util.Map.of("message","Account deleted"));
    }
}
