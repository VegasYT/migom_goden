// features/organization/index.ts - barrel: публичный API фичи

export { organizationApi } from './api/organizationApi';
export { CreateOrganizationForm } from './ui/CreateOrganizationForm';
export { CompanySettingsDialog } from './ui/CompanySettingsDialog';
export { useOrganizationStore } from './model/organizationStore';
export { useCreateOrganization } from './api/useCreateOrganization';
export { useOrganization, organizationKeys } from './api/useOrganization';
export { useMyCompanies, myCompaniesKeys } from './api/useMyCompanies';
export { useUpdateOrganization } from './api/useUpdateOrganization';
export { useDeleteOrganization } from './api/useDeleteOrganization';
export { useOrganizationGuard, useNoOrganizationGuard } from './lib/useOrganizationGuard';
export type { Organization, CreateOrganizationDto, UpdateOrganizationDto } from './types';
