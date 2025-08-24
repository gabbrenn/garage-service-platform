package com.garageservice.repository;

import com.garageservice.model.Garage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GarageRepository extends JpaRepository<Garage, Long> {
    Optional<Garage> findByUserId(Long userId);
    
    @Query("SELECT g FROM Garage g WHERE " +
           "(6371 * acos(cos(radians(:latitude)) * cos(radians(g.latitude)) * " +
           "cos(radians(g.longitude) - radians(:longitude)) + " +
           "sin(radians(:latitude)) * sin(radians(g.latitude)))) <= :radiusKm")
    List<Garage> findGaragesWithinRadius(@Param("latitude") Double latitude, 
                                        @Param("longitude") Double longitude, 
                                        @Param("radiusKm") Double radiusKm);
}