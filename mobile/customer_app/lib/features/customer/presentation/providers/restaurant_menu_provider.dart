import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/company_model.dart';
import 'companies_provider.dart';
import 'nearest_outlet_provider.dart';

/// Меню ресторана для покупателя: блюда - из меню заведения, куда уйдёт заказ (с учётом склада Goden),
/// название и логотип - из компании. Горячие предложения Goden идут первой вкладкой "Рекомендуем".
final restaurantMenuProvider =
    FutureProvider.family<CompanyMenu, int>((ref, companyId) async {
  final company = await ref.watch(companyMenuProvider(companyId).future);
  // названия, описания и обложки в меню нет: они приходят в списке компаний
  final companies = await ref.watch(companiesProvider.future);
  final info = companies.where((c) => c.id == companyId).firstOrNull;
  final outletId = await ref.watch(nearestOutletProvider(companyId).future);
  final outlet = outletId == null ? company : await ref.watch(outletMenuProvider(outletId).future);
  final byId = {for (final item in outlet.allItems) item.id: item};
  final hot = [
    for (final id in outlet.hotItemIds)
      if (byId[id] != null) byId[id]!,
  ];
  return CompanyMenu(
    companyId: company.companyId,
    companyName: info?.name ?? company.companyName,
    logoUrl: info?.logoUrl ?? company.logoUrl,
    description: info?.description ?? company.description,
    rating: company.rating,
    reviewCount: company.reviewCount,
    categories: [
      if (hot.isNotEmpty)
        MenuCategory(id: 0, name: 'Рекомендуем', sortOrder: -1, items: hot),
      ...outlet.categories,
    ],
    hotItemIds: outlet.hotItemIds,
  );
});
