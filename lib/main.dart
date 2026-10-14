// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// eTrader — Trade8 professional trading app entry (A1.1 scaffold).
//
// BFF-only client (sentin8_flutter shell): every backend call routes
// through Bff8ApiClient → Sentin8:BFF /proxy/trade8/...; no direct
// service access (architecture-principles.md §4.7 BFF pattern).
//
// Trader surfaces (order pad, blotter, depth, tape, P&L, alerts) mount
// into this shell; keyboard shortcuts + realtime store land with the
// bootstrap pass (A1.2–A1.4).

import 'package:flutter/material.dart';

import 'shell/app_shell.dart';

void main {
 runApp(const ETraderApp);
}

class ETraderApp extends StatelessWidget {
 const ETraderApp({super.key});

 @override
 Widget build(BuildContext context) {
 return MaterialApp(
 title: 'eTrader',
 debugShowCheckedModeBanner: false,
 theme: ThemeData(
 useMaterial3: true,
 colorScheme: ColorScheme.fromSeed(
 seedColor: const Color(0xFFD4AF37), // Royal Gold (design system)
 ),
 fontFamily: 'Inter',
 ),
 home: const AppShell,
 );
 }
}