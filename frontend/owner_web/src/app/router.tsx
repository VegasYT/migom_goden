import { createBrowserRouter } from 'react-router';
import AuthPage from '@pages/AuthPage';
import DashboardPage from '@pages/DashboardPage';
import CreateOrganizationPage from '@pages/CreateOrganizationPage';
import MenuPage from '@pages/MenuPage';
import OutletsPage from '@pages/OutletsPage';
import OrdersPage from '@pages/OrdersPage';
import OutletManagerPage from '@pages/OutletManagerPage';
import AnalyticsPage from '@pages/AnalyticsPage';

export const router = createBrowserRouter([
	{
		path: '/',
		element: <DashboardPage />,
	},
	{
		path: '/auth',
		element: <AuthPage />,
	},
	{
		path: '/organization/new',
		element: <CreateOrganizationPage />,
	},
	{
		path: '/menu',
		element: <MenuPage />,
	},
	{
		path: '/outlets',
		element: <OutletsPage />,
	},
	{
		path: '/orders',
		element: <OrdersPage />,
	},
	{
		path: '/analytics',
		element: <AnalyticsPage />,
	},
	{
		path: '/outlet-manager',
		element: <OutletManagerPage />,
	},
]);
