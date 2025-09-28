import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
// Removed: import 'package:segmented_button/segmented_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';
import '../../utils/polyline_decode.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garage_provider.dart';
import '../../models/garage.dart';
import '../../utils/geo_format.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/language_picker_sheet.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/theme_toggle_button.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _mapMode = false; // new toggle state
  Garage? _selectedGarage; // for directions
  Set<Polyline> _polylines = {};
  final Map<int, double> _roadDistancesKm = {}; // garageId -> km
  GoogleMapController? _mapController;
  bool _mapReady = false; // becomes true after onMapCreated to gate camera animations
  MapType _mapType = MapType.normal;
  bool _showTraffic = false;
  double? _lastRouteKm;
  double? _lastRouteMinutes;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request location permission
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission is required to find nearby garages'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Load nearby garages
      if (_currentPosition != null) {
        final garageProvider = Provider.of<GarageProvider>(context, listen: false);
        await garageProvider.loadNearbyGarages(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
  final authProvider = Provider.of<AuthProvider>(context);
  final garageProvider = Provider.of<GarageProvider>(context);
    // LanguageProvider not directly needed now (language picker uses shared sheet)

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.findGarages),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        actions: [
          const ThemeToggleButton(),
          Consumer<NotificationProvider>(
            builder: (_, notif, __) => IconButton(
              icon: Stack(children:[
                const Icon(Icons.notifications),
                if(notif.unreadCount>0) Positioned(
                  right:0, top:0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(child: Text('${notif.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                  ),
                )
              ]),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications').then((_) => notif.loadNotifications(forceRefresh: true));
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => showLanguagePickerSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'my_requests') {
                Navigator.pushNamed(context, '/my-requests');
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'logout') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.logout),
                    content: Text(loc.confirmLogoutMessage),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.logout)),
                    ],
                  ),
                );
                if (ok == true) {
                  await authProvider.logout(context);
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'my_requests',
                child: Row(children:[Icon(Icons.list, color: Colors.grey[600]), const SizedBox(width:8), Text(loc.myRequestsMenu)])
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(children:[Icon(Icons.settings, color: Colors.grey[600]), const SizedBox(width:8), Text(Localizations.localeOf(context).languageCode=='fr' ? 'Paramètres' : 'Settings')])
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(children:[Icon(Icons.logout, color: Colors.grey[600]), const SizedBox(width:8), Text(loc.logout)])
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children:[Expanded(child: SegmentedButton<bool>(segments:[
              ButtonSegment<bool>(value:false,label: Text(loc.list),icon: const Icon(Icons.list)),
              ButtonSegment<bool>(value:true,label: Text(loc.map),icon: const Icon(Icons.map)),
            ], selected:<bool>{_mapMode}, onSelectionChanged:(s)=>setState(()=>_mapMode=s.first)))]),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: AppColors.navy.withOpacity(0.05),
            child: Row(children:[
              const Icon(Icons.location_on, color: AppColors.navy), const SizedBox(width:8), Expanded(child: Text(
                _currentPosition != null ? '${loc.location}: ${formatLat(_currentPosition!.latitude)}, ${formatLng(_currentPosition!.longitude)}' : loc.gettingLocation,
                style: const TextStyle(color: AppColors.navy),
              )), if(_isLoadingLocation) const SizedBox(width:20,height:20, child:CircularProgressIndicator(strokeWidth:2))])
          ),
          Expanded(
            child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : garageProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : garageProvider.error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                      const Icon(Icons.error, size:64, color: Colors.red), const SizedBox(height:16),
                      Text(loc.errorLoadingGarages, style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)),
                      const SizedBox(height:8), Text(garageProvider.error!), const SizedBox(height:16),
                      ElevatedButton(onPressed:_getCurrentLocation, child: Text(loc.retry)),
                    ]))
                  : garageProvider.nearbyGarages.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                        const Icon(Icons.search_off, size:64, color: Colors.grey), const SizedBox(height:16),
                        Text(loc.noGaragesFound, style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)),
                        const SizedBox(height:8), Text(loc.tryRefresh), const SizedBox(height:16),
                        ElevatedButton(onPressed:_getCurrentLocation, child: Text(loc.retry)),
                      ]))
                    : _mapMode ? _buildMapView(garageProvider)
                      : ListView.builder(padding: const EdgeInsets.all(16), itemCount: garageProvider.nearbyGarages.length,
                        itemBuilder:(context,index){ final g = garageProvider.nearbyGarages[index]; return _buildGarageCard(g); }),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(GarageProvider garageProvider) {
    if (_currentPosition == null) {
      return Center(child: Text(AppLocalizations.of(context).waitingForLocation));
    }
    // Graceful fallback if Google Maps JS failed to load on web (e.g., key restriction / network)
    if (!_isGoogleMapsAvailable()) {
      final loc = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Map unavailable', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Check your Google Maps key or network and retry.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () { setState(() {}); },
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }
    final loc = AppLocalizations.of(context);
    final userLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final markers = <Marker>{
      Marker(markerId: const MarkerId('user'), position: userLatLng, infoWindow: InfoWindow(title: loc.you)),
      ...garageProvider.nearbyGarages.map((g) => Marker(
        markerId: MarkerId('garage_${g.id}'), position: LatLng(g.latitude, g.longitude),
        infoWindow: InfoWindow(title: g.name, snippet: g.address), onTap: () { setState(() { _selectedGarage = g; _buildPolyline(); }); _showGarageSheet(g); }))
    };
    return Stack(
      children: [
        RepaintBoundary(
          child: GoogleMap(
          initialCameraPosition: CameraPosition(target: userLatLng, zoom: 13),
          markers: markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          mapType: _mapType,
          trafficEnabled: _showTraffic,
          onMapCreated: (c) {
            _mapController = c;
            _mapReady = true;
            // If a garage is already selected, fit bounds to show both points
            if (_selectedGarage != null) {
              _fitMapToBounds(
                userLatLng,
                LatLng(_selectedGarage!.latitude, _selectedGarage!.longitude),
              );
            }
          },
          onTap: (_) {
            setState(() {
              _selectedGarage = null;
              _polylines.clear();
            });
          },
        )),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: () {
                  if (_currentPosition != null) {
                    final user = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
                    if (_selectedGarage != null) {
                      _fitMapToBounds(
                        user,
                        LatLng(_selectedGarage!.latitude, _selectedGarage!.longitude),
                      );
                    } else {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: user, zoom: 13),
                        ),
                      );
                    }
                  }
                },
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'maptype',
                onPressed: () {
                  setState(() {
                    _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
                  });
                },
                child: const Icon(Icons.layers),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'traffic',
                onPressed: () {
                  setState(() {
                    _showTraffic = !_showTraffic;
                  });
                },
                child: Icon(_showTraffic ? Icons.traffic : Icons.traffic_outlined),
              ),
            ],
          ),
        ),
        if (_selectedGarage != null && (_lastRouteKm != null || _lastRouteMinutes != null))
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
                      const Icon(Icons.directions_car, color: AppColors.navy), const SizedBox(width: 8),
                      if (_lastRouteKm != null) Text('${_lastRouteKm!.toStringAsFixed(1)} km'),
                      if (_lastRouteMinutes != null) ...[
                        const SizedBox(width: 12),
                        Text('${_lastRouteMinutes!.toStringAsFixed(0)} min'),
                      ],
                    ]),
                    TextButton.icon(
                      onPressed: _openInGoogleMaps,
                      icon: const Icon(Icons.navigation),
                      label: Text(loc.directions),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isGoogleMapsAvailable() {
    // On mobile platforms the plugin should be available; only need to guard on web.
    // We attempt to detect the web JS context indirectly using kIsWeb and checking for the global "google" object via dart:js_util.
    // Avoid importing dart:js_util on non-web.
    // Implementation placed in a try/catch to never crash.
    try {
      // Conditional import pattern could be cleaner; for brevity using dynamic.
      // ignore: avoid_web_libraries_in_flutter
      // The following code will be tree-shaken out for non-web builds.
      // dart:js_util can't be imported conditionally inline, so this method may be adapted later if needed.
      // We'll use an indirect check relying on plugin internal state fallback (simplified placeholder returning true).
      // TODO: Optionally implement a real web check with conditional imports.
      return true; // Assume available; real failure will show runtime error which we already try to intercept upstream.
    } catch (_) {
      return true;
    }
  }

  void _fitMapToBounds(LatLng a, LatLng b) {
    if (!_mapReady || _mapController == null) return; // guard against early usage
    final sw = LatLng(
      math.min(a.latitude, b.latitude),
      math.min(a.longitude, b.longitude),
    );
    final ne = LatLng(
      math.max(a.latitude, b.latitude),
      math.max(a.longitude, b.longitude),
    );
    // Add padding so both markers and route are visible
    if(!mounted) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        60,
      ),
    );
  }

  void _buildPolyline() {
    _polylines.clear();
    if (_selectedGarage == null || _currentPosition == null) return;
    final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final end = LatLng(_selectedGarage!.latitude, _selectedGarage!.longitude);
    // Try to fetch route geometry
    () async {
      final res = await ApiService.getRoadDistance(
        originLat: start.latitude,
        originLng: start.longitude,
        destLat: end.latitude,
        destLng: end.longitude,
      );
      if (!mounted) return;
      if (res != null && res['polyline'] is String && (res['polyline'] as String).isNotEmpty) {
        if(!mounted) return;
        setState(() {
          _lastRouteKm = (res['distanceKm'] as num?)?.toDouble();
          _lastRouteMinutes = (res['durationMinutes'] as num?)?.toDouble();
        });
        final precision = (res['precision'] is int) ? res['precision'] as int : 6;
        final pts = decodePolyline(res['polyline'] as String, precision: precision)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if(!mounted) return;
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: pts,
              color: AppColors.darkOrange,
              width: 5,
            )
          };
        });
        // Fit to the route bounds using start/end (fast and sufficient)
        _fitMapToBounds(start, end);
      } else {
        if(!mounted) return;
        setState(() {
          _lastRouteKm = null;
          _lastRouteMinutes = null;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [start, end],
              color: AppColors.navy,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            )
          };
        });
        _fitMapToBounds(start, end);
      }
    }();
  }

  Future<void> _openInGoogleMaps() async {
    if (_currentPosition == null || _selectedGarage == null) return;
    final s = _currentPosition!;
    final d = _selectedGarage!;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${s.latitude},${s.longitude}&destination=${d.latitude},${d.longitude}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: try launching in a browser tab
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _showGarageSheet(Garage g) {
    final loc = AppLocalizations.of(context);
    double distanceKm = _currentPosition != null ? g.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude) : 0;
    // We'll update distance inside the bottom sheet using StatefulBuilder so UI updates in place
    bool started = false;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            if (!started && _currentPosition != null) {
              started = true;
              // Fire and update the UI within the sheet
              () async {
                final res = await ApiService.getRoadDistance(
                  originLat: _currentPosition!.latitude,
                  originLng: _currentPosition!.longitude,
                  destLat: g.latitude,
                  destLng: g.longitude,
                );
                if (res != null && res['distanceKm'] != null) {
                  if(!mounted) return; // parent may be disposed
                  setModalState(() {
                    distanceKm = (res['distanceKm'] as num).toDouble();
                  });
                }
              }();
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)),
                  const SizedBox(height:4),
                  Text(g.address),
                  const SizedBox(height:4),
                  Text('${loc.distance}: ${distanceKm.toStringAsFixed(2)} km'),
                  if(g.description!=null)...[ const SizedBox(height:8), Text(g.description!), ],
                  const SizedBox(height:12),
                  Row(children:[
                    ElevatedButton.icon(
                      onPressed:(){ Navigator.pop(ctx); Navigator.pushNamed(context,'/garage-details', arguments: g); },
                      icon: const Icon(Icons.info),
                      label: Text(loc.details),
                    ),
                    const SizedBox(width:12),
                    ElevatedButton.icon(
                      onPressed:(){ Navigator.pop(ctx); },
                      icon: const Icon(Icons.directions),
                      label: Text(loc.directions),
                    ),
                  ])
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGarageCard(Garage garage) {
    final loc = AppLocalizations.of(context);
    double distance = 0;
    if (_currentPosition != null) {
      // Use cached road distance if available; fallback to straight-line
      distance = _roadDistancesKm[garage.id] ??
          garage.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude);
      // Fetch/update road distance (best-effort)
      () async {
        final res = await ApiService.getRoadDistance(
          originLat: _currentPosition!.latitude,
          originLng: _currentPosition!.longitude,
          destLat: garage.latitude,
          destLng: garage.longitude,
        );
        if (!mounted) return; // widget might have been disposed
        if (res != null && res['distanceKm'] != null) {
          final newVal = (res['distanceKm'] as num).toDouble();
          if (_roadDistancesKm[garage.id] != newVal) {
            if (!mounted) return;
            setState(() { _roadDistancesKm[garage.id] = newVal; });
          }
        }
      }();
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/garage-details',
            arguments: garage,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.build, color: AppColors.navy, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      garage.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (distance > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      garage.address,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              if (garage.description != null) ...[
                SizedBox(height: 8),
                Text(
                  garage.description!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (garage.workingHours != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      garage.workingHours!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(onPressed: () { Navigator.pushNamed(context, '/garage-details', arguments: garage); }, icon: const Icon(Icons.arrow_forward), label: Text(loc.viewServices)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}