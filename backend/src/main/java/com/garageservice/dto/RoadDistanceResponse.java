package com.garageservice.dto;

public class RoadDistanceResponse {
    private double distanceMeters;
    private double durationSeconds;
    private String polyline; // encoded route geometry
    private Integer precision; // polyline precision (e.g., 5 for Google, 6 for OSRM)

    public RoadDistanceResponse() {}

    public RoadDistanceResponse(double distanceMeters, double durationSeconds) {
        this.distanceMeters = distanceMeters;
        this.durationSeconds = durationSeconds;
    }

    public double getDistanceMeters() {
        return distanceMeters;
    }

    public void setDistanceMeters(double distanceMeters) {
        this.distanceMeters = distanceMeters;
    }

    public double getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(double durationSeconds) {
        this.durationSeconds = durationSeconds;
    }

    public double getDistanceKm() {
        return distanceMeters / 1000.0;
    }

    public double getDurationMinutes() {
        return durationSeconds / 60.0;
    }

    public String getPolyline() {
        return polyline;
    }

    public void setPolyline(String polyline) {
        this.polyline = polyline;
    }

    public Integer getPrecision() {
        return precision;
    }

    public void setPrecision(Integer precision) {
        this.precision = precision;
    }
}
