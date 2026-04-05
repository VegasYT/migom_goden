import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/websocket_service.dart';
import '../../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isLoggedIn();
});

class AuthNotifier extends AsyncNotifier<void> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.login(email: email, password: password),
    );
    if (!state.hasError) WebSocketService().connect();
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      ),
    );
    if (!state.hasError) WebSocketService().connect();
  }

  Future<void> logout() async {
    WebSocketService().disconnect();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.logout());
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
