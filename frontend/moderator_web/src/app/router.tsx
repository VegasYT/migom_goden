import { createBrowserRouter } from 'react-router';
import AuthPage from '@pages/AuthPage';
import DashboardPage from '@pages/DashboardPage';
import CompaniesPage from '@pages/CompaniesPage';
import CompanyDetailPage from '@pages/CompanyDetailPage';
import CategoriesPage from '@pages/CategoriesPage';
import OrdersPage from '@pages/OrdersPage';
import CouriersPage from '@pages/CouriersPage';
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
		path: '/companies',
		element: <CompaniesPage />,
	},
	{
		path: '/companies/:companyId',
		element: <CompanyDetailPage />,
	},
	{
		path: '/categories',
		element: <CategoriesPage />,
	},
	{
		path: '/orders',
		element: <OrdersPage />,
	},
	{
		path: '/couriers',
		element: <CouriersPage />,
	},
	{
		path: '/analytics',
		element: <AnalyticsPage />,
	},
]);
