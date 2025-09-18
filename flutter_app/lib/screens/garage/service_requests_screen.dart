import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/service_request_provider.dart';
import '../../models/service_request.dart';
import '../../providers/garage_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../../l10n/gen/app_localizations.dart';
import '../../services/api_service.dart';
import '../../utils/polyline_decode.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceRequestsScreen extends StatefulWidget {
  const ServiceRequestsScreen({super.key});

  @override
  _ServiceRequestsScreenState createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Defer to next frame to avoid provider notifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadRequests(); });
  }

  Future<void> _loadRequests() async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    await serviceRequestProvider.loadGarageRequests();
  }

  void _showLocationMap(ServiceRequest request) {
    final garageProvider = Provider.of<GarageProvider>(context, listen: false);
    final myGarage = garageProvider.myGarage;
    if (myGarage == null) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.garageLocationNotLoaded)));
      return;
    }
    if (request.customerLatitude == 0.0 && request.customerLongitude == 0.0) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.customerLocationNotProvided)));
      return;
    }

    final garagePos = LatLng(myGarage.latitude, myGarage.longitude);
    final customerPos = LatLng(request.customerLatitude, request.customerLongitude);

    double haversineKm(LatLng a, LatLng b) {
      const r = 6371.0;
      double toRad(double d) => d * math.pi / 180.0;
      final dLat = toRad(b.latitude - a.latitude);
      final dLon = toRad(b.longitude - a.longitude);
      final lat1 = toRad(a.latitude);
      final lat2 = toRad(b.latitude);
      final h = math.sin(dLat/2) * math.sin(dLat/2) + math.cos(lat1)*math.cos(lat2)*math.sin(dLon/2)*math.sin(dLon/2);
      final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1-h));
      return r * c;
    }

    double distanceKm = haversineKm(garagePos, customerPos);
    // Try road distance from backend (best-effort)
    () async {
      final res = await ApiService.getRoadDistance(
        originLat: garagePos.latitude,
        originLng: garagePos.longitude,
        destLat: customerPos.latitude,
        destLng: customerPos.longitude,
      );
      if (!mounted) return;
      if (res != null && res['distanceKm'] != null) {
        setState(() {
          distanceKm = res['distanceKm']!;
        });
      }
    }();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (innerCtx) {
                    final sheetLoc = AppLocalizations.of(innerCtx);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16,12,16,8),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sheetLoc.customerLocationTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          Text(sheetLoc.distanceKmLabel(distanceKm.toStringAsFixed(2)), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          IconButton(onPressed: () => Navigator.pop(innerCtx), icon: const Icon(Icons.close))
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _RequestMap(garagePos: garagePos, customerPos: customerPos),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,8,16,12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(ctx).garageLabel}: ${myGarage.name}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${AppLocalizations.of(ctx).customerLabel}: Lat ${customerPos.latitude.toStringAsFixed(5)}, Lng ${customerPos.longitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (request.customerAddress!=null && request.customerAddress!.trim().isNotEmpty)
                        Text('${AppLocalizations.of(ctx).addressLabel}: ${request.customerAddress}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.serviceRequestsTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: serviceRequestProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : serviceRequestProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(loc.errorLoadingRequests),
                      SizedBox(height: 8),
                      Text(serviceRequestProvider.error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: Text(loc.retry),
                      ),
                    ],
                  ),
                )
              : serviceRequestProvider.garageRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            loc.noRequestsYet,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(loc.noRequestsYetLong),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: serviceRequestProvider.garageRequests.length,
                      itemBuilder: (context, index) {
                        final request = serviceRequestProvider.garageRequests[index];
                        return _buildRequestCard(request);
                      },
                    ),
    );
  }

  Widget _buildRequestCard(ServiceRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case RequestStatus.ACCEPTED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.IN_PROGRESS:
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      case RequestStatus.COMPLETED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case RequestStatus.CANCELLED:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (request.customer?.fullName ?? request.customerName ?? 'Unknown Customer'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        (() {
                          final cust = request.customer;
                          if (cust != null) {
                            final pn = cust.phoneNumber; // assume non-nullable in model
                            if (pn.isNotEmpty) return pn;
                          }
                          return request.customerPhone ?? 'No phone';
                        })(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        request.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Service: ${request.service.name}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        request.service.formattedPrice,
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (request.description != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Description: ${request.description}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (request.customerAddress != null && request.customerAddress!.trim().isNotEmpty)
                        ? request.customerAddress!
                        : ((request.customerLatitude != 0.0 || request.customerLongitude != 0.0)
                            ? 'Lat: ${request.customerLatitude.toStringAsFixed(4)}, Lng: ${request.customerLongitude.toStringAsFixed(4)}'
                            : 'Location not provided'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                SizedBox(width: 4),
                Text(
                  'Requested: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year} ${request.createdAt.hour}:${request.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            
            if (request.garageResponse != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      request.garageResponse!,
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    if (request.estimatedArrivalMinutes != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'ETA: ${request.formattedEstimatedArrival}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showLocationMap(request),
                icon: const Icon(Icons.map),
                label: const Text('View Location Map'),
              ),
            ),
            
            if (request.status == RequestStatus.PENDING) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(request, RequestStatus.ACCEPTED),
                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text('Accept', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(request, RequestStatus.REJECTED),
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.ACCEPTED) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(request, RequestStatus.IN_PROGRESS),
                      icon: Icon(Icons.build, color: Colors.white),
                      label: Text('Start Work', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (request.status == RequestStatus.IN_PROGRESS) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(request, RequestStatus.COMPLETED),
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Mark Complete', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(ServiceRequest request, RequestStatus status) {
    final responseController = TextEditingController();
    final etaController = TextEditingController();

    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == RequestStatus.ACCEPTED ? loc.acceptRequestTitle : loc.rejectRequestTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseController,
              decoration: InputDecoration(
                labelText: loc.responseMessageLabel,
                hintText: status == RequestStatus.ACCEPTED 
                    ? loc.acceptDefaultResponse
                    : loc.rejectDefaultResponse,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (status == RequestStatus.ACCEPTED) ...[
              SizedBox(height: 16),
              TextField(
                controller: etaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.estimatedArrivalMinutesLabel,
                  hintText: loc.minutesExampleHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToRequest(
                request,
                status,
                responseController.text.trim().isEmpty ? null : responseController.text.trim(),
                etaController.text.trim().isEmpty ? null : int.tryParse(etaController.text.trim()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == RequestStatus.ACCEPTED ? Colors.green : Colors.red,
            ),
            child: Text(
              status == RequestStatus.ACCEPTED ? loc.acceptRequestButton : loc.rejectRequestButton,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToRequest(ServiceRequest request, RequestStatus status, String? response, int? eta) async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    final success = await serviceRequestProvider.respondToRequest(
      requestId: request.id,
      status: status,
      response: response,
      estimatedArrivalMinutes: eta,
    );

    final loc = AppLocalizations.of(context);
    if (success) {
      final statusText = status.toString().split('.').last.toLowerCase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.requestRespondGenericSuccess(statusText)),
          backgroundColor: status == RequestStatus.ACCEPTED ? Colors.green : Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceRequestProvider.error ?? loc.requestRespondFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus(ServiceRequest request, RequestStatus status) async {
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    final success = await serviceRequestProvider.respondToRequest(
      requestId: request.id,
      status: status,
    );

    final loc = AppLocalizations.of(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.requestStatusUpdateSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceRequestProvider.error ?? loc.requestStatusUpdateFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RequestMap extends StatefulWidget {
  final LatLng garagePos;
  final LatLng customerPos;
  const _RequestMap({required this.garagePos, required this.customerPos});
  @override
  State<_RequestMap> createState() => _RequestMapState();
}

class _RequestMapState extends State<_RequestMap> {
  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};
  MapType _mapType = MapType.normal;
  bool _showTraffic = false;
  double? _lastRouteKm;
  double? _lastRouteMinutes;

  @override
  void initState() {
    super.initState();
    // Fetch route polyline best-effort
    () async {
      final res = await ApiService.getRoadDistance(
        originLat: widget.garagePos.latitude,
        originLng: widget.garagePos.longitude,
        destLat: widget.customerPos.latitude,
        destLng: widget.customerPos.longitude,
      );
      if (!mounted) return;
      if (res != null && res['polyline'] is String && (res['polyline'] as String).isNotEmpty) {
        setState(() {
          _lastRouteKm = (res['distanceKm'] as num?)?.toDouble();
          _lastRouteMinutes = (res['durationMinutes'] as num?)?.toDouble();
        });
        final precision = (res['precision'] is int) ? res['precision'] as int : 6;
        final pts = decodePolyline(res['polyline'] as String, precision: precision)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: pts,
              color: Colors.blue,
              width: 5,
            )
          };
        });
        _fitToBounds();
      } else {
        setState(() {
          _lastRouteKm = null;
          _lastRouteMinutes = null;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [widget.garagePos, widget.customerPos],
              color: Colors.blue,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            )
          };
        });
        _fitToBounds();
      }
    }();
  }
  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(markerId: const MarkerId('garage'), position: widget.garagePos, infoWindow: const InfoWindow(title: 'Garage')), 
      Marker(markerId: const MarkerId('customer'), position: widget.customerPos, infoWindow: const InfoWindow(title: 'Customer')),
    };
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: widget.garagePos, zoom: 12),
          markers: markers,
          polylines: _polylines,
          onMapCreated: (c){
            _controller = c;
            // Fit bounds initially
            _fitToBounds();
          },
          zoomControlsEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          mapType: _mapType,
          trafficEnabled: _showTraffic,
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'recenter_req',
                onPressed: _fitToBounds,
                child: const Icon(Icons.center_focus_strong),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'maptype_req',
                onPressed: () {
                  setState(() { _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal; });
                },
                child: const Icon(Icons.layers),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'traffic_req',
                onPressed: () { setState(() { _showTraffic = !_showTraffic; }); },
                child: Icon(_showTraffic ? Icons.traffic : Icons.traffic_outlined),
              ),
            ],
          ),
        ),
        if (_lastRouteKm != null || _lastRouteMinutes != null)
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children:[
                      const Icon(Icons.directions_car, color: Colors.blue), const SizedBox(width: 8),
                      if (_lastRouteKm != null) Text('${_lastRouteKm!.toStringAsFixed(1)} km'),
                      if (_lastRouteMinutes != null) ...[
                        const SizedBox(width: 12),
                        Text('${_lastRouteMinutes!.toStringAsFixed(0)} min'),
                      ],
                    ]),
                    TextButton.icon(
                      onPressed: _openInGoogleMaps,
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _fitToBounds() {
    if (_controller == null) return;
    final sw = LatLng(
      math.min(widget.garagePos.latitude, widget.customerPos.latitude),
      math.min(widget.garagePos.longitude, widget.customerPos.longitude),
    );
    final ne = LatLng(
      math.max(widget.garagePos.latitude, widget.customerPos.latitude),
      math.max(widget.garagePos.longitude, widget.customerPos.longitude),
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      _controller?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          60,
        ),
      );
    });
  }

  Future<void> _openInGoogleMaps() async {
    final g = widget.garagePos;
    final c = widget.customerPos;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${g.latitude},${g.longitude}&destination=${c.latitude},${c.longitude}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}