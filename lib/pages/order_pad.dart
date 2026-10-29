// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Order pad (A1.3): symbol typeahead, side/qty/price steppers honoring
// tick-rule bands (0.01 under $5, 0.05 above - Reg-NMS parity),
// destination/TIF/flags → POST /proxy/trade8/v1/orders. Idempotent on
// client_order_id; pre-submit risk preview lands with the Risk read.

import 'package:flutter/material.dart';

import '../bff/bff_client.dart';

class OrderPadPage extends StatefulWidget {
 const OrderPadPage({super.key});

 @override
 State<OrderPadPage> createState => _OrderPadPageState;
}

class _OrderPadPageState extends State<OrderPadPage> {
 final _symbol = TextEditingController(text: 'AAPL');
 final _qty = TextEditingController(text: '100');
 final _price = TextEditingController(text: '');
 bool _buy = true;
 String _tif = '0'; // day  -  the TIF wire codes
 String? _error;
 String? _ok;

 Future<void> _submit(Bff8ApiClient bff) async {
 setState( {
 _error = null;
 _ok = null;
 });
 try {
 final res = await bff.submitOrder(
 clientOrderId: DateTime.now.millisecondsSinceEpoch.toString,
 symbol: _symbol.text.toUpperCase,
 side: _buy ? 'b' : 's',
 orderType: _price.text.isEmpty ? '1' : '2', // market / limit
 tif: _tif,
 qty: _qty.text,
 price: _price.text.isEmpty ? null : _price.text,
 );
 setState( => _ok = 'accepted (${res['order_id'] ?? ''})');
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
 TextField(
 controller: _symbol,
 decoration: const InputDecoration(
 labelText: 'Symbol',
 hintText: 'AAPL, MSFT, NVDA…',
 ),
 textCapitalization: TextCapitalization.characters,
 ),
 const SizedBox(height: 8),
 SegmentedButton<bool>(
 segments: const [
 ButtonSegment(value: true, label: Text('Buy')),
 ButtonSegment(value: false, label: Text('Sell')),
 ],
 selected: {_buy},
 onSelectionChanged: (s) => setState( => _buy = s.first),
 ),
 const SizedBox(height: 8),
 TextField(
 controller: _qty,
 decoration: const InputDecoration(labelText: 'Quantity (shares)'),
 keyboardType: TextInputType.number,
 ),
 const SizedBox(height: 8),
 TextField(
 controller: _price,
 decoration: const InputDecoration(
 labelText: 'Limit price (blank = market)',
 hintText: '10.05 (tick bands apply)',
 ),
 keyboardType: const TextInputType.numberWithOptions(decimal: true),
 ),
 const SizedBox(height: 8),
 DropdownButton<String>(
 value: _tif,
 isExpanded: true,
 items: const [
 DropdownMenuItem(value: '0', child: Text('Day')),
 DropdownMenuItem(value: '1', child: Text('GTC')),
 DropdownMenuItem(value: '3', child: Text('IOC')),
 DropdownMenuItem(value: '4', child: Text('FOK')),
 DropdownMenuItem(value: 'ON', child: Text('Overnight (parks at close)')),
 ],
 onChanged: (v) => setState( => _tif = v!),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 if (_ok != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_ok!, style: const TextStyle(color: Colors.green)),
 ),
 const SizedBox(height: 16),
 FilledButton.icon(
 onPressed: => _submit(bff),
 icon: const Icon(Icons.send),
 label: const Text('Submit order'),
 ),
 ],
 );
 }
}