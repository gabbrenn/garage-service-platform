package com.garageservice.service;

import com.garageservice.model.DeviceToken;
import com.garageservice.model.User;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.ApnsConfig;
import com.google.firebase.messaging.Aps;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.FirebaseMessaging;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class FcmSenderService {

    @Autowired
    private DeviceTokenService deviceTokenService;

    private boolean isInitialized(){
        return !FirebaseApp.getApps().isEmpty();
    }

    public int sendToUser(User user, String title, String body, Map<String,String> data){
        if(!isInitialized()) return 0;
        List<DeviceToken> tokens = deviceTokenService.tokensFor(user);
        int success = 0;
        for (DeviceToken t : tokens) {
            try {
                Message msg = Message.builder()
                        .setToken(t.getToken())
                        .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                        .putAllData(data)
                        .setAndroidConfig(AndroidConfig.builder().setPriority(AndroidConfig.Priority.HIGH).build())
                        .setApnsConfig(ApnsConfig.builder().setAps(Aps.builder().setSound("default").build()).build())
                        .build();
                FirebaseMessaging.getInstance().send(msg);
                success++;
            } catch (Exception e){
                System.err.println("[FcmSender] Failed to send to token: " + t.getToken() + ": " + e.getMessage());
            }
        }
        return success;
    }

    /**
     * Convenience: send with optional channelId/sound/urgent flags.
     * These will be injected into the data payload for the client to pick a channel and custom sound.
     */
    public int sendToUser(User user, String title, String body, Map<String,String> data,
                          String channelId, String sound, boolean urgent){
        if (data == null) data = new java.util.HashMap<>();
        if (channelId != null && !channelId.isBlank()) data.put("channelId", channelId);
        if (sound != null && !sound.isBlank()) data.put("sound", sound);
        if (urgent) data.put("urgent", "true");
        return sendToUser(user, title, body, data);
    }
}
