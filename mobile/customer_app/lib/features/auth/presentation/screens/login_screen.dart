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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              icon: Icons.delivery_dining_rounded,
              title: 'С возвращением!',
              subtitle: 'Войдите в свой аккаунт',
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
                      label: 'Email',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.isEmpty) ? 'Введите email' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthInputField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hint: '••••••••',
                      icon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                    ),
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
                      label: 'Войти',
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        await ref.read(authNotifierProvider.notifier).login(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );
                        final authState = ref.read(authNotifierProvider);
                        if (authState.hasError && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authState.error.toString())),
                          );
                        } else if (context.mounted) {
                          context.go('/home');
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const AuthDividerOr(),
                    const SizedBox(height: 24),
                    AuthSocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Продолжить с Google',
                      onPressed: () {},
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
