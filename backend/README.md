# Routing / Distance API

This service exposes simple routing endpoints used by the Flutter app to display road distance and draw polylines on maps.

Endpoints:
- `GET /api/routing/distance?originLat&originLng&destLat&destLng` → JSON with `distanceMeters`, `durationSeconds`, `polyline`, `precision`.
- `POST /api/routing/distance/batch` → Accepts a JSON array of origin/destination objects, returns an array with the same fields for each pair.

Provider:
- Configurable via `routing.provider`. Supported: `osrm` (default). Future: `google`, `mapbox`.
- OSRM base URL: `routing.osrm.baseUrl` (default: `https://router.project-osrm.org`).

Notes:
- The default OSRM public server is free but rate-limited; for production consider hosting your own OSRM or use a commercial provider (Google/Mapbox) and set credentials accordingly.
- Responses include an encoded polyline with precision `6` (polyline6) for OSRM.
