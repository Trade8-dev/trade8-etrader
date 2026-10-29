// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// BFF client wiring (etrader surfaces): transport + scope map + SSE
// subscription surface + quote/blotter/P&L caches the pages consume.
//
// All backend access routes through Sentin8:BFF /proxy/trade8/...  - 
// no direct service calls (BFF pattern, architecture-principles §4.7).
// The concrete HTTP/SSE transport comes from `sdk/flutter/sentin8_flutter`'s
// Bff8ApiClient once the app bootstrap lands; this module wraps it with
// trade8's channels and caches.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// BFF transport errors surfaced to the UI.
class BffError implements Exception {
 final String message;
 BffError(this.message);
 @override
 String toString => message;
}

/// One SSE event off /subscribe (trade8:feed:quote:updated etc.).
class BffEvent {
 final String channel;
 final Map<String, dynamic> data;
 BffEvent(this.channel, this.data);
}

/// Blotter row (Desk OrderSummary shape).
class OrderRow {
 final String orderId;
 final String clientOrderId;
 final String symbol;
 final String side; // b|s|t
 final String state;
 final int qty;
 final int leavesQty;
 final int filledQty;
 final int? priceRaw;
 final String usrId;
 final String officeId;
 final String submittedAt;
 OrderRow({
 required this.orderId,
 required this.clientOrderId,
 required this.symbol,
 required this.side,
 required this.state,
 required this.qty,
 required this.leavesQty,
 required this.filledQty,
 this.priceRaw,
 required this.usrId,
 required this.officeId,
 required this.submittedAt,
 });

 factory OrderRow.fromJson(Map<String, dynamic> j) => OrderRow(
 orderId: (j['order_id'] ?? '').toString,
 clientOrderId: (j['client_order_id'] ?? '').toString,
 symbol: (j['symbol_name'] ?? '').toString,
 side: (j['side'] ?? 'b').toString,
 state: (j['state'] ?? 'pending').toString,
 qty: (j['qty'] is Map) ? ((j['qty']['raw'] ?? 0) as int) : ((j['qty'] ?? 0) as int),
 leavesQty: (j['leaves_qty'] is Map)
 ? ((j['leaves_qty']['raw'] ?? 0) as int)
 : ((j['leaves_qty'] ?? 0) as int),
 filledQty: (j['filled_qty'] is Map)
 ? ((j['filled_qty']['raw'] ?? 0) as int)
 : ((j['filled_qty'] ?? 0) as int),
 priceRaw: j['price'] is Map ? (j['price']['raw'] as int?) : (j['price'] as int?),
 usrId: (j['usr_id'] ?? '').toString,
 officeId: (j['office_id'] ?? '').toString,
 submittedAt: (j['submitted_at'] ?? '').toString,
 );

 bool get working =>
 state == 'accepted' || state == 'routed' || state == 'partially_filled';
}

/// Quote snapshot (Feed QuoteUpdate shape - scaled prices).
class Quote {
 final String symbol;
 final int bidRaw;
 final int askRaw;
 final int bidSize;
 final int askSize;
 Quote({
 required this.symbol,
 required this.bidRaw,
 required this.askRaw,
 required this.bidSize,
 required this.askSize,
 });

 factory Quote.fromJson(Map<String, dynamic> j) => Quote(
 symbol: (j['symbol_name'] ?? '').toString,
 bidRaw: (j['bid_price'] is Map) ? (j['bid_price']['raw'] ?? 0) as int : 0,
 askRaw: (j['ask_price'] is Map) ? (j['ask_price']['raw'] ?? 0) as int : 0,
 bidSize: (j['bid_size'] ?? 0) as int,
 askSize: (j['ask_size'] ?? 0) as int,
 );

 String get bboLabel =>
 '${_fmt(bidRaw)} / ${_fmt(askRaw)}';
 static String _fmt(int raw) => (raw / 10000).toStringAsFixed(2);
}

/// The BFF client surface the pages use.
class Bff8ApiClient {
 final Future<Map<String, dynamic>> Function(
 String method, String path, Map<String, dynamic>? body) _http;
 final Stream<BffEvent> Function(String channel) _sse;

 /// Hot caches the pages read (SSE-driven updates land here).
 final Map<String, OrderRow> orderCache = {};
 final Map<String, Quote> quoteCache = {};
 final Map<String, List<Map<String, dynamic>>> tapeCache = {};
 final Map<String, Map<String, dynamic>> pnlCache = {};

 Bff8ApiClient(this._http, this._sse);

 Future<Map<String, dynamic>> get(String path) => _http('GET', path, null);
 Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
 _http('POST', path, body ?? {});

 Stream<BffEvent> subscribe(String channel) => _sse(channel);

 /// Submit a new order (Desk POST /v1/orders).
 Future<Map<String, dynamic>> submitOrder({
 required String clientOrderId,
 required String symbol,
 required String side,
 required String orderType,
 required String tif,
 required String qty,
 String? price,
 String? destinationId,
 }) =>
 post('/proxy/trade8/v1/orders', body: {
 'client_order_id': clientOrderId,
 'symbol_name': symbol,
 if (destinationId != null) 'destination_id': destinationId,
 'side': side,
 'order_type': orderType,
 'tif': tif,
 'qty': qty,
 if (price != null) 'price': price,
 });

 /// Cancel one order.
 Future<void> cancelOrder(String orderId) =>
 _http('DELETE', '/proxy/trade8/v1/orders/$orderId', null).then((_) {});

 /// Blotter refresh (GET /v1/orders).
 Future<List<OrderRow>> refreshBlotter async {
 final res = await get('/proxy/trade8/v1/orders?limit=200');
 final rows = (res['orders'] as List? ?? res as List? ?? [])
 .map((e) => OrderRow.fromJson((e as Map).cast<String, dynamic>))
 .toList;
 for (final r in rows) {
 orderCache[r.orderId] = r;
 }
 return rows;
 }

 /// Quote refresh (GET /v1/quotes/{symbol}).
 Future<Quote?> refreshQuote(String symbol) async {
 try {
 final res = await get('/proxy/trade8/v1/quotes/$symbol');
 final q = Quote.fromJson(res);
 quoteCache[symbol] = q;
 return q;
 } on BffError {
 return quoteCache[symbol];
 }
 }
}

/// Inherited scope holder (the shell provides the authenticated client).
class BffClientScope extends InheritedWidget {
 final Bff8ApiClient client;
 const BffClientScope({super.key, required this.client, required super.child});

 static Bff8ApiClient of(BuildContext context) =>
 context.dependOnInheritedWidgetOfExactType<BffClientScope>!.client;

 @override
 bool updateShouldNotify(BffClientScope old) => old.client != client;
}