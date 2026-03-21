import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/work_provider.dart';
import '../providers/cycle_provider.dart';
import '../services/api_service.dart';
import '../models/inspiration.dart';
import '../models/work.dart';

class WritingEditorPage extends StatefulWidget {
  final LiteraryWork? work;
  const WritingEditorPage({super.key, this.work});

  @override
  State<WritingEditorPage> createState() => _WritingEditorPageState();
}

class _WritingEditorPageState extends State<WritingEditorPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  String _selectedGenre = '散文';
  bool _saving = false;
  bool _aiLoading = false;

  final List<String> _genres = ['散文', '新詩', '短札記', '微小說', '書信體'];
  List<String> _hashtags = [];
  int? _completedCycleId;
  List<int> _selectedInspirationIds = [];
  bool _metadataInitialized = false;
  bool _loadingAvailableInspirations = false;
  String? _availableInspirationsError;
  List<Inspiration> _availableInspirations = [];

  @override
  void initState() {
    super.initState();
    if (widget.work != null) {
      _titleController.text = widget.work!.title;
      _contentController.text = widget.work!.content;
      _selectedGenre = widget.work!.genre;
      _hashtags = _parseHashtags(widget.work!.hashtags);
      _completedCycleId = widget.work!.completedCycleId;
      _selectedInspirationIds = List<int>.from(widget.work!.inspirationIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _hashtagController.dispose();
    super.dispose();
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

  String _joinHashtags(List<String> tags) {
    final normalized = <String>[];
    for (final t in tags) {
      final v = t.trim();
      if (v.isEmpty) continue;
      final withHash = v.startsWith('#') ? v : '#$v';
      if (!normalized.contains(withHash)) normalized.add(withHash);
    }
    return normalized.join(' ');
  }

  Future<void> _ensureMetadataLoaded() async {
    if (_metadataInitialized) return;
    _metadataInitialized = true;
    await context.read<CycleProvider>().fetchAllCycles();
    await _fetchAvailableInspirations();
  }

  Future<void> _fetchAvailableInspirations() async {
    setState(() {
      _loadingAvailableInspirations = true;
      _availableInspirationsError = null;
    });
    try {
      final base = Uri.parse('${ApiConfig.inspirationsUrl}/');
      final queryParameters = <String, String>{};
      if (_completedCycleId != null) {
        queryParameters['cycle_id'] = _completedCycleId.toString();
      }
      final url = queryParameters.isEmpty
          ? base.toString()
          : base.replace(queryParameters: queryParameters).toString();
      final data = await ApiService.getList(url);
      final list = data.map((j) => Inspiration.fromJson(j)).toList();
      if (!mounted) return;
      setState(() {
        _availableInspirations = list;
        _loadingAvailableInspirations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableInspirationsError = e.toString();
        _loadingAvailableInspirations = false;
      });
    }
  }

  void _openMetadataDrawer() {
    _ensureMetadataLoaded();
    _scaffoldKey.currentState?.openDrawer();
  }

  void _addHashtagsFromInput() {
    final input = _hashtagController.text.trim();
    if (input.isEmpty) return;
    final toAdd = _parseHashtags(input);
    setState(() {
      for (final t in toAdd) {
        if (!_hashtags.contains(t)) _hashtags.add(t);
      }
      _hashtagController.clear();
    });
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
    final hashtags = _joinHashtags(_hashtags);

    if (widget.work != null) {
      work = await workProvider.updateWork(
        widget.work!.id,
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        content: _contentController.text,
        hashtags: hashtags,
        completedCycleId: _completedCycleId,
        setCompletedCycleId: true,
        inspirationIds: _selectedInspirationIds,
      );
    } else {
      final cycleId = cycleProvider.currentCycle?.id;
      work = await workProvider.createWork(
        cycleId: cycleId,
        completedCycleId: _completedCycleId,
        title: _titleController.text.trim(),
        genre: _selectedGenre,
        content: _contentController.text,
        visibility: 'private',
        hashtags: hashtags,
        inspirationIds: _selectedInspirationIds,
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.work != null ? '編輯作品' : '創作',
          style: GoogleFonts.notoSerifTc(),
        ),
        leadingWidth: canPop ? 96 : 56,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPop)
              IconButton(
                tooltip: '返回',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            IconButton(
              tooltip: '文章設定',
              onPressed: _openMetadataDrawer,
              icon: const Icon(
                Icons.menu_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '文章設定',
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '關閉',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hashtag',
                          style: GoogleFonts.notoSansTc(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hashtagController,
                          onSubmitted: (_) => _addHashtagsFromInput(),
                          style: GoogleFonts.notoSansTc(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '#旅行 #夜晚',
                            suffixIcon: IconButton(
                              tooltip: '新增',
                              onPressed: _addHashtagsFromInput,
                              icon: const Icon(Icons.add_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_hashtags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _hashtags
                                .map(
                                  (t) => Chip(
                                    label: Text(
                                      t,
                                      style: GoogleFonts.notoSansTc(fontSize: 12),
                                    ),
                                    onDeleted: () => setState(() => _hashtags.remove(t)),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 22),
                        Text(
                          '完成週期',
                          style: GoogleFonts.notoSansTc(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<CycleProvider>(
                          builder: (context, provider, _) {
                            final completed = provider.allCycles
                                .where((c) => c.status == 'completed')
                                .toList();
                            String labelFor(int id) {
                              dynamic c;
                              for (final x in provider.allCycles) {
                                if (x.id == id) {
                                  c = x;
                                  break;
                                }
                              }
                              if (c == null) return '已選週期';
                              final df = DateFormat('yyyy/MM/dd');
                              return '${df.format(c.startDate)} - ${df.format(c.endDate)}';
                            }

                            return DropdownButtonFormField<int?>(
                              initialValue: _completedCycleId,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('未指定', style: GoogleFonts.notoSansTc()),
                                ),
                                ...completed.map((c) {
                                  final df = DateFormat('yyyy/MM/dd');
                                  final label =
                                      '${df.format(c.startDate)} - ${df.format(c.endDate)}';
                                  return DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(label, style: GoogleFonts.notoSansTc(fontSize: 13)),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _completedCycleId = value;
                                  _selectedInspirationIds = [];
                                });
                                _fetchAvailableInspirations();
                              },
                              decoration: InputDecoration(
                                hintText: _completedCycleId == null
                                    ? '選擇已完成週期'
                                    : labelFor(_completedCycleId!),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Text(
                              '靈感來源',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '已選 ${_selectedInspirationIds.length}',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 12,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_completedCycleId != null)
                          Text(
                            '僅顯示此週期期間內的靈感',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 12,
                              color: AppTheme.textHint,
                            ),
                          ),
                        if (_completedCycleId != null) const SizedBox(height: 6),
                        if (_loadingAvailableInspirations)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(color: AppTheme.accent),
                            ),
                          )
                        else if (_availableInspirationsError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _availableInspirationsError!,
                              style: GoogleFonts.notoSansTc(color: AppTheme.error, fontSize: 12),
                            ),
                          )
                        else if (_availableInspirations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              '沒有可選擇的靈感',
                              style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availableInspirations.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final insp = _availableInspirations[index];
                                final checked = _selectedInspirationIds.contains(insp.id);
                                final title = insp.objectOrEvent.isNotEmpty
                                    ? insp.objectOrEvent
                                    : (insp.detailText.isNotEmpty ? insp.detailText : '（未命名靈感）');
                                final subtitleParts = <String>[];
                                if (insp.location.isNotEmpty) subtitleParts.add(insp.location);
                                if (insp.feeling.isNotEmpty) subtitleParts.add(insp.feeling);
                                final subtitle = subtitleParts.join(' · ');
                                return CheckboxListTile(
                                  value: checked,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        if (!_selectedInspirationIds.contains(insp.id)) {
                                          _selectedInspirationIds.add(insp.id);
                                        }
                                      } else {
                                        _selectedInspirationIds.remove(insp.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    title,
                                    style: GoogleFonts.notoSansTc(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: subtitle.isEmpty
                                      ? null
                                      : Text(
                                          subtitle,
                                          style: GoogleFonts.notoSansTc(
                                            fontSize: 12,
                                            color: AppTheme.textHint,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 48),
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
