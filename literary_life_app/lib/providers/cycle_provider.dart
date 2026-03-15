import 'package:flutter/material.dart';
import '../models/cycle.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CycleProvider extends ChangeNotifier {
  WritingCycle? _currentCycle;
  List<WritingCycle> _allCycles = [];
  bool _isLoading = false;
  String? _error;

  WritingCycle? get currentCycle => _currentCycle;
  List<WritingCycle> get allCycles => _allCycles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCurrentCycle() async {
    _error = null;
    try {
      final data = await ApiService.get('${ApiConfig.cyclesUrl}/current');
      _currentCycle = WritingCycle.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _currentCycle = null;
      } else {
        _error = error.message;
      }
    } catch (error) {
      _error = error.toString();
    }
    notifyListeners();
  }

  Future<void> fetchAllCycles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getList('${ApiConfig.cyclesUrl}/');
      _allCycles = data.map((j) => WritingCycle.fromJson(j)).toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startCycle(int cycleType) async {
    try {
      _error = null;
      final data = await ApiService.post(
        '${ApiConfig.cyclesUrl}/',
        body: {'cycle_type': cycleType},
      );
      _currentCycle = WritingCycle.fromJson(data);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> endCycle() async {
    if (_currentCycle == null) return false;
    try {
      _error = null;
      await ApiService.put('${ApiConfig.cyclesUrl}/${_currentCycle!.id}/end');
      _currentCycle = null;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }
}
