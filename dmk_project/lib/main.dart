import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:dmk_project/app_theme.dart';
import 'package:dmk_project/home.dart';
import 'package:dmk_project/password_login.dart';
import 'package:dmk_project/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(token: token));
}

class MyApp extends StatefulWidget {
  final String? token;

  const MyApp({super.key, required this.token});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDeepLinks());
  }

  Future<void> _initDeepLinks() async {
    try {
      _appLinks = AppLinks();
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null && initialUri.pathSegments.contains('post')) {
        await _openProfileFromDeepLink(initialUri);
      }

      _sub = _appLinks!.uriLinkStream.listen((uri) async {
        if (uri.pathSegments.contains('post')) {
          await _openProfileFromDeepLink(uri);
        }
      });
    } catch (e) {
      debugPrint('Deep links skipped: $e');
    }
  }

  Future<void> _openProfileFromDeepLink(Uri uri) async {
    final postId = uri.pathSegments.last;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null || !mounted) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userId: userId,
          isPublicView: true,
          initialPostId: postId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.token != null
        ? const MainShell()
        : const PasswordLoginPage();

    if (Platform.isIOS) {
      return CupertinoApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: home,
      );
    }

    return MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
