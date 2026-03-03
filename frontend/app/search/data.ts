import type { SubscriptionCategory } from "@/app/constants/subscription-categories";

export type SearchSubscriptionItem = {
  id: string;
  name: string;
  imgLink: string;
  categoryName: string;
  categorySlug: SubscriptionCategory;
  suggestedMonthlyPrice: number | null;
  subscribersCount: number;
  price: number;
  period: number;
};

export type SearchCategory = {
  id: string;
  slug: SubscriptionCategory;
  name: string;
};

export type SearchCatalogPage = {
  items: SearchSubscriptionItem[];
  total: number;
  totalPages: number;
  page: number;
  pageSize: number;
};
