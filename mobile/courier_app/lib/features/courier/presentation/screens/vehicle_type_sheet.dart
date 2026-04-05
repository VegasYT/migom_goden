import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/vehicle_type.dart';
import '../providers/courier_profile_provider.dart';
import '../widgets/vehicle/vehicle_option_tile.dart';

class VehicleTypeSheet extends ConsumerWidget {
  const VehicleTypeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VehicleTypeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(courierProfileSyncProvider).vehicleType;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Транспортное средство',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Выберите способ доставки',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            ...VehicleType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VehicleOptionTile(
                  type: type,
                  selected: type == current,
                  onTap: () {
                    ref
                        .read(courierProfileProvider.notifier)
                        .updateVehicleType(type)
                        .ignore();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
