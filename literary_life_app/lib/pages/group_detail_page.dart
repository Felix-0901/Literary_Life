import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../models/work.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import 'article_detail_page.dart';
import '../widgets/work_share_sheet.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<LiteraryWork> _works = [];
  bool _isLoading = true;
  final Set<int> _likedWorkIds = {};

  @override
  void initState() {
    super.initState();
    _fetchWorks();
  }

  Future<void> _fetchWorks() async {
    try {
      final works = await ApiService.getGroupWorks(widget.group.id);
      if (mounted) {
        setState(() {
          _works = works;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, int?>(
      (provider) => provider.user?.id,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '${widget.group.name} 的文章',
          style: GoogleFonts.notoSerifTc(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _works.isEmpty
          ? Center(
              child: Text(
                '群組內還沒有分享任何文章',
                style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchWorks,
              color: AppTheme.accent,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: _works.length,
                itemBuilder: (context, index) => _workCard(_works[index], currentUserId),
              ),
            ),
    );
  }

  Widget _workCard(LiteraryWork work, int? currentUserId) {
    final isLiked = _likedWorkIds.contains(work.id);
    final canShare = work.isPublished || currentUserId == work.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.divider),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticleDetailPage(work: work)),
          ).then((_) {
            _fetchWorks(); // Refresh counts when popping back
          });
        },
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
            const SizedBox(height: 14),
            Row(
              children: [
                if (work.isPublished) ...[
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
                ],
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
    return GestureDetector(
      onTap: onTap,
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
                          final result = await ApiService.createResponse(
                            workId: work.id,
                            content: controller.text.trim(),
                          );
                          if (!mounted || !ctx.mounted || result == null) {
                            return;
                          }
                          navigator.pop();
                          _fetchWorks();
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
