import { redirect } from "next/navigation";

import { LoginForm } from "@/app/components/auth/login-form";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import styles from "./login.module.css";

type LoginPageProps = {
  searchParams: Promise<{
    ban?: string;
  }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  try {
    const me = await apiServerGet<{ user: { isBanned: boolean } | null }>("/auth/me");
    if (me?.user && !me.user.isBanned) {
      redirect("/");
    }
  } catch (error) {
    if (!(error instanceof ApiClientError) || error.status !== 401) {
      throw error;
    }
  }

  const params = await searchParams;
  const banReason = (params.ban ?? "").trim();

  return (
    <main className={styles.page}>
      <section className={styles.card}>
        <p className={styles.overline}>SubTrack</p>
        <h1 className={styles.title}>Вход в аккаунт</h1>
        <p className={styles.subtitle}>Используйте email и пароль для входа в личный кабинет.</p>

        <LoginForm initialError={banReason || null} />
      </section>
    </main>
  );
}
