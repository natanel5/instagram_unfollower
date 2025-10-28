import 'package:flutter/material.dart';
// Import the home screen created
import 'package:instagram_unfollowers/screens/home_page.dart';

// The main entry point for the Flutter application.
void main() {
  // Tells Flutter to run the app defined in UnfollowerApp
  runApp(const UnfollowerApp());
}

// The root widget of the application.
class UnfollowerApp extends StatelessWidget {
  const UnfollowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp provides the app's base structure, theme, and navigation.
    return MaterialApp(
      title: 'Unfollower App',
      theme: ThemeData(
        // Defines the global color palette for the app.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // The widget to show when the app first launches.
      home: const HomePage(),
      // Hides the "DEBUG" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
    );
  }
}