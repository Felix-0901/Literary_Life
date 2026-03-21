import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/work_provider.dart';
import '../models/work.dart';
import 'writing_editor_page.dart';
import '../widgets/work_share_sheet.dart';

class MyWorksPage extends StatefulWidget {
  const MyWorksPage({super.key});

  @override
  State<MyWorksPage> createState() => _MyWorksPageState();
}

class _MyWorksPageState extends State<MyWorksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkProvider>().fetchWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('我的作品', style: GoogleFonts.notoSerifTc()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WorkProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (provider.works.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 56,
                    color: AppTheme.textHint.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有作品',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '到創作頁面寫下你的第一篇作品',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: provider.works.length,
            itemBuilder: (context, index) =>
                _workCard(provider.works[index], provider),
          );
        },
      ),
    );
  }

  Widget _workCard(LiteraryWork work, WorkProvider provider) {
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
                    builder: (_) => WritingEditorPage(work: work),
                  ),
                ).then((_) {
                  workProvider.fetchWorks();
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            work.title,
                            style: GoogleFonts.notoSerifTc(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: work.isPublished
                                ? AppTheme.accent.withValues(alpha: 0.15)
                                : AppTheme.divider,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            work.isPublished ? '已發布' : '草稿',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: work.isPublished
                                  ? AppTheme.accent
                                  : AppTheme.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      work.genre,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      work.content,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                      maxLines: 3,
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
                  _publishButton(work, provider),
                  const SizedBox(width: 8),
                  const Spacer(),
                  _actionButton(
                    Icons.share_outlined,
                    '分享',
                    onTap: () => _showShareDialog(work),
                  ),
                  const SizedBox(width: 4),
                  _actionButton(
                    Icons.delete_outline_rounded,
                    '刪除',
                    onTap: () => _deleteWork(work, provider),
                    isActive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _publishButton(LiteraryWork work, WorkProvider provider) {
    final isPublished = work.isPublished;

    return TextButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final updatedWork = isPublished
            ? await provider.unpublishWork(work.id)
            : await provider.publishWork(work.id);

        if (!mounted || updatedWork == null) {
          if (mounted && provider.error != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(provider.error!, style: GoogleFonts.notoSansTc()),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              updatedWork.isPublished ? '作品已發布 ✦' : '已取消發布',
              style: GoogleFonts.notoSansTc(),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: Icon(
        isPublished ? Icons.unpublished_rounded : Icons.publish_rounded,
        size: 18,
      ),
      label: Text(
        isPublished ? '取消發布' : '發布',
        style: GoogleFonts.notoSansTc(fontSize: 13),
      ),
      style: TextButton.styleFrom(
        foregroundColor: isPublished ? AppTheme.error : AppTheme.accent,
        minimumSize: const Size(112, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  void _showShareDialog(LiteraryWork work) {
    showWorkShareSheet(context, work);
  }

  Future<void> _deleteWork(LiteraryWork work, WorkProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '確認刪除文章',
          style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '確定要刪除這篇文章嗎？刪除後將無法復原。',
          style: GoogleFonts.notoSansTc(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '刪除',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final ok = await provider.deleteWork(work.id);
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('文章已刪除', style: GoogleFonts.notoSansTc()),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? '刪除失敗，請再試一次',
          style: GoogleFonts.notoSansTc(),
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
