package com.garageservice.repository;

import com.garageservice.model.GarageService;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GarageServiceRepository extends JpaRepository<GarageService, Long> {
    List<GarageService> findByGarageId(Long garageId);
}