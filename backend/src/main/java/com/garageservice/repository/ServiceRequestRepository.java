package com.garageservice.repository;

import com.garageservice.model.ServiceRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceRequestRepository extends JpaRepository<ServiceRequest, Long> {
    List<ServiceRequest> findByCustomerId(Long customerId);
    List<ServiceRequest> findByGarageId(Long garageId);
    List<ServiceRequest> findByGarageIdOrderByCreatedAtDesc(Long garageId);
    List<ServiceRequest> findByCustomerIdOrderByCreatedAtDesc(Long customerId);
}