import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/order_model.dart';
import 'active_order_map.dart';
import 'order_status_helpers.dart';

const double _kSheetInitial = 0.46;
const double _kSheetMax = 0.68;
const double _kSheetMin = 0.28;

class ActiveOrderExpanded extends StatefulWidget {
  final ActiveOrderModel order;
  final Animation<double> animation;
  final VoidCallback onClose;

  const ActiveOrderExpanded({
    super.key,
    required this.order,
    required this.animation,
    required this.onClose,
  });

  @override
  State<ActiveOrderExpanded> createState() => _ActiveOrderExpandedState();
}

class _ActiveOrderExpandedState extends State<ActiveOrderExpanded> {
  final _sheetController = DraggableScrollableController();

  /// Высота панели в пикселях - карта подписана на этот notifier напрямую
  final _sheetHeightNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    _sheetHeightNotifier.dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    if (!_sheetController.isAttached) return;
    final screenH = MediaQuery.sizeOf(context).height;
    _sheetHeightNotifier.value = _sheetController.size * screenH;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ─── Карта на весь экран
            Positioned.fill(
              child: ActiveOrderMap(
                order: widget.order,
                expanded: true,
                sheetHeightNotifier: _sheetHeightNotifier,
                sheetInitialFraction: _kSheetInitial,
              ),
            ),

            // ─── Кнопка закрытия
            Positioned(
              top: topPadding + 8,
              left: 12,
              child: _FadeSlide(
                animation: widget.animation,
                child: _CloseButton(onTap: widget.onClose),
              ),
            ),

            // ─── Статус пилюля
            Positioned(
              top: topPadding + 8,
              left: 0,
              right: 0,
              child: _FadeSlide(
                animation: widget.animation,
                child: Center(child: _StatusPill(order: widget.order)),
              ),
            ),

            // ─── Панель деталей
            _DetailsPanel(
              order: widget.order,
              animation: widget.animation,
              sheetController: _sheetController,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Панель деталей ───────────────────────────────���────────────────────────────

class _DetailsPanel extends StatelessWidget {
  final ActiveOrderModel order;
  final Animation<double> animation;
  final DraggableScrollableController sheetController;

  const _DetailsPanel({
    required this.order,
    required this.animation,
    required this.sheetController,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: _kSheetInitial,
      minChildSize: _kSheetMin,
      maxChildSize: _kSheetMax,
      snap: true,
      snapSizes: const [_kSheetMin, _kSheetInitial, _kSheetMax],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding + 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _FadeSlide(
                animation: animation,
                offsetY: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderRow(order: order),
                    const SizedBox(height: 16),
                    if (order.courier != null) ...[
                      _CourierCard(courier: order.courier!),
                      const SizedBox(height: 12),
                    ],
                    _AddressSection(order: order),
                    const SizedBox(height: 12),
                    _ItemsSection(order: order),
                    const SizedBox(height: 12),
                    _TotalsSection(order: order),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────���───────────────────

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double offsetY;

  const _FadeSlide({
    required this.animation,
    required this.child,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, offsetY / 100),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: cs.onSurface),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ActiveOrderModel order;

  const _StatusPill({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = orderStatusColor(order.status, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderStatusIcon(order.status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            orderStatusLabel(order.status),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final ActiveOrderModel order;

  const _HeaderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.restaurantName,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Заказ №${order.id}',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                order.estimatedTime,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                'осталось',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourierCard extends StatelessWidget {
  final CourierModel courier;

  const _CourierCard({required this.courier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(courier.avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courier.name,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      courier.rating.toStringAsFixed(1),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _ActionBtn(
            icon: Icons.phone_rounded,
            color: colorScheme.primary,
            onTap: () => HapticFeedback.selectionClick(),
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.chat_bubble_outline_rounded,
            color: colorScheme.primary,
            onTap: () => HapticFeedback.selectionClick(),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final ActiveOrderModel order;

  const _AddressSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _AddrRow(
            icon: Icons.storefront_rounded,
            color: colorScheme.tertiary,
            label: 'Ресторан',
            address: order.restaurantAddress,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 2,
                  height: 3,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          _AddrRow(
            icon: Icons.home_rounded,
            color: colorScheme.primary,
            label: 'Доставка',
            address: order.deliveryAddress,
          ),
        ],
      ),
    );
  }
}

class _AddrRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddrRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(address,
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final ActiveOrderModel order;

  const _ItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Состав заказа',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Text('${item.quantity}×',
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.name, style: textTheme.bodySmall)),
                  Text('${item.total.toStringAsFixed(0)} ₽',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  final ActiveOrderModel order;

  const _TotalsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final paymentLabel = switch (order.paymentMethod) {
      PaymentMethod.card => 'Карта',
      PaymentMethod.cash => 'Наличные',
      PaymentMethod.sbp => 'СБП',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Товары', value: '${order.subtotal.toStringAsFixed(0)} ₽'),
          const SizedBox(height: 4),
          _TotalRow(
            label: 'Доставка',
            value: order.deliveryFee == 0 ? 'Бесплатно' : '${order.deliveryFee.toStringAsFixed(0)} ₽',
            valueColor: order.deliveryFee == 0 ? const Color(0xFF16A34A) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: colorScheme.outlineVariant, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Итого',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${order.total.toStringAsFixed(0)} ₽',
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.credit_card_rounded, size: 13, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(paymentLabel,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        Text(value,
            style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
