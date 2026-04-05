import '../domain/notification_model.dart';

abstract final class NotificationsMockData {
  static const notifications = [
    NotificationModel(
      id: 'n1',
      type: NotificationType.order,
      title: 'Заказ доставлен',
      body: 'Ваш заказ из Суши Мастер успешно доставлен. Приятного аппетита!',
      time: '5 мин назад',
      isRead: false,
    ),
    NotificationModel(
      id: 'n2',
      type: NotificationType.order,
      title: 'Курьер в пути',
      body: 'Ваш заказ из Burger House забрали и везут к вам.',
      time: '18 мин назад',
      isRead: false,
    ),
    NotificationModel(
      id: 'n3',
      type: NotificationType.promo,
      title: 'Скидка 20% на пиццу',
      body: 'Только сегодня - скидка 20% на все пиццы в Пицца 33. Успейте заказать!',
      time: '2 ч назад',
      isRead: false,
    ),
    NotificationModel(
      id: 'n4',
      type: NotificationType.promo,
      title: 'Бонусы начислены',
      body: 'За последний заказ вам начислено 95 бонусных баллов.',
      time: '1 д назад',
      isRead: true,
    ),
    NotificationModel(
      id: 'n5',
      type: NotificationType.order,
      title: 'Заказ отменён',
      body: 'Ваш заказ №8799 из Пицца 33 был отменён. Деньги вернутся в течение 3 дней.',
      time: '10 д назад',
      isRead: true,
    ),
    NotificationModel(
      id: 'n6',
      type: NotificationType.system,
      title: 'Новый адрес доставки',
      body: 'Мы расширили зону доставки. Теперь доступны заказы в Северном районе.',
      time: '12 д назад',
      isRead: true,
    ),
    NotificationModel(
      id: 'n7',
      type: NotificationType.promo,
      title: 'Приведи друга',
      body: 'Поделитесь промокодом с другом и получите 200 бонусов после его первого заказа.',
      time: '15 д назад',
      isRead: true,
    ),
  ];
}
