"use client";

import Link from "next/link";
import { useState } from "react";

import { SubscriptionIcon } from "@/app/components/subscription-icon/subscription-icon";
import { getSubscriptionCategoryLabel } from "@/app/constants/subscription-categories";
import { formatPeriodLabel } from "@/app/utils/subscription-formatters";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "../admin.module.css";

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

type PublishedClientProps = {
  items: PublishedItem[];
};

const formatRub = (value: number) =>
  `${new Intl.NumberFormat("ru-RU", { maximumFractionDigits: 0 }).format(Math.round(value))} ₽`;

export function PublishedClient({ items }: PublishedClientProps) {
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reasons, setReasons] = useState<Record<string, string>>({});

  const refreshPage = () => window.location.reload();

  const deleteItem = async (id: string) => {
    const reason = reasons[id]?.trim();
    if (!reason) {
      setError("Укажите причину удаления.");
      return;
    }

    setError(null);
    setPendingId(id);
    try {
      await apiClientRequest(`/admin/subscriptions/${id}`, {
        method: "DELETE",
        body: JSON.stringify({ reason }),
      });
      refreshPage();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось удалить подписку.");
      }
    } finally {
      setPendingId(null);
    }
  };

  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>Опубликованные</h2>
      {error ? <p className={styles.emptyText}>{error}</p> : null}
      {items.length === 0 ? (
        <p className={styles.emptyText}>Пока нет опубликованных подписок.</p>
      ) : (
        <div className={styles.grid}>
          {items.map((item) => (
            <article key={item.id} className={styles.card}>
              <div className={styles.cardTopRow}>
                <SubscriptionIcon
                  src={item.imgLink}
                  name={item.name}
                  wrapperClassName={styles.cardIconWrap}
                  imageClassName={styles.cardIconImage}
                  fallbackClassName={styles.cardIconFallback}
                />
                <p className={styles.cardTitle}>{item.name}</p>
              </div>

              <p className={styles.cardMeta}>
                {(item.categoryName ?? getSubscriptionCategoryLabel(item.category))} • {formatRub(item.price)} •{" "}
                {formatPeriodLabel(item.period)}
              </p>
              <p className={styles.cardSubMeta}>Подписчиков: {item.subscribersCount}</p>

              <div className={styles.actionsRow}>
                <Link href={`/admin/subscriptions/${item.id}`} className={styles.editLink}>
                  Редактировать
                </Link>
              </div>

              <div className={styles.inlineForm}>
                <input
                  className={styles.input}
                  type="text"
                  placeholder="Причина удаления"
                  value={reasons[item.id] ?? ""}
                  onChange={(event) =>
                    setReasons((prev) => ({
                      ...prev,
                      [item.id]: event.target.value,
                    }))
                  }
                  required
                />
                <button
                  type="button"
                  className={styles.deleteButton}
                  onClick={() => deleteItem(item.id)}
                  disabled={pendingId === item.id}
                >
                  {pendingId === item.id ? "Удаление..." : "Удалить"}
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
