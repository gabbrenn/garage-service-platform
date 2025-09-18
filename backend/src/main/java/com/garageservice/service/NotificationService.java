package com.garageservice.service;

import com.garageservice.model.Notification;
import com.garageservice.model.User;
import com.garageservice.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class NotificationService {
    @Autowired
    private NotificationRepository notificationRepository;

    public Notification create(User user, String title, String message){
        Notification n = new Notification(user, title, message);
        return notificationRepository.save(n);
    }

    public List<Notification> forUser(Long userId){
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public Optional<Notification> findById(Long id){ return notificationRepository.findById(id); }

    public long unreadCount(Long userId){ return notificationRepository.countByUserIdAndReadFlagFalse(userId); }

    public Notification save(Notification n){ return notificationRepository.save(n); }

    public List<Notification> saveAll(List<Notification> list){ return notificationRepository.saveAll(list); }
}
