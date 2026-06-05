import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dmk_project/app_bottom_nav.dart';
import 'package:dmk_project/app_theme.dart';
import 'package:dmk_project/hashtag.dart';
import 'package:dmk_project/profile.dart';

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

  static const List<({String id, String label})> _categories = [
    (id: 'all', label: 'அனைத்தும்'),
    (id: '4', label: 'நூலகம்'),
    (id: '2', label: 'சிந்தனைகள்'),
    (id: '3', label: 'அறிகைகள்'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndFeed();
  }

  Future<void> _loadUserAndFeed() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    await _fetchFeed();
    await _fetchUserInteractions();
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true);
    if (mounted) {
      setState(() {
        _posts = [];
        _isLoading = false;
      });
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
  }

  Future<void> _toggleSave(String postId) async {
    if (_userId == null) return;
    final bool isAlreadySaved = _savedPosts.contains(postId);

    setState(() {
      if (isAlreadySaved) {
        _savedPosts.remove(postId);
      } else {
        _savedPosts.add(postId);
      }
    });

    await _saveInteractionsLocal();
  }

  List<Map<String, dynamic>> _getFilteredPosts() {
    if (_selectedCategoryId == 'all') return List.from(_posts);

    return _posts.where((p) {
      final catId = p['category_id']?.toString();
      if (catId == _selectedCategoryId) return true;

      final catName = p['category']?.toString();
      switch (_selectedCategoryId) {
        case '2':
          return catName == 'Sinthanaigal';
        case '3':
          return catName == 'Arikaigal';
        case '4':
          return catName == 'Noolagam';
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
      appBar: appBar('Star'),
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
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: filteredPosts.length,
                          itemBuilder: (context, index) {
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
  final String currentCategory;

  const PostContainer({
    super.key,
    required this.post,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onSave,
    this.onDelete,
    this.currentCategory = "All",
  });

  String _fullUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    path = path.trim();

    if (path.startsWith("http")) {
      return path;
    }

    path = path.replaceAll("\\", "/").replaceAll(RegExp(r'^/+'), "");

    return "https://bigiluu.com/$path";
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

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB11226);
    final postId = post['post_id']?.toString() ?? "";
    final username = post['username']?.toString() ?? "Anonymous";
    final profileImage = _fullUrl(post['profile_image']?.toString());
    final coverImage = _fullUrl(post['cover_img']?.toString());
    final title = post['title']?.toString() ?? "Untitled Story";
    final caption = post['caption']?.toString() ?? "";
    final supportCount = int.tryParse(post['support_count']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
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
                          style: const TextStyle(
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
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
          // Cover Image / Book Layout
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenPostViewer(
                    pages: _extractPages(post['content']),
                    username: username,
                    profileImage: profileImage,
                    postId: postId,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFDFBF7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverImage.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: coverImage,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandColor.withOpacity(0.8), brandColor.withOpacity(0.4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    // Glass Overlay & Title Text
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Read Story Page",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
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
          ),
          // Caption Description
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          // Interactive Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? brandColor : Colors.grey.shade600,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$supportCount",
                        style: TextStyle(
                          color: isLiked ? brandColor : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved ? brandColor : Colors.grey.shade600,
                    size: 22,
                  ),
                  onPressed: onSave,
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: Colors.grey.shade600, size: 22),
                  onPressed: () {
                    Share.share("Check out this story: '$title' on Bigilu!");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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

  const FullScreenPostViewer({
    super.key,
    required this.pages,
    required this.username,
    required this.profileImage,
    required this.postId,
  });

  @override
  State<FullScreenPostViewer> createState() => _FullScreenPostViewerState();
}

class _FullScreenPostViewerState extends State<FullScreenPostViewer> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  Color _parseColor(dynamic val) {
    if (val == null) return Colors.black;
    try {
      return Color(int.parse(val.toString()));
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFB11226);
    final totalPages = widget.pages.length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              "Reading Story",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            if (totalPages > 0)
              Text(
                "Page ${_currentPage + 1} of $totalPages",
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: totalPages == 0
          ? const Center(
              child: Text(
                "This story has no pages.",
                style: TextStyle(color: Colors.white, fontSize: 16),
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
                  },
                  itemBuilder: (context, index) {
                    final page = widget.pages[index];
                    final fontSize = (page['fontSize'] ?? 18).toDouble();
                    final fontFamily = page['fontFamily'] ?? 'Roboto';
                    final fontColor = _parseColor(page['fontColor']);

                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
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
                                      Colors.black.withOpacity(0.12),
                                      Colors.black.withOpacity(0.05),
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
                                            fontSize: fontSize,
                                            fontFamily: fontFamily,
                                            color: fontColor,
                                            height: 1.6,
                                          ),
                                        ),
                                      );
                                    }
                                    if (block['type'] == "image" && block['image'] != null && block['image'].toString().isNotEmpty) {
                                      final imgPath = block['image'].toString();
                                      final fullImgUrl = imgPath.startsWith("http")
                                          ? imgPath
                                          : "https://bigiluu.com/uploads/page_images/$imgPath";

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
                                    color: Colors.grey.shade400,
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
              ],
            ),
    );
  }
}
