package com.garageservice.controller;

import com.garageservice.dto.ServiceRequestDto;
import com.garageservice.model.Garage;
import com.garageservice.model.GarageService;
import com.garageservice.model.ServiceRequest;
import com.garageservice.model.User;
import com.garageservice.repository.GarageRepository;
import com.garageservice.repository.GarageServiceRepository;
import com.garageservice.repository.ServiceRequestRepository;
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
@RequestMapping("/api/service-requests")
public class ServiceRequestController {

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private GarageRepository garageRepository;

    @Autowired
    private GarageServiceRepository garageServiceRepository;

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<?> createServiceRequest(@Valid @RequestBody ServiceRequestDto requestDto, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        User customer = userRepository.findById(userPrincipal.getId()).orElse(null);

        if (customer == null) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Customer not found");
            return ResponseEntity.badRequest().body(response);
        }

        Optional<Garage> garage = garageRepository.findById(requestDto.getGarageId());
        Optional<GarageService> service = garageServiceRepository.findById(requestDto.getServiceId());

        if (!garage.isPresent() || !service.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Garage or service not found");
            return ResponseEntity.badRequest().body(response);
        }

        ServiceRequest serviceRequest = new ServiceRequest(
                customer,
                garage.get(),
                service.get(),
                requestDto.getCustomerLatitude(),
                requestDto.getCustomerLongitude(),
                requestDto.getCustomerAddress(),
                requestDto.getDescription()
        );

        ServiceRequest savedRequest = serviceRequestRepository.save(serviceRequest);
        return ResponseEntity.ok(savedRequest);
    }

    @GetMapping("/my-requests")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<ServiceRequest>> getMyRequests(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        List<ServiceRequest> requests = serviceRequestRepository.findByCustomerIdOrderByCreatedAtDesc(userPrincipal.getId());
        return ResponseEntity.ok(requests);
    }

    @GetMapping("/garage-requests")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> getGarageRequests(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        List<ServiceRequest> requests = serviceRequestRepository.findByGarageIdOrderByCreatedAtDesc(garage.get().getId());
        return ResponseEntity.ok(requests);
    }

    @PutMapping("/{requestId}/respond")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> respondToRequest(@PathVariable Long requestId, @RequestBody ResponseDto responseDto, Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garage = garageRepository.findByUserId(userPrincipal.getId());

        if (!garage.isPresent()) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No garage found for this user");
            return ResponseEntity.badRequest().body(response);
        }

        Optional<ServiceRequest> serviceRequest = serviceRequestRepository.findById(requestId);
        if (!serviceRequest.isPresent() || !serviceRequest.get().getGarage().getId().equals(garage.get().getId())) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Service request not found or not for this garage");
            return ResponseEntity.badRequest().body(response);
        }

        ServiceRequest request = serviceRequest.get();
        request.setStatus(responseDto.getStatus());
        request.setGarageResponse(responseDto.getResponse());
        request.setEstimatedArrivalMinutes(responseDto.getEstimatedArrivalMinutes());

        ServiceRequest updatedRequest = serviceRequestRepository.save(request);
        return ResponseEntity.ok(updatedRequest);
    }

    public static class ResponseDto {
        private ServiceRequest.RequestStatus status;
        private String response;
        private Integer estimatedArrivalMinutes;

        // Getters and Setters
        public ServiceRequest.RequestStatus getStatus() { return status; }
        public void setStatus(ServiceRequest.RequestStatus status) { this.status = status; }

        public String getResponse() { return response; }
        public void setResponse(String response) { this.response = response; }

        public Integer getEstimatedArrivalMinutes() { return estimatedArrivalMinutes; }
        public void setEstimatedArrivalMinutes(Integer estimatedArrivalMinutes) { this.estimatedArrivalMinutes = estimatedArrivalMinutes; }
    }
}