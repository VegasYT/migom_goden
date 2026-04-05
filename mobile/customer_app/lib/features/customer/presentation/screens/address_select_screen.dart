import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/address/address_tile.dart';
import '../widgets/address/address_form_sheet.dart';

/// [selectionMode] = true - выбор адреса (возвращает выбранный через Navigator.pop)
/// [selectionMode] = false - управление адресами из профиля
class AddressSelectScreen extends ConsumerWidget {
  final bool selectionMode;

  const AddressSelectScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressProvider);
    final defaultId = ref.watch(defaultAddressProvider)?.id;
    final addresses = addressesAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode ? 'Выберите адрес' : 'Адреса доставки'),
        centerTitle: false,
        actions: [
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddSheet(context, ref),
            ),
        ],
      ),
      body: addressesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? _EmptyState(onAdd: () => _showAddSheet(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (_, i) {
                final address = addresses[i];
                return AddressTile(
                  address: address,
                  isSelected: selectionMode
                      ? address.id == defaultId
                      : address.isDefault,
                  selectionMode: selectionMode,
                  onTap: () {
                    if (selectionMode) {
                      ref.read(addressProvider.notifier).setDefault(address.id);
                      Navigator.of(context).pop(address);
                    } else {
                      ref.read(addressProvider.notifier).setDefault(address.id);
                    }
                  },
                  onDelete: selectionMode
                      ? null
                      : () => _confirmDelete(context, ref, address),
                );
              },
            ),
      floatingActionButton: selectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Новый адрес'),
            )
          : null,
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    AddressFormSheet.show(context, onSave: (address) {
      ref.read(addressProvider.notifier).add(address);
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AddressModel address) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить адрес?'),
        content: Text(address.fullAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(addressProvider.notifier).remove(address.id);
            },
            child: Text(
              'Удалить',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Нет сохранённых адресов',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте адрес доставки, чтобы заказывать быстрее',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Добавить адрес'),
            ),
          ],
        ),
      ),
    );
  }
}
