import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/companies_service.dart';
import '../../domain/company_model.dart';

final companiesServiceProvider =
    Provider<CompaniesService>((ref) => CompaniesService());

final companiesProvider = FutureProvider<List<CompanyModel>>((ref) async {
  return ref.watch(companiesServiceProvider).getCompanies();
});

final companyMenuProvider =
    FutureProvider.family<CompanyMenu, int>((ref, companyId) async {
  return ref.watch(companiesServiceProvider).getCompanyMenu(companyId);
});

final outletMenuProvider =
    FutureProvider.family<CompanyMenu, int>((ref, outletId) async {
  return ref.watch(companiesServiceProvider).getOutletMenu(outletId);
});

final companyOutletsProvider =
    FutureProvider.family<List<OutletModel>, int>((ref, companyId) async {
  return ref.watch(companiesServiceProvider).getCompanyOutlets(companyId);
});

/// Имя компании по id - берёт из уже загруженного списка компаний.
final companyNameProvider =
    Provider.family<String, int>((ref, companyId) {
  final companies = ref.watch(companiesProvider).valueOrNull ?? [];
  final match = companies.where((c) => c.id == companyId);
  return match.isNotEmpty ? match.first.name : 'Заведение';
});
