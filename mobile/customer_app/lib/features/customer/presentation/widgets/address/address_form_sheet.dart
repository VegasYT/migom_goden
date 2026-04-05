import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../domain/address_model.dart';

class AddressFormSheet extends StatefulWidget {
  final void Function(AddressModel) onSave;

  const AddressFormSheet({super.key, required this.onSave});

  static void show(BuildContext context, {required void Function(AddressModel) onSave}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddressFormSheet(onSave: onSave),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _commentController = TextEditingController();
  String _selectedLabel = 'Дом';
  bool _saving = false;

  static const _labels = ['Дом', 'Работа', 'Другое'];

  @override
  void dispose() {
    _streetController.dispose();
    _apartmentController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final street = _streetController.text.trim();
    double? lat, lon;

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': street,
          'format': 'json',
          'limit': '1',
          'accept-language': 'ru',
        },
        options: Options(
          headers: {'User-Agent': 'MigomCustomerApp/1.0'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final results = response.data as List<dynamic>;
      if (results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        lat = double.tryParse(first['lat'] as String? ?? '');
        lon = double.tryParse(first['lon'] as String? ?? '');
      }
    } catch (_) {
      // геокодирование не обязательно - сохраним без координат
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (lat == null || lon == null) {
      // Предупреждаем но не блокируем - адрес сохранится без координат
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось определить координаты адреса. Уточните название улицы.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final address = AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _selectedLabel,
      street: street,
      apartment: _apartmentController.text.trim().isEmpty
          ? null
          : _apartmentController.text.trim(),
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      latitude: lat,
      longitude: lon,
    );
    widget.onSave(address);
    Navigator.of(context).pop();
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
          // Handle
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Новый адрес',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label chips
                    Row(
                      children: _labels.map((lbl) {
                        final selected = lbl == _selectedLabel;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(lbl),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedLabel = lbl),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Улица и дом *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Введите улицу' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Квартира / офис',
                        prefixIcon: Icon(Icons.door_front_door_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Комментарий курьеру',
                        prefixIcon: Icon(Icons.comment_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Сохранить адрес', style: TextStyle(fontSize: 16)),
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
}
