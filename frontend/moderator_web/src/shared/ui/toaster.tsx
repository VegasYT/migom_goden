import { useState, useEffect } from 'react';
import { Snackbar, Alert, AlertTitle } from '@mui/material';

type ToastSeverity = 'success' | 'error' | 'info' | 'warning';

interface ToastOptions {
	title: string;
	description?: string;
}

interface ToastEvent extends ToastOptions {
	type: ToastSeverity;
	id: number;
}

let _nextId = 0;
const _listeners: Array<(event: ToastEvent) => void> = [];

function emit(type: ToastSeverity, options: ToastOptions) {
	const event: ToastEvent = { ...options, type, id: ++_nextId };
	_listeners.forEach((l) => l(event));
}

export const toaster = {
	success: (options: ToastOptions) => emit('success', options),
	error: (options: ToastOptions) => emit('error', options),
	info: (options: ToastOptions) => emit('info', options),
	warning: (options: ToastOptions) => emit('warning', options),
};

export function Toaster() {
	const [toasts, setToasts] = useState<ToastEvent[]>([]);

	useEffect(() => {
		const handler = (event: ToastEvent) => {
			setToasts((prev) => [...prev, event]);
		};
		_listeners.push(handler);
		return () => {
			const idx = _listeners.indexOf(handler);
			if (idx > -1) _listeners.splice(idx, 1);
		};
	}, []);

	const close = (id: number) => {
		setToasts((prev) => prev.filter((t) => t.id !== id));
	};

	return (
		<>
			{toasts.map((toast, index) => (
				<Snackbar
					key={toast.id}
					open
					autoHideDuration={4000}
					onClose={() => close(toast.id)}
					anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
					sx={{ bottom: `${16 + index * 80}px !important` }}
				>
					<Alert
						onClose={() => close(toast.id)}
						severity={toast.type}
						variant="filled"
						sx={{ minWidth: 280 }}
					>
						{toast.description ? (
							<>
								<AlertTitle sx={{ mb: 0 }}>{toast.title}</AlertTitle>
								{toast.description}
							</>
						) : (
							toast.title
						)}
					</Alert>
				</Snackbar>
			))}
		</>
	);
}
