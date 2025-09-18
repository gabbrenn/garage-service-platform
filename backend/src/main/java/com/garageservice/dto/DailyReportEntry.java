package com.garageservice.dto;

import java.time.LocalDate;
import java.util.Map;

public class DailyReportEntry {
    private LocalDate day;
    private Map<String, Long> statusCounts; // PENDING->x, ACCEPTED->y ...
    private Double averageEstimatedArrivalMinutes; // may be null if no data that day

    public DailyReportEntry(LocalDate day, Map<String, Long> statusCounts, Double averageEstimatedArrivalMinutes) {
        this.day = day;
        this.statusCounts = statusCounts;
        this.averageEstimatedArrivalMinutes = averageEstimatedArrivalMinutes;
    }

    public LocalDate getDay() { return day; }
    public void setDay(LocalDate day) { this.day = day; }

    public Map<String, Long> getStatusCounts() { return statusCounts; }
    public void setStatusCounts(Map<String, Long> statusCounts) { this.statusCounts = statusCounts; }

    public Double getAverageEstimatedArrivalMinutes() { return averageEstimatedArrivalMinutes; }
    public void setAverageEstimatedArrivalMinutes(Double averageEstimatedArrivalMinutes) { this.averageEstimatedArrivalMinutes = averageEstimatedArrivalMinutes; }
}
