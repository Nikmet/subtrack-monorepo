import { redirect } from "next/navigation";

import { RegisterForm } from "@/app/components/auth/register-form";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import styles from "./register.module.css";

export default async function RegisterPage() {
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

  return (
    <main className={styles.page}>
      <section className={styles.card}>
        <p className={styles.overline}>SubTrack</p>
        <h1 className={styles.title}>Регистрация</h1>
        <p className={styles.subtitle}>Создайте аккаунт, чтобы начать вести подписки.</p>

        <RegisterForm />
      </section>
    </main>
  );
}
