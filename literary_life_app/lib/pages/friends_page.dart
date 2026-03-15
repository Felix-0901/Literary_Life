import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/friend_provider.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().fetchFriends();
      context.read<FriendProvider>().fetchPendingRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.trim().isNotEmpty) {
      context.read<FriendProvider>().searchUsers(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '好友',
          style: GoogleFonts.notoSerifTc(color: AppTheme.primary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.accent,
          tabs: [
            const Tab(text: '我的好友'),
            const Tab(text: '搜尋與加入'),
            Consumer<FriendProvider>(
              builder: (context, provider, _) {
                final count = provider.pendingRequests.length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('好友邀請'),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildSearchTab(),
          _buildPendingRequests(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.friends.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }
        if (provider.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 56,
                  color: AppTheme.textHint.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  '還沒有加入好友',
                  style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                ),
                const SizedBox(height: 6),
                Text(
                  '到搜尋頁面找找你的朋友吧',
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
          onRefresh: () => provider.fetchFriends(),
          child: ListView.builder(
            itemCount: provider.friends.length,
            itemBuilder: (context, index) {
              final friend = provider.friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    (friend.friendNickname ?? '?')[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  friend.friendNickname ?? '匿名',
                  style: GoogleFonts.notoSansTc(),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textHint,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '輸入使用者代碼 (如 #123456) 或暱稱',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.accent,
                ),
                onPressed: () => _onSearch(_searchController.text),
              ),
            ),
            onSubmitted: _onSearch,
          ),
        ),
        Expanded(
          child: Consumer<FriendProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }
              if (provider.searchResults.isEmpty) {
                return Center(
                  child: Text(
                    '輸入使用者代碼或暱稱來搜尋好友',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                  ),
                );
              }
              return ListView.builder(
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final user = provider.searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        user.nickname.isNotEmpty ? user.nickname[0] : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(user.nickname, style: GoogleFonts.notoSansTc()),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: user.userCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已複製用戶編號: ${user.userCode}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            '#${user.userCode}',
                            style: GoogleFonts.notoSansTc(
                              fontSize: 13,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.accent.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      user.bio,
                      style: GoogleFonts.notoSansTc(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                    ),
                    trailing: TextButton(
                      child: Text(
                        '加入好友',
                        style: GoogleFonts.notoSansTc(color: AppTheme.accent),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await provider.requestFriend(user.id);
                        if (!mounted || !success) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '已發送邀請 ✦',
                              style: GoogleFonts.notoSansTc(),
                            ),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequests() {
    return Consumer<FriendProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.pendingRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }
        if (provider.pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 56,
                  color: AppTheme.textHint.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  '沒有待處理的好友邀請',
                  style: GoogleFonts.notoSansTc(color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () => provider.fetchPendingRequests(),
          child: ListView.builder(
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              final friend = provider.pendingRequests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    (friend.friendNickname ?? '?')[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  friend.friendNickname ?? '匿名',
                  style: GoogleFonts.notoSansTc(),
                ),
                trailing: TextButton(
                  child: Text(
                    '接受',
                    style: GoogleFonts.notoSansTc(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await provider.acceptFriend(friend.id);
                    if (!mounted || !success) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '已成為好友 ✦',
                          style: GoogleFonts.notoSansTc(),
                        ),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
