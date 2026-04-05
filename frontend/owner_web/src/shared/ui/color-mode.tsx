import * as React from 'react';
import { ThemeProvider, CssBaseline, IconButton } from '@mui/material';
import DarkModeOutlinedIcon from '@mui/icons-material/DarkModeOutlined';
import LightModeOutlinedIcon from '@mui/icons-material/LightModeOutlined';
import { lightTheme, darkTheme } from '@shared/lib/theme';

export type ColorMode = 'light' | 'dark';

export interface ColorModeProviderProps {
	children: React.ReactNode;
}

interface ColorModeContextValue {
	colorMode: ColorMode;
	setColorMode: (mode: ColorMode) => void;
	toggleColorMode: () => void;
}

const ColorModeContext = React.createContext<ColorModeContextValue>({
	colorMode: 'light',
	setColorMode: () => {},
	toggleColorMode: () => {},
});

export function ColorModeProvider({ children }: ColorModeProviderProps) {
	const [colorMode, setColorModeState] = React.useState<ColorMode>(() => {
		try {
			const stored = localStorage.getItem('color-mode');
			return stored === 'dark' ? 'dark' : 'light';
		} catch {
			return 'light';
		}
	});

	const setColorMode = React.useCallback((mode: ColorMode) => {
		setColorModeState(mode);
		try {
			localStorage.setItem('color-mode', mode);
		} catch {}
	}, []);

	const toggleColorMode = React.useCallback(() => {
		setColorMode(colorMode === 'light' ? 'dark' : 'light');
	}, [colorMode, setColorMode]);

	return (
		<ColorModeContext.Provider value={{ colorMode, setColorMode, toggleColorMode }}>
			<ThemeProvider theme={colorMode === 'dark' ? darkTheme : lightTheme}>
				<CssBaseline />
				{children}
			</ThemeProvider>
		</ColorModeContext.Provider>
	);
}

export function useColorMode(): ColorModeContextValue {
	return React.useContext(ColorModeContext);
}

export function useColorModeValue<T>(light: T, dark: T): T {
	const { colorMode } = useColorMode();
	return colorMode === 'dark' ? dark : light;
}

export const ColorModeButton = React.forwardRef<HTMLButtonElement, React.ComponentProps<typeof IconButton>>(
	function ColorModeButton(props, ref) {
		const { toggleColorMode, colorMode } = useColorMode();
		return (
			<IconButton
				onClick={toggleColorMode}
				aria-label="Toggle color mode"
				size="small"
				ref={ref}
				{...props}
			>
				{colorMode === 'dark' ? (
					<LightModeOutlinedIcon fontSize="small" />
				) : (
					<DarkModeOutlinedIcon fontSize="small" />
				)}
			</IconButton>
		);
	},
);
