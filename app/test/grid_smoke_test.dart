/// Grid smoke test (§17 Phase 10): a 1000-entry vault builds and scrolls
/// without exceptions. Not a jank measurement — that needs a device —
/// but it pins the "large vault doesn't explode the UI" property in CI.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'lock_gate_test.dart' show app;
import 'support/fakes.dart';
import 'support/test_graph.dart';

void main() {
  testWidgets('a 1000-entry grid builds and scrolls', (tester) async {
    final g = TestGraph(unlocked: true);
    for (var i = 0; i < 1000; i++) {
      final created = unwrap(
        await g.graph.createEntry.execute(
          CreateEntryCommand(
            type: EntryType.photo,
            title: 'Entry $i',
            source: sourceOf(100 + (i % 50), 100),
          ),
        ),
      );
      expect(created.assets, hasLength(1));
    }

    await tester.pumpWidget(app(g));
    await tester.pumpAndSettle();
    expect(find.byType(SliverGrid), findsOneWidget);

    // The grid is lazy: a thousand entries do not produce a thousand
    // cards in the tree at once.
    expect(find.byType(Card).evaluate().length, lessThan(100));

    // Scroll hard to the bottom and back: no overflow, no exceptions.
    final scrollable = find.byType(Scrollable).first;
    await tester.fling(scrollable, const Offset(0, -5000), 8000);
    await tester.pumpAndSettle();
    await tester.fling(scrollable, const Offset(0, 5000), 8000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
