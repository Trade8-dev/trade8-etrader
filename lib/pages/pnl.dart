// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// P&L (A1.10): self day summary, positions with marks, per-symbol resume.
// Scope: trade8:pnl:self:read (trader) / :office:read (desk board).

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class PnlPage extends StatefulWidget {
 const PnlPage({super.key});

 @override
 State<PnlPage> createState => _PnlPageState;
}

class _PnlPageState extends State<PnlPage> {
 Map<String, dynamic>? _summary;
 List<Map<String, dynamic>> _positions = [];
 String? _error;

 Future<void> _refresh(Bff8ApiClient bff) async {
 try {
 final summary = await bff.get('/proxy/trade8/v1/pnl/summary');
 final positions = await bff.get('/proxy/trade8/v1/pnl/positions');
 setState( {
 _summary = summary;
 _positions = (positions as List)
 .map((e) => (e as Map).cast<String, dynamic>)
 .toList;
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 String _money(dynamic raw) {
 if (raw is! int) return '—';
 final v = raw / 10000;
 return v.toStringAsFixed(2);
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 final net = _summary?['total_net'];
 final unreal = _summary?['unrealized'];
 return ListView(
 padding: const EdgeInsets.all(16),
 children: [
 Row(
 children: [
 FilledButton.tonalIcon(
 onPressed: => _refresh(bff),
 icon: const Icon(Icons.refresh),
 label: const Text('Refresh'),
 ),
 ],
 ),
 const SizedBox(height: 16),
 Card(
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Day P&L',
 style: Theme.of(context).textTheme.titleMedium,
 ),
 const SizedBox(height: 8),
 Text(
 'Net ${_money(net)}',
 style: TextStyle(
 fontSize: 24,
 fontWeight: FontWeight.bold,
 color: (net is int && net < 0) ? Colors.red : Colors.green,
 ),
 ),
 Text('Unrealized ${_money(unreal)}',
 style: Theme.of(context).textTheme.bodySmall),
 ],
 ),
 ),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 const SizedBox(height: 16),
 Text('Positions', style: Theme.of(context).textTheme.titleMedium),
 for (final p in _positions)
 ListTile(
 dense: true,
 leading: Text(
 (p['symbol_name'] ?? '?').toString,
 style: const TextStyle(fontWeight: FontWeight.bold),
 ),
 title: Text('${p['signed_size'] ?? 0} @ '
 '${_money(p['avg_cost_raw'])}'),
 trailing: Text(
 'P&L ${_money(p['realized'])}',
 style: TextStyle(
 color: ((p['realized'] as int?) ?? 0) < 0 ? Colors.red : Colors.green,
 ),
 ),
 ),
 ],
 );
 }
}