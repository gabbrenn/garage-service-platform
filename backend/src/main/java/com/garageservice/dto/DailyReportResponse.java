package com.garageservice.dto;

import java.time.LocalDate;
import java.util.List;

public class DailyReportResponse {
    private Long garageId;
    private LocalDate from;
    private LocalDate to;
    private List<DailyReportEntry> entries;

    private Double overallAverageEta;
    private Long totalRequests;

    public DailyReportResponse(Long garageId, LocalDate from, LocalDate to, List<DailyReportEntry> entries, Double overallAverageEta, Long totalRequests) {
        this.garageId = garageId;
        this.from = from;
        this.to = to;
        this.entries = entries;
        this.overallAverageEta = overallAverageEta;
        this.totalRequests = totalRequests;
    }

    public Long getGarageId() { return garageId; }
    public void setGarageId(Long garageId) { this.garageId = garageId; }

    public LocalDate getFrom() { return from; }
    public void setFrom(LocalDate from) { this.from = from; }

    public LocalDate getTo() { return to; }
    public void setTo(LocalDate to) { this.to = to; }

    public List<DailyReportEntry> getEntries() { return entries; }
    public void setEntries(List<DailyReportEntry> entries) { this.entries = entries; }

    public Double getOverallAverageEta() { return overallAverageEta; }
    public void setOverallAverageEta(Double overallAverageEta) { this.overallAverageEta = overallAverageEta; }

    public Long getTotalRequests() { return totalRequests; }
    public void setTotalRequests(Long totalRequests) { this.totalRequests = totalRequests; }
}
