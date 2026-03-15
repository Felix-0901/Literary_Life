import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class FriendProvider with ChangeNotifier {
  List<Friend> _friends = [];
  List<Friend> _pendingRequests = [];
  List<FriendSearchUser> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<Friend> get friends => _friends;
  List<Friend> get pendingRequests => _pendingRequests;
  List<FriendSearchUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await ApiService.getFriends();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingRequests = await ApiService.getPendingFriendRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String keyword) async {
    if (keyword.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await ApiService.searchUsers(keyword);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestFriend(int friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.requestFriend(friendId);
      if (success) {
        _searchResults.removeWhere((u) => u.id == friendId);
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

  Future<bool> acceptFriend(int requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.acceptFriend(requestId);
      if (success) {
        _pendingRequests.removeWhere((f) => f.id == requestId);
        await fetchFriends();
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
