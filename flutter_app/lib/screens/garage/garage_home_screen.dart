import 'package:flutter/material.dart';
import 'package:garage_service_app/models/service_request.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garage_provider.dart';
import '../../providers/service_request_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/language_picker_sheet.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/theme_toggle_button.dart';

class GarageHomeScreen extends StatefulWidget {
  const GarageHomeScreen({super.key});

  @override
  _GarageHomeScreenState createState() => _GarageHomeScreenState();
}

class _GarageHomeScreenState extends State<GarageHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final garageProvider = Provider.of<GarageProvider>(context, listen: false);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context, listen: false);
    
    await garageProvider.loadMyGarage();
    
    if (garageProvider.myGarage != null) {
      await Future.wait([
        garageProvider.loadMyServices(),
        serviceRequestProvider.loadGarageRequests(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

  final garageProvider = Provider.of<GarageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.garageDashboard),
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
                    constraints: const BoxConstraints(minWidth:16,minHeight:16),
                    child: Center(child: Text('${notif.unreadCount}', style: const TextStyle(color: Colors.white, fontSize:10)))
                  )
                )
              ]),
              onPressed: () { Navigator.pushNamed(context, '/notifications').then((_) => notif.loadNotifications(forceRefresh: true)); },
            ),
          ),
          IconButton(icon: const Icon(Icons.language), tooltip: loc.language, onPressed: () { showLanguagePickerSheet(context); }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'settings') {
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
                  final authProvider = Provider.of<AuthProvider>(context, listen:false);
                  await authProvider.logout(context);
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            itemBuilder: (context) => [
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
      body: garageProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : garageProvider.myGarage == null ? _buildNoGarageView() : _buildGarageView(),
      floatingActionButton: garageProvider.myGarage != null ? FloatingActionButton(
        onPressed: () { Navigator.pushNamed(context, '/add-service'); },
        backgroundColor: AppColors.darkOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildNoGarageView() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size:100, color: Colors.grey),
            const SizedBox(height:20),
            Text(loc.setUpYourGarage, style: const TextStyle(fontSize:24,fontWeight: FontWeight.bold)),
            const SizedBox(height:10),
            Text(loc.createGarageProfile, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize:16)),
            const SizedBox(height:30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/garage-setup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal:32, vertical:16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(loc.setUpGarageButton, style: const TextStyle(fontSize:16,fontWeight: FontWeight.bold,color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarageView() {
    final loc = AppLocalizations.of(context);
    final garageProvider = Provider.of<GarageProvider>(context);
    final serviceRequestProvider = Provider.of<ServiceRequestProvider>(context);
    final garage = garageProvider.myGarage!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garage Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, color: AppColors.navy, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          garage.name,
                          style: TextStyle(
                            fontSize: 20,
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
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  loc.services,
                  garageProvider.myServices.length.toString(),
                  Icons.build,
                  AppColors.navy,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  loc.requests,
                  serviceRequestProvider.garageRequests.length.toString(),
                  Icons.inbox,
                  AppColors.darkOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/manage-services');
                  },
                  icon: const Icon(Icons.design_services, color: Colors.white),
                  label: Text(loc.manageServices, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical:12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/service-requests');
                  },
                  icon: const Icon(Icons.inbox, color: Colors.white),
                  label: Text(loc.viewRequests, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkOrange,
                    padding: const EdgeInsets.symmetric(vertical:12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-service');
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(loc.addService, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical:12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit-garage');
                  },
                  icon: const Icon(Icons.store_mall_directory, color: Colors.white),
                  label: Text(loc.editProfile, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical:12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/garage-report');
                  },
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  label: Text(loc.viewReport, style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkOrange,
                    padding: const EdgeInsets.symmetric(vertical:12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Recent Requests
          Text(
            loc.recentRequests,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          serviceRequestProvider.garageRequests.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          loc.noRequestsYet,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          loc.requestsAppearHere,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: serviceRequestProvider.garageRequests
                      .take(3)
                      .map((request) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.navy.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppColors.navy),
                              ),
                              title: Text(request.service.name),
                              subtitle: Text(
                                request.customer?.fullName ?? loc.unknownCustomer,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(request.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _localizedStatus(request.status),
                                  style: TextStyle(
                                    color: _getStatusColor(request.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(context, '/service-requests');
                              },
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return AppColors.pending;
      case RequestStatus.ACCEPTED:
        return AppColors.accepted;
      case RequestStatus.IN_PROGRESS:
        return AppColors.inProgress;
      case RequestStatus.REJECTED:
        return AppColors.rejected;
      default:
        return AppColors.cancelled;
    }
  }

  String _localizedStatus(RequestStatus status) {
    final loc = AppLocalizations.of(context);
    switch(status) {
      case RequestStatus.PENDING: return loc.statusPending;
      case RequestStatus.ACCEPTED: return loc.statusAccepted;
      case RequestStatus.REJECTED: return loc.statusRejected;
      case RequestStatus.IN_PROGRESS: return loc.statusInProgress;
      case RequestStatus.COMPLETED: return loc.statusAccepted; // consider adding dedicated completed label later
      case RequestStatus.CANCELLED: return loc.statusRejected; // consider adding dedicated cancelled label
    }
  }
  }