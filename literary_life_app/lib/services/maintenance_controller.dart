import 'package:flutter/foundation.dart';


class MaintenanceState {
  final bool isActive;
  final String message;

  const MaintenanceState({
    required this.isActive,
    required this.message,
  });

  const MaintenanceState.inactive() : this(isActive: false, message: '');

  MaintenanceState copyWith({
    bool? isActive,
    String? message,
  }) {
    return MaintenanceState(
      isActive: isActive ?? this.isActive,
      message: message ?? this.message,
    );
  }
}


class MaintenanceController {
  MaintenanceController._();

  static final MaintenanceController instance = MaintenanceController._();

  final ValueNotifier<MaintenanceState> state = ValueNotifier(
    const MaintenanceState.inactive(),
  );

  void deactivate() {
    state.value = const MaintenanceState.inactive();
  }

  void activate({
    String message = '',
  }) {
    state.value = MaintenanceState(isActive: true, message: message);
  }

  void updateFromJson(Map<String, dynamic> json) {
    final isActive = json['is_active'] == true;
    final message = (json['message'] ?? '') as String;
    if (!isActive) {
      deactivate();
      return;
    }
    activate(message: message);
  }
}

