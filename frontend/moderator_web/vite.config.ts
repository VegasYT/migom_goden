import { defineConfig } from 'vite';
import react, { reactCompilerPreset } from '@vitejs/plugin-react';
import babel from '@rolldown/plugin-babel';

export default defineConfig({
	plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
	resolve: {
		tsconfigPaths: true,
	},
	// клиент Keycloak migom-web разрешает возврат на этот порт; 5173 занят frontend Goden
	server: { port: 5175, strictPort: true },
});
