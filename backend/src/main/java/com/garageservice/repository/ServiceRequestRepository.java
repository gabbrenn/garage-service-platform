package com.garageservice.repository;

import com.garageservice.model.ServiceRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceRequestRepository extends JpaRepository<ServiceRequest, Long> {
    List<ServiceRequest> findByCustomerId(Long customerId);
    List<ServiceRequest> findByGarageId(Long garageId);
    List<ServiceRequest> findByGarageIdOrderByCreatedAtDesc(Long garageId);
    List<ServiceRequest> findByCustomerIdOrderByCreatedAtDesc(Long customerId);

    // Daily aggregated counts per status for a garage between date range (inclusive)
    @Query("SELECT DATE(sr.createdAt) as day, sr.status as status, COUNT(sr) as count " +
        "FROM ServiceRequest sr WHERE sr.garage.id = :garageId " +
        "AND sr.createdAt BETWEEN :from AND :to " +
        "GROUP BY DATE(sr.createdAt), sr.status ORDER BY day DESC")
    List<Object[]> findDailyStatusCounts(@Param("garageId") Long garageId,
                          @Param("from") java.time.LocalDateTime from,
                          @Param("to") java.time.LocalDateTime to);

    // Average estimated arrival minutes per day if provided
    @Query("SELECT DATE(sr.createdAt) as day, AVG(sr.estimatedArrivalMinutes) as avgEta " +
        "FROM ServiceRequest sr WHERE sr.garage.id = :garageId AND sr.estimatedArrivalMinutes IS NOT NULL " +
        "AND sr.createdAt BETWEEN :from AND :to GROUP BY DATE(sr.createdAt) ORDER BY day DESC")
    List<Object[]> findDailyAverageEta(@Param("garageId") Long garageId,
                        @Param("from") java.time.LocalDateTime from,
                        @Param("to") java.time.LocalDateTime to);

    // Overall average estimated arrival minutes for a garage within date range
    @Query("SELECT AVG(sr.estimatedArrivalMinutes) FROM ServiceRequest sr WHERE sr.garage.id = :garageId " +
        "AND sr.estimatedArrivalMinutes IS NOT NULL AND sr.createdAt BETWEEN :from AND :to")
    Double findOverallAverageEta(@Param("garageId") Long garageId,
                                 @Param("from") java.time.LocalDateTime from,
                                 @Param("to") java.time.LocalDateTime to);
}