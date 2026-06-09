import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'boli_bottom_nav_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow under the bottom nav bar
      body: child,
      bottomNavigationBar: _BottomNavBuilder(),
    );
  }
}

class _BottomNavBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;

    if (location.startsWith('/wallet')) {
      currentIndex = 1;
    } else if (location.startsWith('/marketplace')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    }

    return SafeArea(
      child: BoliBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/wallet');
              break;
            case 2:
              context.go('/marketplace');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
