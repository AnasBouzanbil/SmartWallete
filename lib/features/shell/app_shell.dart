import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../debts/logic/debt_notification_sync.dart';
import '../debts/ui/debts_screen.dart';
import '../home/ui/home_screen.dart';
import '../settings/ui/settings_screen.dart';
import '../stats/ui/stats_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _select(int index) {
    if (index != _index) {
      HapticFeedback.selectionClick();
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    // Activate debt due-date notification sync while the shell is alive.
    ref.watch(debtNotificationSyncProvider);

    final Brightness brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
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
      ),
    );
  }
}
