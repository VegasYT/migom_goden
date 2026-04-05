import '../domain/address_model.dart';

abstract final class AddressMockData {
  static const addresses = [
    AddressModel(
      id: '1',
      label: 'Дом',
      street: 'ул. Пушкина, 12',
      apartment: '47',
      comment: 'Домофон 47, 3 этаж',
      isDefault: true,
    ),
    AddressModel(
      id: '2',
      label: 'Работа',
      street: 'пр. Ленина, 88',
      apartment: null,
      comment: 'Бизнес-центр Альфа, 5 этаж',
      isDefault: false,
    ),
    AddressModel(
      id: '3',
      label: 'Другое',
      street: 'ул. Гагарина, 34',
      apartment: '12',
      isDefault: false,
    ),
  ];
}
