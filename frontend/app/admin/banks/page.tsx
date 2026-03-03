import Link from "next/link";
import { redirect } from "next/navigation";

import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";
import { requireAdminUser } from "@/lib/auth-guards";

import { BanksClient } from "./banks-client";
import styles from "../admin.module.css";

export const dynamic = "force-dynamic";

type BankItem = {
  id: string;
  name: string;
  iconLink: string;
  _count: {
    paymentMethods: number;
  };
};

export default async function BanksPage() {
  await requireAdminUser();

  let banks: BankItem[] = [];
  try {
    banks = await apiServerGet<BankItem[]>("/admin/banks");
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <header className={styles.header}>
          <Link href="/admin" className={styles.backLink}>
            {"<- Back to admin panel"}
          </Link>
          <h1 className={styles.title}>Banks</h1>
        </header>

        <BanksClient banks={banks} />
      </div>
    </main>
  );
}
