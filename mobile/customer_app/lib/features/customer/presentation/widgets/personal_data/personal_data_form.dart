import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/profile_model.dart';
import '../../providers/profile_provider.dart';

class PersonalDataForm extends ConsumerStatefulWidget {
  final ProfileModel profile;

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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(profileUpdateProvider.notifier).save(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    final error = ref.read(profileUpdateProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные сохранены'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _changed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoading = ref.watch(profileUpdateProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AvatarSection(avatarUrl: widget.profile.avatarUrl, name: widget.profile.name),
          const SizedBox(height: 32),
          _ProfileField(
            controller: _nameController,
            label: 'Имя',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Введите email';
              if (!v.contains('@')) return 'Некорректный email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _ProfileField(
            controller: _phoneController,
            label: 'Телефон',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()-]'))],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите телефон' : null,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: (_changed && !isLoading) ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: cs.primary.withValues(alpha: 0.12),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const _AvatarSection({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: cs.primaryContainer,
            child: avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _Initials(initials: initials),
                    ),
                  )
                : _Initials(initials: initials),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {}, // TODO: image picker
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2.5),
                ),
                child: Icon(Icons.camera_alt_outlined, size: 16, color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  const _Initials({required this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      initials,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cs.onPrimaryContainer,
      ),
    );
  }
}

// ─── Field ─────────────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool readOnly;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
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
