import 'package:flutter/material.dart';

import '../services/maintenance_controller.dart';


class MaintenanceOverlay extends StatelessWidget {
  const MaintenanceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MaintenanceState>(
      valueListenable: MaintenanceController.instance.state,
      builder: (context, state, _) {
        if (!state.isActive) return const SizedBox.shrink();

        final message = state.message.trim().isEmpty ? '目前系統維護中，請稍後再試。' : state.message;

        return Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

