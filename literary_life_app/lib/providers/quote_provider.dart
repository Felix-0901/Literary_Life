import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class QuoteProvider extends ChangeNotifier {
  Quote? _dailyQuote;
  bool _isLoading = false;
  String? _error;

  Quote? get dailyQuote => _dailyQuote;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDailyQuote() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.get('${ApiConfig.quotesUrl}/daily');
      _dailyQuote = Quote.fromJson(data);
    } catch (error) {
      _error = error.toString();
      // Fallback quote
      _dailyQuote = Quote(id: 0, content: '把生活拾起，寫成文字。', author: '拾字日常');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshQuote() async {
    try {
      _error = null;
      final data = await ApiService.get('${ApiConfig.quotesUrl}/random');
      _dailyQuote = Quote.fromJson(data);
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }
}
