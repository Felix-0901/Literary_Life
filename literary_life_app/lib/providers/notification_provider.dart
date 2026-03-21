import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification.dart';
import '../services/app_api_client.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({AppApiClient? apiClient})
    : _apiClient = apiClient ?? const DefaultAppApiClient();

  final AppApiClient _apiClient;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  bool _isDisposed = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  String? get error => _error;

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (_isDisposed) return;
    if (!silent) {
      _isLoading = true;
    }
    _error = null;
    if (!silent) {
      _safeNotifyListeners();
    }

    try {
      _notifications = await _apiClient.getNotifications();
    } catch (error) {
      _error = error.toString();
    }
    if (_isDisposed) return;
    _isLoading = false;
    _safeNotifyListeners();
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 5)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      fetchNotifications(silent: true);
    });
  }

  void stopAutoRefresh() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> markRead(int notificationId) async {
    if (_isDisposed) return;
    try {
      _error = null;
      await _apiClient.markNotificationRead(notificationId);
      if (_isDisposed) return;
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        _notifications[idx] = AppNotification(
          id: _notifications[idx].id,
          userId: _notifications[idx].userId,
          type: _notifications[idx].type,
          message: _notifications[idx].message,
          relatedWorkId: _notifications[idx].relatedWorkId,
          isRead: true,
          createdAt: _notifications[idx].createdAt,
        );
        _safeNotifyListeners();
      }
    } catch (error) {
      _error = error.toString();
      _safeNotifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_isDisposed) return;
    try {
      _error = null;
      await _apiClient.markAllNotificationsRead();
      if (_isDisposed) return;
      _notifications = _notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              message: n.message,
              relatedWorkId: n.relatedWorkId,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      _safeNotifyListeners();
    } catch (error) {
      _error = error.toString();
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    super.dispose();
  }
}
