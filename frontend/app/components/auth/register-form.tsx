"use client";

import Link from "next/link";
import { useRouter } from "@/lib/navigation/client";
import { FormEvent, useState } from "react";

import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";
import styles from "./register-form.module.css";

export function RegisterForm() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isPending, setIsPending] = useState(false);

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);

    const name = typeof formData.get("name") === "string" ? formData.get("name")!.toString().trim() : "";
    const email =
      typeof formData.get("email") === "string"
        ? formData.get("email")!.toString().trim().toLowerCase()
        : "";
    const password = typeof formData.get("password") === "string" ? formData.get("password")!.toString() : "";

    if (!name || !email || !password) {
      setError("Укажите имя, email и пароль.");
      return;
    }

    setError(null);
    setIsPending(true);
    try {
      await apiClientRequest("/auth/register", {
        method: "POST",
        body: JSON.stringify({
          name,
          email,
          password,
          clientType: "web",
        }),
      });
      router.replace("/");
      router.refresh();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось создать аккаунт.");
      }
    } finally {
      setIsPending(false);
    }
  };

  return (
    <form onSubmit={onSubmit} className={styles.form}>
      <label className={styles.label} htmlFor="name">
        Имя
      </label>
      <input className={styles.input} id="name" name="name" type="text" autoComplete="name" required />

      <label className={styles.label} htmlFor="email">
        Email
      </label>
      <input className={styles.input} id="email" name="email" type="email" autoComplete="email" required />

      <label className={styles.label} htmlFor="password">
        Пароль
      </label>
      <input
        className={styles.input}
        id="password"
        name="password"
        type="password"
        autoComplete="new-password"
        minLength={8}
        required
      />

      {error ? (
        <p className={styles.errorText} role="alert">
          {error}
        </p>
      ) : null}

      <button className={styles.submitButton} disabled={isPending} type="submit">
        {isPending ? "Регистрация..." : "Создать аккаунт"}
      </button>

      <p className={styles.linkRow}>
        Уже есть аккаунт?{" "}
        <Link className={styles.link} href="/login">
          Войти
        </Link>
      </p>
    </form>
  );
}
