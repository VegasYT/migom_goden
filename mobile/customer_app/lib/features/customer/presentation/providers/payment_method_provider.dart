import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payment_method_service.dart';
import '../../domain/payment_method_model.dart';

final paymentMethodServiceProvider =
    Provider<PaymentMethodService>((ref) => PaymentMethodService());

class PaymentMethodNotifier extends AsyncNotifier<List<PaymentMethodModel>> {
  PaymentMethodService get _service => ref.read(paymentMethodServiceProvider);

  @override
  Future<List<PaymentMethodModel>> build() async {
    var methods = await _service.getMethods();
    print('[PaymentMethods] from API: ${methods.map((m) => '${m.id}:${m.type}:${m.title}').toList()}');

    // Если нет наличных - создаём на сервере
    final hasCash = methods.any((m) => m.type == PaymentType.cash);
    if (!hasCash) {
      try {
        final cash = await _service.createMethod(const PaymentMethodModel(
          id: '0', type: PaymentType.cash, title: 'Наличные',
        ));
        print('[PaymentMethods] created cash: id=${cash.id}');
        methods = [...methods, cash];
      } catch (e) {
        print('[PaymentMethods] create cash error: $e');
      }
    }

    // Сортируем: наличные первыми
    methods.sort((a, b) {
      int rank(PaymentMethodModel m) {
        if (m.type == PaymentType.cash) return 0;
        return 1;
      }
      return rank(a).compareTo(rank(b));
    });
    return methods;
  }

  void setDefault(String id) {
    final methods = state.valueOrNull ?? [];
    state = AsyncData(methods.map((m) => PaymentMethodModel(
      id: m.id,
      type: m.type,
      title: m.title,
      subtitle: m.subtitle,
      isDefault: m.id == id,
    )).toList());
  }

  Future<void> add(PaymentMethodModel method) async {
    final created = await _service.createMethod(method);
    state = AsyncData([...(state.valueOrNull ?? []), created]);
  }

  Future<void> remove(String id) async {
    await _service.deleteMethod(id);
    final updated = (state.valueOrNull ?? []).where((m) => m.id != id).toList();
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getMethods());
  }
}

final paymentMethodProvider =
    AsyncNotifierProvider<PaymentMethodNotifier, List<PaymentMethodModel>>(
  PaymentMethodNotifier.new,
);

final defaultPaymentMethodProvider = Provider<PaymentMethodModel?>((ref) {
  final methods = ref.watch(paymentMethodProvider).valueOrNull ?? [];
  try {
    return methods.firstWhere((m) => m.isDefault);
  } catch (_) {
    return methods.isNotEmpty ? methods.first : null;
  }
});
