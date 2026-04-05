export const categoriesKeys = {
	all: ['categories'] as const,
	list: (search?: string) => [...categoriesKeys.all, 'list', search] as const,
};
