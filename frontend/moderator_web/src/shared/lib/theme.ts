import { createTheme, type Theme } from '@mui/material/styles';

const typography = {
	fontFamily:
		'-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
};

export const lightTheme: Theme = createTheme({
	palette: {
		mode: 'light',
		primary: {
			main: '#4ADE80',
			dark: '#34D399',
			contrastText: '#ffffff',
		},
		background: {
			default: '#EEF4F5',
			paper: '#FFFFFF',
		},
		text: {
			primary: '#4A5568',
			secondary: '#8896A7',
		},
		divider: '#E2E8F0',
		error: {
			main: '#EF4444',
		},
	},
	typography,
	shape: { borderRadius: 8 },
});

export const darkTheme: Theme = createTheme({
	palette: {
		mode: 'dark',
		primary: {
			main: '#34D399',
			dark: '#4ADE80',
			contrastText: '#ffffff',
		},
		background: {
			default: '#0F1117',
			paper: '#1A1D27',
		},
		text: {
			primary: '#E2E8F0',
			secondary: '#8896A7',
		},
		divider: '#2A2D3A',
		error: {
			main: '#EF4444',
		},
	},
	typography,
	shape: { borderRadius: 8 },
});
