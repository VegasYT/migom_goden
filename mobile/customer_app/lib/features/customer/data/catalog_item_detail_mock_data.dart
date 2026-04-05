import '../domain/catalog_item_detail_model.dart';

abstract final class CatalogItemDetailMockData {
  // Мок детальных данных для нескольких позиций каталога.
  // Ключ - catalog_item.id из restaurant_mock_data.dart
  static final Map<int, CatalogItemDetail> items = {
    2: CatalogItemDetail(
      id: 2,
      name: 'Пепперони',
      description:
          'Томатный соус, моцарелла и щедрая порция острой пепперони. '
          'Выпекается в дровяной печи при 450°C - хрустящий борт гарантирован.',
      price: 690,
      photoUrl:
          'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=800&q=80',
      discount: const CatalogItemDetailDiscount(
        label: '-15%',
        type: DiscountType.percent,
        value: 15,
      ),
      reviews: [
        CatalogItemReview(
          id: 1,
          customerName: 'Алексей М.',
          rating: 5,
          comment: 'Пепперони просто огонь, острая и хрустящая!',
          createdAt: DateTime(2026, 3, 28),
        ),
        CatalogItemReview(
          id: 2,
          customerName: 'Наташа Р.',
          rating: 5,
          comment: 'Лучшая пицца в городе. Беру каждую неделю.',
          createdAt: DateTime(2026, 3, 22),
        ),
        CatalogItemReview(
          id: 3,
          customerName: 'Иван С.',
          rating: 4,
          comment: 'Очень вкусно, но хотелось бы побольше пепперони.',
          createdAt: DateTime(2026, 3, 15),
        ),
      ],
    ),
    1: CatalogItemDetail(
      id: 1,
      name: 'Маргарита',
      description:
          'Классика итальянской кухни: томатный соус, свежая моцарелла, '
          'листья базилика и оливковое масло первого отжима.',
      price: 590,
      photoUrl:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80',
      reviews: [
        CatalogItemReview(
          id: 4,
          customerName: 'Мария К.',
          rating: 5,
          comment: 'Нежная, ароматная, идеальное тесто.',
          createdAt: DateTime(2026, 3, 25),
        ),
      ],
    ),
  };

  static CatalogItemDetail? forId(int id) => items[id];
}
