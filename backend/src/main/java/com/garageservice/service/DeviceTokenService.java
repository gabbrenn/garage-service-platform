package com.garageservice.service;

import com.garageservice.model.DeviceToken;
import com.garageservice.model.User;
import com.garageservice.repository.DeviceTokenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DeviceTokenService {
    @Autowired
    private DeviceTokenRepository deviceTokenRepository;

    public DeviceToken register(User user, String token, String platform){
        Optional<DeviceToken> existing = deviceTokenRepository.findByToken(token);
        DeviceToken dt = existing.orElseGet(() -> new DeviceToken(user, token, platform));
        dt.setUser(user);
        dt.setPlatform(platform);
        return deviceTokenRepository.save(dt);
    }

    public void removeByToken(String token){
        deviceTokenRepository.deleteByToken(token);
    }

    public List<DeviceToken> tokensFor(User user){
        return deviceTokenRepository.findByUser(user);
    }

    public Optional<DeviceToken> findByToken(String token){
        return deviceTokenRepository.findByToken(token);
    }

    public void delete(DeviceToken token){
        deviceTokenRepository.delete(token);
    }
}
