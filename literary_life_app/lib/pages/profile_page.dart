import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../navigation/app_navigation.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/work_provider.dart';
import '../providers/inspiration_provider.dart';
import '../providers/cycle_provider.dart';
import 'my_works_page.dart';
import 'cycle_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkProvider>().fetchWorks();
      context.read<CycleProvider>().fetchAllCycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile header
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user.nickname[0],
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.nickname,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.userCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已複製用戶編號: ${user.userCode}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    '#${user.userCode}',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Stats
                Consumer2<WorkProvider, CycleProvider>(
                  builder: (context, workProvider, cycleProvider, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem('作品', '${workProvider.works.length}'),
                        _divider(),
                        _statItem('週期', '${cycleProvider.allCycles.length}'),
                        _divider(),
                        Consumer<InspirationProvider>(
                          builder: (context, inspProvider, _) {
                            return _statItem(
                              '靈感',
                              '${inspProvider.inspirations.length}',
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Menu items
                _menuItem(Icons.article_outlined, '我的作品', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyWorksPage()),
                  );
                }),
                _menuItem(Icons.auto_awesome_outlined, '我的靈感', () {
                  // Switch to inspiration tab
                  context.read<MainShellController>().switchTab(1);
                }),
                _menuItem(Icons.timer_outlined, '週期紀錄', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CycleHistoryPage()),
                  );
                }),
                _menuItem(Icons.bookmark_outline_rounded, '收藏的句子', () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.background,
                      title: Text(
                        '收藏的句子',
                        style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
                      ),
                      content: Text(
                        '此功能即將推出，敬請期待！',
                        style: GoogleFonts.notoSansTc(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '好的',
                            style: GoogleFonts.notoSansTc(
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Divider(color: AppTheme.divider),
                const SizedBox(height: 8),
                _menuItem(Icons.settings_outlined, '設定', () {
                  Navigator.pushNamed(context, '/settings');
                }),
                _menuItem(Icons.logout_rounded, '登出', () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        '確認登出',
                        style: GoogleFonts.notoSansTc(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text('確定要登出嗎？', style: GoogleFonts.notoSansTc()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            '登出',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await auth.logout();
                    if (context.mounted) {
                      AppNavigation.goToLogin(context);
                    }
                  }
                }, isDestructive: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSerifTc(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSansTc(fontSize: 12, color: AppTheme.textHint),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: AppTheme.divider);
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        size: 22,
        color: isDestructive ? AppTheme.error : AppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: GoogleFonts.notoSansTc(
          fontSize: 15,
          color: isDestructive ? AppTheme.error : AppTheme.primary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppTheme.textHint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
