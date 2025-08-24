package com.garageservice.dto;

import jakarta.validation.constraints.NotNull;

public class ServiceRequestDto {
    @NotNull
    private Long garageId;

    @NotNull
    private Long serviceId;

    @NotNull
    private Double customerLatitude;

    @NotNull
    private Double customerLongitude;

    private String customerAddress;
    private String description;

    public ServiceRequestDto() {}

    public ServiceRequestDto(Long garageId, Long serviceId, Double customerLatitude, Double customerLongitude, String customerAddress, String description) {
        this.garageId = garageId;
        this.serviceId = serviceId;
        this.customerLatitude = customerLatitude;
        this.customerLongitude = customerLongitude;
        this.customerAddress = customerAddress;
        this.description = description;
    }

    // Getters and Setters
    public Long getGarageId() { return garageId; }
    public void setGarageId(Long garageId) { this.garageId = garageId; }

    public Long getServiceId() { return serviceId; }
    public void setServiceId(Long serviceId) { this.serviceId = serviceId; }

    public Double getCustomerLatitude() { return customerLatitude; }
    public void setCustomerLatitude(Double customerLatitude) { this.customerLatitude = customerLatitude; }

    public Double getCustomerLongitude() { return customerLongitude; }
    public void setCustomerLongitude(Double customerLongitude) { this.customerLongitude = customerLongitude; }

    public String getCustomerAddress() { return customerAddress; }
    public void setCustomerAddress(String customerAddress) { this.customerAddress = customerAddress; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}