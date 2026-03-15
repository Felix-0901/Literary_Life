import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/cycle_provider.dart';
import '../services/api_service.dart';

class CycleHistoryPage extends StatefulWidget {
  const CycleHistoryPage({super.key});

  @override
  State<CycleHistoryPage> createState() => _CycleHistoryPageState();
}

class _CycleHistoryPageState extends State<CycleHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CycleProvider>().fetchAllCycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('週期紀錄', style: GoogleFonts.notoSerifTc()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CycleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (provider.allCycles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 56,
                    color: AppTheme.textHint.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有週期紀錄',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 16,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '回首頁開始你的第一個創作週期',
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
            itemCount: provider.allCycles.length,
            itemBuilder: (context, index) {
              final cycle = provider.allCycles[index];
              final isActive = cycle.status == 'active';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isActive ? AppTheme.accentLight : AppTheme.divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.timer_outlined
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: isActive
                                  ? AppTheme.accent
                                  : AppTheme.textHint,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${cycle.cycleType} 天週期',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.accent.withValues(alpha: 0.15)
                                : AppTheme.divider.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? '進行中' : '已完成',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppTheme.accent
                                  : AppTheme.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${cycle.startDate.month}/${cycle.startDate.day} — ${cycle.endDate.month}/${cycle.endDate.day}',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (!isActive) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _analyzeInspirations(cycle.id),
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'AI 靈感分析',
                            style: GoogleFonts.notoSansTc(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondary,
                            side: BorderSide(
                              color: AppTheme.secondary.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    if (isActive) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final cycleProvider = context.read<CycleProvider>();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  '結束週期',
                                  style: GoogleFonts.notoSansTc(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  '確定要提前結束此週期嗎？',
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
                                      '確定',
                                      style: TextStyle(color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await cycleProvider.endCycle();
                              if (!mounted) return;
                              cycleProvider.fetchAllCycles();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            '結束週期',
                            style: GoogleFonts.notoSansTc(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _analyzeInspirations(int cycleId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(width: 20),
            Text('拾字 AI 正在分析靈感...', style: GoogleFonts.notoSansTc()),
          ],
        ),
      ),
    );

    try {
      final result = await ApiService.analyzeInspirations(cycleId);
      if (!mounted) return;
      navigator.pop();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '靈感分析結果',
                style: GoogleFonts.notoSerifTc(
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              result['analysis'] ?? '分析完成，但沒有收到結果。',
              style: GoogleFonts.notoSansTc(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '關閉',
                style: GoogleFonts.notoSansTc(color: AppTheme.accent),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('分析失敗：$e'), backgroundColor: AppTheme.error),
      );
    }
  }
}
