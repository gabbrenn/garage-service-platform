import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
// Using consolidated import for stomp_dart_client 2.x
// Single entrypoint import for stomp_dart_client (exports StompClient, StompConfig, StompFrame)
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:async';
import 'dart:convert';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _initialLoaded = false;
  StompClient? _stompClient;
  Timer? _pollTimer;
  int? _userId; // captured after login

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get hasLoadedOnce => _initialLoaded;

  void _setLoading(bool v){
    _isLoading = v; notifyListeners();
  }
  void _setError(String? e){ _error = e; notifyListeners(); }

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    if(_initialLoaded && !forceRefresh) return; // avoid duplicate first load
    try {
      _setLoading(true); _setError(null);
      final list = await ApiService.getNotifications();
      _notifications = list;
      _initialLoaded = true;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    try {
      final list = await ApiService.getNotifications();
      _notifications = list; notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void configureUser(int userId){
    _userId = userId;
  }

  Future<void> preloadIfPossible() async {
    if(_userId == null) return;
    if(_notifications.isEmpty){
      try { _notifications = await ApiService.getNotifications(); notifyListeners(); } catch(_){}
    }
  }

  void startRealtime() {
    if(_userId == null) return;
    // Avoid duplicate
    stopRealtime();
    final tokenFuture = ApiService.getToken();
    tokenFuture.then((token) async {
      // Build WS URL from ApiService.baseUrl to respect environment
      // e.g., http://localhost:8080/api -> ws://localhost:8080/ws/websocket
      var wsUrl = 'ws://localhost:8080/ws/websocket';
      try {
        final api = ApiService.baseUrl; // static const in ApiService
        final uri = Uri.parse(api);
        final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
        final host = uri.host;
        final port = uri.hasPort ? ':${uri.port}' : '';
        var raw = '$scheme://$host$port/ws/websocket';
        // On web, custom headers are ignored during WS handshake; include token in query as fallback
        if (token != null && token.isNotEmpty) {
          final u = Uri.parse(raw);
          final qp = Map<String, String>.from(u.queryParameters);
          qp['access_token'] = token; // common convention
          qp['authorization'] = 'Bearer $token'; // some servers look for this
          raw = u.replace(queryParameters: qp).toString();
        }
        wsUrl = raw;
      } catch(_) { /* fallback to default above */ }

      _stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          // Provide auth both in headers and query param (some proxies drop headers)
          // Backend should validate Authorization header; query is best-effort
          stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : const {},
          webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : const {},
          onConnect: (frame){
            _stompClient?.subscribe(
              destination: '/topic/notifications.${_userId.toString()}',
              callback: (StompFrame f){ _handleSocketMessage(f); },
            );
          },
          onStompError: (f){ _startPollingFallback(); },
          onWebSocketError: (e){ _startPollingFallback(); },
          beforeConnect: () async {},
          connectionTimeout: const Duration(seconds: 5),
          heartbeatOutgoing: const Duration(seconds: 10),
          heartbeatIncoming: const Duration(seconds: 10),
        )
      );
      _stompClient?.activate();
    });
  }

  void _handleSocketMessage(StompFrame frame){
    if(frame.body == null) return;
    try {
      final data = frame.body!;
      final obj = jsonDecode(data);
      final type = obj['type'];
      if(type == 'CREATED'){
        // fetch specific new list (simpler to refresh)
        refresh();
      } else if(type == 'READ' || type == 'READ_ALL'){
        refresh();
      }
    } catch(_){ /* ignore */ }
  }

  void _startPollingFallback(){
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) { refresh(); });
  }

  void stopRealtime(){
    _stompClient?.deactivate();
    _stompClient = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> markRead(int id) async {
    try {
      final updated = await ApiService.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if(idx != -1){
        _notifications[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearAll(){
    _notifications = [];
    _initialLoaded = false;
    stopRealtime();
    notifyListeners();
  }
}
