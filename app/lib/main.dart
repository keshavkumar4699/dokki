/// Entry point: compose the graph, then hand it to Riverpod and the router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/app_lifecycle.dart';
import 'bootstrap/composition_root.dart';
import 'bootstrap/providers.dart';
import 'core_ui/theme.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boot = await composeBoot();
  runApp(
    ProviderScope(
      overrides: [appBootProvider.overrideWithValue(boot)],
      child: const DokkiApp(),
    ),
  );
}

class DokkiApp extends ConsumerWidget {
  const DokkiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'dokki',
    debugShowCheckedModeBanner: false,
    theme: DokkiTheme.light(),
    darkTheme: DokkiTheme.dark(),
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) => AppLifecycle(child: child!),
  );
}
