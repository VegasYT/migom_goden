import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/profile_service.dart';
import '../../domain/profile_model.dart';

part 'profile_provider.g.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileService());

@riverpod
Future<ProfileModel> profile(Ref ref) async {
  return ref.watch(profileServiceProvider).getProfile();
}

@riverpod
List<ProfileOrderItem> profileOrders(Ref ref) => const [];

// Notifier для обновления профиля
class ProfileUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save({String? fullName, String? phone}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileServiceProvider).updateProfile(
        fullName: fullName,
        phone: phone,
      );
      ref.invalidate(profileProvider);
    });
  }
}

final profileUpdateProvider =
    AsyncNotifierProvider<ProfileUpdateNotifier, void>(ProfileUpdateNotifier.new);
