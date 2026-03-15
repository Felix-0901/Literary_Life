import 'package:flutter/material.dart';
import '../models/work.dart';
import '../models/share.dart';
import '../services/app_api_client.dart';
import '../config/api_config.dart';

class WorkProvider extends ChangeNotifier {
  WorkProvider({AppApiClient? apiClient})
    : _apiClient = apiClient ?? const DefaultAppApiClient();

  final AppApiClient _apiClient;
  List<LiteraryWork> _works = [];
  List<LiteraryWork> _publicWorks = [];
  bool _isLoading = false;
  String? _error;

  List<LiteraryWork> get works => _works;
  List<LiteraryWork> get publicWorks => _publicWorks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWorks({int? cycleId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiConfig.worksUrl}/';
      if (cycleId != null) url += '?cycle_id=$cycleId';
      final data = await _apiClient.getList(url);
      _works = data.map((j) => LiteraryWork.fromJson(j)).toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPublicWorks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.getList(
        '${ApiConfig.worksUrl}/?public=true',
      );
      _publicWorks = data.map((j) => LiteraryWork.fromJson(j)).toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch community feed from the enriched share feed endpoint.
  /// Converts ShareFeedItem responses into LiteraryWork objects.
  Future<void> fetchCommunityFeed({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.getList('${ApiConfig.sharesUrl}/feed');
      _publicWorks = data
          .map((j) => ShareFeedItem.fromJson(j).toLiteraryWork())
          .toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<LiteraryWork?> createWork({
    int? cycleId,
    required String title,
    required String genre,
    required String content,
    String visibility = 'private',
  }) async {
    try {
      _error = null;
      final data = await _apiClient.post(
        '${ApiConfig.worksUrl}/',
        body: {
          if (cycleId != null) 'cycle_id': cycleId,
          'title': title,
          'genre': genre,
          'content': content,
          'visibility': visibility,
        },
      );
      final work = LiteraryWork.fromJson(data);
      _works.insert(0, work);
      notifyListeners();
      return work;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<LiteraryWork?> updateWork(
    int workId, {
    String? title,
    String? content,
    String? genre,
    String? visibility,
  }) async {
    try {
      _error = null;
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (genre != null) body['genre'] = genre;
      if (visibility != null) body['visibility'] = visibility;

      final data = await _apiClient.put(
        '${ApiConfig.worksUrl}/$workId',
        body: body,
      );
      if (data.isNotEmpty) {
        final work = LiteraryWork.fromJson(data);
        final idx = _works.indexWhere((w) => w.id == workId);
        if (idx >= 0) {
          _works[idx] = work;
          notifyListeners();
        }
        return work;
      }
      return null;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<LiteraryWork?> publishWork(int workId) async {
    try {
      _error = null;
      final data = await _apiClient.post(
        '${ApiConfig.worksUrl}/$workId/publish',
      );
      final work = LiteraryWork.fromJson(data);
      _replaceWork(work);
      return work;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<LiteraryWork?> unpublishWork(int workId) async {
    try {
      _error = null;
      final data = await _apiClient.post(
        '${ApiConfig.worksUrl}/$workId/unpublish',
      );
      final work = LiteraryWork.fromJson(data);
      _replaceWork(work);
      return work;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  void _replaceWork(LiteraryWork work) {
    final idx = _works.indexWhere((item) => item.id == work.id);
    if (idx >= 0) {
      _works[idx] = work;
    } else {
      _works.insert(0, work);
    }

    final publicIdx = _publicWorks.indexWhere((item) => item.id == work.id);
    if (work.isPublished) {
      if (publicIdx >= 0) {
        _publicWorks[publicIdx] = work;
      } else {
        _publicWorks.insert(0, work);
      }
    } else if (publicIdx >= 0) {
      _publicWorks.removeAt(publicIdx);
    }

    notifyListeners();
  }
}
