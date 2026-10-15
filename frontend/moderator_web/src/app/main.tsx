import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App.tsx';

import { Provider } from '@shared/ui/provider';
import { startSession } from '@shared/auth/keycloak';

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			retry: 1,
			staleTime: 1000 * 60 * 5, // 5 минут
		},
	},
});

// кабинет открывается только после входа через Keycloak
void startSession().then(() =>
	createRoot(document.getElementById('root')!).render(
		<Provider>
			<QueryClientProvider client={queryClient}>
				<App />
			</QueryClientProvider>
		</Provider>
	),
);
