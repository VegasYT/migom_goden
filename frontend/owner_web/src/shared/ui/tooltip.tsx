import * as React from 'react';
import { Tooltip as MuiTooltip, type TooltipProps as MuiTooltipProps } from '@mui/material';

export interface TooltipProps extends Omit<MuiTooltipProps, 'title'> {
	content: React.ReactNode;
	disabled?: boolean;
}

export const Tooltip = React.forwardRef<HTMLDivElement, TooltipProps>(
	function Tooltip({ content, disabled, children, ...rest }, ref) {
		if (disabled) return <>{children}</>;
		return (
			<MuiTooltip ref={ref} title={content} {...rest}>
				{children as React.ReactElement}
			</MuiTooltip>
		);
	},
);
