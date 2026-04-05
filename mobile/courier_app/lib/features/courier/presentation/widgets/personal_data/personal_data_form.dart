import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/courier_profile_model.dart';
import '../../providers/courier_profile_provider.dart';
import '../profile/profile_avatar.dart';

class PersonalDataForm extends ConsumerStatefulWidget {
  final CourierProfileModel profile;

  const PersonalDataForm({super.key, required this.profile});

  @override
  ConsumerState<PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);

    for (final c in [_nameController, _emailController, _phoneController]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    final changed = _nameController.text != widget.profile.name ||
        _emailController.text != widget.profile.email ||
        _phoneController.text != widget.profile.phone;
    if (changed != _changed) setState(() => _changed = changed);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(courierProfileProvider.notifier).updatePersonalData(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          ).ignore();
      setState(() => _changed = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные сохранены'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileAvatar(avatarUrl: widget.profile.avatarUrl, name: widget.profile.name),
          const SizedBox(height: 32),
          _Field(
            controller: _nameController,
            label: 'Имя',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Введите email';
              if (!v.contains('@')) return 'Некорректный email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _phoneController,
            label: 'Телефон',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()-]'))
            ],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите телефон' : null,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _changed ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: cs.primary.withValues(alpha: 0.12),
            ),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
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
      ),
    );
  }
}
