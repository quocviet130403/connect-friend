import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          border: Border(top: BorderSide(color: AppTheme.borderDark.withValues(alpha: 0.3), width: 0.5)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, size: 24),
              selectedIcon: Icon(Icons.explore, color: AppTheme.primary, size: 24),
              label: 'Khám phá',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, size: 24),
              selectedIcon: Icon(Icons.people, color: AppTheme.primary, size: 24),
              label: 'Nhóm',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined, size: 22),
              selectedIcon: Icon(Icons.calendar_today, color: AppTheme.primary, size: 22),
              label: 'Cuộc hẹn',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 24),
              selectedIcon: Icon(Icons.person, color: AppTheme.primary, size: 24),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}
