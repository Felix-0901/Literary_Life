import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/inspiration_provider.dart';
import '../widgets/quick_add_sheet.dart';

class InspirationListPage extends StatefulWidget {
  const InspirationListPage({super.key});

  @override
  State<InspirationListPage> createState() => _InspirationListPageState();
}

class _InspirationListPageState extends State<InspirationListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspirationProvider>().fetchInspirations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('靈感紀錄', style: GoogleFonts.notoSerifTc())),
      floatingActionButton: FloatingActionButton(
        heroTag: 'inspiration_add_fab',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const QuickAddSheet(),
        ),
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.notoSansTc(fontSize: 14),
              onSubmitted: (v) => context
                  .read<InspirationProvider>()
                  .fetchInspirations(keyword: v),
              decoration: InputDecoration(
                hintText: '搜尋靈感...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context.read<InspirationProvider>().fetchInspirations();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: Consumer<InspirationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  );
                }
                if (provider.inspirations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 56,
                          color: AppTheme.textHint.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '還沒有靈感紀錄',
                          style: GoogleFonts.notoSansTc(
                            fontSize: 16,
                            color: AppTheme.textHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '生活中的每個瞬間都值得被記錄',
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
                  color: AppTheme.accent,
                  onRefresh: () => provider.fetchInspirations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: provider.inspirations.length,
                    itemBuilder: (context, index) {
                      final insp = provider.inspirations[index];
                      return Dismissible(
                        key: ValueKey(insp.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.error,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                '刪除靈感',
                                style: GoogleFonts.notoSansTc(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                '確定要刪除這筆靈感紀錄嗎？',
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
                        },
                        onDismissed: (_) => provider.deleteInspiration(insp.id),
                        child: InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => QuickAddSheet(inspiration: insp),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
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
                                if (insp.objectOrEvent.isNotEmpty)
                                  Text(
                                    insp.objectOrEvent,
                                    style: GoogleFonts.notoSansTc(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                if (insp.detailText.isNotEmpty) ...[
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
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    if (insp.location.isNotEmpty)
                                      _infoChip(
                                        Icons.place_outlined,
                                        insp.location,
                                      ),
                                    if (insp.feeling.isNotEmpty)
                                      _infoChip(
                                        Icons.favorite_outline_rounded,
                                        insp.feeling,
                                      ),
                                    if (insp.keywords.isNotEmpty) ...[
                                      ...insp.keywords
                                          .split(' ')
                                          .where((s) => s.isNotEmpty)
                                          .map((tag) {
                                            return _infoChip(
                                              Icons.tag_rounded,
                                              tag.startsWith('#')
                                                  ? tag
                                                  : '#$tag',
                                            );
                                          }),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textHint),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.notoSansTc(
              fontSize: 11,
              color: AppTheme.textHint,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
