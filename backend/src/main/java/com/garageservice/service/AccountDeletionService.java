package com.garageservice.service;

import com.garageservice.model.*;
import com.garageservice.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountDeletionService {
    private final UserRepository userRepository;
    private final DeviceTokenRepository deviceTokenRepository;
    private final NotificationRepository notificationRepository;
    private final ServiceRequestRepository serviceRequestRepository;
    private final GarageRepository garageRepository;

    public AccountDeletionService(UserRepository userRepository,
                                  DeviceTokenRepository deviceTokenRepository,
                                  NotificationRepository notificationRepository,
                                  ServiceRequestRepository serviceRequestRepository,
                                  GarageRepository garageRepository) {
        this.userRepository = userRepository;
        this.deviceTokenRepository = deviceTokenRepository;
        this.notificationRepository = notificationRepository;
        this.serviceRequestRepository = serviceRequestRepository;
        this.garageRepository = garageRepository;
    }

    @Transactional
    public void deleteUserAndCleanup(Long userId) {
        var userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) return;
        var user = userOpt.get();

        // 1) Delete notifications linked to user
        notificationRepository.deleteAll(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId));

        // 2) Delete device tokens linked to user
    deviceTokenRepository.deleteAll(deviceTokenRepository.findByUser(user));

        // 3) Detach user from service requests as customer
        for (var req : serviceRequestRepository.findByCustomerId(userId)) {
            req.setCustomer(null);
            serviceRequestRepository.save(req);
        }

        // 4) If user owns a garage, delete it (cascade to services/requests per mapping)
        var garage = user.getGarage();
        if (garage != null) {
            // Break the user<->garage link first to avoid constraint issues
            garage.setUser(null);
            garageRepository.save(garage);
            // Null-out garage reference on any service requests pointing to this garage
            for (var req : serviceRequestRepository.findByGarageId(garage.getId())) {
                req.setGarage(null);
                serviceRequestRepository.save(req);
            }
            garageRepository.delete(garage);
        }

        // 5) Finally delete the user
        userRepository.delete(user);
    }
}
