import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../navigation/main_shell_controller.dart';
import '../providers/quote_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/inspiration_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/quick_add_sheet.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuoteProvider>().fetchDailyQuote();
      context.read<CycleProvider>().fetchCurrentCycle();
      context.read<InspirationProvider>().fetchInspirations();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '拾字日常',
                            style: GoogleFonts.notoSerifTc(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Notification bell with badge
                      Consumer2<NotificationProvider, CycleProvider>(
                        builder: (context, notifProvider, cycleProvider, _) {
                          final hasUnread = notifProvider.unreadCount > 0;
                          final needsCycle = cycleProvider.currentCycle == null;
                          final showBadge = hasUnread || needsCycle;

                          return Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationPage(),
                                    ),
                                  ).then((_) {
                                    if (!context.mounted) return;
                                    context
                                        .read<NotificationProvider>()
                                        .fetchNotifications();
                                  });
                                },
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (showBadge)
                                Positioned(
                                  right: 11,
                                  top: 11,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Daily Quote Card
                  _buildDailyQuoteCard(),
                  const SizedBox(height: 16),

                  // Cycle Info Card
                  Consumer<CycleProvider>(
                    builder: (context, cycleProvider, _) {
                      if (cycleProvider.currentCycle == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCycleCard(),
                      );
                    },
                  ),

                  // Quick Add Button
                  _buildQuickAddCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Recent Inspirations Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '最近的靈感',
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Consumer<InspirationProvider>(
                    builder: (context, provider, _) {
                      if (provider.inspirations.isNotEmpty) {
                        return TextButton(
                          onPressed: () {
                            context.read<MainShellController>().switchTab(1);
                          },
                          child: Text(
                            '查看全部',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Recent Inspirations List (Fixed Frame with Scrollable Content)
            Expanded(child: _buildRecentInspirationsList()),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了，靈感最豐沛的時刻';
    if (hour < 12) return '早安，今天也要拾起文字';
    if (hour < 18) return '午後的光，適合寫字';
    return '晚安，用文字收束今日';
  }

  Widget _buildDailyQuoteCard() {
    return Consumer<QuoteProvider>(
      builder: (context, quoteProvider, _) {
        final quote = quoteProvider.dailyQuote;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary,
                AppTheme.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '✦',
                    style: TextStyle(fontSize: 12, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '每日一句',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                quote?.content ?? '把生活拾起，寫成文字。',
                style: GoogleFonts.notoSerifTc(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '— ${quote?.author ?? '拾字日常'}',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => quoteProvider.refreshQuote(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '換一句',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleCard() {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, _) {
        final cycle = cycleProvider.currentCycle;
        if (cycle == null) {
          return const SizedBox.shrink();
        }

        final progress = 1.0 - (cycle.daysRemaining / cycle.cycleType);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.divider),
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
                        Icons.timer_outlined,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cycle.cycleType} 天創作週期',
                        style: GoogleFonts.notoSansTc(
                          fontSize: 14,
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
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '剩餘 ${cycle.daysRemaining} 天',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddCard() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const QuickAddSheet(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_rounded, color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '記一筆靈感',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '快速記錄你此刻的感受與觀察',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInspirationsList() {
    return Consumer<InspirationProvider>(
      builder: (context, provider, _) {
        if (provider.inspirations.isEmpty) {
          // 純靜態佈局：為了避免小螢幕上溢出 (Bottom Overflowed)，還是需使其能夠擴展，但禁用滑動實體
          return Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: AppTheme.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '還沒有靈感紀錄',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 14,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '點擊上方按鈕，開始記錄生活中的每一個瞬間',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // 有資料時：才套用 RefreshIndicator 與可滑動的 ListView
        final list = provider.inspirations.take(5).toList();
        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async {
            final quoteProvider = context.read<QuoteProvider>();
            final cycleProvider = context.read<CycleProvider>();
            final inspirationProvider = context.read<InspirationProvider>();
            final notificationProvider = context.read<NotificationProvider>();

            await quoteProvider.fetchDailyQuote();
            await cycleProvider.fetchCurrentCycle();
            await inspirationProvider.fetchInspirations();
            await notificationProvider.fetchNotifications();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _inspirationItem(list[index]);
            },
          ),
        );
      },
    );
  }

  Widget _inspirationItem(dynamic insp) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((insp.objectOrEvent as String).isNotEmpty)
            Text(
              insp.objectOrEvent,
              style: GoogleFonts.notoSansTc(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          if ((insp.detailText as String).isNotEmpty) ...[
            const SizedBox(height: 6),
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
          const SizedBox(height: 12),
          Row(
            children: [
              if ((insp.location as String).isNotEmpty) ...[
                Icon(Icons.place_outlined, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  insp.location,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if ((insp.feeling as String).isNotEmpty) ...[
                Icon(
                  Icons.favorite_outline_rounded,
                  size: 14,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  insp.feeling,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${insp.createdAt.month}/${insp.createdAt.day}',
                style: GoogleFonts.notoSansTc(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
