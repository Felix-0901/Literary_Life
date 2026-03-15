import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/notification_provider.dart';
import 'home_page.dart';
import 'inspiration_list_page.dart';
import 'writing_editor_page.dart';
import 'community_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late final MainShellController _controller;
  NotificationProvider? _notificationProvider;
  final List<Widget?> _pageCache = List<Widget?>.filled(5, null);

  static const List<Widget> _pageBuilders = [
    HomePage(),
    InspirationListPage(),
    WritingEditorPage(),
    CommunityPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = MainShellController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifications = context.read<NotificationProvider>();
      _notificationProvider = notifications;
      notifications.fetchNotifications(silent: true);
      notifications.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _notificationProvider?.stopAutoRefresh();
    super.dispose();
  }

  Widget _pageAt(int index) {
    return _pageCache[index] ??= _pageBuilders[index];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainShellController>.value(
      value: _controller,
      child: Consumer<MainShellController>(
        builder: (context, controller, _) {
          return Scaffold(
            body: IndexedStack(
              index: controller.currentIndex,
              children: List<Widget>.generate(_pageBuilders.length, (index) {
                if (!controller.isInitialized(index)) {
                  return const SizedBox.shrink();
                }
                return _pageAt(index);
              }),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _navItem(
                            controller,
                            0,
                            Icons.home_outlined,
                            Icons.home_rounded,
                            '首頁',
                          ),
                          _navItem(
                            controller,
                            1,
                            Icons.auto_awesome_outlined,
                            Icons.auto_awesome,
                            '靈感',
                          ),
                          _navItem(
                            controller,
                            2,
                            Icons.edit_note_rounded,
                            Icons.edit_note_rounded,
                            '創作',
                          ),
                          _navItem(
                            controller,
                            3,
                            Icons.people_outline_rounded,
                            Icons.people_rounded,
                            '社群',
                          ),
                          _navItem(
                            controller,
                            4,
                            Icons.person_outline_rounded,
                            Icons.person_rounded,
                            '我的',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(
    MainShellController controller,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = controller.currentIndex == index;
    return GestureDetector(
      onTap: () => controller.switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.notoSansTc(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
