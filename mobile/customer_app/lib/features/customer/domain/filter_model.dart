enum SortOption { popular, rating, deliveryTime, deliveryPrice }

class FilterModel {
  final SortOption sort;
  final int maxDeliveryTime; // минуты, 0 = любое
  final bool freeDeliveryOnly;
  final double minRating; // 0 = любой
  final Set<String> cuisines; // пустой = все
  final bool promoOnly;

  const FilterModel({
    this.sort = SortOption.popular,
    this.maxDeliveryTime = 0,
    this.freeDeliveryOnly = false,
    this.minRating = 0,
    this.cuisines = const {},
    this.promoOnly = false,
  });

  static const empty = FilterModel();

  bool get isEmpty =>
      sort == SortOption.popular &&
      maxDeliveryTime == 0 &&
      !freeDeliveryOnly &&
      minRating == 0 &&
      cuisines.isEmpty &&
      !promoOnly;

  int get activeCount {
    int count = 0;
    if (sort != SortOption.popular) count++;
    if (maxDeliveryTime > 0) count++;
    if (freeDeliveryOnly) count++;
    if (minRating > 0) count++;
    if (cuisines.isNotEmpty) count++;
    if (promoOnly) count++;
    return count;
  }

  FilterModel copyWith({
    SortOption? sort,
    int? maxDeliveryTime,
    bool? freeDeliveryOnly,
    double? minRating,
    Set<String>? cuisines,
    bool? promoOnly,
  }) {
    return FilterModel(
      sort: sort ?? this.sort,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      freeDeliveryOnly: freeDeliveryOnly ?? this.freeDeliveryOnly,
      minRating: minRating ?? this.minRating,
      cuisines: cuisines ?? this.cuisines,
      promoOnly: promoOnly ?? this.promoOnly,
    );
  }
}
