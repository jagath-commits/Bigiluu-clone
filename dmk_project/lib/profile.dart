import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dmk_project/app_theme.dart';
import 'package:dmk_project/home.dart';
import 'package:dmk_project/profile1.dart';
import 'package:dmk_project/write.dart' deferred as write;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final bool isPublicView;
  final String? initialPostId;

  const ProfilePage({
    super.key,
    required this.userId,
    this.isPublicView = false,
    this.initialPostId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  static const _baseUrl = 'https://bigiluu.com/api';

  late TabController _tabController;

  String _username = '';
  String? _constituency;
  String? _profileImageUrl;
  String? _profileImagePath;

  List<Map<String, dynamic>> _myPosts = [];
  List<Map<String, dynamic>> _drafts = [];
  List<Map<String, dynamic>> _savedPosts = [];

  Set<String> _likedPosts = {};
  Set<String> _savedPostIds = {};

  bool _loadingProfile = true;
  bool _loadingPosts = true;
  bool _loadingDrafts = true;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadInteractions(),
      _fetchMyPosts(),
      _fetchDrafts(),
      _fetchSavedPosts(),
    ]);
  }

  Future<void> _loadInteractions() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _likedPosts = (prefs.getStringList('cached_liked_posts') ?? []).toSet();
      _savedPostIds = (prefs.getStringList('cached_saved_posts') ?? []).toSet();
    });
  }

  Future<void> _saveInteractionsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_liked_posts', _likedPosts.toList());
    await prefs.setStringList('cached_saved_posts', _savedPostIds.toList());
  }

  String _fullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    path = path.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    path = path
        .replaceAll('Uploads', 'uploads')
        .replaceAll('Profile_images', 'profile_images');
    if (!path.contains('/')) {
      path = 'uploads/profile_images/$path';
    }
    return 'https://bigiluu.com/$path';
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    final prefs = await SharedPreferences.getInstance();

    _username = prefs.getString('username') ?? '';
    _constituency = prefs.getString('user_constituency');
    _profileImageUrl = prefs.getString('profile_image_url');
    _profileImagePath = prefs.getString('profile_image_path');

    if (widget.userId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/profile/profile/${widget.userId}'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map) {
            _username = data['username']?.toString() ?? _username;
            final constituency = data['Constituency']?.toString();
            if (constituency != null && constituency.isNotEmpty) {
              _constituency = constituency;
            }
            final image = data['profile_image']?.toString();
            if (image != null && image.isNotEmpty) {
              _profileImageUrl = _fullUrl(image);
              _profileImagePath = null;
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    if (widget.userId.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$endpoint/${widget.userId}'),
      );
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (decoded['data'] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
      }
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
          decoded.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (_) {}
    return [];
  }

  Future<void> _fetchMyPosts() async {
    setState(() => _loadingPosts = true);
    final posts = await _fetchList('userposts');
    if (mounted) {
      setState(() {
        _myPosts = posts;
        _loadingPosts = false;
      });
    }
  }

  Future<void> _fetchDrafts() async {
    setState(() => _loadingDrafts = true);
    var drafts = await _fetchList('getdraftposts');
    if (drafts.isEmpty) {
      drafts = await _fetchList('draftposts');
    }
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _loadingDrafts = false;
      });
    }
  }

  Future<void> _fetchSavedPosts() async {
    setState(() => _loadingSaved = true);
    final posts = await _fetchList('savedposts');
    if (mounted) {
      setState(() {
        _savedPosts = posts;
        _loadingSaved = false;
      });
    }
  }

  ImageProvider? _avatarProvider() {
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      final file = File(_profileImagePath!);
      if (file.existsSync()) return FileImage(file);
    }
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(_profileImageUrl!);
    }
    return null;
  }

  Future<void> _openEditProfile() async {
    if (widget.userId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(userId: widget.userId),
      ),
    );
    if (mounted) _loadAll();
  }

  Future<void> _openDraft(Map<String, dynamic> draft) async {
    await write.loadLibrary();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => write.WritePage(
          category: draft['category_id']?.toString(),
          draftId: draft['draft_id']?.toString() ?? draft['id']?.toString(),
          draftContent: draft['content']?.toString(),
          draftCover: draft['cover_img']?.toString(),
        ),
      ),
    );
    if (mounted) _fetchDrafts();
  }

  Future<void> _toggleLike(String postId) async {
    final isLiked = _likedPosts.contains(postId);
    setState(() {
      if (isLiked) {
        _likedPosts.remove(postId);
      } else {
        _likedPosts.add(postId);
      }
    });
    await _saveInteractionsLocal();
  }

  Future<void> _toggleSave(String postId) async {
    final isSaved = _savedPostIds.contains(postId);
    setState(() {
      if (isSaved) {
        _savedPostIds.remove(postId);
      } else {
        _savedPostIds.add(postId);
      }
    });
    await _saveInteractionsLocal();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _username.isNotEmpty
        ? _username
        : (widget.userId.isNotEmpty ? widget.userId : 'Guest');

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _loadAll,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildProfileHeader(displayName)),
            SliverToBoxAdapter(child: _buildSegmentedTabs()),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(
                _myPosts,
                _loadingPosts,
                icon: Icons.article_outlined,
                title: 'No posts yet',
                subtitle: 'Stories you publish will appear here',
              ),
              _buildDraftsTab(),
              _buildPostsTab(
                _savedPosts,
                _loadingSaved,
                icon: Icons.bookmark_border_rounded,
                title: 'Nothing saved',
                subtitle: 'Bookmark stories to read them later',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String displayName) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                if (!widget.isPublicView)
                  Material(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _openEditProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.brand,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.brand.withValues(alpha: 0.08),
                backgroundImage: _avatarProvider(),
                child: _avatarProvider() == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildSimpleCounts(),
            if (_constituency != null && _constituency!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _constituency!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (_loadingProfile)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCounts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countText(
          _loadingPosts ? '—' : '${_myPosts.length}',
          'Posts',
        ),
        _countDivider(),
        _countText(
          _loadingDrafts ? '—' : '${_drafts.length}',
          'Drafts',
        ),
        _countDivider(),
        _countText(
          _loadingSaved ? '—' : '${_savedPosts.length}',
          'Saved',
        ),
      ],
    );
  }

  Widget _countText(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _segmentTab(
              0,
              Icons.article_outlined,
              'My Posts',
            ),
            _segmentTab(
              1,
              Icons.drafts_outlined,
              'Drafts',
            ),
            _segmentTab(
              2,
              Icons.bookmark_outline_rounded,
              'Saved',
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab(int index, IconData icon, String label) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: AppColors.brand),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(
    List<Map<String, dynamic>> posts,
    bool isLoading, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (posts.isEmpty) {
      return _buildEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final postId = post['post_id']?.toString() ?? '';
        return PostContainer(
          post: post,
          isLiked: _likedPosts.contains(postId),
          isSaved: _savedPostIds.contains(postId),
          onLike: () => _toggleLike(postId),
          onSave: () => _toggleSave(postId),
        );
      },
    );
  }

  Widget _buildDraftsTab() {
    if (_loadingDrafts) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (_drafts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.drafts_outlined,
        title: 'No drafts yet',
        subtitle: 'Start writing and save as draft to continue later',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _drafts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        final title = draft['title']?.toString().trim();
        final label =
            title != null && title.isNotEmpty ? title : 'Untitled draft';
        final updated = draft['updated_at']?.toString() ??
            draft['created_at']?.toString();

        return Material(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _openDraft(draft),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.brand.withValues(alpha: 0.15),
                            AppColors.brand.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            updated != null && updated.isNotEmpty
                                ? 'Last edited · $updated'
                                : 'Tap to continue writing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
