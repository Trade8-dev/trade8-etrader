// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Depth ladder (A1.6): 10-level book with click-to-trade pre-fill (taps
// hand the price to the order pad via the shared symbol/price channel —
// the ValueNotifier below is the app-internal wiring).

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

/// Cross-page price hand-off (click-to-trade pre-fill).
final ValueNotifier<String?> tappedPrice = ValueNotifier(null);

class DepthLadderPage extends StatefulWidget {
 const DepthLadderPage({super.key});

 @override
 State<DepthLadderPage> createState => _DepthLadderPageState;
}

class _DepthLadderPageState extends State<DepthLadderPage> {
 final _symbol = TextEditingController(text: 'AAPL');
 Map<String, dynamic>? _depth;
 String? _error;

 Future<void> _load(Bff8ApiClient bff) async {
 try {
 final res = await bff.get('/proxy/trade8/v1/depth/${_symbol.text.toUpperCase}');
 setState( {
 _depth = res;
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 String _fmt(dynamic level) {
 if (level is! List || level.isEmpty) return '—';
 final raw = level[0];
 final qty = level.length > 1 ? level[1] : 0;
 final px = (raw is int) ? (raw / 10000).toStringAsFixed(2) : raw.toString;
 final q = (qty is Map) ? (qty['raw'] ?? 0) : qty;
 return '$px × $q';
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 final asks = (_depth?['asks'] as List? ?? []).take(10).toList;
 final bids = (_depth?['bids'] as List? ?? []).take(10).toList;
 return Column(
 children: [
 Padding(
 padding: const EdgeInsets.all(8),
 child: Row(
 children: [
 Expanded(
 child: TextField(
 controller: _symbol,
 decoration: const InputDecoration(labelText: 'Symbol', isDense: true),
 textCapitalization: TextCapitalization.characters,
 ),
 ),
 const SizedBox(width: 8),
 FilledButton.tonal(
 onPressed: => _load(bff),
 child: const Text('Load'),
 ),
 ],
 ),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.all(8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 Expanded(
 child: Row(
 children: [
 Expanded(
 child: ListView(
 reverse: true,
 children: [
 for (final level in asks)
 ListTile(
 dense: true,
 title: Text(_fmt(level)),
 onTap: {
 tappedPrice.value = _fmt(level).split(' ×').first;
 },
 ),
 ],
 ),
 ),
 const VerticalDivider(width: 1),
 Expanded(
 child: ListView(
 children: [
 for (final level in bids)
 ListTile(
 dense: true,
 title: Text(_fmt(level)),
 onTap: {
 tappedPrice.value = _fmt(level).split(' ×').first;
 },
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ],
 );
 }
}