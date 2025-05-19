import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnity/theme/theme_provider.dart';
import 'package:learnity/screen/userpage/social_feed_page.dart';
import 'package:learnity/theme/theme.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _showHeader = true;

  void _updateHeaderVisibility(bool show) {
    setState(() {
      _showHeader = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      body: SocialFeedPage(
        onFooterVisibilityChanged: _updateHeaderVisibility,
      ),
    );
  }
} 