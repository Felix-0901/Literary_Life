import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/friend.dart';
import '../models/work.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';

enum _WorkShareMode { menu, friendPicker }

Future<void> showWorkShareSheet(BuildContext context, LiteraryWork work) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WorkShareSheet(work: work, messenger: messenger),
  );
}

class _WorkShareSheet extends StatefulWidget {
  const _WorkShareSheet({required this.work, required this.messenger});

  final LiteraryWork work;
  final ScaffoldMessengerState messenger;

  @override
  State<_WorkShareSheet> createState() => _WorkShareSheetState();
}

class _WorkShareSheetState extends State<_WorkShareSheet> {
  _WorkShareMode _mode = _WorkShareMode.menu;
  final Set<int> _selectedFriendIds = <int>{};
  List<Friend> _friends = <Friend>[];
  bool _isLoadingFriends = false;
  bool _isSending = false;
  String? _friendsError;
  String? _shareError;

  Future<void> _openFriendPicker() async {
    setState(() {
      _mode = _WorkShareMode.friendPicker;
    });
    if (_friends.isNotEmpty || _isLoadingFriends) {
      return;
    }

    setState(() {
      _isLoadingFriends = true;
      _friendsError = null;
    });

    try {
      final friends = await ApiService.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _friendsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFriends = false;
        });
      }
    }
  }

  Future<void> _shareToGroups() async {
    if (_isSending) return;

    final navigator = Navigator.of(context);
    final notificationProvider = context.read<NotificationProvider>();
    setState(() {
      _isSending = true;
      _shareError = null;
    });

    try {
      await ApiService.shareWork(workId: widget.work.id, targetType: 'group');
      if (!mounted) return;
      await notificationProvider.fetchNotifications();
      navigator.pop();
      widget.messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('發送成功！已分享到群組 ✦', style: GoogleFonts.notoSansTc()),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _shareError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendFriendShare() async {
    if (_isSending || _selectedFriendIds.isEmpty) return;

    final navigator = Navigator.of(context);
    final notificationProvider = context.read<NotificationProvider>();
    setState(() {
      _isSending = true;
      _shareError = null;
    });

    try {
      await ApiService.shareWork(
        workId: widget.work.id,
        targetType: 'friend',
        targetIds: _selectedFriendIds.toList(),
      );
      if (!mounted) return;
      await notificationProvider.fetchNotifications();
      navigator.pop();
      final count = _selectedFriendIds.length;
      widget.messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('發送成功！已分享給 $count 位好友 ✦', style: GoogleFonts.notoSansTc()),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _shareError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _mode == _WorkShareMode.menu
                ? _buildMenu()
                : _buildFriendPicker(),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      key: const ValueKey<String>('menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        _buildHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '分享「${widget.work.title}」',
                style: GoogleFonts.notoSerifTc(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              _shareOption(
                icon: Icons.people_outline_rounded,
                title: '分享給好友',
                subtitle: '勾選好友後再發送',
                onTap: _openFriendPicker,
              ),
              _shareOption(
                icon: Icons.group_work_outlined,
                title: '分享到群組',
                subtitle: '群組成員能看到',
                onTap: _shareToGroups,
              ),
              if (_shareError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '發送失敗：$_shareError',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 14,
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendPicker() {
    final friends = _friends;
    final canSend = _selectedFriendIds.isNotEmpty && !_isSending;

    return Column(
      key: const ValueKey<String>('friends'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        _buildHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _isSending
                    ? null
                    : () {
                        setState(() {
                          _mode = _WorkShareMode.menu;
                        });
                      },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppTheme.textSecondary,
              ),
              Expanded(
                child: Text(
                  '選擇要分享的好友',
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Text(
                _selectedFriendIds.isEmpty
                    ? '未選擇'
                    : '已選 ${_selectedFriendIds.length}',
                style: GoogleFonts.notoSansTc(
                  fontSize: 12,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingFriends)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppTheme.accent),
          )
        else if (_friendsError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _statusCard(
              icon: Icons.error_outline_rounded,
              title: '好友載入失敗',
              subtitle: _friendsError!,
            ),
          )
        else if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _statusCard(
              icon: Icons.people_outline_rounded,
              title: '目前還沒有好友',
              subtitle: '先加入好友，之後就能勾選對象來分享文章。',
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              itemCount: friends.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final isSelected = _selectedFriendIds.contains(friend.friendId);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isSending
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriendIds.remove(friend.friendId);
                            } else {
                              _selectedFriendIds.add(friend.friendId);
                            }
                          });
                        },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.warmGold50
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : AppTheme.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (friend.friendNickname ?? '?')[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            friend.friendNickname ?? '匿名好友',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          onChanged: _isSending
                              ? null
                              : (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedFriendIds.remove(
                                        friend.friendId,
                                      );
                                    } else {
                                      _selectedFriendIds.add(friend.friendId);
                                    }
                                  });
                                },
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_shareError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '發送失敗：$_shareError',
              style: GoogleFonts.notoSansTc(
                fontSize: 14,
                color: AppTheme.error,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSend ? _sendFriendShare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.divider,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedFriendIds.isEmpty ? '請先選擇好友' : '發送',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: _isSending ? null : onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.accent, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSansTc(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.notoSansTc(fontSize: 12, color: AppTheme.textHint),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppTheme.textHint,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textHint, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.notoSansTc(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTc(
              fontSize: 12,
              color: AppTheme.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
