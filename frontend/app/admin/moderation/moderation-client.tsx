"use client";

import { useState } from "react";

import { SubscriptionIcon } from "@/app/components/subscription-icon/subscription-icon";
import { getSubscriptionCategoryLabel } from "@/app/constants/subscription-categories";
import { formatPeriodLabel } from "@/app/utils/subscription-formatters";
import { apiClientRequest } from "@/lib/api/client";
import { ApiClientError } from "@/lib/api/types";

import styles from "../admin.module.css";

type ModerationItem = {
  id: string;
  name: string;
  imgLink: string;
  category: string;
  categoryName?: string;
  price: number;
  period: number;
  createdByUser: {
    name: string;
    email: string;
  } | null;
};

type ModerationClientProps = {
  items: ModerationItem[];
};

const formatRub = (value: number) =>
  `${new Intl.NumberFormat("ru-RU", { maximumFractionDigits: 0 }).format(Math.round(value))} ₽`;

export function ModerationClient({ items }: ModerationClientProps) {
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [publishComments, setPublishComments] = useState<Record<string, string>>({});
  const [rejectReasons, setRejectReasons] = useState<Record<string, string>>({});

  const refreshPage = () => window.location.reload();

  const publishItem = async (itemId: string) => {
    setError(null);
    setPendingId(itemId);
    try {
      await apiClientRequest(`/admin/moderation/subscriptions/${itemId}/publish`, {
        method: "POST",
        body: JSON.stringify({ moderationComment: publishComments[itemId]?.trim() || null }),
      });
      refreshPage();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось опубликовать подписку.");
      }
    } finally {
      setPendingId(null);
    }
  };

  const rejectItem = async (itemId: string) => {
    const reason = rejectReasons[itemId]?.trim();
    if (!reason) {
      setError("Укажите причину отклонения.");
      return;
    }

    setError(null);
    setPendingId(itemId);
    try {
      await apiClientRequest(`/admin/moderation/subscriptions/${itemId}/reject`, {
        method: "POST",
        body: JSON.stringify({ reason }),
      });
      refreshPage();
    } catch (requestError) {
      if (requestError instanceof ApiClientError) {
        setError(requestError.message);
      } else {
        setError("Не удалось отклонить подписку.");
      }
    } finally {
      setPendingId(null);
    }
  };

  return (
    <section className={styles.section}>
      <h2 className={styles.sectionTitle}>Модерация</h2>
      {error ? <p className={styles.emptyText}>{error}</p> : null}
      {items.length === 0 ? (
        <p className={styles.emptyText}>Нет заявок в очереди.</p>
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

              <p className={styles.cardSubMeta}>
                Автор: {item.createdByUser?.name ?? "Неизвестно"} ({item.createdByUser?.email ?? "-"})
              </p>

              <div className={styles.inlineForm}>
                <input
                  value={publishComments[item.id] ?? ""}
                  onChange={(event) =>
                    setPublishComments((prev) => ({
                      ...prev,
                      [item.id]: event.target.value,
                    }))
                  }
                  className={styles.input}
                  type="text"
                  placeholder="Комментарий к публикации (необязательно)"
                />
                <button
                  type="button"
                  className={styles.publishButton}
                  onClick={() => publishItem(item.id)}
                  disabled={pendingId === item.id}
                >
                  {pendingId === item.id ? "Публикация..." : "Опубликовать"}
                </button>
              </div>

              <div className={styles.inlineForm}>
                <input
                  value={rejectReasons[item.id] ?? ""}
                  onChange={(event) =>
                    setRejectReasons((prev) => ({
                      ...prev,
                      [item.id]: event.target.value,
                    }))
                  }
                  className={styles.input}
                  type="text"
                  placeholder="Причина отклонения"
                  required
                />
                <button
                  type="button"
                  className={styles.deleteButton}
                  onClick={() => rejectItem(item.id)}
                  disabled={pendingId === item.id}
                >
                  {pendingId === item.id ? "Отклонение..." : "Отклонить"}
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
