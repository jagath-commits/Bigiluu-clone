import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dmk_project/api_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dmk_project/app_bottom_nav.dart';
import 'package:dmk_project/app_theme.dart';
import 'package:dmk_project/hashtag.dart';
import 'package:dmk_project/profile.dart';
import 'package:dmk_project/legal_pages.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// MAIN SHELL (TAB COORDINATOR)
// ==========================================
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _isLoading = false;
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 1:
        return const HashtagPage();
      case 2:
        return ProfilePage(userId: _userId ?? '', isPublicView: false);
      case 0:
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: AppBottomNavBar(
        activeIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ==========================================
// HOME PAGE (STORY FEED)
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _posts = [];
  Set<String> _likedPosts = {};
  Set<String> _savedPosts = {};
  bool _isLoading = true;
  String _selectedCategoryId = 'all';
  String? _userId;

  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _limit = 10;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;

  static const List<({String id, String label})> _categories = [
    (id: 'all', label: 'அனைத்தும்'),
    (id: '4', label: 'நூலகம்'),
    (id: '2', label: 'சிந்தனைகள்'),
    (id: '3', label: 'அறிக்கைகள்'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    _loadUserAndFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndFeed() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    await _fetchFeed();
    await _fetchUserInteractions();
  }

  Future<void> _fetchFeed() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasNextPage = true;
    });
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.apiBaseUrl}/posts?page=$_page&limit=$_limit"),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          _posts = List<Map<String, dynamic>>.from(
            (decoded['data'] as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
        }
        if (decoded is Map && decoded['pagination'] is Map) {
          final pagination = decoded['pagination'];
          final totalPages = int.tryParse(pagination['totalPages']?.toString() ?? '1') ?? 1;
          if (_page >= totalPages) {
            _hasNextPage = false;
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_hasNextPage &&
        !_isLoading &&
        !_isLoadMoreRunning &&
        _scrollController.position.extentAfter < 300) {
      setState(() => _isLoadMoreRunning = true);
      _page += 1;
      try {
        final response = await http.get(
          Uri.parse("${ApiConfig.apiBaseUrl}/posts?page=$_page&limit=$_limit"),
        );
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['data'] is List) {
            final List newPosts = decoded['data'];
            if (newPosts.isNotEmpty) {
              setState(() {
                _posts.addAll(List<Map<String, dynamic>>.from(
                  newPosts.map((e) => Map<String, dynamic>.from(e as Map)),
                ));
              });
            } else {
              setState(() => _hasNextPage = false);
            }
          }
          if (decoded is Map && decoded['pagination'] is Map) {
            final pagination = decoded['pagination'];
            final totalPages = int.tryParse(pagination['totalPages']?.toString() ?? '1') ?? 1;
            if (_page >= totalPages) {
              setState(() => _hasNextPage = false);
            }
          }
        }
      } catch (_) {}
      if (mounted) {
        setState(() => _isLoadMoreRunning = false);
      }
    }
  }

  Future<void> _fetchUserInteractions() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPosts = (prefs.getStringList('cached_saved_posts') ?? []).toSet();
      _likedPosts = (prefs.getStringList('cached_liked_posts') ?? []).toSet();
    });
  }

  Future<void> _saveInteractionsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_saved_posts', _savedPosts.toList());
    await prefs.setStringList('cached_liked_posts', _likedPosts.toList());
  }

  Future<void> _toggleLike(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to support stories")),
      );
      return;
    }

    final bool isAlreadyLiked = _likedPosts.contains(postId);

    setState(() {
      if (isAlreadyLiked) {
        _likedPosts.remove(postId);
      } else {
        _likedPosts.add(postId);
      }

      for (var p in _posts) {
        if (p['post_id']?.toString() == postId) {
          int count = int.tryParse(p['support_count']?.toString() ?? '0') ?? 0;
          p['support_count'] = isAlreadyLiked ? (count - 1).clamp(0, 999999) : (count + 1);
          break;
        }
      }
    });

    await _saveInteractionsLocal();

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.apiBaseUrl}/posts/toggleSupport/$postId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode != 200) {
        // Revert
        setState(() {
          if (isAlreadyLiked) {
            _likedPosts.add(postId);
          } else {
            _likedPosts.remove(postId);
          }
          for (var p in _posts) {
            if (p['post_id']?.toString() == postId) {
              int count = int.tryParse(p['support_count']?.toString() ?? '0') ?? 0;
              p['support_count'] = isAlreadyLiked ? (count + 1) : (count - 1).clamp(0, 999999);
              break;
            }
          }
        });
        await _saveInteractionsLocal();
      }
    } catch (_) {
      // Revert
      setState(() {
        if (isAlreadyLiked) {
          _likedPosts.add(postId);
        } else {
          _likedPosts.remove(postId);
        }
        for (var p in _posts) {
          if (p['post_id']?.toString() == postId) {
            int count = int.tryParse(p['support_count']?.toString() ?? '0') ?? 0;
            p['support_count'] = isAlreadyLiked ? (count + 1) : (count - 1).clamp(0, 999999);
            break;
          }
        }
      });
      await _saveInteractionsLocal();
    }
  }

  Future<void> _toggleSave(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to bookmark stories")),
      );
      return;
    }

    final bool isAlreadySaved = _savedPosts.contains(postId);

    setState(() {
      if (isAlreadySaved) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });

    await _saveInteractionsLocal();

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.apiBaseUrl}/posts/toggleSave/$postId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode != 200) {
        // Revert
        setState(() {
          if (isAlreadySaved) {
            _savedPosts.add(postId);
          } else {
            _savedPosts.remove(postId);
          }
        });
        await _saveInteractionsLocal();
      }
    } catch (_) {
      // Revert
      setState(() {
        if (isAlreadySaved) {
          _savedPosts.add(postId);
        } else {
          _savedPosts.remove(postId);
        }
      });
      await _saveInteractionsLocal();
    }
  }

  List<Map<String, dynamic>> _getFilteredPosts() {
    if (_selectedCategoryId == 'all') return List.from(_posts);

    return _posts.where((p) {
      final catId = p['category_id']?.toString().toUpperCase();
      final expectedCatId = 'CAT' + _selectedCategoryId.padLeft(8, '0');
      if (catId == expectedCatId || catId == _selectedCategoryId) return true;

      final catName = p['category']?.toString().toLowerCase() ?? "";
      switch (_selectedCategoryId) {
        case '2': // சிந்தனைகள் (Thoughts / Sinthanaigal)
          return catName.contains('sinthanaigal') || catName.contains('thoughts') || catName.contains('சிந்தனைகள்');
        case '3': // அறிக்கைகள் / அறிகுறைகள் (Announcements / Arikaigal)
          return catName.contains('arikaigal') || catName.contains('announcements') || catName.contains('அறிக்கைகள்') || catName.contains('அறிகைகள்');
        case '4': // நூலகம் (Library / Noolagam)
          return catName.contains('noolagam') || catName.contains('library') || catName.contains('நூலகம்');
        default:
          return false;
      }
    }).toList();
  }

  String get _selectedCategoryLabel {
    return _categories
        .firstWhere((c) => c.id == _selectedCategoryId)
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Sooriyan-logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
            const SizedBox(width: 8),
            Text(
              "Sooriyan",
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                );
              } else if (value == 'terms') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 20, color: AppColors.brand),
                    SizedBox(width: 10),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'terms',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 20, color: AppColors.brand),
                    SizedBox(width: 10),
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Selector
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryId == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    showCheckmark: false,
                    selected: isSelected,
                    selectedColor: AppColors.brand,
                    backgroundColor: AppColors.chipBg,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredPosts.isEmpty
                    ? appEmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: _selectedCategoryId == 'all'
                            ? 'கதைகள் இல்லை'
                            : '$_selectedCategoryLabel இல் கதைகள் இல்லை',
                        subtitle: 'புதிய கதைகள் வரும்போது இங்கே தெரியும்',
                      )
                    : RefreshIndicator(
                        color: AppColors.brand,
                        onRefresh: _fetchFeed,
                      child: ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: filteredPosts.length + (_isLoadMoreRunning ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredPosts.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brand,
                                  ),
                                ),
                              );
                            }
                            final post = filteredPosts[index];
                            final postId = post['post_id'].toString();

                            return PostContainer(
                              post: post,
                              isLiked: _likedPosts.contains(postId),
                              isSaved: _savedPosts.contains(postId),
                              onLike: () => _toggleLike(postId),
                              onSave: () => _toggleSave(postId),
                              currentCategory: _selectedCategoryLabel,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// POST CONTAINER (STORY CARD)
// ==========================================
class PostContainer extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool isDraft;
  final String currentCategory;

  const PostContainer({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
    this.onDelete,
    this.onTap,
    this.isDraft = false,
    this.currentCategory = "All",
  });

  String _fullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    path = path.trim();

    if (path.startsWith("http")) {
      return path;
    }

    path = path.replaceAll("\\", "/").replaceAll(RegExp(r'^/+'), "");

    if (!path.contains("/")) {
      if (path.contains("profile_image")) {
        path = "uploads/profile_images/$path";
      } else if (path.contains("cover_image") || path.contains("page_img")) {
        path = "uploads/page_images/$path";
      }
    }

    return "${ApiConfig.baseUrl}/$path";
  }

  List<dynamic> _extractPages(dynamic rawContent) {
    if (rawContent == null) return [];
    if (rawContent is List) return rawContent;
    if (rawContent is String) {
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('pages')) {
          return decoded['pages'] ?? [];
        }
      } catch (_) {}
    }
    return [];
  }

  String _getFirstParagraph(dynamic rawContent) {
    final pages = _extractPages(rawContent);
    if (pages.isEmpty) return "";
    final firstPage = pages[0];
    final blocks = firstPage['blocks'];
    if (blocks is List) {
      for (var block in blocks) {
        if (block is Map && block['type'] == 'text') {
          final text = block['text']?.toString() ?? "";
          if (text.isNotEmpty) {
            if (text.length > 120) {
              return text.substring(0, 120) + "...";
            }
            return text;
          }
        }
      }
    }
    return "";
  }

  String _getCategoryTamil(String? category) {
    if (category == null) return "சிந்தனைகள்";
    final lower = category.toLowerCase();
    if (lower.contains("sinthanaigal") || lower.contains("thoughts") || lower.contains("சிந்தனைகள்")) {
      return "சிந்தனைகள்";
    }
    if (lower.contains("arikaigal") || lower.contains("announcements") || lower.contains("அறிக்கைகள்") || lower.contains("அறிகைகள்")) {
      return "அறிக்கைகள்";
    }
    if (lower.contains("noolagam") || lower.contains("library") || lower.contains("நூலகம்")) {
      return "நூலகம்";
    }
    return category;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB11226);
    final postId = post['post_id']?.toString() ?? post['draft_id']?.toString() ?? "";
    final username = post['username']?.toString() ?? "Anonymous";
    final profileImage = _fullUrl(post['profile_image']?.toString());
    final title = post['title']?.toString() ?? "Untitled Story";
    final caption = post['caption']?.toString() ?? "";
    final supportCount = int.tryParse(post['support_count']?.toString() ?? '0') ?? 0;
    final hashtagsStr = post['hashtags']?.toString() ?? "";
    final viewsCount = int.tryParse(post['views']?.toString() ?? '0') ?? 0;

    final isNoolagam = _getCategoryTamil(post['category']?.toString()) == "நூலகம்";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isNoolagam
          ? _buildNoolagamLayout(context, brandColor, postId, username, profileImage, title, caption, supportCount, hashtagsStr, viewsCount)
          : _buildStandardLayout(context, brandColor, postId, username, profileImage, title, caption, supportCount, hashtagsStr, viewsCount),
    );
  }

  Widget _buildNoolagamLayout(
    BuildContext context,
    Color brandColor,
    String postId,
    String username,
    String profileImage,
    String title,
    String caption,
    int supportCount,
    String hashtagsStr,
    int viewsCount,
  ) {
    final hasCover = post['cover_img'] != null && post['cover_img'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Profile Header at the top
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: brandColor.withOpacity(0.1),
              backgroundImage: profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "U",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (post['Constituency'] != null && post['Constituency'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      post['Constituency'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: brandColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "$viewsCount",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Clickable cover image + title block
        GestureDetector(
          onTap: onTap ?? () async {
            if (postId.isNotEmpty && !isDraft) {
              final prefs = await SharedPreferences.getInstance();
              final List<String> viewedList = prefs.getStringList('viewed_posts') ?? [];
              if (!viewedList.contains(postId)) {
                viewedList.add(postId);
                await prefs.setStringList('viewed_posts', viewedList);
                http.post(Uri.parse("${ApiConfig.apiBaseUrl}/posts/view/$postId")).catchError((_) => http.Response("", 500));
                try {
                  post['views'] = (int.tryParse(post['views']?.toString() ?? '0') ?? 0) + 1;
                } catch (_) {}
              }
            }
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenPostViewer(
                    pages: _extractPages(post['content']),
                    username: username,
                    profileImage: profileImage,
                    postId: postId,
                    postTitle: title,
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasCover)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: _fullUrl(post['cover_img']?.toString()),
                    fit: BoxFit.contain, // Display whole image without cropping
                    placeholder: (context, url) => SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator(color: brandColor)),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      height: 250,
                      child: Icon(Icons.error_outline_rounded, size: 40),
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_stories_outlined, color: brandColor, size: 48),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Engagement, hashtags & support buttons
        if (hashtagsStr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: hashtagsStr.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).map((tag) {
                return GestureDetector(
                  onTap: () {
                    final route = MaterialPageRoute(
                      builder: (_) => HashtagPostsPage(tag: tag),
                    );
                    Navigator.push(context, route);
                  },
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: brandColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (!isDraft) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$supportCount",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: isLiked ? Icons.touch_app : Icons.touch_app_outlined,
                      iconColor: isLiked ? brandColor : Colors.black54,
                      textColor: isLiked ? brandColor : Colors.black87,
                      label: "Support",
                      onTap: onLike,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      iconColor: Colors.black54,
                      textColor: Colors.black87,
                      label: "Share",
                      onTap: () {
                        Share.share("Check out this story: '$title' on Bigilu!");
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      iconColor: isSaved ? brandColor : Colors.black54,
                      textColor: isSaved ? brandColor : Colors.black87,
                      label: "Save",
                      onTap: onSave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStandardLayout(
    BuildContext context,
    Color brandColor,
    String postId,
    String username,
    String profileImage,
    String title,
    String caption,
    int supportCount,
    String hashtagsStr,
    int viewsCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: brandColor.withOpacity(0.1),
              backgroundImage: profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "U",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (post['Constituency'] != null && post['Constituency'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      post['Constituency'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: brandColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "$viewsCount",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap ?? () async {
            if (postId.isNotEmpty && !isDraft) {
              final prefs = await SharedPreferences.getInstance();
              final List<String> viewedList = prefs.getStringList('viewed_posts') ?? [];
              if (!viewedList.contains(postId)) {
                viewedList.add(postId);
                await prefs.setStringList('viewed_posts', viewedList);
                http.post(Uri.parse("${ApiConfig.apiBaseUrl}/posts/view/$postId")).catchError((_) => http.Response("", 500));
                try {
                  post['views'] = (int.tryParse(post['views']?.toString() ?? '0') ?? 0) + 1;
                } catch (_) {}
              }
            }
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenPostViewer(
                    pages: _extractPages(post['content']),
                    username: username,
                    profileImage: profileImage,
                    postId: postId,
                    postTitle: title,
                  ),
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryTamil(post['category']?.toString()),
                    style: TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                if (_getFirstParagraph(post['content']).isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: _getFirstParagraph(post['content']) + " ",
                        ),
                        TextSpan(
                          text: "Read more",
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            caption,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (hashtagsStr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: hashtagsStr.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).map((tag) {
                return GestureDetector(
                  onTap: () {
                    final route = MaterialPageRoute(
                      builder: (_) => HashtagPostsPage(tag: tag),
                    );
                    Navigator.push(context, route);
                  },
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: brandColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (!isDraft) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$supportCount",
                      style: TextStyle(
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: isLiked ? Icons.touch_app : Icons.touch_app_outlined,
                      iconColor: isLiked ? brandColor : Colors.black54,
                      textColor: isLiked ? brandColor : Colors.black87,
                      label: "Support",
                      onTap: onLike,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      iconColor: Colors.black54,
                      textColor: Colors.black87,
                      label: "Share",
                      onTap: () {
                        Share.share("Check out this story: '$title' on Bigilu!");
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    _buildActionButton(
                      icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      iconColor: isSaved ? brandColor : Colors.black54,
                      textColor: isSaved ? brandColor : Colors.black87,
                      label: "Save",
                      onTap: onSave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ==========================================
// EXPANDABLE POST IMAGE (ZOOM SUPPORT)
// ==========================================
class ExpandablePostImage extends StatelessWidget {
  final String imageUrl;

  const ExpandablePostImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFB11226))),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error_outline_rounded),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FULL SCREEN POST VIEWER (BOOK READER)
// ==========================================
class FullScreenPostViewer extends StatefulWidget {
  final List<dynamic> pages;
  final String username;
  final String profileImage;
  final String postId;
  final String postTitle;

  const FullScreenPostViewer({
    super.key,
    required this.pages,
    required this.username,
    required this.profileImage,
    required this.postId,
    required this.postTitle,
  });

  @override
  State<FullScreenPostViewer> createState() => _FullScreenPostViewerState();
}

class _FullScreenPostViewerState extends State<FullScreenPostViewer> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  double _fontSize = 18.0;
  String _appearance = "Sepia"; // Options: "Light", "Sepia", "Dark"

  @override
  void initState() {
    super.initState();
    _loadLastReadPage();
  }

  Future<void> _loadLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt("last_read_page_${widget.postId}") ?? 0;
    if (savedPage > 0 && savedPage < widget.pages.length) {
      setState(() {
        _currentPage = savedPage;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(savedPage);
        }
      });
    }
  }

  Future<void> _saveLastReadPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("last_read_page_${widget.postId}", index);
  }

  Color _parseColor(dynamic val) {
    if (val == null) return Colors.black;
    try {
      return Color(int.parse(val.toString()));
    } catch (_) {
      return Colors.black;
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "DISPLAYS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black38,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _fontSize = 18.0;
                            _appearance = "Sepia";
                          });
                          setSheetState(() {});
                        },
                        child: const Text(
                          "RESET",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB11226),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Font Size Section
                  const Text(
                    "FONT SIZE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: () {
                          if (_fontSize > 12.0) {
                            setState(() {
                              _fontSize -= 2.0;
                            });
                            setSheetState(() {});
                          }
                        },
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F4F7),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.remove, color: Colors.black87),
                      ),
                      const SizedBox(width: 32),
                      // Size Display
                      Text(
                        "${_fontSize.toInt()} px",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Plus Button
                      IconButton(
                        onPressed: () {
                          if (_fontSize < 32.0) {
                            setState(() {
                              _fontSize += 2.0;
                            });
                            setSheetState(() {});
                          }
                        },
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F4F7),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.add, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Appearance Section
                  const Text(
                    "APPEARANCE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Light Mode Card
                      _buildAppearanceCard(
                        label: "Light",
                        isSelected: _appearance == "Light",
                        cardColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        checkColor: Colors.black87,
                        onTap: () {
                          setState(() {
                            _appearance = "Light";
                          });
                          setSheetState(() {});
                        },
                      ),
                      // Sepia Mode Card
                      _buildAppearanceCard(
                        label: "Sepia",
                        isSelected: _appearance == "Sepia",
                        cardColor: const Color(0xFFFDFBF7),
                        borderColor: const Color(0xFFB11226),
                        checkColor: const Color(0xFFB11226),
                        onTap: () {
                          setState(() {
                            _appearance = "Sepia";
                          });
                          setSheetState(() {});
                        },
                      ),
                      // Dark Mode Card
                      _buildAppearanceCard(
                        label: "Dark",
                        isSelected: _appearance == "Dark",
                        cardColor: const Color(0xFF2C2C2C),
                        borderColor: Colors.transparent,
                        checkColor: Colors.white,
                        onTap: () {
                          setState(() {
                            _appearance = "Dark";
                          });
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppearanceCard({
    required String label,
    required bool isSelected,
    required Color cardColor,
    required Color borderColor,
    required Color checkColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? borderColor : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Icon(Icons.check, color: checkColor, size: 20),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPageGridBottomSheet(BuildContext context) {
    const brandColor = Color(0xFFB11226);
    
    Color sheetBg;
    Color sheetTextColor;
    Color gridItemBg;
    Color gridItemTextColor;

    switch (_appearance) {
      case "Light":
        sheetBg = Colors.white;
        sheetTextColor = const Color(0xFF1E1E1E);
        gridItemBg = const Color(0xFFF2F4F7);
        gridItemTextColor = const Color(0xFF1E1E1E);
        break;
      case "Dark":
        sheetBg = const Color(0xFF1E1E1E);
        sheetTextColor = const Color(0xFFE0E0E0);
        gridItemBg = const Color(0xFF2C2C2C);
        gridItemTextColor = const Color(0xFFE0E0E0);
        break;
      case "Sepia":
      default:
        sheetBg = const Color(0xFFFDFBF7);
        sheetTextColor = const Color(0xFF2C2C2C);
        gridItemBg = const Color(0xFFE5DDD3);
        gridItemTextColor = const Color(0xFF2C2C2C);
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: sheetTextColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Header
              Text(
                "Table of Contents",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                  color: sheetTextColor,
                ),
              ),
              const SizedBox(height: 20),
              // Grid of Pages
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: widget.pages.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentPage;
                    return GestureDetector(
                      onTap: () {
                        _pageController.jumpToPage(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? brandColor : gridItemBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : gridItemTextColor,
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.pages.length;

    Color scaffoldBg;
    Color cardBg;
    Color textColor;
    Color appBarTextColor;
    Color shadowColor;
    double shadowOpacity;
    Color spineShadowColor;
    Color pageNumColor;

    switch (_appearance) {
      case "Light":
        scaffoldBg = const Color(0xFFF2F4F7);
        cardBg = Colors.white;
        textColor = const Color(0xFF1E1E1E);
        appBarTextColor = const Color(0xFF2C2C2C);
        shadowColor = Colors.black;
        shadowOpacity = 0.05;
        spineShadowColor = Colors.black.withOpacity(0.08);
        pageNumColor = Colors.grey.shade400;
        break;
      case "Dark":
        scaffoldBg = const Color(0xFF121212);
        cardBg = const Color(0xFF1E1E1E);
        textColor = const Color(0xFFE0E0E0);
        appBarTextColor = Colors.white;
        shadowColor = Colors.black;
        shadowOpacity = 0.3;
        spineShadowColor = Colors.black.withOpacity(0.2);
        pageNumColor = Colors.grey.shade600;
        break;
      case "Sepia":
      default:
        scaffoldBg = const Color(0xFFE5DDD3);
        cardBg = const Color(0xFFFDFBF7);
        textColor = const Color(0xFF2C2C2C);
        appBarTextColor = const Color(0xFF2C2C2C);
        shadowColor = Colors.black;
        shadowOpacity = 0.06;
        spineShadowColor = Colors.black.withOpacity(0.1);
        pageNumColor = Colors.grey.shade400;
        break;
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "Reading",
              style: TextStyle(
                color: appBarTextColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (totalPages > 0)
              Text(
                "Page ${_currentPage + 1} of $totalPages",
                style: TextStyle(
                  color: appBarTextColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: appBarTextColor, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Text(
              "A",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontFamily: 'serif',
                color: appBarTextColor,
              ),
            ),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: appBarTextColor, size: 24),
            onPressed: () {
              Share.share("Check out this story: '${widget.postTitle}' on Bigilu!");
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: totalPages == 0
          ? Center(
              child: Text(
                "This story has no pages.",
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: totalPages,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _saveLastReadPage(index);
                  },
                  itemBuilder: (context, index) {
                    final page = widget.pages[index];
                    final fontColor = page['fontColor'] != null ? _parseColor(page['fontColor']) : textColor;

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor.withOpacity(shadowOpacity),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Left spine shadow for realistic book page look
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 30,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      spineShadowColor.withOpacity(0.8),
                                      spineShadowColor.withOpacity(0.3),
                                      Colors.transparent
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(45, 40, 35, 60),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...(page['blocks'] as List? ?? []).map<Widget>((block) {
                                    if (block['type'] == "text") {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          block['text'] ?? "",
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            fontFamily: 'serif',
                                            color: _appearance == "Dark" ? textColor : fontColor,
                                            height: 1.6,
                                          ),
                                        ),
                                      );
                                    }
                                    if (block['type'] == "image" && block['image'] != null && block['image'].toString().isNotEmpty) {
                                      final imgPath = block['image'].toString();
                                      final fullImgUrl = imgPath.startsWith("http")
                                          ? imgPath
                                          : "${ApiConfig.baseUrl}/uploads/page_images/$imgPath";

                                      return ExpandablePostImage(imageUrl: fullImgUrl);
                                    }
                                    return const SizedBox();
                                  }),
                                ],
                              ),
                            ),
                            // Page bottom indicator
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  "— Page ${index + 1} —",
                                  style: TextStyle(
                                    color: pageNumColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showPageGridBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardBg.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: appBarTextColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: appBarTextColor.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_currentPage + 1} of $totalPages",
                              style: TextStyle(
                                color: appBarTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: appBarTextColor.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
