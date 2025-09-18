import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/gen/app_localizations.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onLocationPicked;

  const MapLocationPicker({super.key, this.initialLat, this.initialLng, required this.onLocationPicked});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? _picked;
  GoogleMapController? _controller;
  bool _loadingLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      // Defer geolocation query to post-frame to avoid build-phase state changes on web
      WidgetsBinding.instance.addPostFrameCallback((_) { _determinePosition(); });
    }
  }

  Future<void> _determinePosition() async {
    setState(() { _loadingLocation = true; _error = null; });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'Location services disabled'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _error = 'Location permission denied'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission permanently denied'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _picked = LatLng(pos.latitude, pos.longitude);
      if (mounted && _controller != null) {
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(_picked!, 15));
      }
      setState(() {});
    } catch (e) {
      setState(() { _error = 'Location error: $e'; });
    } finally {
      if (mounted) setState(() { _loadingLocation = false; });
    }
  }

  void _recenter() {
    if (_picked != null && _controller != null) {
      _controller!.animateCamera(CameraUpdate.newLatLngZoom(_picked!, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
  final center = _picked ?? const LatLng(9.0108, 38.7613); // default center (Addis Ababa fallback?)
  final loc = AppLocalizations.of(context);
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 14),
            onMapCreated: (c) {
              _controller = c;
              // Animate to initial picked position if provided
              if (_picked != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _picked != null) {
                    _controller?.animateCamera(CameraUpdate.newLatLngZoom(_picked!, 15));
                  }
                });
              }
            },
            markers: _picked != null ? { Marker(markerId: const MarkerId('picked'), position: _picked!) } : {},
            onTap: (pos) {
              setState(() { _picked = pos; });
              widget.onLocationPicked(pos.latitude, pos.longitude);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            myLocationEnabled: false,
          ),
          if (_loadingLocation)
            const Positioned(
              left: 0, right: 0, top: 0, bottom: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Positioned(
              left: 8, bottom: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
              onPressed: _picked == null ? null : () {
                if (_picked != null) {
                  widget.onLocationPicked(_picked!.latitude, _picked!.longitude);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.locationSelectedSuccess)),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: Text(loc.useLocation),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, minimumSize: const Size(44,44)),
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location, size: 20), // recenter button
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, minimumSize: const Size(44,44)),
                  onPressed: _determinePosition,
                  child: const Icon(Icons.gps_fixed, size: 20), // gps fixed button
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
