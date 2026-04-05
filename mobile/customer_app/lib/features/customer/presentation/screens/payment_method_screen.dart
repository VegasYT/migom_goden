import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/payment_method_model.dart';
import '../providers/payment_method_provider.dart';
import '../widgets/payment/payment_method_tile.dart';

/// [selectionMode] = true - выбор метода (возвращает выбранный через Navigator.pop)
/// [selectionMode] = false - управление методами из профиля
class PaymentMethodScreen extends ConsumerWidget {
  final bool selectionMode;

  const PaymentMethodScreen({super.key, this.selectionMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodProvider);
    final defaultId = ref.watch(defaultPaymentMethodProvider)?.id;
    final methods = methodsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode ? 'Способ оплаты' : 'Способы оплаты'),
        centerTitle: false,
      ),
      body: methodsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : methods.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...methods.map((method) => PaymentMethodTile(
                      method: method,
                      isSelected: selectionMode
                          ? method.id == defaultId
                          : method.isDefault,
                      selectionMode: selectionMode,
                      onTap: () {
                        ref
                            .read(paymentMethodProvider.notifier)
                            .setDefault(method.id);
                        if (selectionMode) Navigator.of(context).pop(method);
                      },
                      onDelete: selectionMode ||
                              method.id == 'cash' ||
                              method.id == 'card_on_delivery'
                          ? null
                          : () => _confirmDelete(context, ref, method),
                    )),
              ],
            ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PaymentMethodModel method) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить способ оплаты?'),
        content: Text(method.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(paymentMethodProvider.notifier).remove(method.id);
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
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card_off_outlined, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('Нет способов оплаты', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
