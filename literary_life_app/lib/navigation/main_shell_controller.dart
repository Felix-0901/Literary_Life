import 'package:flutter/foundation.dart';

class MainShellController extends ChangeNotifier {
  MainShellController({int initialIndex = 0}) : _currentIndex = initialIndex {
    _initializedTabs.add(initialIndex);
  }

  final Set<int> _initializedTabs = <int>{};
  int _currentIndex;
  int _reClickTrigger = 0; // Increment this to signal a re-click

  int get currentIndex => _currentIndex;
  int get reClickTrigger => _reClickTrigger;

  bool isInitialized(int index) => _initializedTabs.contains(index);

  void switchTab(int index) {
    if (_currentIndex == index) {
      _reClickTrigger++;
      notifyListeners();
      return;
    }

    _currentIndex = index;
    _initializedTabs.add(index);
    notifyListeners();
  }

  void preloadTabs(Iterable<int> indexes) {
    var changed = false;
    for (final index in indexes) {
      if (_initializedTabs.add(index)) {
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
}
