import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/filter_model.dart';

class FilterNotifier extends StateNotifier<FilterModel> {
  FilterNotifier() : super(FilterModel.empty);

  void update(FilterModel filter) => state = filter;

  void reset() => state = FilterModel.empty;
}

final filterProvider =
    StateNotifierProvider<FilterNotifier, FilterModel>(
  (_) => FilterNotifier(),
);
