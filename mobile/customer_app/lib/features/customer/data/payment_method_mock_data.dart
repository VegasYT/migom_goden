import '../domain/payment_method_model.dart';

abstract final class PaymentMethodMockData {
  static const methods = [
    PaymentMethodModel(
      id: '1',
      type: PaymentType.card,
      title: 'Visa •••• 4242',
      subtitle: 'Срок: 08/27',
      isDefault: true,
    ),
    PaymentMethodModel(
      id: '2',
      type: PaymentType.card,
      title: 'Mastercard •••• 8810',
      subtitle: 'Срок: 12/25',
      isDefault: false,
    ),
    PaymentMethodModel(
      id: '3',
      type: PaymentType.sbp,
      title: 'СБП',
      subtitle: 'Системa быстрых платежей',
      isDefault: false,
    ),
    PaymentMethodModel(
      id: '4',
      type: PaymentType.cash,
      title: 'Наличными',
      subtitle: 'При получении',
      isDefault: false,
    ),
  ];
}
