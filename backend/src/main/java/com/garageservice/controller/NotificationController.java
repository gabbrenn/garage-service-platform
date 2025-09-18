package com.garageservice.controller;

import com.garageservice.model.Notification;
import com.garageservice.service.NotificationService;
import com.garageservice.service.DeviceTokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    @Autowired
    private DeviceTokenService deviceTokenService;
    @Autowired
    private com.garageservice.service.FcmSenderService fcmSenderService;

    @GetMapping("/my")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> myNotifications(Authentication authentication){
        Long userId = resolveUserId(authentication);
        List<Notification> list = notificationService.forUser(userId);
        return ResponseEntity.ok(list.stream().map(this::toDto).toList());
    }

    @PutMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> markRead(@PathVariable Long id, Authentication authentication){
        Long userId = resolveUserId(authentication);
        return notificationService.findById(id)
                .filter(n -> n.getUser().getId().equals(userId))
                .map(n -> {
                    n.setReadFlag(true);
                    notificationService.save(n);
                    publishEvent(userId, "READ", n.getId());
                    return ResponseEntity.ok(toDto(n));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/mark-all-read")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> markAll(Authentication authentication){
        Long userId = resolveUserId(authentication);
        List<Notification> list = notificationService.forUser(userId);
        list.forEach(n -> n.setReadFlag(true));
        notificationService.saveAll(list);
        Map<String,Object> resp = new HashMap<>();
        resp.put("updated", list.size());
        publishEvent(userId, "READ_ALL", null);
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/register-token")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> registerToken(@RequestBody Map<String,String> body, Authentication authentication){
        Long userId = resolveUserId(authentication);
        String token = body.getOrDefault("deviceToken", "").trim();
        String platform = body.getOrDefault("platform", "");
        if(token.isEmpty()){
            Map<String,Object> err = new HashMap<>();
            err.put("message", "deviceToken is required");
            return ResponseEntity.badRequest().body(err);
        }
        var user = new com.garageservice.model.User();
        user.setId(userId);
        deviceTokenService.register(user, token, platform);
        Map<String,Object> ok = new HashMap<>();
        ok.put("status", "ok");
        return ResponseEntity.ok(ok);
    }

    @DeleteMapping("/remove-token")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> removeToken(@RequestParam("deviceToken") String token, Authentication authentication){
        Long userId = resolveUserId(authentication);
        var opt = deviceTokenService.findByToken(token);
        if(opt.isEmpty()){
            return ResponseEntity.ok(Map.of("status","ok"));
        }
        var dt = opt.get();
        if(dt.getUser() == null || dt.getUser().getId().equals(userId)){
            deviceTokenService.delete(dt);
            return ResponseEntity.ok(Map.of("status","ok"));
        }
        return ResponseEntity.status(403).body(Map.of("message","Forbidden"));
    }

    @PostMapping("/test-push")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> testPush(Authentication authentication){
        Long userId = resolveUserId(authentication);
        com.garageservice.model.User u = new com.garageservice.model.User();
        u.setId(userId);
        int sent = fcmSenderService.sendToUser(u, "Test Notification", "Hello from backend", Map.of("type","TEST"));
        return ResponseEntity.ok(Map.of("sent", sent));
    }

    @PostMapping("/test-push-custom")
    @PreAuthorize("hasAnyRole('CUSTOMER','GARAGE_OWNER')")
    public ResponseEntity<?> testPushCustom(@RequestBody Map<String,String> body, Authentication authentication){
        Long userId = resolveUserId(authentication);
        com.garageservice.model.User u = new com.garageservice.model.User();
        u.setId(userId);
        String title = body.getOrDefault("title", "Custom Test");
        String message = body.getOrDefault("message", "Hello with custom sound/channel");
        String channelId = body.getOrDefault("channelId", "");
        String sound = body.getOrDefault("sound", "");
        boolean urgent = Boolean.parseBoolean(body.getOrDefault("urgent", "false"));
        java.util.Map<String,String> data = new java.util.HashMap<>();
        data.put("type", "TEST");
        int sent = fcmSenderService.sendToUser(u, title, message, data, channelId, sound, urgent);
        return ResponseEntity.ok(Map.of("sent", sent));
    }

    private Long resolveUserId(Authentication authentication) {
        // Prefer principal id if available; otherwise derive from name/email as needed.
        Object principal = authentication.getPrincipal();
        try {
            // Avoid compile-time dependency; use reflection if it's our UserPrincipal
            Class<?> upClass = Class.forName("com.garageservice.security.UserPrincipal");
            if (upClass.isInstance(principal)) {
                var method = upClass.getMethod("getId");
                Object id = method.invoke(principal);
                if (id instanceof Long l) return l;
            }
        } catch (Exception ignore) {
            // Fall through
        }
        // Fallback: if principal is a username/email, service layer methods that require id must be adjusted accordingly in future.
        // For now, return null-safe invalid id to avoid NPE.
        return -1L;
    }

    private void publishEvent(Long userId, String type, Long notificationId){
        Map<String,Object> payload = new HashMap<>();
        payload.put("type", type);
        if(notificationId != null) payload.put("id", notificationId);
        messagingTemplate.convertAndSend("/topic/notifications." + userId, payload);
    }

    private Map<String,Object> toDto(Notification n){
        Map<String,Object> m = new HashMap<>();
        m.put("id", n.getId());
        m.put("title", n.getTitle());
        m.put("message", n.getMessage());
        m.put("read", n.isReadFlag());
        m.put("createdAt", n.getCreatedAt());
        return m;
    }
}
