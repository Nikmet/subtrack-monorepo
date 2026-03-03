"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";
import styles from "./login-form.module.css";

type LoginFormProps = {
    initialError?: string | null;
};

export function LoginForm({ initialError = null }: LoginFormProps) {
    const router = useRouter();
    const [error, setError] = useState<string | null>(initialError);
    const [isPending, setIsPending] = useState(false);

    const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        const formData = new FormData(event.currentTarget);
        const email = typeof formData.get("email") === "string" ? formData.get("email")!.toString() : "";
        const password = typeof formData.get("password") === "string" ? formData.get("password")!.toString() : "";

        if (!email.trim() || !password) {
            setError("Введите email и пароль.");
            return;
        }

        setError(null);
        setIsPending(true);
        try {
            await apiClientRequest("/auth/login", {
                method: "POST",
                body: JSON.stringify({
                    email: email.trim().toLowerCase(),
                    password,
                    clientType: "web"
                })
            });
            router.replace("/");
            router.refresh();
        } catch (requestError) {
            if (requestError instanceof ApiClientError) {
                setError(requestError.message);
            } else {
                setError("Не удалось выполнить вход. Попробуйте снова.");
            }
        } finally {
            setIsPending(false);
        }
    };

    return (
        <form onSubmit={onSubmit} className={styles.form}>
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
                autoComplete="current-password"
                required
            />

            {error ? (
                <p className={styles.errorText} role="alert">
                    {error}
                </p>
            ) : null}

            <button className={styles.submitButton} disabled={isPending} type="submit">
                {isPending ? "Вход..." : "Войти"}
            </button>

            <p className={styles.linkRow}>
                Нет аккаунта?{" "}
                <Link className={styles.link} href="/register">
                    Зарегистрироваться
                </Link>
            </p>
        </form>
    );
}
