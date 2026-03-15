import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import 'group_detail_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text(
            '建立群組',
            style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '群組名稱',
                  labelStyle: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: '群組介紹',
                  labelStyle: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
              ),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final success = await context.read<GroupProvider>().createGroup(
                  _nameController.text.trim(),
                  _descController.text.trim(),
                );
                if (!mounted || !success) return;
                navigator.pop();
                _nameController.clear();
                _descController.clear();
              },
              child: Text(
                '建立',
                style: GoogleFonts.notoSansTc(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text(
            '加入群組',
            style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
          ),
          content: TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: '請輸入群組代碼',
              labelStyle: GoogleFonts.notoSansTc(color: AppTheme.textHint),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
              ),
            ),
            TextButton(
              onPressed: () async {
                final groupProvider = context.read<GroupProvider>();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final code = _codeController.text.trim();
                if (code.isEmpty) return;

                final success = await groupProvider.joinGroupByCode(code);
                if (!mounted) return;
                if (success) {
                  navigator.pop();
                  _codeController.clear();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('成功加入群組')),
                  );
                  return;
                }

                final error = groupProvider.error;
                messenger.showSnackBar(
                  SnackBar(content: Text(error ?? '加入失敗')),
                );
              },
              child: Text(
                '加入',
                style: GoogleFonts.notoSansTc(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '群組找文章',
          style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login_rounded),
            tooltip: '加入群組',
            onPressed: _showJoinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: '建立群組',
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (provider.groups.isEmpty) {
            return Center(
              child: Text(
                '目前沒有任何群組',
                style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return _groupCard(group);
            },
          );
        },
      ),
    );
  }

  Widget _groupCard(Group group) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  group.name,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  '${group.memberCount} 人',
                  style: GoogleFonts.notoSansTc(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: GoogleFonts.notoSansTc(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 16,
                    color: AppTheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                     onTap: () {
                       Clipboard.setData(ClipboardData(text: group.inviteCode));
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('已複製群組代碼: ${group.inviteCode}'),
                           duration: const Duration(seconds: 2),
                         ),
                       );
                     },
                     child: RichText(
                       text: TextSpan(
                         style: GoogleFonts.notoSansTc(
                           fontSize: 13,
                           color: AppTheme.primary,
                           fontWeight: FontWeight.w600,
                         ),
                         children: [
                           const TextSpan(text: '群組代碼: '),
                           TextSpan(
                             text: group.inviteCode,
                             style: const TextStyle(
                               decoration: TextDecoration.underline,
                               decorationThickness: 1.5,
                             ),
                           ),
                         ],
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
}
