import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../debts/ui/debts_screen.dart';
import '../home/ui/home_screen.dart';
import '../settings/ui/settings_screen.dart';
import '../stats/ui/stats_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          HomeScreen(onOpenDebts: () => _select(1)),
          const DebtsScreen(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.handCoins),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chartPieSlice),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.gearSix),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
