import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/company_model.dart';
import 'address_provider.dart';
import 'companies_provider.dart';

// Возвращает id ближайшей активной точки компании к дефолтному адресу.
// Если у адреса нет координат или адресов нет - первая активная точка.
final nearestOutletProvider =
    FutureProvider.family<int?, int>((ref, companyId) async {
  final outlets = await ref.watch(companyOutletsProvider(companyId).future)
      .timeout(const Duration(seconds: 10), onTimeout: () => <OutletModel>[]);
  if (outlets.isEmpty) return null;
  final active = outlets.where((o) => o.isActive).toList();
  final candidates = active.isNotEmpty ? active : outlets;
  if (candidates.length == 1) return candidates.first.id;

  final address = ref.watch(defaultAddressProvider);
  final lat = address?.latitude;
  final lon = address?.longitude;

  if (lat == null || lon == null) return candidates.first.id;

  OutletModel? nearest;
  double minDist = double.infinity;
  for (final outlet in candidates) {
    if (outlet.latitude == null || outlet.longitude == null) continue;
    final dist = _distanceKm(lat, lon, outlet.latitude!, outlet.longitude!);
    if (dist < minDist) {
      minDist = dist;
      nearest = outlet;
    }
  }
  return nearest?.id ?? candidates.first.id;
});

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;
