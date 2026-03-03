import Link from "next/link";
import { redirect } from "next/navigation";

import { AdminToastTrigger } from "@/app/components/toast/admin-toast-trigger";
import { SUBSCRIPTION_CATEGORIES } from "@/app/constants/subscription-categories";
import { requireAdminUser } from "@/lib/auth-guards";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { PublishedClient } from "./published-client";
import styles from "../admin.module.css";

export const dynamic = "force-dynamic";

type PublishedPageProps = {
  searchParams: Promise<{
    q?: string;
    category?: string;
    period?: string;
    toast?: string;
    name?: string;
  }>;
};

type PublishedItem = {
  id: string;
  name: string;
  imgLink: string;
  category: string;
  categoryName?: string;
  price: number;
  period: number;
  subscribersCount: number;
};

const allowedPeriods = new Set([1, 3, 6, 12]);

export default async function PublishedPage({ searchParams }: PublishedPageProps) {
  await requireAdminUser();

  const params = await searchParams;
  const q = (params.q ?? "").trim();
  const category = (params.category ?? "").trim();
  const periodRaw = (params.period ?? "").trim();
  const period = Number(periodRaw);
  const hasPeriod = allowedPeriods.has(period);

  const query = new URLSearchParams();
  if (q) query.set("q", q);
  if (category) query.set("category", category);
  if (hasPeriod) query.set("period", String(period));

  let items: PublishedItem[] = [];
  try {
    items = await apiServerGet<PublishedItem[]>(`/admin/published/subscriptions?${query.toString()}`);
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <AdminToastTrigger toastType={params.toast} name={params.name} redirectPath="/admin/published" />

        <header className={styles.header}>
          <Link href="/admin" className={styles.backLink}>
            {"<- Back to admin panel"}
          </Link>
          <h1 className={styles.title}>Published subscriptions</h1>
        </header>

        <form action="/admin/published" method="GET" className={styles.filtersPanel}>
          <input className={styles.input} type="text" name="q" defaultValue={q} placeholder="Search by subscription name" />

          <div className={styles.filtersRow}>
            <select className={styles.input} name="category" defaultValue={category}>
              <option value="">All categories</option>
              {SUBSCRIPTION_CATEGORIES.map((item) => (
                <option key={item.value} value={item.value}>
                  {item.label}
                </option>
              ))}
            </select>

            <select className={styles.input} name="period" defaultValue={hasPeriod ? String(period) : ""}>
              <option value="">Any period</option>
              <option value="1">Monthly</option>
              <option value="3">Every 3 months</option>
              <option value="6">Every 6 months</option>
              <option value="12">Yearly</option>
            </select>
          </div>

          <div className={styles.filterActions}>
            <button type="submit" className={styles.publishButton}>
              Apply
            </button>
            <Link href="/admin/published" className={styles.editLink}>
              Reset
            </Link>
          </div>
        </form>

        <PublishedClient items={items} />
      </div>
    </main>
  );
}
