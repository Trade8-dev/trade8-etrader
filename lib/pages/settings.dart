// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Trade8:ETrader
// SPDX-License-Identifier: Apache-2.0

// Settings + compliance (A1.13): shortcuts editor (trader_profile
// tool_preferences sync), defaults, audit/keystroke view.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bff/bff_client.dart';
import '../bff/shortcuts.dart';

class SettingsPage extends StatefulWidget {
 const SettingsPage({super.key});

 @override
 State<SettingsPage> createState => _SettingsPageState;
}

class _SettingsPageState extends State<SettingsPage> {
 late final ShortcutMap _shortcuts;
 String? _error;
 String? _saved;

 @override
 void initState {
 super.initState;
 _shortcuts = ShortcutMap; // fromPrefs once the profile API lands
 }

 Future<void> _save(Bff8ApiClient bff) async {
 try {
 await bff.post('/proxy/trade8/v1/profile/tool-preferences',
 body: _shortcuts.toPrefs);
 setState( {
 _saved = 'Saved';
 _error = null;
 });
 } on BffError catch (e) {
 setState( => _error = e.message);
 }
 }

 Future<void> _captureBinding(String action) async {
 // Keyboard capture: the next key press rebinds the action.
 final focused = FocusManager.instance.primaryFocus;
 final node = FocusNode(onKey: (_, event) {
 if (event is KeyDownEvent) {
 setState( => _shortcuts.bindings[action] = event.logicalKey);
 node.dispose;
 return KeyEventResult.handled;
 }
 return KeyEventResult.ignored;
 });
 focused?.requestChildFocus(node); // placeholder: overlay capture
 }

 @override
 Widget build(BuildContext context) {
 final bff = BffClientScope.of(context);
 return ListView(
 padding: const EdgeInsets.all(16),
 children: [
 Text('Shortcuts', style: Theme.of(context).textTheme.titleMedium),
 const SizedBox(height: 8),
 for (final e in kDefaultShortcuts.entries)
 ListTile(
 dense: true,
 title: Text(e.value.label),
 subtitle: Text(
 _shortcuts.bindings[e.key]?.keyLabel ?? '?',
 ),
 trailing: TextButton(
 onPressed: => _captureBinding(e.key),
 child: const Text('Rebind'),
 ),
 ),
 if (_error != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_error!, style: const TextStyle(color: Colors.red)),
 ),
 if (_saved != null)
 Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(_saved!, style: const TextStyle(color: Colors.green)),
 ),
 FilledButton.icon(
 onPressed: => _save(bff),
 icon: const Icon(Icons.save),
 label: const Text('Save preferences'),
 ),
 const SizedBox(height: 24),
 Text('Compliance', style: Theme.of(context).textTheme.titleMedium),
 const Padding(
 padding: EdgeInsets.only(top: 8),
 child: Text(
 'Audit + keystroke view (trade8:desk:keystroke:logged trail) '
 'renders for holders of the pnl/keystroke read scope; the '
 'on-behalf-of attribution is shown per row.',
 ),
 ),
 ],
 );
 }
}