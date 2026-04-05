import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/payment_method_model.dart';

class AddCardSheet extends StatefulWidget {
  final void Function(PaymentMethodModel) onSave;

  const AddCardSheet({super.key, required this.onSave});

  static void show(BuildContext context, {required void Function(PaymentMethodModel) onSave}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddCardSheet(onSave: onSave),
    );
  }

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final number = _numberController.text.replaceAll(' ', '');
    final last4 = number.length >= 4 ? number.substring(number.length - 4) : number;
    final brand = _detectBrand(number);

    widget.onSave(PaymentMethodModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PaymentType.card,
      title: '$brand •••• $last4',
      subtitle: 'Срок: ${_expiryController.text}',
    ));
    Navigator.of(context).pop();
  }

  String _detectBrand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5') || number.startsWith('2')) return 'Mastercard';
    if (number.startsWith('2200') || number.startsWith('2201') ||
        number.startsWith('2202') || number.startsWith('2203') ||
        number.startsWith('2204')) return 'Мир';
    return 'Карта';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Text(
              'Новая карта',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card preview
                    _CardPreview(
                      number: _numberController.text,
                      expiry: _expiryController.text,
                      holder: _nameController.text,
                    ),
                    const SizedBox(height: 24),
                    // Number
                    TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                        LengthLimitingTextInputFormatter(19),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        context,
                        label: 'Номер карты',
                        icon: Icons.credit_card_rounded,
                      ),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(' ', '');
                        if (digits.length < 16) return 'Введите 16 цифр';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ExpiryFormatter(),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              context,
                              label: 'ММ/ГГ',
                              icon: Icons.calendar_today_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.length < 5) return 'Неверный срок';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: _inputDecoration(
                              context,
                              label: 'CVV',
                              icon: Icons.lock_outline_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.length < 3) return 'Неверный CVV';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                        _UpperCaseFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        context,
                        label: 'Имя на карте',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Добавить карту', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }
}

// ─── Card preview ──────────────────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  final String number;
  final String expiry;
  final String holder;

  const _CardPreview({
    required this.number,
    required this.expiry,
    required this.holder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final digits = number.replaceAll(' ', '');

    // Build display groups: fill with dots if not enough digits
    final groups = <String>[];
    for (var i = 0; i < 4; i++) {
      final start = i * 4;
      final end = (start + 4).clamp(0, digits.length);
      if (start >= digits.length) {
        groups.add('••••');
      } else {
        final part = digits.substring(start, end);
        groups.add(part.padRight(4, '•'));
      }
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.credit_card_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
              Text(
                _brandFromDigits(digits),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            groups.join('  '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOLDER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    holder.isEmpty ? 'ВАШЕ ИМЯ' : holder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    expiry.isEmpty ? 'ММ/ГГ' : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _brandFromDigits(String digits) {
    if (digits.startsWith('4')) return 'VISA';
    if (digits.startsWith('5') || digits.startsWith('2')) return 'MASTERCARD';
    if (digits.startsWith('2200') || digits.startsWith('2201') ||
        digits.startsWith('2202') || digits.startsWith('2203') ||
        digits.startsWith('2204')) return 'МИР';
    return '';
  }
}

// ─── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return newValue.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
