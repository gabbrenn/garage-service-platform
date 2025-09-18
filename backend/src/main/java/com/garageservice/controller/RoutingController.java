package com.garageservice.controller;

import com.garageservice.dto.RoadDistanceResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.beans.factory.annotation.Value;

import java.net.URI;
import java.util.Map;

@RestController
@RequestMapping("/api/routing")
@CrossOrigin(origins = "*", maxAge = 3600)
public class RoutingController {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${routing.provider:osrm}")
    private String provider; // osrm|google|mapbox (currently osrm implemented)

    @Value("${routing.osrm.baseUrl:https://router.project-osrm.org}")
    private String osrmBaseUrl;

    // Simple in-memory cache: key -> response (small TTL logic omitted for brevity)
    private final java.util.concurrent.ConcurrentHashMap<String, RoadDistanceResponse> cache = new java.util.concurrent.ConcurrentHashMap<>();

    @GetMapping("/distance")
    public ResponseEntity<?> getRoadDistance(
            @RequestParam double originLat,
            @RequestParam double originLng,
            @RequestParam double destLat,
            @RequestParam double destLng) {
        String key = String.format("%s|%s|%s|%s|%s", provider, originLat, originLng, destLat, destLng);
        var cached = cache.get(key);
        if (cached != null) return ResponseEntity.ok(cached);
        try {
            RoadDistanceResponse resp;
            switch (provider.toLowerCase()) {
                case "osrm":
                default:
                    resp = queryOsrm(originLat, originLng, destLat, destLng);
                    break;
            }
            if (resp == null) return ResponseEntity.status(502).body(Map.of("message", "Routing failed"));
            cache.put(key, resp);
            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            return ResponseEntity.status(502).body(Map.of("message", "Routing error", "error", e.getMessage()));
        }
    }

    @PostMapping("/distance/batch")
    public ResponseEntity<?> getRoadDistanceBatch(@RequestBody java.util.List<Map<String, Object>> pairs) {
        var result = new java.util.ArrayList<Map<String, Object>>();
        for (var p : pairs) {
            try {
                double oLat = ((Number)p.get("originLat")).doubleValue();
                double oLng = ((Number)p.get("originLng")).doubleValue();
                double dLat = ((Number)p.get("destLat")).doubleValue();
                double dLng = ((Number)p.get("destLng")).doubleValue();
                String key = String.format("%s|%s|%s|%s|%s", provider, oLat, oLng, dLat, dLng);
                var cached = cache.get(key);
                RoadDistanceResponse resp = cached != null ? cached : queryOsrm(oLat, oLng, dLat, dLng);
                if (resp != null) cache.put(key, resp);
                result.add(Map.of(
                        "originLat", oLat,
                        "originLng", oLng,
                        "destLat", dLat,
                        "destLng", dLng,
                        "distanceMeters", resp == null ? null : resp.getDistanceMeters(),
                        "durationSeconds", resp == null ? null : resp.getDurationSeconds(),
                        "polyline", resp == null ? null : resp.getPolyline(),
                        "precision", resp == null ? null : resp.getPrecision()
                ));
            } catch (Exception e) {
                result.add(Map.of(
                        "error", e.getMessage()
                ));
            }
        }
        return ResponseEntity.ok(result);
    }

    private RoadDistanceResponse queryOsrm(double originLat, double originLng, double destLat, double destLng) {
        // OSRM expects lon,lat ordering; request geometry as polyline6 (precision 6)
        String path = String.format("/route/v1/driving/%f,%f;%f,%f", originLng, originLat, destLng, destLat);
        URI uri = UriComponentsBuilder.fromHttpUrl(osrmBaseUrl + path)
                .queryParam("overview", "full")
                .queryParam("geometries", "polyline6")
                .queryParam("alternatives", "false")
                .queryParam("annotations", "false")
                .build(true).toUri();

        Map<?,?> json = restTemplate.getForObject(uri, Map.class);
        if (json == null || !"Ok".equals(json.get("code"))) {
            return null;
        }
        var routes = (java.util.List<?>) json.get("routes");
        if (routes == null || routes.isEmpty()) {
            return null;
        }
        var first = (Map<?,?>) routes.get(0);
        double distance = ((Number) first.get("distance")).doubleValue(); // meters
        double duration = ((Number) first.get("duration")).doubleValue(); // seconds
        String polyline = null;
        Object geometryObj = first.get("geometry");
        if (geometryObj instanceof String) {
            polyline = (String) geometryObj; // encoded polyline6
        }
        RoadDistanceResponse resp = new RoadDistanceResponse(distance, duration);
        resp.setPolyline(polyline);
        resp.setPrecision(6);
        return resp;
    }
}
