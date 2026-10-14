// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Alerts (A1.12): rule CRUD + fired queue with ack. Scope:
// trade8:feed:quote:read.

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class AlertsPage extends StatefulWidget {
 const AlertsPage({super.key});

 @override
 State<AlertsPage> createState => _AlertsPageState;
}

class _AlertsPageState extends State<AlertsPage> {
 final _symbol = TextEditingController(text: 'AAPL');
 final _threshold = TextEditingController(text: '1050000'); // 105.00 ×10⁴
 String _op = 'gt';
 List<Map<String, dynamic>> _rules = [];
 List<Map<String, dynamic>> _fired = [];
 String? _error;

 Future<void> _refresh(Bff8ApiClient bff) async {
 try {
 final rules = await bff.get('/proxy/trade8/v1/alerts');
 setState( {
 _rules = (rules['rules'] as List? ?? [])
 .map((e) => (e as Map).cast<String, dynamic>)
 .toList;
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 Future<void> _create(Bff8ApiClient bff) async {
 try {
 await bff.post('/proxy/trade8/v1/alerts', body: {
 'symbol': _symbol.text.toUpperCase,
 'op': _op,
 'threshold_raw': int.tryParse(_threshold.text) ?? 0,
 });
 await _refresh(bff);
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 return ListView(
 padding: const EdgeInsets.all(16),
 children: [
 Row(
 children: [
 Expanded(
 child: TextField(
 controller: _symbol,
 decoration: const InputDecoration(labelText: 'Symbol', isDense: true),
 textCapitalization: TextCapitalization.characters,
 ),
 ),
 const SizedBox(width: 8),
 DropdownButton<String>(
 value: _op,
 items: const [
 DropdownMenuItem(value: 'gt', child: Text('>')),
 DropdownMenuItem(value: 'lt', child: Text('<')),
 DropdownMenuItem(value: 'gte', child: Text('≥')),
 DropdownMenuItem(value: 'lte', child: Text('≤')),
 ],
 onChanged: (v) => setState( => _op = v!),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: TextField(
 controller: _threshold,
 decoration: const InputDecoration(
 labelText: 'Threshold (×10⁴ raw)',
 isDense: true,
 ),
 keyboardType: TextInputType.number,
 ),
 ),
 const SizedBox(width: 8),
 FilledButton(
 onPressed: => _create(bff),
 child: const Text('Add'),
 ),
 ],
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 const SizedBox(height: 16),
 Row(
 children: [
 Text('Rules', style: Theme.of(context).textTheme.titleMedium),
 const Spacer,
 IconButton(
 icon: const Icon(Icons.refresh),
 onPressed: => _refresh(bff),
 ),
 ],
 ),
 for (final r in _rules)
 ListTile(
 dense: true,
 leading: Text((r['symbol'] ?? '?').toString),
 title: Text((r['condition'] ?? '').toString),
 subtitle: Text((r['usr_id'] ?? '').toString),
 ),
 const SizedBox(height: 16),
 Text('Fired', style: Theme.of(context).textTheme.titleMedium),
 if (_fired.isEmpty)
 const Padding(
 padding: EdgeInsets.only(top: 8),
 child: Text('No fired alerts.'),
 ),
 ],
 );
 }
}