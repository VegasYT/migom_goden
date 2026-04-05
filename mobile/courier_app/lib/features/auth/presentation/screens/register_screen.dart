import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreed = false;
  bool _loading = false;
  String? _errorMessage;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _errorMessage = 'Примите условия использования');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      String msg;
      if (detail is String) {
        msg = detail;
      } else if (detail is List && detail.isNotEmpty) {
        msg = detail.map((d) => d['msg'] ?? d.toString()).join('; ');
      } else {
        msg = 'Ошибка регистрации (${e.response?.statusCode ?? "?"})';
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка соединения: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AuthHeader(
                icon: Icons.person_add_rounded,
                title: 'Стать курьером',
                subtitle: 'Регистрация займёт меньше минуты',
                showBack: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section: personal data
                      _SectionLabel(
                        label: 'Личные данные',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 14),

                      AuthInputField(
                        controller: _nameController,
                        label: 'Полное имя',
                        hint: 'Иван Иванов',
                        icon: Icons.person_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Введите имя' : null,
                      ),
                      const SizedBox(height: 14),
                      AuthInputField(
                        controller: _emailController,
                        label: 'Электронная почта',
                        hint: 'example@mail.ru',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Введите email' : null,
                      ),
                      const SizedBox(height: 14),
                      AuthInputField(
                        controller: _phoneController,
                        label: 'Номер телефона (необязательно)',
                        hint: '+7 999 000 00 00',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 24),
                      // Section: credentials
                      _SectionLabel(
                        label: 'Данные для входа',
                        icon: Icons.lock_outline_rounded,
                      ),
                      const SizedBox(height: 14),

                      AuthInputField(
                        controller: _passwordController,
                        label: 'Пароль',
                        hint: 'Минимум 8 символов',
                        icon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        onToggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) =>
                            (v == null || v.length < 8) ? 'Минимум 8 символов' : null,
                      ),

                      // Password strength bar
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PasswordStrength(password: _passwordController.text),
                      ],

                      const SizedBox(height: 20),

                      // Terms checkbox
                      GestureDetector(
                        onTap: () => setState(() => _agreed = !_agreed),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreed
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _agreed
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _agreed
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Я принимаю ',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'условия использования',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' и '),
                                    TextSpan(
                                      text: 'политику конфиденциальности',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: _loading ? 'Регистрируемся...' : 'Зарегистрироваться',
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Уже есть аккаунт?',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Войти'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colorScheme.outlineVariant, height: 1)),
      ],
    );
  }
}

// ─── Password strength ────────────────────────────────────────────────────────

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s.clamp(0, 4);
  }

  static const _labels = ['Слабый', 'Средний', 'Хороший', 'Надёжный'];
  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF4ADE80),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final idx = (s - 1).clamp(0, 3);
    final color = s == 0 ? Colors.transparent : _colors[idx];
    final label = s == 0 ? '' : _labels[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < s ? color : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
