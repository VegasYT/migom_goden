import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import { ORDER_STATUS_LABEL } from '../types';
import type { Order, OrderStatus } from '../types';

function formatDate(iso: string) {
	return new Date(iso).toLocaleString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		year: 'numeric',
		hour: '2-digit',
		minute: '2-digit',
	});
}

export function exportAnalyticsReport(orders: Order[]) {
	const wb = XLSX.utils.book_new();

	// ─── Лист 1: Сводка ──────────────────────────────────────────────────────
	const completed = orders.filter((o) =>
		['delivered', 'received'].includes(o.status)
	);
	const completedRevenue = completed.reduce(
		(s, o) => s + Number(o.total_price),
		0
	);
	const avgCheck =
		completed.length > 0 ? completedRevenue / completed.length : 0;
	const cancelled = orders.filter((o) => o.status === 'cancelled').length;
	const cancelRate =
		orders.length > 0 ? (cancelled / orders.length) * 100 : 0;
	const deliveryCount = orders.filter(
		(o) => o.delivery_type === 'delivery'
	).length;
	const pickupCount = orders.filter(
		(o) => o.delivery_type === 'pickup'
	).length;

	const summaryData = [
		['Аналитический отчёт - Модератор Мигом!'],
		['Дата формирования', formatDate(new Date().toISOString())],
		[
			'Период данных',
			orders.length > 0
				? `${formatDate(orders[orders.length - 1].created_at)} - ${formatDate(orders[0].created_at)}`
				: 'Нет данных',
		],
		[],
		['Метрика', 'Значение'],
		['Всего заказов', orders.length],
		['Выполнено', completed.length],
		['Отменено', cancelled],
		['Процент отмен', `${cancelRate.toFixed(1)}%`],
		[
			'Выручка (выполненные)',
			`${completedRevenue.toLocaleString('ru-RU')} ₽`,
		],
		[
			'Средний чек',
			`${avgCheck.toLocaleString('ru-RU', { maximumFractionDigits: 0 })} ₽`,
		],
		[],
		['Способ получения', 'Кол-во', 'Доля'],
		[
			'Доставка',
			deliveryCount,
			orders.length > 0
				? `${((deliveryCount / orders.length) * 100).toFixed(1)}%`
				: '0%',
		],
		[
			'Самовывоз',
			pickupCount,
			orders.length > 0
				? `${((pickupCount / orders.length) * 100).toFixed(1)}%`
				: '0%',
		],
	];

	const wsSummary = XLSX.utils.aoa_to_sheet(summaryData);
	wsSummary['!cols'] = [{ wch: 28 }, { wch: 30 }, { wch: 12 }];
	XLSX.utils.book_append_sheet(wb, wsSummary, 'Сводка');

	// ─── Лист 2: По статусам ─────────────────────────────────────────────────
	const byStatus = new Map<OrderStatus, number>();
	for (const o of orders) {
		byStatus.set(o.status, (byStatus.get(o.status) ?? 0) + 1);
	}
	const statusData: (string | number)[][] = [['Статус', 'Кол-во', 'Доля']];
	for (const [status, count] of [...byStatus.entries()].sort(
		(a, b) => b[1] - a[1]
	)) {
		statusData.push([
			ORDER_STATUS_LABEL[status],
			count,
			`${((count / orders.length) * 100).toFixed(1)}%`,
		]);
	}
	const wsStatus = XLSX.utils.aoa_to_sheet(statusData);
	wsStatus['!cols'] = [{ wch: 20 }, { wch: 10 }, { wch: 10 }];
	XLSX.utils.book_append_sheet(wb, wsStatus, 'По статусам');

	// ─── Лист 3: Популярные позиции ──────────────────────────────────────────
	const itemMap = new Map<
		string,
		{ name: string; qty: number; revenue: number }
	>();
	for (const o of orders) {
		for (const item of o.items) {
			const existing = itemMap.get(item.name);
			if (existing) {
				existing.qty += item.quantity;
				existing.revenue += Number(item.subtotal);
			} else {
				itemMap.set(item.name, {
					name: item.name,
					qty: item.quantity,
					revenue: Number(item.subtotal),
				});
			}
		}
	}
	const topItems = [...itemMap.values()].sort((a, b) => b.qty - a.qty);
	const itemsSheetData: (string | number)[][] = [
		['Позиция', 'Продано (шт)', 'Выручка (₽)'],
	];
	for (const item of topItems) {
		itemsSheetData.push([item.name, item.qty, Math.round(item.revenue)]);
	}
	const wsItems = XLSX.utils.aoa_to_sheet(itemsSheetData);
	wsItems['!cols'] = [{ wch: 32 }, { wch: 14 }, { wch: 14 }];
	XLSX.utils.book_append_sheet(wb, wsItems, 'Популярные позиции');

	// ─── Лист 4: Все заказы ──────────────────────────────────────────────────
	const ordersSheetData: (string | number)[][] = [
		[
			'№',
			'Дата',
			'Статус',
			'Тип',
			'Сумма (₽)',
			'Компания ID',
			'Точка ID',
			'Курьер ID',
			'Позиции',
			'Комментарий',
		],
	];
	for (const o of orders) {
		const itemsList = o.items
			.map((i) => `${i.name} ×${i.quantity}`)
			.join('; ');
		ordersSheetData.push([
			o.id,
			formatDate(o.created_at),
			ORDER_STATUS_LABEL[o.status],
			o.delivery_type === 'delivery' ? 'Доставка' : 'Самовывоз',
			Number(o.total_price),
			o.company_id,
			o.outlet_id,
			o.courier_id ?? '',
			itemsList,
			o.comment ?? '',
		]);
	}
	const wsOrders = XLSX.utils.aoa_to_sheet(ordersSheetData);
	wsOrders['!cols'] = [
		{ wch: 8 },
		{ wch: 18 },
		{ wch: 16 },
		{ wch: 12 },
		{ wch: 12 },
		{ wch: 12 },
		{ wch: 10 },
		{ wch: 10 },
		{ wch: 50 },
		{ wch: 30 },
	];
	XLSX.utils.book_append_sheet(wb, wsOrders, 'Все заказы');

	// ─── Сохранение ──────────────────────────────────────────────────────────
	const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
	const blob = new Blob([wbout], { type: 'application/octet-stream' });
	const dateStr = new Date().toISOString().slice(0, 10);
	saveAs(blob, `Аналитика_Мигом_${dateStr}.xlsx`);
}
