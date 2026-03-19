import 'package:contractor_mobile/src/screens/dashboard_screen.dart';
import 'package:contractor_mobile/src/screens/settings_screen.dart';
import 'package:contractor_mobile/src/screens/timesheet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    TimesheetScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index].animate().fadeIn(duration: 260.ms).moveX(begin: 14, end: 0),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 72,
            selectedIndex: _index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.stacked_bar_chart_outlined),
                selectedIcon: Icon(Icons.stacked_bar_chart_rounded),
                label: 'Week',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'Settings',
              ),
            ],
            onDestinationSelected: (value) {
              setState(() {
                _index = value;
              });
            },
          ),
        ),
      ),
    );
  }
}
