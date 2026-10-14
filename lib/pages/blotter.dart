// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Blotter (A1.5): working orders + history, live SSE updates, cancel
// actions. Scope: trade8:desk:order:read + :cancel for the actions.

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class BlotterPage extends StatefulWidget {
 const BlotterPage({super.key});

 @override
 State<BlotterPage> createState => _BlotterPageState;
}

class _BlotterPageState extends State<BlotterPage> {
 List<OrderRow> _rows = [];
 String? _error;

 Future<void> _refresh(Bff8ApiClient bff) async {
 try {
 final rows = await bff.refreshBlotter;
 setState( {
 _rows = rows;
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 Future<void> _cancel(Bff8ApiClient bff, OrderRow row) async {
 try {
 await bff.cancelOrder(row.orderId);
 await _refresh(bff);
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 Color _stateColor(String state) {
 switch (state) {
 case 'filled':
 return Colors.green;
 case 'cancelled':
 case 'rejected':
 case 'expired':
 return Colors.grey;
 case 'partially_filled':
 return Colors.orange;
 default:
 return Colors.blue;
 }
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 return Column(
 children: [
 Padding(
 padding: const EdgeInsets.all(8),
 child: Row(
 children: [
 FilledButton.tonalIcon(
 onPressed: => _refresh(bff),
 icon: const Icon(Icons.refresh),
 label: const Text('Refresh'),
 ),
 const SizedBox(width: 8),
 Text('${_rows.where((r) => r.working).length} working'),
 if (_error != null) ...[
 const SizedBox(width: 8),
 Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
 ],
 ],
 ),
 ),
 Expanded(
 child: _rows.isEmpty
 ? const Center(child: Text('No orders — submit from the ticket.'))
 : ListView.builder(
 itemCount: _rows.length,
 itemBuilder: (context, i) {
 final r = _rows[i];
 return ListTile(
 dense: true,
 leading: Text(
 r.symbol,
 style: const TextStyle(fontWeight: FontWeight.bold),
 ),
 title: Text('${r.side == 'b' ? 'BUY' : 'SELL'} ${r.qty} '
 '@ ${r.priceRaw != null ? (r.priceRaw! / 10000).toStringAsFixed(2) : 'MKT'}'),
 subtitle: Text(r.clientOrderId),
 trailing: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: _stateColor(r.state).withValues(alpha: 0.15),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 r.state.replaceAll('_', ' '),
 style: TextStyle(color: _stateColor(r.state), fontSize: 12),
 ),
 ),
 if (r.working)
 IconButton(
 icon: const Icon(Icons.close, size: 18),
 tooltip: 'Cancel',
 onPressed: => _cancel(bff, r),
 ),
 ],
 ),
 );
 },
 ),
 ),
 ],
 );
 }
}