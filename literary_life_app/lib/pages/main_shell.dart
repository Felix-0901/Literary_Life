import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/announcement_service.dart';
import '../widgets/announcement_dialog.dart';
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

class MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late final MainShellController _controller;
  AuthProvider? _authProvider;
  NotificationProvider? _notificationProvider;
  final List<Widget?> _pageCache = List<Widget?>.filled(5, null);
  bool _hasShownAnnouncementInForeground = false;
  bool _isCheckingAnnouncement = false;
  String _announcementUserKey = 'guest';

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      _authProvider = auth;
      _syncAnnouncementUserKey(auth);
      auth.addListener(_onAuthChanged);
      final notifications = context.read<NotificationProvider>();
      _notificationProvider = notifications;
      notifications.fetchNotifications(silent: true);
      notifications.startAutoRefresh();
      _triggerAnnouncementCheck();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider?.removeListener(_onAuthChanged);
    _notificationProvider?.stopAutoRefresh();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = _authProvider;
    if (auth == null) return;
    final changed = _syncAnnouncementUserKey(auth);
    if (changed) {
      _triggerAnnouncementCheck();
    }
  }

  bool _syncAnnouncementUserKey(AuthProvider auth) {
    final nextKey = auth.user?.id.toString() ?? 'guest';
    if (nextKey == _announcementUserKey) return false;
    _announcementUserKey = nextKey;
    _hasShownAnnouncementInForeground = false;
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerAnnouncementCheck();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _hasShownAnnouncementInForeground = false;
    }
  }

  void _triggerAnnouncementCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showAnnouncementIfNeeded();
    });
  }

  Future<void> _showAnnouncementIfNeeded() async {
    if (_isCheckingAnnouncement) return;
    if (_hasShownAnnouncementInForeground) return;
    _isCheckingAnnouncement = true;
    try {
      final announcement = await AnnouncementService.fetchActiveAnnouncement();
      if (!mounted || announcement == null) return;

      final prefs = await SharedPreferences.getInstance();
      const legacyKey = 'dismissed_announcement_signature';
      final dateKey = 'dismissed_announcement_date:$_announcementUserKey';
      final signatureKey =
          'dismissed_announcement_signature_v2:$_announcementUserKey';
      final legacySignature = prefs.getString(legacyKey);
      final today = _todayKey(DateTime.now());

      if (legacySignature != null) {
        if (prefs.getString(dateKey) == null &&
            prefs.getString(signatureKey) == null) {
          await prefs.setString(dateKey, today);
          await prefs.setString(signatureKey, legacySignature);
        }
        await prefs.remove(legacyKey);
      }

      final dismissedDate = prefs.getString(dateKey);
      final dismissedSignature = prefs.getString(signatureKey);
      if (dismissedDate == today && dismissedSignature == announcement.signature) {
        return;
      }

      if (!mounted) return;
      _hasShownAnnouncementInForeground = true;
      final dontShowToday = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AnnouncementDialog(announcement: announcement),
      );
      if (dontShowToday == true) {
        await prefs.setString(dateKey, today);
        await prefs.setString(signatureKey, announcement.signature);
      }
    } finally {
      _isCheckingAnnouncement = false;
    }
  }

  String _todayKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
