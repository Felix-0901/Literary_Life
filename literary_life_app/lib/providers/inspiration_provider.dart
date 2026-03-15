import 'package:flutter/material.dart';
import '../models/inspiration.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class InspirationProvider extends ChangeNotifier {
  List<Inspiration> _inspirations = [];
  bool _isLoading = false;
  String? _error;

  List<Inspiration> get inspirations => _inspirations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInspirations({int? cycleId, String? keyword}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String url = '${ApiConfig.inspirationsUrl}/';
      final params = <String>[];
      if (cycleId != null) params.add('cycle_id=$cycleId');
      if (keyword != null && keyword.isNotEmpty) params.add('keyword=$keyword');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final data = await ApiService.getList(url);
      _inspirations = data.map((j) => Inspiration.fromJson(j)).toList();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createInspiration({
    int? cycleId,
    DateTime? eventTime,
    String location = '',
    String objectOrEvent = '',
    String detailText = '',
    String feeling = '',
    String keywords = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.createInspiration(
        cycleId: cycleId,
        eventTime: eventTime ?? DateTime.now(),
        location: location,
        objectOrEvent: objectOrEvent,
        detailText: detailText,
        feeling: feeling,
        keywords: keywords,
      );
      await fetchInspirations(cycleId: cycleId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInspiration(
    int id, {
    DateTime? eventTime,
    String? location,
    String? objectOrEvent,
    String? detailText,
    String? feeling,
    String? keywords,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateInspiration(
        id,
        eventTime: eventTime,
        location: location,
        objectOrEvent: objectOrEvent,
        detailText: detailText,
        feeling: feeling,
        keywords: keywords,
      );
      if (updated != null) {
        final index = _inspirations.indexWhere((i) => i.id == id);
        if (index != -1) {
          _inspirations[index] = updated;
        }
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteInspiration(int id) async {
    try {
      await ApiService.delete('${ApiConfig.inspirationsUrl}/$id');
      _inspirations.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
