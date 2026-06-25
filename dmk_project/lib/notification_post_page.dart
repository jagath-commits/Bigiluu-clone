import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dmk_project/api_config.dart';
import 'package:dmk_project/home.dart';

class NotificationPostPage extends StatefulWidget {
  final String postId;

  const NotificationPostPage({
    super.key,
    required this.postId,
  });

  @override
  State<NotificationPostPage> createState() =>
      _NotificationPostPageState();
}

class _NotificationPostPageState
    extends State<NotificationPostPage> {

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  List<dynamic> _extractPages(dynamic rawContent) {
    if (rawContent == null) return [];

    if (rawContent is List) return rawContent;

    if (rawContent is String) {
      try {
        return jsonDecode(rawContent);
      } catch (_) {}
    }

    return [];
  }

  Future<void> _loadPost() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.apiBaseUrl}/posts/${widget.postId}",
        ),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);

        final post =
            data["data"] ?? data["post"] ?? data;

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenPostViewer(
              pages: _extractPages(post["content"]),
              username:
                  post["username"] ?? "Unknown",
              profileImage:
                  post["profile_image"] ?? "",
              postId:
                  post["post_id"] ?? widget.postId,
              postTitle:
                  post["title"] ?? "Post",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}