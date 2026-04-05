import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../widgets/personal_data/personal_data_form.dart';

class PersonalDataScreen extends ConsumerWidget {
  const PersonalDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Личные данные'),
        centerTitle: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PersonalDataForm(profile: profile),
        ),
      ),
    );
  }
}
