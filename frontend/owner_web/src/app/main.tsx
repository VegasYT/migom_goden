import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App.tsx';

import { Provider } from '@shared/ui/provider';
import { _injectAuthStore } from '@shared/api/httpClient';
import { useAuthStore } from '@features/auth';

// Инжектируем store-геттер в httpClient (избегаем circular dependency)
_injectAuthStore(() => ({
	accessToken: useAuthStore.getState().accessToken,
	refreshToken: useAuthStore.getState().refreshToken,
	setTokens: useAuthStore.getState().setTokens,
	logout: useAuthStore.getState().logout,
}));

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			retry: 1,
			staleTime: 1000 * 60 * 5, // 5 минут
		},
	},
});

createRoot(document.getElementById('root')!).render(
	<Provider>
		<QueryClientProvider client={queryClient}>
			<App />
		</QueryClientProvider>
	</Provider>
);
