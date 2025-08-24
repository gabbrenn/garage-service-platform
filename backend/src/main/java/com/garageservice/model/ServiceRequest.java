package com.garageservice.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.time.LocalDateTime;

@Entity
@Table(name = "service_requests")
public class ServiceRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    @JsonIgnore
    private User customer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "garage_id")
    @JsonIgnore
    private Garage garage;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id")
    private GarageService service;

    @NotNull
    private Double customerLatitude;

    @NotNull
    private Double customerLongitude;

    private String customerAddress;
    private String description;
    private String garageResponse;
    private Integer estimatedArrivalMinutes;

    @Enumerated(EnumType.STRING)
    private RequestStatus status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public ServiceRequest() {
        this.status = RequestStatus.PENDING;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public ServiceRequest(User customer, Garage garage, GarageService service, Double customerLatitude, 
                         Double customerLongitude, String customerAddress, String description) {
        this.customer = customer;
        this.garage = garage;
        this.service = service;
        this.customerLatitude = customerLatitude;
        this.customerLongitude = customerLongitude;
        this.customerAddress = customerAddress;
        this.description = description;
        this.status = RequestStatus.PENDING;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getCustomer() { return customer; }
    public void setCustomer(User customer) { this.customer = customer; }

    public Garage getGarage() { return garage; }
    public void setGarage(Garage garage) { this.garage = garage; }

    public GarageService getService() { return service; }
    public void setService(GarageService service) { this.service = service; }

    public Double getCustomerLatitude() { return customerLatitude; }
    public void setCustomerLatitude(Double customerLatitude) { this.customerLatitude = customerLatitude; }

    public Double getCustomerLongitude() { return customerLongitude; }
    public void setCustomerLongitude(Double customerLongitude) { this.customerLongitude = customerLongitude; }

    public String getCustomerAddress() { return customerAddress; }
    public void setCustomerAddress(String customerAddress) { this.customerAddress = customerAddress; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getGarageResponse() { return garageResponse; }
    public void setGarageResponse(String garageResponse) { this.garageResponse = garageResponse; }

    public Integer getEstimatedArrivalMinutes() { return estimatedArrivalMinutes; }
    public void setEstimatedArrivalMinutes(Integer estimatedArrivalMinutes) { this.estimatedArrivalMinutes = estimatedArrivalMinutes; }

    public RequestStatus getStatus() { return status; }
    public void setStatus(RequestStatus status) { 
        this.status = status; 
        this.updatedAt = LocalDateTime.now();
    }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public enum RequestStatus {
        PENDING, ACCEPTED, REJECTED, IN_PROGRESS, COMPLETED, CANCELLED
    }
}