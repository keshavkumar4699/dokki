/// The vault: a filterable grid of entries with a single "Add" action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../routing/routes.dart';
import 'add_entry_sheet.dart';
import 'entry_card.dart';

/// The active type filter for the grid. `null` = everything.
final vaultFilterProvider = StateProvider<EntryType?>((_) => null);

/// Free-text search over titles; matched client-side on the summary list.
final vaultSearchProvider = StateProvider<String>((_) => '');

class VaultHomeScreen extends ConsumerWidget {
  const VaultHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vaultFilterProvider);
    final search = ref.watch(vaultSearchProvider).trim().toLowerCase();
    final entries = ref.watch(entriesProvider(filter));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Vault'),
            actions: [
              IconButton(
                onPressed: () => context.push(Routes.settings),
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Settings',
              ),
              IconButton(
                onPressed: () => ref.read(sessionProvider).lock(),
                icon: const Icon(Icons.lock_outline),
                tooltip: 'Lock now',
              ),
              const SizedBox(width: DokkiSpace.sm),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DokkiSpace.lg,
                0,
                DokkiSpace.lg,
                DokkiSpace.sm,
              ),
              child: _SearchField(
                onChanged: (v) =>
                    ref.read(vaultSearchProvider.notifier).state = v,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _TypeFilterBar()),
          entries.when(
            data: (items) {
              final visible = search.isEmpty
                  ? items
                  : items
                        .where(
                          (e) => (e.title ?? '').toLowerCase().contains(search),
                        )
                        .toList();
              if (visible.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: items.isEmpty
                      ? EmptyState(
                          icon: filter == null
                              ? Icons.inventory_2_outlined
                              : EntryTypeStyle.of(filter).icon,
                          title: filter == null
                              ? 'Your vault is empty'
                              : 'No ${EntryTypeStyle.of(filter).pluralLabel.toLowerCase()} yet',
                          message: filter == null
                              ? 'Add a photo, an ID, a signature, a thumbprint or a document. Everything is encrypted the moment it arrives.'
                              : EntryTypeStyle.of(filter).hint,
                          action: FilledButton.icon(
                            onPressed: () =>
                                showAddEntrySheet(context, preselected: filter),
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        )
                      : const EmptyState(
                          icon: Icons.search_off,
                          title: 'No matches',
                          message: 'Try a different search.',
                        ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  DokkiSpace.lg,
                  DokkiSpace.sm,
                  DokkiSpace.lg,
                  96,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: DokkiSpace.md,
                    crossAxisSpacing: DokkiSpace.md,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => EntryCard(
                      summary: visible[index],
                      onTap: () =>
                          context.push(Routes.entry(visible[index].id)),
                    ),
                    childCount: visible.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.error_outline,
                title: describeError(error).title,
                message: describeError(error).detail,
                action: OutlinedButton(
                  onPressed: () => ref.invalidate(entriesProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ),
        ],
      ),
      // The empty state carries its own CTA; two "Add" buttons is noise.
      floatingActionButton: entries.valueOrNull?.isEmpty ?? true
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddEntrySheet(context, preselected: filter),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              backgroundColor: scheme.primary,
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: const InputDecoration(
      hintText: 'Search titles',
      prefixIcon: Icon(Icons.search),
      isDense: true,
    ),
  );
}

class _TypeFilterBar extends ConsumerWidget {
  const _TypeFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(vaultFilterProvider);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DokkiSpace.lg,
          vertical: DokkiSpace.sm,
        ),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) =>
                ref.read(vaultFilterProvider.notifier).state = null,
          ),
          for (final type in EntryType.values) ...[
            const SizedBox(width: DokkiSpace.sm),
            ChoiceChip(
              avatar: Icon(
                EntryTypeStyle.of(type).icon,
                size: 16,
                color: selected == type
                    ? scheme.onSecondaryContainer
                    : EntryTypeStyle.of(type).foregroundOn(scheme),
              ),
              label: Text(EntryTypeStyle.of(type).pluralLabel),
              selected: selected == type,
              onSelected: (_) => ref.read(vaultFilterProvider.notifier).state =
                  selected == type ? null : type,
            ),
          ],
        ],
      ),
    );
  }
}
