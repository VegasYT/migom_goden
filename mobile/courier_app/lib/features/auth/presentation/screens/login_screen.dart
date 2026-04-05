import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
        msg = 'Неверный email или пароль (${e.response?.statusCode ?? "?"})';
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AuthHeader(
              icon: Icons.directions_bike_rounded,
              title: 'С возвращением!',
              subtitle: 'Войдите в аккаунт курьера',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthInputField(
                      controller: _emailController,
                      label: 'Электронная почта',
                      hint: 'example@mail.ru',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Введите электронную почту' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthInputField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hint: '••••••••',
                      icon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Введите пароль' : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Забыли пароль?',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuthPrimaryButton(
                      label: _loading ? 'Входим...' : 'Войти',
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Нет аккаунта?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Зарегистрироваться'),
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
    );
  }
}
