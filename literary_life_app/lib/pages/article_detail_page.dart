import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/inspiration.dart';
import '../models/work.dart';
import '../models/response.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/work_share_sheet.dart';
import '../widgets/quick_add_sheet.dart';

class ArticleDetailPage extends StatefulWidget {
  final LiteraryWork work;

  const ArticleDetailPage({super.key, required this.work});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late LiteraryWork _work;
  bool _isLiked = false;
  List<LiteraryResponse> _responses = [];
  bool _isLoadingResponses = true;
  bool _isLoadingWork = false;

  @override
  void initState() {
    super.initState();
    _work = widget.work;
    _refreshWork();
    _fetchResponses();
  }

  Future<void> _refreshWork() async {
    setState(() => _isLoadingWork = true);
    try {
      final work = await ApiService.getWorkById(widget.work.id);
      if (!mounted) return;
      setState(() {
        if (work != null) _work = work;
        _isLoadingWork = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWork = false);
    }
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
                      '回應「${_work.title}」',
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
                            workId: _work.id,
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
    showWorkShareSheet(context, _work);
  }

  List<String> _parseHashtags(String raw) {
    final tags = <String>[];
    for (final token in raw.split(RegExp(r'\s+'))) {
      final t = token.trim();
      if (t.isEmpty) continue;
      final normalized = t.startsWith('#') ? t : '#$t';
      if (!tags.contains(normalized)) tags.add(normalized);
    }
    return tags;
  }

  Future<List<Inspiration>> _getWorkInspirations() async {
    final data = await ApiService.getList(
      '${ApiConfig.worksUrl}/${_work.id}/inspirations',
    );
    return data.map((j) => Inspiration.fromJson(j)).toList();
  }

  void _showInspirationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      '靈感來源',
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '關閉',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Inspiration>>(
                  future: _getWorkInspirations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.accent),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '載入失敗：${snapshot.error}',
                            style: GoogleFonts.notoSansTc(color: AppTheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final list = snapshot.data ?? const <Inspiration>[];
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          '這篇文章沒有標記靈感來源',
                          style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final insp = list[index];
                        final title = insp.objectOrEvent.isNotEmpty
                            ? insp.objectOrEvent
                            : (insp.detailText.isNotEmpty ? insp.detailText : '（未命名靈感）');
                        final subtitleParts = <String>[];
                        if (insp.location.isNotEmpty) subtitleParts.add(insp.location);
                        if (insp.feeling.isNotEmpty) subtitleParts.add(insp.feeling);
                        final subtitle = subtitleParts.join(' · ');
                        return InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => QuickAddSheet(inspiration: insp),
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.notoSansTc(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.notoSansTc(
                                      fontSize: 12,
                                      color: AppTheme.textHint,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (insp.detailText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    insp.detailText,
                                    style: GoogleFonts.notoSansTc(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final canShare = _work.isPublished || currentUserId == _work.userId;
    final hashtags = _parseHashtags(_work.hashtags);

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
                          (_work.authorNickname ?? '?')[0],
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
                            _work.authorNickname ?? '匿名',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            _work.genre,
                            style: GoogleFonts.notoSansTc(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('yyyy/MM/dd').format(_work.createdAt),
                        style: GoogleFonts.notoSansTc(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                  if (_isLoadingWork) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.divider,
                      minHeight: 2,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _work.title,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (_work.completedCycleStartDate != null &&
                      _work.completedCycleEndDate != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_note_rounded,
                          size: 16,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '完成週期：${DateFormat('yyyy/MM/dd').format(_work.completedCycleStartDate!)} - ${DateFormat('yyyy/MM/dd').format(_work.completedCycleEndDate!)}',
                          style: GoogleFonts.notoSansTc(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hashtags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hashtags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.notoSansTc(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _work.content,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.8,
                    ),
                  ),
                  if (_work.inspirationIds.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: _showInspirationsSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_outlined,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '查看靈感來源（${_work.inspirationIds.length}）',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: AppTheme.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
