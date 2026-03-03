"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "./security.module.css";

export function SecurityForm() {
  const router = useRouter();
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isPending, setIsPending] = useState(false);

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsPending(true);

    try {
      await apiClientRequest("/settings/security/password", {
        method: "PATCH",
        body: JSON.stringify({
          currentPassword,
          newPassword,
          confirmPassword,
        }),
      });
      router.push("/settings/security?toast=changed");
      router.refresh();
    } catch (error) {
      if (error instanceof ApiClientError) {
        const message = error.message.toLowerCase();
        if (message.includes("текущ")) {
          router.push("/settings/security?toast=current_wrong");
        } else if (message.includes("совпад")) {
          router.push("/settings/security?toast=mismatch");
        } else if (newPassword.length < 8) {
          router.push("/settings/security?toast=weak");
        } else {
          router.push("/settings/security?toast=invalid");
        }
      } else {
        router.push("/settings/security?toast=invalid");
      }
    } finally {
      setIsPending(false);
    }
  };

  return (
    <form onSubmit={onSubmit} className={styles.form}>
      <label className={styles.label} htmlFor="currentPassword">
        Текущий пароль
      </label>
      <input
        id="currentPassword"
        className={styles.input}
        name="currentPassword"
        type="password"
        value={currentPassword}
        onChange={(event) => setCurrentPassword(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="newPassword">
        Новый пароль
      </label>
      <input
        id="newPassword"
        className={styles.input}
        name="newPassword"
        type="password"
        minLength={8}
        value={newPassword}
        onChange={(event) => setNewPassword(event.target.value)}
        required
      />

      <label className={styles.label} htmlFor="confirmPassword">
        Подтвердите новый пароль
      </label>
      <input
        id="confirmPassword"
        className={styles.input}
        name="confirmPassword"
        type="password"
        minLength={8}
        value={confirmPassword}
        onChange={(event) => setConfirmPassword(event.target.value)}
        required
      />

      <button className={styles.submitButton} type="submit" disabled={isPending}>
        {isPending ? "Сохранение..." : "Изменить пароль"}
      </button>
    </form>
  );
}
