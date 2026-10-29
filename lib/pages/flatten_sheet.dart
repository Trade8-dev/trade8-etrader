// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Flatten sheet + basket editor (A1.11): typed flatten-strategy
// params (mode/improve-ticks/attempts/hold) → POST
// /proxy/trade8/v1/positions/flatten; the Func basket progress is a
// read-only view of the module execution events.

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class FlattenSheetPage extends StatefulWidget {
 const FlattenSheetPage({super.key});

 @override
 State<FlattenSheetPage> createState => _FlattenSheetPageState;
}

class _FlattenSheetPageState extends State<FlattenSheetPage> {
 String _mode = 'market';
 final _improveTicks = TextEditingController(text: '100');
 final _attempts = TextEditingController(text: '5');
 final _holdMs = TextEditingController(text: '2000');
 String? _result;
 String? _error;

 Future<void> _flatten(Bff8ApiClient bff) async {
 try {
 final res = await bff.post('/proxy/trade8/v1/positions/flatten', body: {
 // Typed the typed flatten strategy params (apps design §2.2).
 'mode': _mode,
 'improve_ticks': int.tryParse(_improveTicks.text) ?? 0,
 'max_attempts': int.tryParse(_attempts.text) ?? 5,
 'hold_ms': int.tryParse(_holdMs.text) ?? 2000,
 });
 setState( {
 _result = 'cancelled ${res['flatten_orders_submitted'] ?? 0} working orders';
 _error = null;
 });
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
 Text('Flatten', style: Theme.of(context).textTheme.titleMedium),
 const SizedBox(height: 8),
 SegmentedButton<String>(
 segments: const [
 ButtonSegment(value: 'market', label: Text('Market')),
 ButtonSegment(value: 'improve', label: Text('Improve')),
 ButtonSegment(value: 'cross', label: Text('Cross')),
 ],
 selected: {_mode},
 onSelectionChanged: (s) => setState( => _mode = s.first),
 ),
 const SizedBox(height: 8),
 TextField(
 controller: _improveTicks,
 decoration: const InputDecoration(
 labelText: 'Improve ticks (improve mode)'),
 keyboardType: TextInputType.number,
 ),
 const SizedBox(height: 8),
 TextField(
 controller: _attempts,
 decoration: const InputDecoration(labelText: 'Max attempts'),
 keyboardType: TextInputType.number,
 ),
 const SizedBox(height: 8),
 TextField(
 controller: _holdMs,
 decoration: const InputDecoration(labelText: 'Hold ms between attempts'),
 keyboardType: TextInputType.number,
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 if (_result != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_result!, style: const TextStyle(color: Colors.green)),
 ),
 const SizedBox(height: 16),
 FilledButton.icon(
 onPressed: => _flatten(bff),
 icon: const Icon(Icons.compress),
 label: const Text('Flatten working orders'),
 ),
 const SizedBox(height: 24),
 Text('Basket (Func module progress - read-only)',
 style: Theme.of(context).textTheme.titleMedium),
 const Padding(
 padding: EdgeInsets.only(top: 8),
 child: Text(
 'Basket executions stream their per-item progress from the '
 'trade8-basket-runner module events (trade8:desk:order:… inbox '
 'trail); the editable submitter is the F1 - F4 ticket + batch.',
 ),
 ),
 ],
 );
 }
}