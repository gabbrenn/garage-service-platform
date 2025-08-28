package com.garageservice.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class ServiceRequestResponseDto {
    private Long id;
    private String customerEmail;
    private String customerName;
    private String customerPhone;
    private String garageName;
    private String garageAddress;
    private String garagePhone;
    private String serviceName;
    private String serviceDescription;
    private Double servicePrice;
    private String description;
    private LocalDateTime createdAt;
    private String status;
    private String garageResponse;
    private Integer estimatedArrivalMinutes;
    private String customerAddress;
    private Double customerLatitude;
    private Double customerLongitude;

    public ServiceRequestResponseDto(Long id, String customerEmail, String customerName, String customerPhone,
            String garageName, String garageAddress, String garagePhone,
            String serviceName, String serviceDescription, BigDecimal servicePrice,
            String description, LocalDateTime createdAt, String status, String garageResponse,
            Integer estimatedArrivalMinutes) {
        this.id = id;
        this.customerEmail = customerEmail;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.garageName = garageName;
        this.garageAddress = garageAddress;
        this.garagePhone = garagePhone;
        this.serviceName = serviceName;
        this.serviceDescription = serviceDescription;
        this.servicePrice = servicePrice != null ? servicePrice.doubleValue() : null;
        this.description = description;
        this.createdAt = createdAt;
        this.status = status != null ? status.toString() : null;
        this.garageResponse = garageResponse;
        this.estimatedArrivalMinutes = estimatedArrivalMinutes;
    }

    public ServiceRequestResponseDto(Long id, String customerEmail, String customerName, String customerPhone,
            String garageName, String garageAddress, String garagePhone,
            String serviceName, String serviceDescription, BigDecimal servicePrice,
            String description, LocalDateTime createdAt, String status, String garageResponse,
            Integer estimatedArrivalMinutes, String customerAddress, Double customerLatitude, Double customerLongitude) {
        this.id = id;
        this.customerEmail = customerEmail;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.garageName = garageName;
        this.garageAddress = garageAddress;
        this.garagePhone = garagePhone;
        this.serviceName = serviceName;
        this.serviceDescription = serviceDescription;
        this.servicePrice = servicePrice != null ? servicePrice.doubleValue() : null;
        this.description = description;
        this.createdAt = createdAt;
        this.status = status != null ? status.toString() : null;
        this.garageResponse = garageResponse;
        this.estimatedArrivalMinutes = estimatedArrivalMinutes;
        this.customerAddress = customerAddress;
        this.customerLatitude = customerLatitude;
        this.customerLongitude = customerLongitude;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }

    public String getGarageName() { return garageName; }
    public void setGarageName(String garageName) { this.garageName = garageName; }

    public String getGarageAddress() { return garageAddress; }
    public void setGarageAddress(String garageAddress) { this.garageAddress = garageAddress; }

    public String getGaragePhone() { return garagePhone; }
    public void setGaragePhone(String garagePhone) { this.garagePhone = garagePhone; }

    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }

    public String getServiceDescription() { return serviceDescription; }
    public void setServiceDescription(String serviceDescription) { this.serviceDescription = serviceDescription; }

    public Double getServicePrice() { return servicePrice; }
    public void setServicePrice(Double servicePrice) { this.servicePrice = servicePrice; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getGarageResponse() { return garageResponse; }
    public void setGarageResponse(String garageResponse) { this.garageResponse = garageResponse; }

    public Integer getEstimatedArrivalMinutes() { return estimatedArrivalMinutes; }
    public void setEstimatedArrivalMinutes(Integer estimatedArrivalMinutes) { this.estimatedArrivalMinutes = estimatedArrivalMinutes; }

    public String getCustomerAddress() { return customerAddress; }
    public void setCustomerAddress(String customerAddress) { this.customerAddress = customerAddress; }

    public Double getCustomerLatitude() { return customerLatitude; }
    public void setCustomerLatitude(Double customerLatitude) { this.customerLatitude = customerLatitude; }

    public Double getCustomerLongitude() { return customerLongitude; }
    public void setCustomerLongitude(Double customerLongitude) { this.customerLongitude = customerLongitude; }
}
