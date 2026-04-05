import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/catalog_item_detail_model.dart';
import '../../domain/company_model.dart';
import 'companies_provider.dart';

part 'catalog_item_detail_provider.g.dart';

@riverpod
Future<CatalogItemDetail?> catalogItemDetail(Ref ref, int itemId) async {
  // itemId here is the catalog_item id.
  // We need companyId to fetch menu - pass it via a combined param approach.
  // For now return null; use catalogItemDetailByCompanyProvider below.
  return null;
}

// Use this provider when you have both companyId and itemId
final catalogItemDetailByCompanyProvider =
    FutureProvider.family<CatalogItemDetail?, ({int companyId, int itemId})>(
  (ref, args) async {
    final menu = await ref.watch(companyMenuProvider(args.companyId).future);
    final item = menu.allItems.cast<MenuItem?>().firstWhere(
      (i) => i?.id == args.itemId,
      orElse: () => null,
    );
    if (item == null) return null;
    return CatalogItemDetail(
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      photoUrl: item.photoUrl,
      discount: item.discount != null
          ? CatalogItemDetailDiscount(
              label: item.discount!.label,
              type: item.discount!.discountType == 'percent'
                  ? DiscountType.percent
                  : DiscountType.fixed,
              value: item.discount!.value.toInt(),
            )
          : null,
      reviews: const [],
    );
  },
);
