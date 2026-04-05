import 'package:flutter/material.dart';

import '../../../data/courier_mock_data.dart';

class ShiftHistoryList extends StatelessWidget {
  const ShiftHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final records = CourierMockData.shiftHistory;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'История смен',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...records.map((record) => _ShiftRecordCard(record: record)),
      ],
    );
  }
}

const _ruMonths = [
  '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];

const _ruWeekdays = [
  '', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье',
];

class _ShiftRecordCard extends StatelessWidget {
  final ShiftRecord record;
  const _ShiftRecordCard({required this.record});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}ч ${m}м'; // ignore: unnecessary_brace_in_string_interps
  }

  String _formatDate(DateTime date) {
    final month = _ruMonths[date.month];
    final weekday = _ruWeekdays[date.weekday];
    return '${date.day} $month, $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateLabel = _formatDate(record.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${record.earned.toInt()} ₽',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                icon: Icons.local_shipping_rounded,
                label: '${record.ordersCompleted} заказов',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.access_time_rounded,
                label: _formatDuration(record.activeTime),
                color: const Color(0xFFF97316),
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.route_rounded,
                label: '${record.distanceKm} км',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
