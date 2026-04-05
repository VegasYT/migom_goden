import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/courier_mock_data.dart';

// NOTE: The delivery/business service API does not expose courier statistics
// (earnings, average delivery time, total distance, orders completed per period).
// The only shift data from API is: started_at, ended_at, is_active.
//
// Stats tab shows mocked data until a dedicated statistics endpoint is
// implemented on the backend. See COMMENTED_FEATURES.md for details.

final statsPeriodProvider = StateProvider<StatsPeriod>(
  (ref) => StatsPeriod.today,
);

final currentPeriodStatsProvider = Provider<PeriodStats>((ref) {
  final period = ref.watch(statsPeriodProvider);
  // TODO: replace with real API when /couriers/me/stats or similar is available
  return CourierMockData.periodStats[period]!;
});
