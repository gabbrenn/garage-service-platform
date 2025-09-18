package com.garageservice.controller;

import com.garageservice.dto.ServiceRequestDto;
import com.garageservice.model.Garage;
import com.garageservice.model.GarageService;
import com.garageservice.model.ServiceRequest;
import com.garageservice.dto.ServiceRequestResponseDto;
import com.garageservice.model.User;
import com.garageservice.repository.GarageRepository;
import com.garageservice.service.NotificationService;
import org.springframework.messaging.simp.SimpMessagingTemplate;
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
    @Autowired
    private NotificationService notificationService;
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

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
    // Notify garage owner
    User garageOwner = garage.get().getUser();
    var createdNotif = notificationService.create(garageOwner, "New Service Request", "A new request #"+savedRequest.getId()+" has been created by "+customer.getFirstName());
    messagingTemplate.convertAndSend("/topic/notifications."+garageOwner.getId(), java.util.Map.of("type","CREATED","id", createdNotif.getId()));
        ServiceRequestResponseDto dto = new ServiceRequestResponseDto(
            savedRequest.getId(),
            savedRequest.getCustomer().getEmail(),
            savedRequest.getCustomer().getFirstName() + " " + savedRequest.getCustomer().getLastName(),
            savedRequest.getCustomer().getPhoneNumber(),
            savedRequest.getGarage().getName(),
            savedRequest.getGarage().getAddress(),
            savedRequest.getGarage().getDescription(),
            savedRequest.getService().getName(),
            savedRequest.getService().getDescription(),
            savedRequest.getService().getPrice(),
            savedRequest.getDescription(),
            savedRequest.getCreatedAt(),
            savedRequest.getStatus() != null ? savedRequest.getStatus().name() : null,
            savedRequest.getGarageResponse(),
            savedRequest.getEstimatedArrivalMinutes(),
            savedRequest.getCustomerAddress(),
            savedRequest.getCustomerLatitude(),
            savedRequest.getCustomerLongitude()
        );
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/my-requests")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<List<ServiceRequestResponseDto>> getMyRequests(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        List<ServiceRequest> requests = serviceRequestRepository.findByCustomerIdOrderByCreatedAtDesc(userPrincipal.getId());
        
        List<ServiceRequestResponseDto> dtoList = requests.stream().map(req -> 
            new ServiceRequestResponseDto(
                req.getId(),
                req.getCustomer().getEmail(),
                req.getCustomer().getFirstName() + " " + req.getCustomer().getLastName(),
                req.getCustomer().getPhoneNumber(),
                req.getGarage().getName(),
                req.getGarage().getAddress(),
                req.getGarage().getDescription(),
                req.getService().getName(),
                req.getService().getDescription(),
                req.getService().getPrice(),
                req.getDescription(),
                req.getCreatedAt(),
                req.getStatus() != null ? req.getStatus().name() : null,
                req.getGarageResponse(),
                req.getEstimatedArrivalMinutes(),
                req.getCustomerAddress(),
                req.getCustomerLatitude(),
                req.getCustomerLongitude()
            )
        ).toList();

        return ResponseEntity.ok(dtoList);
        // return ResponseEntity.ok(requests);
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
        List<ServiceRequestResponseDto> dtoList = requests.stream().map(req -> 
            new ServiceRequestResponseDto(
                req.getId(),
                req.getCustomer().getEmail(),
                req.getCustomer().getFirstName() + " " + req.getCustomer().getLastName(),
                req.getCustomer().getPhoneNumber(),
                req.getGarage().getName(),
                req.getGarage().getAddress(),
                req.getGarage().getDescription(),
                req.getService().getName(),
                req.getService().getDescription(),
                req.getService().getPrice(),
                req.getDescription(),
                req.getCreatedAt(),
                req.getStatus() != null ? req.getStatus().name() : null,
                req.getGarageResponse(),
                req.getEstimatedArrivalMinutes(),
                req.getCustomerAddress(),
                req.getCustomerLatitude(),
                req.getCustomerLongitude()
            )
        ).toList();

        return ResponseEntity.ok(dtoList);
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
    // Notify customer
    var createdNotif = notificationService.create(updatedRequest.getCustomer(), "Request Updated", "Your request #"+updatedRequest.getId()+" status is now "+updatedRequest.getStatus());
    messagingTemplate.convertAndSend("/topic/notifications."+updatedRequest.getCustomer().getId(), java.util.Map.of("type","CREATED","id", createdNotif.getId()));
        ServiceRequestResponseDto dto = new ServiceRequestResponseDto(
            updatedRequest.getId(),
            updatedRequest.getCustomer().getEmail(),
            updatedRequest.getCustomer().getFirstName() + " " + updatedRequest.getCustomer().getLastName(),
            updatedRequest.getCustomer().getPhoneNumber(),
            updatedRequest.getGarage().getName(),
            updatedRequest.getGarage().getAddress(),
            updatedRequest.getGarage().getDescription(),
            updatedRequest.getService().getName(),
            updatedRequest.getService().getDescription(),
            updatedRequest.getService().getPrice(),
            updatedRequest.getDescription(),
            updatedRequest.getCreatedAt(),
            updatedRequest.getStatus() != null ? updatedRequest.getStatus().name() : null,
            updatedRequest.getGarageResponse(),
            updatedRequest.getEstimatedArrivalMinutes(),
            updatedRequest.getCustomerAddress(),
            updatedRequest.getCustomerLatitude(),
            updatedRequest.getCustomerLongitude()
        );
        return ResponseEntity.ok(dto);
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