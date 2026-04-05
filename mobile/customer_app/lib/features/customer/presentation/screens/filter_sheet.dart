import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/filter_model.dart';
import '../providers/filter_provider.dart';
import '../widgets/filter/filter_cuisine_chips.dart';
import '../widgets/filter/filter_delivery_time_slider.dart';
import '../widgets/filter/filter_rating_row.dart';
import '../widgets/filter/filter_sort_row.dart';
import '../widgets/filter/filter_toggle_row.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late FilterModel _draft;

  @override
  void initState() {
    super.initState();
    // Стартуем с текущим состоянием фильтра - изменения применяются только при нажатии «Применить»
    _draft = ref.read(filterProvider);
  }

  void _apply() {
    HapticFeedback.mediumImpact();
    ref.read(filterProvider.notifier).update(_draft);
    Navigator.of(context).pop();
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() => _draft = FilterModel.empty);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final activeCount = _draft.activeCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ─── Шапка
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    // Drag handle по центру
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'Фильтры',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (activeCount > 0)
                      TextButton(
                        onPressed: _reset,
                        child: Text(
                          'Сбросить',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),

              // ─── Контент
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  children: [
                    FilterSortRow(
                      selected: _draft.sort,
                      onChanged: (v) =>
                          setState(() => _draft = _draft.copyWith(sort: v)),
                    ),

                    const SizedBox(height: 28),

                    FilterDeliveryTimeSlider(
                      value: _draft.maxDeliveryTime,
                      onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(maxDeliveryTime: v)),
                    ),

                    const SizedBox(height: 28),

                    FilterRatingRow(
                      selected: _draft.minRating,
                      onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(minRating: v)),
                    ),

                    const SizedBox(height: 28),

                    FilterCuisineChips(
                      selected: _draft.cuisines,
                      onChanged: (v) =>
                          setState(() => _draft = _draft.copyWith(cuisines: v)),
                    ),

                    const SizedBox(height: 28),

                    FilterToggleRow(
                      icon: Icons.delivery_dining_rounded,
                      label: 'Бесплатная доставка',
                      subtitle: 'Только рестораны без платы за доставку',
                      value: _draft.freeDeliveryOnly,
                      onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(freeDeliveryOnly: v)),
                    ),

                    const SizedBox(height: 10),

                    FilterToggleRow(
                      icon: Icons.local_offer_rounded,
                      label: 'Только со скидками',
                      subtitle: 'Акции, промокоды и специальные предложения',
                      value: _draft.promoOnly,
                      onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(promoOnly: v)),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ─── Кнопка применить
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color: colorScheme.outlineVariant, width: 0.8),
                  ),
                ),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    activeCount > 0 ? 'Применить ($activeCount)' : 'Применить',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
