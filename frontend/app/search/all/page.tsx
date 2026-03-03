import Link from "next/link";
import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import type { SearchCatalogPage, SearchCategory, SearchSubscriptionItem } from "../data";
import { SearchAllClient } from "./search-all-client";
import styles from "../search.module.css";

export const dynamic = "force-dynamic";

type SearchAllPageProps = {
  searchParams: Promise<{
    q?: string;
    category?: string;
    page?: string;
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

const parsePage = (value: string) => {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 1) {
    return 1;
  }

  return Math.trunc(parsed);
};

export default async function SearchAllPage({ searchParams }: SearchAllPageProps) {
  const params = await searchParams;
  const q = (params.q ?? "").trim();
  const category = (params.category ?? "").trim();
  const page = parsePage((params.page ?? "").trim());
  const attach = (params.attach ?? "").trim();

  const catalogQuery = new URLSearchParams();
  catalogQuery.set("q", q);
  if (category) {
    catalogQuery.set("category", category);
  }
  catalogQuery.set("page", String(page));
  catalogQuery.set("pageSize", "24");

  let categories: SearchCategory[] = [];
  let catalogPage: SearchCatalogPage = {
    items: [],
    total: 0,
    totalPages: 1,
    page,
    pageSize: 24,
  };
  let attachType: SearchSubscriptionItem | null = null;
  let paymentMethods: SearchPaymentMethod[] = [];
  let banks: SearchBank[] = [];

  try {
    [categories, catalogPage, paymentMethods, banks] = await Promise.all([
      apiServerGet<SearchCategory[]>("/catalog/categories"),
      apiServerGet<SearchCatalogPage>(`/catalog?${catalogQuery.toString()}`),
      apiServerGet<SearchPaymentMethod[]>("/payment-methods"),
      apiServerGet<SearchBank[]>("/banks"),
    ]);

    if (attach) {
      attachType = await apiServerGet<SearchSubscriptionItem | null>(`/catalog/${attach}`);
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
        <div className={styles.sectionHead}>
          <h1 className={styles.title}>Каталог подписок</h1>
          <Link href="/search" className={styles.sectionLink}>
            Назад
          </Link>
        </div>

        <SearchAllClient
          q={q}
          category={category}
          categories={categories}
          catalogPage={catalogPage}
          attachType={attachType}
          paymentMethods={paymentMethods}
          banks={banks}
        />
      </div>

      <AppMenu />
    </main>
  );
}
