import Link from "next/link";
import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { SettingsSecurityToastTrigger } from "@/app/components/toast/settings-security-toast-trigger";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { SecurityForm } from "./security-form";
import styles from "./security.module.css";

export const dynamic = "force-dynamic";

type SettingsSecurityPageProps = {
  searchParams: Promise<{
    toast?: string;
  }>;
};

export default async function SettingsSecurityPage({ searchParams }: SettingsSecurityPageProps) {
  try {
    await apiServerGet<{ user: { id: string } }>("/auth/me");
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  const params = await searchParams;

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <SettingsSecurityToastTrigger toastType={params.toast} />

        <header className={styles.header}>
          <Link href="/settings" className={styles.backButton} aria-label="Назад в настройки">
            ←
          </Link>
          <h1 className={styles.title}>Безопасность</h1>
          <span className={styles.spacer} />
        </header>

        <SecurityForm />
      </div>

      <AppMenu />
    </main>
  );
}
