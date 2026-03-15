import 'package:flutter_test/flutter_test.dart';
import 'package:literary_life_app/navigation/main_shell_controller.dart';

void main() {
  test('MainShellController lazily initializes tabs when switching', () {
    final controller = MainShellController();

    expect(controller.currentIndex, 0);
    expect(controller.isInitialized(0), isTrue);
    expect(controller.isInitialized(1), isFalse);

    controller.switchTab(1);

    expect(controller.currentIndex, 1);
    expect(controller.isInitialized(1), isTrue);
  });
}
