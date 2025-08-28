package com.garageservice.controller;

import com.garageservice.model.Garage;
import com.garageservice.model.GarageService;
import com.garageservice.repository.GarageRepository;
import com.garageservice.repository.GarageServiceRepository;
import com.garageservice.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/services")
public class ServiceController {

    @Autowired
    private GarageServiceRepository garageServiceRepository;

    @Autowired
    private GarageRepository garageRepository;

    @PostMapping
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> createService(@Valid @RequestBody ServiceRequest serviceRequest, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        GarageService service = new GarageService(
                serviceRequest.getName(),
                serviceRequest.getDescription(),
                serviceRequest.getPrice(),
                serviceRequest.getEstimatedDurationMinutes(),
                garage.get()
        );

        GarageService savedService = garageServiceRepository.save(service);
        return ResponseEntity.ok(savedService);
    }

    @GetMapping("/my-services")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> getMyServices(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        List<GarageService> services = garageServiceRepository.findByGarageId(garage.get().getId());
        return ResponseEntity.ok(services);
    }

    @DeleteMapping("/{serviceId}")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> deleteService(@PathVariable Long serviceId, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        Optional<GarageService> service = garageServiceRepository.findById(serviceId);
        if (!service.isPresent() || !service.get().getGarage().getId().equals(garage.get().getId())) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Service not found or not owned by this garage");
            return ResponseEntity.badRequest().body(response);
        }

        garageServiceRepository.deleteById(serviceId);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Service deleted successfully");
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{serviceId}")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> updateService(@PathVariable Long serviceId, @Valid @RequestBody ServiceRequest serviceRequest, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> resp = new HashMap<>();
            resp.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(resp);
        }

        Optional<GarageService> service = garageServiceRepository.findById(serviceId);
        if (!service.isPresent() || !service.get().getGarage().getId().equals(garage.get().getId())) {
            Map<String, String> resp = new HashMap<>();
            resp.put("message", "Service not found or not owned by this garage");
            return ResponseEntity.badRequest().body(resp);
        }

        GarageService existing = service.get();
        if (serviceRequest.getName() != null) existing.setName(serviceRequest.getName());
        existing.setDescription(serviceRequest.getDescription());
        if (serviceRequest.getPrice() != null) existing.setPrice(serviceRequest.getPrice());
        existing.setEstimatedDurationMinutes(serviceRequest.getEstimatedDurationMinutes());

        GarageService updated = garageServiceRepository.save(existing);
        return ResponseEntity.ok(updated);
    }

    public static class ServiceRequest {
        private String name;
        private String description;
        private BigDecimal price;
        private Integer estimatedDurationMinutes;

        // Getters and Setters
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }

        public BigDecimal getPrice() { return price; }
        public void setPrice(BigDecimal price) { this.price = price; }

        public Integer getEstimatedDurationMinutes() { return estimatedDurationMinutes; }
        public void setEstimatedDurationMinutes(Integer estimatedDurationMinutes) { this.estimatedDurationMinutes = estimatedDurationMinutes; }
    }
}