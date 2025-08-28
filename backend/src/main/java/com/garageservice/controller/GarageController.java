package com.garageservice.controller;

import com.garageservice.dto.GarageRequest;
import com.garageservice.model.Garage;
import com.garageservice.model.GarageService;
import com.garageservice.model.User;
import com.garageservice.repository.GarageRepository;
import com.garageservice.repository.GarageServiceRepository;
import com.garageservice.repository.UserRepository;
import com.garageservice.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/garages")
public class GarageController {

    @Autowired
    private GarageRepository garageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private GarageServiceRepository garageServiceRepository;

    @PostMapping
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> createGarage(@Valid @RequestBody GarageRequest garageRequest, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User user = userRepository.findById(userPrincipal.getId()).orElse(null);

        if (user == null) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "User not found");
            return ResponseEntity.badRequest().body(response);
        }

        // Check if user already has a garage
        Optional<Garage> existingGarage = garageRepository.findByUserId(user.getId());
        if (existingGarage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "User already has a garage");
            return ResponseEntity.badRequest().body(response);
        }

        Garage garage = new Garage(
                garageRequest.getName(),
                garageRequest.getAddress(),
                garageRequest.getLatitude(),
                garageRequest.getLongitude(),
                garageRequest.getDescription(),
                garageRequest.getWorkingHours(),
                user
        );

        Garage savedGarage = garageRepository.save(garage);
        return ResponseEntity.ok(savedGarage);
    }

    @GetMapping("/my-garage")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> getMyGarage(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (garage.isPresent()) {
            return ResponseEntity.ok(garage.get());
        } else {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/my-garage")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> updateMyGarage(@Valid @RequestBody GarageRequest garageRequest, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garageOpt = garageRepository.findByUserId(userPrincipal.getId());

        if (!garageOpt.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        Garage garage = garageOpt.get();
        garage.setName(garageRequest.getName());
        garage.setAddress(garageRequest.getAddress());
        garage.setLatitude(garageRequest.getLatitude());
        garage.setLongitude(garageRequest.getLongitude());
        garage.setDescription(garageRequest.getDescription());
        garage.setWorkingHours(garageRequest.getWorkingHours());

        Garage updated = garageRepository.save(garage);
        return ResponseEntity.ok(updated);
    }

    @GetMapping("/nearby")
    public ResponseEntity<List<Garage>> getNearbyGarages(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "10.0") Double radiusKm) {
        
        List<Garage> nearbyGarages = garageRepository.findGaragesWithinRadius(latitude, longitude, radiusKm);
        return ResponseEntity.ok(nearbyGarages);
    }

    @GetMapping("/{garageId}/services")
    public ResponseEntity<List<GarageService>> getGarageServices(@PathVariable Long garageId) {
        List<GarageService> services = garageServiceRepository.findByGarageId(garageId);
        return ResponseEntity.ok(services);
    }

    @GetMapping
    public ResponseEntity<List<Garage>> getAllGarages() {
        List<Garage> garages = garageRepository.findAll();
        return ResponseEntity.ok(garages);
    }
}