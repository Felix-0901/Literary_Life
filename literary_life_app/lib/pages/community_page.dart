import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../providers/work_provider.dart';
import '../services/api_service.dart';
import '../navigation/main_shell_controller.dart';
import '../widgets/work_share_sheet.dart';
import 'article_detail_page.dart';
import 'friends_page.dart';
import 'group_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final Set<int> _likedWorkIds = {};
  final ScrollController _scrollController = ScrollController();
  int _lastReClickTrigger = 0;
  int _lastIndex = 0;
  String _feedType = 'literary';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkProvider>().fetchCommunityFeed(workType: _feedType);
        _setupTabListener();
      }
    });
  }

  void _setupTabListener() {
    final shellController = context.read<MainShellController>();
    shellController.addListener(_onTabChanged);
    _lastReClickTrigger = shellController.reClickTrigger;
    _lastIndex = shellController.currentIndex;
  }

  void _onTabChanged() {
    if (!mounted) return;
    final shellController = context.read<MainShellController>();
    final workProvider = context.read<WorkProvider>();
    
    // Check if the current tab is the Community tab (index 3)
    if (shellController.currentIndex == 3) {
      // 1. If it was a re-click on the already active tab
      if (shellController.reClickTrigger != _lastReClickTrigger) {
        _lastReClickTrigger = shellController.reClickTrigger;
        _scrollToTopAndRefresh();
      }
      // 2. If we just switched to this tab from another tab
      else if (_lastIndex != 3) {
        // Silent refresh if we already have works, otherwise show loading
        workProvider.fetchCommunityFeed(
          silent: workProvider.publicWorks.isNotEmpty,
          workType: _feedType,
        );
      }
    }
    _lastIndex = shellController.currentIndex;
  }

  void _scrollToTopAndRefresh() {
    final workProvider = context.read<WorkProvider>();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        workProvider.fetchCommunityFeed(silent: true, workType: _feedType);
      });
    } else {
      workProvider.fetchCommunityFeed(silent: true, workType: _feedType);
    }
  }

  void _onFeedTypeChanged(String newType) {
    if (newType == _feedType) return;
    setState(() => _feedType = newType);
    context.read<WorkProvider>().fetchCommunityFeed(workType: _feedType);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    // Note: We need to be careful with removing the listener if we don't have the same controller instance
    // but typically it's fine as long as we use the same context or store it.
    try {
      context.read<MainShellController>().removeListener(_onTabChanged);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, int?>(
      (provider) => provider.user?.id,
    );

    final feedLabel = _feedType == 'life' ? '生活貼文' : '文學社群';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: PopupMenuButton<String>(
          initialValue: _feedType,
          tooltip: '切換社群類型',
          onSelected: _onFeedTypeChanged,
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'literary',
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: _feedType == 'literary'
                        ? AppTheme.accent
                        : AppTheme.textHint,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '文學社群',
                    style: GoogleFonts.notoSerifTc(
                      fontWeight: _feedType == 'literary'
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _feedType == 'literary'
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'life',
              child: Row(
                children: [
                  Icon(
                    Icons.local_cafe_outlined,
                    size: 18,
                    color: _feedType == 'life'
                        ? AppTheme.accent
                        : AppTheme.textHint,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '生活貼文',
                    style: GoogleFonts.notoSerifTc(
                      fontWeight: _feedType == 'life'
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _feedType == 'life'
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feedLabel,
                style: GoogleFonts.notoSerifTc(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
        actions: [
          Tooltip(
            message: '好友',
            child: InkResponse(
              radius: 20,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendsPage()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<WorkProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final publishedWorks = provider.publicWorks;
          if (publishedWorks.isEmpty) {
            final isLife = _feedType == 'life';
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLife
                        ? Icons.local_cafe_outlined
                        : Icons.menu_book_rounded,
                    size: 56,
                    color: AppTheme.textHint.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLife ? '還沒有人分享生活貼文' : '還沒有已發布的作品',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLife
                        ? '記下日常片段，與朋友分享你的生活'
                        : '完成創作後發布，與朋友分享你的文字',
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
            onRefresh: () => provider.fetchCommunityFeed(workType: _feedType),
            color: AppTheme.accent,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: publishedWorks.length,
              itemBuilder: (context, index) =>
                  _workCard(publishedWorks[index], currentUserId),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_group_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupPage()),
          );
        },
        backgroundColor: AppTheme.accent,
        shape: const CircleBorder(),
        tooltip: '群組找文章',
        child: const Icon(Icons.groups_outlined, color: Colors.white),
      ),
    );
  }

  Widget _workCard(LiteraryWork work, int? currentUserId) {
    final isLiked = _likedWorkIds.contains(work.id);
    final canShare = work.isPublished || currentUserId == work.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium),
              ),
              onTap: () {
                final workProvider = context.read<WorkProvider>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailPage(work: work),
                  ),
                ).then((_) {
                  workProvider.fetchCommunityFeed(workType: _feedType);
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (work.authorNickname ?? '?')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              work.authorNickname ?? '匿名',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              work.genre,
                              style: GoogleFonts.notoSansTc(
                                fontSize: 11,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy/MM/dd').format(work.createdAt),
                          style: GoogleFonts.notoSansTc(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      work.title,
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      work.content,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.7,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _actionButton(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    '收藏',
                    isActive: isLiked,
                    onTap: () {
                      setState(() {
                        if (isLiked) {
                          _likedWorkIds.remove(work.id);
                        } else {
                          _likedWorkIds.add(work.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    Icons.chat_bubble_outline_rounded,
                    '回應',
                    onTap: () => _showResponseDialog(work),
                  ),
                  if (canShare) ...[
                    const SizedBox(width: 16),
                    _actionButton(
                      Icons.share_outlined,
                      '分享',
                      onTap: () => _showShareDialog(work),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${work.responseCount} 則回應',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.error : AppTheme.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.notoSansTc(
                fontSize: 12,
                color: isActive ? AppTheme.error : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(LiteraryWork work) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '回應「${work.title}」',
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      autofocus: true,
                      style: GoogleFonts.notoSansTc(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '寫下你的文學回應...',
                        hintStyle: GoogleFonts.notoSansTc(
                          color: AppTheme.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);
                          try {
                            final result = await ApiService.createResponse(
                              workId: work.id,
                              content: controller.text.trim(),
                            );
                            if (!mounted || !ctx.mounted || result == null) {
                              return;
                            }
                            navigator.pop();
                            if (!mounted) return;
                            context.read<WorkProvider>().fetchCommunityFeed(
                                  workType: _feedType,
                                );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '回應已送出 ✦',
                                  style: GoogleFonts.notoSansTc(),
                                ),
                                backgroundColor: AppTheme.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '回應送出失敗：$error',
                                  style: GoogleFonts.notoSansTc(),
                                ),
                                backgroundColor: AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '送出回應',
                          style: GoogleFonts.notoSansTc(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(LiteraryWork work) {
    showWorkShareSheet(context, work);
  }
}
