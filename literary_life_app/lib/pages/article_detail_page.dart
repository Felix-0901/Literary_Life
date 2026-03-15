import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/work.dart';
import '../models/response.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/work_share_sheet.dart';

class ArticleDetailPage extends StatefulWidget {
  final LiteraryWork work;

  const ArticleDetailPage({super.key, required this.work});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool _isLiked = false;
  List<LiteraryResponse> _responses = [];
  bool _isLoadingResponses = true;

  @override
  void initState() {
    super.initState();
    _fetchResponses();
  }

  Future<void> _fetchResponses() async {
    try {
      final responses = await ApiService.getWorkResponses(widget.work.id);
      if (mounted) {
        setState(() {
          _responses = responses;
          _isLoadingResponses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingResponses = false);
    }
  }

  void _showResponseDialog() {
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
                      '回應「${widget.work.title}」',
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
                            workId: widget.work.id,
                            content: controller.text.trim(),
                          );
                          if (!mounted || !ctx.mounted || result == null) {
                            return;
                          }
                          navigator.pop();
                          _fetchResponses();
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

  void _showShareDialog() {
    showWorkShareSheet(context, widget.work);
  }

  Widget _compactActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        radius: 20,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, int?>(
      (provider) => provider.user?.id,
    );
    final canShare = widget.work.isPublished || currentUserId == widget.work.userId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('文章內容', style: GoogleFonts.notoSerifTc()),
        actions: [
          _compactActionIcon(
            icon: _isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            tooltip: '收藏',
            color: _isLiked ? AppTheme.error : AppTheme.textSecondary,
            onTap: () {
              setState(() => _isLiked = !_isLiked);
            },
          ),
          _compactActionIcon(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: '回應',
            onTap: _showResponseDialog,
          ),
          if (canShare)
            _compactActionIcon(
              icon: Icons.share_outlined,
              tooltip: '分享',
              onTap: _showShareDialog,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          (widget.work.authorNickname ?? '?')[0],
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
                            widget.work.authorNickname ?? '匿名',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            widget.work.genre,
                            style: GoogleFonts.notoSansTc(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('yyyy/MM/dd').format(widget.work.createdAt),
                        style: GoogleFonts.notoSansTc(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.work.title,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.work.content,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '共 ${_responses.length} 則回應',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoadingResponses)
            const SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (_responses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    '還沒有任何回應\n成為第一個回應的人吧！',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTc(
                      color: AppTheme.textHint,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final r = _responses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.8,
                        ),
                        child: Text(
                          (r.authorNickname ?? '?')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  r.authorNickname ?? '匿名',
                                  style: GoogleFonts.notoSansTc(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat(
                                    'yyyy/MM/dd HH:mm',
                                  ).format(r.createdAt.toLocal()),
                                  style: GoogleFonts.notoSansTc(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.content,
                              style: GoogleFonts.notoSansTc(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: _responses.length),
            ),
        ],
      ),
    );
  }
}
