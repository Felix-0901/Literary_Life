import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../navigation/app_navigation.dart';
import '../providers/auth_provider.dart';
import 'notification_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('設定', style: GoogleFonts.notoSerifTc()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('帳號'),
          _settingItem(context, Icons.person_outline_rounded, '編輯個人資料', () {
            _showEditProfileDialog(context);
          }),
          _settingItem(context, Icons.lock_outline_rounded, '修改密碼', () {
            _showComingSoonDialog(context, '修改密碼');
          }),
          const SizedBox(height: 20),
          _sectionTitle('通知'),
          _settingItem(context, Icons.notifications_none_rounded, '通知中心', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            );
          }),
          _settingItem(context, Icons.timer_outlined, '週期提醒設定', () {
            _showComingSoonDialog(context, '週期提醒設定');
          }),
          const SizedBox(height: 20),
          _sectionTitle('其他'),
          _settingItem(context, Icons.info_outline_rounded, '關於拾字日常', () {
            _showAboutDialog(context);
          }),
          _settingItem(context, Icons.article_outlined, '開放原始碼授權', () {
            _showLicensesDialog(context);
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
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
                  await authProvider.logout();
                  if (!context.mounted) return;
                  AppNavigation.goToLogin(context);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                '登出',
                style: GoogleFonts.notoSansTc(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final nicknameController = TextEditingController(text: user.nickname);
    final bioController = TextEditingController(text: user.bio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(
          '編輯個人資料',
          style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(
                labelText: '暱稱',
                labelStyle: GoogleFonts.notoSansTc(color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '個人簡介',
                labelStyle: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                hintText: '用一句話描述自己...',
                hintStyle: GoogleFonts.notoSansTc(
                  color: AppTheme.textHint,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '取消',
              style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await auth.updateProfile(
                nickname: nicknameController.text.trim(),
                bio: bioController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!context.mounted) return;
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('個人資料已更新 ✦', style: GoogleFonts.notoSansTc()),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              '儲存',
              style: GoogleFonts.notoSansTc(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(
          feature,
          style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
        ),
        content: Text(
          '此功能即將推出，敬請期待！',
          style: GoogleFonts.notoSansTc(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '好的',
              style: GoogleFonts.notoSansTc(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.notoSansTc(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textHint,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: AppTheme.textSecondary),
      title: Text(
        label,
        style: GoogleFonts.notoSansTc(fontSize: 15, color: AppTheme.primary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppTheme.textHint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      '拾字日常',
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '關於拾字日常',
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '拾起生活的片段，化作文學的語言。\n\n「拾字日常」是一個專為文學愛好者設計的創作與社群平台。我們相信，每一個平凡的日常片段，都值得被拾起、記錄並轉化為深刻的文字。',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _aboutInfoItem(Icons.code_rounded, '開發版本', '1.0.0'),
                    _aboutInfoItem(Icons.copyright_rounded, '著作權', '© 2026 Literary Life'),
                    _aboutInfoItem(Icons.favorite_rounded, '團隊', '拾字日常開發小組'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    '關閉',
                    style: GoogleFonts.notoSansTc(color: AppTheme.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: '拾字日常',
      applicationVersion: '1.0.0',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(Icons.auto_stories_rounded, size: 48, color: AppTheme.primary),
      ),
      applicationLegalese: '© 2026 Literary Life\nLicensed under MIT License',
    );
  }

  Widget _aboutInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textHint),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.notoSansTc(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.notoSansTc(
              fontSize: 13,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
