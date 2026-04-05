import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier(this._service) : super(AuthStatus.unknown);

  final AuthService _service;

  Future<void> checkAuth() async {
    final loggedIn = await _service.isLoggedIn();
    state = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<void> login({required String email, required String password}) async {
    await _service.login(email: email, password: password);
    state = AuthStatus.authenticated;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    await _service.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _service.logout();
    state = AuthStatus.unauthenticated;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
