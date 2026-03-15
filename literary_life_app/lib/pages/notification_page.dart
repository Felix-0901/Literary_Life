import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/notification_provider.dart';
import '../providers/cycle_provider.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import 'article_detail_page.dart';
import 'friends_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('通知', style: GoogleFonts.notoSerifTc()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationProvider>().markAllRead(),
            child: Text(
              '全部已讀',
              style: GoogleFonts.notoSansTc(
                fontSize: 13,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<NotificationProvider, CycleProvider>(
        builder: (context, provider, cycleProvider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          final needsCycle = cycleProvider.currentCycle == null;
          final displayNotifications = [
            if (needsCycle)
              AppNotification(
                id: -1,
                userId: -1,
                type: 'cycle_reminder',
                message: '尚未開始週期，點擊建立 3 天或 7 天的創作計畫',
                isRead: false,
                createdAt: DateTime.now(),
              ),
            ...provider.notifications,
          ];

          if (displayNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppTheme.textHint.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '目前沒有通知',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '有新的好友邀請、文章分享或回應時會通知你',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: displayNotifications.length,
              itemBuilder: (context, index) {
                final notif = displayNotifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: notif.isRead
                        ? AppTheme.surface
                        : AppTheme.warmGold50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: notif.isRead
                          ? AppTheme.divider
                          : AppTheme.accentLight,
                    ),
                  ),
                  child: ListTile(
                    onTap: () async {
                      if (notif.type == 'cycle_reminder') {
                        _showCycleSelectionDialog(context, cycleProvider);
                        return;
                      }

                      if (!notif.isRead) {
                        await provider.markRead(notif.id);
                      }

                      if (!context.mounted) return;

                      if (notif.type == 'friend_request' ||
                          notif.type == 'friend_accepted') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsPage(),
                          ),
                        );
                        return;
                      }

                      if (notif.type == 'share' &&
                          notif.relatedWorkId != null) {
                        await _openSharedWork(context, notif.relatedWorkId!);
                      }
                    },
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: notif.isRead
                          ? AppTheme.divider
                          : AppTheme.accent.withValues(alpha: 0.15),
                      child: Icon(
                        _notifIcon(notif.type),
                        size: 18,
                        color: notif.isRead
                            ? AppTheme.textHint
                            : AppTheme.accent,
                      ),
                    ),
                    title: Text(
                      notif.message,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        fontWeight: notif.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      _formatTime(notif.createdAt),
                      style: GoogleFonts.notoSansTc(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                    trailing: notif.isRead
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'cycle_reminder':
        return Icons.calendar_today_rounded;
      case 'friend_request':
        return Icons.person_add_outlined;
      case 'friend_accepted':
        return Icons.people_rounded;
      case 'response':
        return Icons.chat_bubble_outline_rounded;
      case 'share':
        return Icons.share_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

  Future<void> _openSharedWork(BuildContext context, int workId) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final work = await ApiService.getWorkById(workId);
      if (!context.mounted || work == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailPage(work: work)),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('找不到這篇文章或你目前沒有權限查看', style: GoogleFonts.notoSansTc()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCycleSelectionDialog(
    BuildContext context,
    CycleProvider cycleProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '尚未開始週期',
                style: GoogleFonts.notoSansTc(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '選擇 3 天或 7 天，開始記錄你的日常靈感',
                style: GoogleFonts.notoSansTc(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        cycleProvider.startCycle(3);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '3 天',
                        style: GoogleFonts.notoSansTc(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        cycleProvider.startCycle(7);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '7 天',
                        style: GoogleFonts.notoSansTc(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
