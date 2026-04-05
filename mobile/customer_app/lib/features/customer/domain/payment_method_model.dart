enum PaymentType { card, cash, sbp }

class PaymentMethodModel {
  final String id;
  final PaymentType type;
  final String title;
  final String? subtitle;
  final bool isDefault;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'card';
    final type = switch (typeStr) {
      'cash' => PaymentType.cash,
      'sbp' => PaymentType.sbp,
      _ => PaymentType.card,
    };
    return PaymentMethodModel(
      id: json['id'].toString(),
      type: type,
      title: json['title'] as String? ?? '',
      subtitle: null,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': switch (type) {
      PaymentType.card => 'card',
      PaymentType.cash => 'cash',
      PaymentType.sbp => 'sbp',
    },
    'title': title,
  };
}
