import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import type { SearchCategory, SearchSubscriptionItem } from "./data";
import { SearchClient } from "./search-client";
import styles from "./search.module.css";

export const dynamic = "force-dynamic";

type SearchPageProps = {
  searchParams: Promise<{
    q?: string;
    category?: string;
    attach?: string;
  }>;
};

type SearchPaymentMethod = {
  id: string;
  bankId: string;
  cardNumber: string;
  isDefault: boolean;
  bank: {
    name: string;
    iconLink: string;
  };
};

type SearchBank = {
  id: string;
  name: string;
  iconLink: string;
};

export default async function SearchPage({ searchParams }: SearchPageProps) {
  const params = await searchParams;
  const q = (params.q ?? "").trim();
  const category = (params.category ?? "").trim();
  const attach = (params.attach ?? "").trim();
  const hasFilters = q.length > 0 || category.length > 0;

  const searchQuery = new URLSearchParams();
  searchQuery.set("q", q);
  if (category) {
    searchQuery.set("category", category);
  }

  let categories: SearchCategory[] = [];
  let popularTypes: SearchSubscriptionItem[] = [];
  let attachType: SearchSubscriptionItem | null = null;
  let paymentMethods: SearchPaymentMethod[] = [];
  let banks: SearchBank[] = [];
  let matchedTypes: SearchSubscriptionItem[] = [];

  try {
    [categories, popularTypes, paymentMethods, banks] = await Promise.all([
      apiServerGet<SearchCategory[]>("/catalog/categories"),
      apiServerGet<SearchSubscriptionItem[]>("/catalog/popular?limit=8"),
      apiServerGet<SearchPaymentMethod[]>("/payment-methods"),
      apiServerGet<SearchBank[]>("/banks"),
    ]);

    if (attach) {
      attachType = await apiServerGet<SearchSubscriptionItem | null>(`/catalog/${attach}`);
    }

    if (hasFilters) {
      matchedTypes = await apiServerGet<SearchSubscriptionItem[]>(`/catalog/search?${searchQuery.toString()}`);
    }
  } catch (error) {
    if (error instanceof ApiClientError) {
      if (error.status === 401) {
        redirect("/login");
      }
      if (error.code === "BANNED") {
        redirect(`/login?ban=${encodeURIComponent(error.message)}`);
      }
    }
    throw error;
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <SearchClient
          q={q}
          category={category}
          hasFilters={hasFilters}
          categories={categories}
          matchedTypes={matchedTypes}
          popularTypes={popularTypes}
          attachType={attachType}
          paymentMethods={paymentMethods}
          banks={banks}
        />
      </div>

      <AppMenu />
    </main>
  );
}
