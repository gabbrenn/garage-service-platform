import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _devModeEnabled = false;

  @override
  void initState() {
    super.initState();
    // Defer to next frame to avoid calling provider before build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<NotificationProvider>();
      p.loadNotifications();
    });
    _loadDevMode();
  }

  Future<void> _refresh() async {
    await context.read<NotificationProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _toggleDevMode,
          child: const Text('Notifications'),
        ),
        actions: [
          if (!kReleaseMode || _devModeEnabled)
            IconButton(
              tooltip: 'Send test push',
              icon: const Icon(Icons.notification_important),
              onPressed: () => _openTestPushDialog(context),
            ),
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await context.read<NotificationProvider>().markAllRead();
            },
          )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.hasLoadedOnce) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${provider.error!}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (provider.notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadDevMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _devModeEnabled = prefs.getBool('dev_mode') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _toggleDevMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = !_devModeEnabled;
      await prefs.setBool('dev_mode', next);
      if (!mounted) return;
      setState(() { _devModeEnabled = next; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Developer mode ${next ? 'enabled' : 'disabled'}')),
      );
    } catch (_) {}
  }

  Future<void> _openTestPushDialog(BuildContext context) async {
    final titleCtrl = TextEditingController(text: 'Custom Test');
    final msgCtrl = TextEditingController(text: 'Hello with custom sound/channel');
    final channelCtrl = TextEditingController(text: 'garage_service_urgent');
    final soundCtrl = TextEditingController(text: 'urgent');
    bool urgent = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Send Test Push'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'Message')),
                  TextField(controller: channelCtrl, decoration: const InputDecoration(labelText: 'Channel ID')), 
                  TextField(controller: soundCtrl, decoration: const InputDecoration(labelText: 'Sound name (no extension)')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Urgent'),
                      const SizedBox(width: 8),
                      Switch(value: urgent, onChanged: (v) => setState(() => urgent = v)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final resp = await ApiService.sendTestPushCustom(
                      title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                      message: msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim(),
                      channelId: channelCtrl.text.trim().isEmpty ? null : channelCtrl.text.trim(),
                      sound: soundCtrl.text.trim().isEmpty ? null : soundCtrl.text.trim(),
                      urgent: urgent,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sent to ${resp['sent']} device(s)')),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                },
                child: const Text('Send'),
              )
            ],
          );
        });
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final p = context.read<NotificationProvider>();
    return ListTile(
      onTap: () {
        if(!notification.read){
          p.markRead(notification.id);
        }
      },
      leading: Icon(
        notification.read ? Icons.notifications_none : Icons.notifications_active,
  color: notification.read ? Colors.grey : AppColors.navy,
      ),
      title: Text(notification.title, style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold)),
      subtitle: Text(notification.message),
      trailing: Text(_formatTime(notification.createdAt), style: const TextStyle(fontSize: 12)),
  tileColor: notification.read ? null : AppColors.navy.withOpacity(0.05),
    );
  }

  String _formatTime(DateTime dt){
    final now = DateTime.now();
    final diff = now.difference(dt);
    if(diff.inMinutes < 1) return 'now';
    if(diff.inMinutes < 60) return '${diff.inMinutes}m';
    if(diff.inHours < 24) return '${diff.inHours}h';
    if(diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
