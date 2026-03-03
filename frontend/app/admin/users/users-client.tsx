"use client";

import { useState } from "react";

import { UserAvatar } from "@/app/components/user-avatar/user-avatar";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "../admin.module.css";

type UserItem = {
  id: string;
  name: string;
  avatarLink: string | null;
  email: string;
  role: "USER" | "ADMIN";
  isBanned: boolean;
  banReason: string | null;
  subscriptionsCount: number;
};

const getInitials = (name: string) =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

type UsersClientProps = {
  users: UserItem[];
};

export function UsersClient({ users }: UsersClientProps) {
  const [error, setError] = useState<string | null>(null);
  const [pendingId, setPendingId] = useState<string | null>(null);

  const refreshPage = () => window.location.reload();

  const banUser = async (userId: string) => {
    const reason = window.prompt("Введите причину:", "");
    if (!reason?.trim()) {
      return;
    }

    setError(null);
    setPendingId(userId);
    try {
      await apiClientRequest(`/admin/users/${userId}/ban`, {
        method: "POST",
        body: JSON.stringify({ reason: reason.trim() }),
      });
      refreshPage();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось заблокировать пользователя.");
      }
    } finally {
      setPendingId(null);
    }
  };

  const unbanUser = async (userId: string) => {
    setError(null);
    setPendingId(userId);
    try {
      await apiClientRequest(`/admin/users/${userId}/unban`, {
        method: "POST",
        body: JSON.stringify({}),
      });
      refreshPage();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось разблокировать пользователя.");
      }
    } finally {
      setPendingId(null);
    }
  };

  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>Пользователи</h2>
      {error ? <p className={styles.emptyText}>{error}</p> : null}
      {users.length === 0 ? (
        <p className={styles.emptyText}>Пользователи не найдены.</p>
      ) : (
        <div className={styles.grid}>
          {users.map((item) => (
            <article key={item.id} className={styles.card}>
              <div className={styles.cardTopRow}>
                <UserAvatar
                  src={item.avatarLink}
                  name={item.name}
                  wrapperClassName={styles.userIconWrap}
                  imageClassName={styles.userIconImage}
                  fallbackClassName={styles.userIcon}
                  fallbackText={getInitials(item.name)}
                />
                <p className={styles.cardTitle}>
                  {item.name} {item.role === "ADMIN" ? "• ADMIN" : ""}
                </p>
              </div>
              <p className={styles.cardMeta}>{item.email}</p>
              <p className={styles.cardSubMeta}>Подписок: {item.subscriptionsCount}</p>
              {item.isBanned ? <p className={styles.bannedBadge}>Блокировка: {item.banReason || "-"}</p> : null}

              {item.role === "USER" ? (
                item.isBanned ? (
                  <button
                    type="button"
                    className={styles.publishButton}
                    onClick={() => unbanUser(item.id)}
                    disabled={pendingId === item.id}
                  >
                    {pendingId === item.id ? "Разблокировка..." : "Разблокировать"}
                  </button>
                ) : (
                  <button
                    type="button"
                    className={styles.deleteButton}
                    onClick={() => banUser(item.id)}
                    disabled={pendingId === item.id}
                  >
                    {pendingId === item.id ? "Блокировка..." : "Заблокировать"}
                  </button>
                )
              ) : (
                <p className={styles.cardSubMeta}>Администраторы не блокируются.</p>
              )}
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
