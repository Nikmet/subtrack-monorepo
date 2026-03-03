import Link from "next/link";
import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { PaymentMethodsToastTrigger } from "@/app/components/toast/payment-methods-toast-trigger";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { PaymentMethodsClient } from "./payment-methods-client";
import styles from "./payment-methods.module.css";

export const dynamic = "force-dynamic";

type PaymentMethodsPageProps = {
  searchParams: Promise<{
    toast?: string;
    name?: string;
  }>;
};

type Bank = {
  id: string;
  name: string;
  iconLink: string;
};

type PaymentMethod = {
  id: string;
  cardNumber: string;
  bankId: string;
  isDefault: boolean;
  bank: {
    name: string;
    iconLink: string;
  };
  _count: {
    subscriptions: number;
  };
};

export default async function PaymentMethodsPage({ searchParams }: PaymentMethodsPageProps) {
  const params = await searchParams;

  let banks: Bank[] = [];
  let paymentMethods: PaymentMethod[] = [];

  try {
    [banks, paymentMethods] = await Promise.all([
      apiServerGet<Bank[]>("/banks"),
      apiServerGet<PaymentMethod[]>("/payment-methods"),
    ]);
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
        <PaymentMethodsToastTrigger toastType={params.toast} name={params.name} />

        <header className={styles.header}>
          <Link href="/settings" className={styles.backButton} aria-label="Назад в настройки">
            ←
          </Link>
          <h1 className={styles.title}>Способы оплаты</h1>
          <span className={styles.spacer} />
        </header>

        <PaymentMethodsClient banks={banks} paymentMethods={paymentMethods} />
      </div>

      <AppMenu />
    </main>
  );
}
