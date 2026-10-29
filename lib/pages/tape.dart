// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Tape / market board (A1.7): watchlist grid with last/BBO/Δ + prints.
// Refresh-driven (SSE wiring lands with the bootstrap pass - A1.2).

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class TapePage extends StatefulWidget {
 const TapePage({super.key});

 @override
 State<TapePage> createState => _TapePageState;
}

class _TapePageState extends State<TapePage> {
 static const _watchlist = ['AAPL', 'MSFT', 'NVDA', 'AMZN', 'TSLA'];
 final Map<String, Quote> _quotes = {};
 String? _error;

 Future<void> _refreshAll(Bff8ApiClient bff) async {
 for (final sym in _watchlist) {
 await bff.refreshQuote(sym).then((q) {
 if (q != null) setState( => _quotes[sym] = q);
 }).catchError((e) {
 setState( => _error = e is BffError ? e.message : '$e');
 });
 }
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 return Column(
 children: [
 Padding(
 padding: const EdgeInsets.all(8),
 child: FilledButton.tonalIcon(
 onPressed: => _refreshAll(bff),
 icon: const Icon(Icons.refresh),
 label: const Text('Refresh watchlist'),
 ),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 Expanded(
 child: _quotes.isEmpty
 ? const Center(child: Text('No prints yet - refresh the watchlist.'))
 : ListView(
 children: [
 for (final sym in _watchlist)
 if (_quotes[sym] != null)
 ListTile(
 dense: true,
 leading: Text(sym, style: const TextStyle(fontWeight: FontWeight.bold)),
 title: Text(_quotes[sym]!.bboLabel),
 subtitle: Text(
 '${_quotes[sym]!.bidSize} × ${_quotes[sym]!.askSize}'),
 ),
 ],
 ),
 ),
 ],
 );
 }
}