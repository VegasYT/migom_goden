import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface OrganizationStore {
	companyId: number | null;
	setCompanyId: (id: number) => void;
	clearCompany: () => void;
}

export const useOrganizationStore = create<OrganizationStore>()(
	persist(
		(set) => ({
			companyId: null,
			setCompanyId: (id) => set({ companyId: id }),
			clearCompany: () => set({ companyId: null }),
		}),
		{
			name: 'migom-organization',
		},
	),
);
