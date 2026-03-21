import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/work_provider.dart';
import '../providers/cycle_provider.dart';
import '../services/api_service.dart';
import '../models/work.dart';

class WritingEditorPage extends StatefulWidget {
  final LiteraryWork? work;
  const WritingEditorPage({super.key, this.work});

  @override
  State<WritingEditorPage> createState() => _WritingEditorPageState();
}

class _WritingEditorPageState extends State<WritingEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedGenre = '散文';
  bool _saving = false;
  bool _aiLoading = false;

  final List<String> _genres = ['散文', '新詩', '短札記', '微小說', '書信體'];

  @override
  void initState() {
    super.initState();
    if (widget.work != null) {
      _titleController.text = widget.work!.title;
      _contentController.text = widget.work!.content;
      _selectedGenre = widget.work!.genre;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveWork({bool publish = false, bool unpublish = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final workProvider = context.read<WorkProvider>();
    final cycleProvider = context.read<CycleProvider>();
    final shellController = context.read<MainShellController>();

    if (_titleController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('請輸入標題'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_contentController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('請輸入內容'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _saving = true);
    LiteraryWork? work;

    if (widget.work != null) {
      work = await workProvider.updateWork(
        widget.work!.id,
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        content: _contentController.text,
      );
    } else {
      final cycleId = cycleProvider.currentCycle?.id;
      work = await workProvider.createWork(
        cycleId: cycleId,
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        content: _contentController.text,
        visibility: 'private',
      );
    }

    if (mounted && work != null) {
      final isNowPublished = widget.work?.isPublished ?? false;
      if (publish && !isNowPublished) {
        await workProvider.publishWork(work.id);
      } else if (unpublish && isNowPublished) {
        await workProvider.unpublishWork(work.id);
      }

      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            unpublish ? '已取消發布 ✦' : (publish ? '作品已發布 ✦' : '作品已儲存 ✦'),
            style: GoogleFonts.notoSansTc(),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Home tab or pop back
      if (widget.work == null) {
        _titleController.clear();
        _contentController.clear();
        shellController.switchTab(0);
      } else {
        navigator.pop();
      }
    } else {
      if (mounted) {
        setState(() => _saving = false);
        final errorMsg = workProvider.error ?? '儲存失敗，請再試一次';
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errorMsg, style: GoogleFonts.notoSansTc()),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getAiHelp(String helpType) async {
    final messenger = ScaffoldMessenger.of(context);
    final content = _contentController.text;
    if (content.isEmpty && helpType != 'title') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('請先輸入一些文字'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final contextText = helpType == 'title'
        ? '文體：$_selectedGenre\n${_contentController.text}'
        : _contentController.text;

    setState(() => _aiLoading = true);

    try {
      final result = await ApiService.getWritingHelp(helpType, contextText);
      if (!mounted) return;
      setState(() => _aiLoading = false);
      _showAiResult(helpType, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('AI 暫時無法使用：$e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showAiResult(String helpType, String result) {
    final titles = {
      'title': '標題建議',
      'opening': '開頭句建議',
      'polish': '文字潤飾',
      'structure': '段落結構建議',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titles[helpType] ?? 'AI 建議',
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SelectableText(
                  result,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (helpType == 'polish')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _contentController.text = result;
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '套用潤飾結果',
                          style: GoogleFonts.notoSansTc(color: Colors.white),
                        ),
                      ),
                    ),
                  if (helpType == 'polish') const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.divider),
                      ),
                      child: Text(
                        '關閉',
                        style: GoogleFonts.notoSansTc(
                          color: AppTheme.textSecondary,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPublished = widget.work?.isPublished ?? false;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.work != null ? '編輯作品' : '創作',
          style: GoogleFonts.notoSerifTc(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: '儲存',
              onPressed: _saveWork,
              icon: const Icon(
                Icons.save_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          heroTag: 'writing_publish_fab',
          onPressed:
              _saving ? null : () => _saveWork(publish: !isPublished, unpublish: isPublished),
          backgroundColor: isPublished ? AppTheme.error : AppTheme.accent,
          shape: const CircleBorder(),
          tooltip: isPublished ? '取消發布' : '發布',
          child: Icon(
            isPublished ? Icons.public_off_rounded : Icons.publish_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre selector
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _genres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final genre = _genres[index];
                      final isSelected = genre == _selectedGenre;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGenre = genre),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Text(
                            genre,
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Title field
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '作品標題',
                    hintStyle: GoogleFonts.notoSerifTc(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textHint,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
                const Divider(height: 24, color: AppTheme.divider),
              ],
            ),
          ),

          // Content field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.notoSansTc(
                  fontSize: 16,
                  color: AppTheme.primary,
                  height: 2.0,
                ),
                decoration: InputDecoration(
                  hintText: '在這裡寫下你的文字...\n讓日常的片段，化作文學的語言。',
                  hintStyle: GoogleFonts.notoSansTc(
                    fontSize: 16,
                    color: AppTheme.textHint,
                    height: 2.0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // AI Assist Toolbar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SafeArea(
              top: false,
              child: _aiLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '拾字 AI 思考中...',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _aiChip('標題', () => _getAiHelp('title')),
                          _aiChip('開頭', () => _getAiHelp('opening')),
                          _aiChip('潤飾', () => _getAiHelp('polish')),
                          _aiChip('結構', () => _getAiHelp('structure')),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansTc(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
