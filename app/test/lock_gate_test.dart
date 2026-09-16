/// The router's lock gate (§15.2): onboarding without a vault, unlock while
/// locked, vault once unlocked. Also a layout smoke test for each screen.
library;

import 'package:dokki/bootstrap/providers.dart';
import 'package:dokki/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_graph.dart';

Widget app(TestGraph g) => ProviderScope(
  overrides: [appBootProvider.overrideWithValue(g.boot)],
  child: const DokkiApp(),
);

void main() {
  testWidgets('no vault → full onboarding creates it', (tester) async {
    final g = TestGraph(hasVault: false);
    await tester.pumpWidget(app(g));
    await tester.pumpAndSettle();
    expect(find.text('Create my vault'), findsOneWidget);
    await tester.tap(find.text('Create my vault'));
    await tester.pumpAndSettle();
    for (var round = 0; round < 2; round++) {
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }
    expect(find.text('Write these six words down'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create vault'));
    await tester.pumpAndSettle();
    expect(g.keys.hasVault, isTrue);
    expect(find.text('Your vault is empty'), findsOneWidget);
  });

  testWidgets('vault + locked → unlock screen with PIN pad', (tester) async {
    await tester.pumpWidget(app(TestGraph()));
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('correct PIN unlocks and shows the vault', (tester) async {
    final g = TestGraph();
    await tester.pumpWidget(app(g));
    await tester.pumpAndSettle();
    for (final d in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    // FakeKeyManager's PIN is 1234 → wrong → still locked, error copy shown.
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.textContaining('attempts left'), findsOneWidget);

    await g.session.unlockWithPin('1234');
    await tester.pumpAndSettle();
    expect(find.text('Your vault is empty'), findsOneWidget);
  });

  testWidgets('locking from the vault returns to the gate', (tester) async {
    final g = TestGraph(unlocked: true);
    await tester.pumpWidget(app(g));
    await tester.pumpAndSettle();
    expect(find.text('Your vault is empty'), findsOneWidget);
    await tester.tap(find.byTooltip('Lock now'));
    // Frame by frame: the router must never route through /opening on the
    // way to the gate (it would try to reopen a vault whose keys are gone).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Opening your vault…'), findsNothing);
      expect(find.text('Vault is locked'), findsNothing);
    }
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(g.closeCount, 1);
  });
}
