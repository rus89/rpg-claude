// ABOUTME: Full-screen loading indicator shown while CSV data is being fetched.
// ABOUTME: Placeholder until Task 8 is implemented.

import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Učitavanje')));
  }
}
