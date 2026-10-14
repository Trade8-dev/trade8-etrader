// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// App shell — navigation across the eTrader surfaces: order pad,
// blotter, depth ladder, tape, P&L, alerts. The BFF client scope wraps
// the tree; the sentin8_flutter bootstrap injects the authenticated
// transport (scope-gated: traders see order/pnl pages, managers the
// office board).

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';
import '../pages/alerts.dart';
import '../pages/blotter.dart';
import '../pages/chart.dart';
import '../pages/depth_ladder.dart';
import '../pages/flatten_sheet.dart';
import '../pages/order_pad.dart';
import '../pages/pnl.dart';
import '../pages/settings.dart';
import '../pages/tape.dart';

class AppShell extends StatefulWidget {
 const AppShell({super.key});

 @override
 State<AppShell> createState => _AppShellState;
}

class _AppShellState extends State<AppShell> {
 int _tab = 0;

 @override
 Widget build(BuildContext context) {
 // The sentin8_flutter bootstrap injects the authenticated transport;
 // the scaffold wires it into the scope for the pages.
 final bff = Bff8ApiClient(
 (method, path, body) async => throw BffError('bootstrap pending (A1.1 shell)'),
 (channel) => const Stream.empty,
 );
 return BffClientScope(
 client: bff,
 child: Scaffold(
 appBar: AppBar(title: const Text('eTrader')),
 body: IndexedStack(
 index: _tab,
 children: const [
 OrderPadPage,
 BlotterPage,
 DepthLadderPage,
 TapePage,
 ChartPage,
 PnlPage,
 AlertsPage,
 FlattenSheetPage,
 SettingsPage,
 ],
 ),
 bottomNavigationBar: NavigationBar(
 selectedIndex: _tab,
 onDestinationSelected: (i) => setState( => _tab = i),
 destinations: const [
 NavigationDestination(icon: Icon(Icons.send), label: 'Ticket'),
 NavigationDestination(icon: Icon(Icons.list), label: 'Blotter'),
 NavigationDestination(icon: Icon(Icons.stacked_bar_chart), label: 'Depth'),
 NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Tape'),
 NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), label: 'Chart'),
 NavigationDestination(icon: Icon(Icons.trending_up), label: 'P&L'),
 NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
 NavigationDestination(icon: Icon(Icons.compress), label: 'Flatten'),
 NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
 ],
 ),
 ),
 );
 }
}