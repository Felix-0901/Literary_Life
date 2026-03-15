import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/app_api_client.dart';

class GroupProvider with ChangeNotifier {
  GroupProvider({AppApiClient? apiClient})
    : _apiClient = apiClient ?? const DefaultAppApiClient();

  final AppApiClient _apiClient;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _apiClient.getGroups();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGroup = await _apiClient.createGroup(name, description);
      if (newGroup != null) {
        _groups.insert(0, newGroup);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroupByCode(String inviteCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiClient.joinGroupByCode(inviteCode);
      if (success) {
        await fetchGroups();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
