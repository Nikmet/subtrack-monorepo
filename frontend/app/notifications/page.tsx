import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { ClearNotificationsButton } from "./clear-notifications-button";
import styles from "./notifications.module.css";

export const dynamic = "force-dynamic";

type NotificationItem = {
  id: string;
  kind: string;
  title: string;
  message: string;
  createdAt: string;
};

const toPlural = (count: number, one: string, twoToFour: string, many: string) => {
  const mod10 = count % 10;
  const mod100 = count % 100;

  if (mod10 === 1 && mod100 !== 11) {
    return one;
  }

  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return twoToFour;
  }

  return many;
};

const formatRelative = (createdAtRaw: string) => {
  const createdAt = new Date(createdAtRaw);
  const now = new Date();
  const diffMs = now.getTime() - createdAt.getTime();

  if (diffMs < 60_000) {
    return "только что";
  }

  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 60) {
    return `${minutes} ${toPlural(minutes, "минута", "минуты", "минут")} назад`;
  }

  const hours = Math.floor(diffMs / 3_600_000);
  if (hours < 24) {
    return `${hours} ${toPlural(hours, "час", "часа", "часов")} назад`;
  }

  const days = Math.floor(diffMs / 86_400_000);
  if (days < 30) {
    return `${days} ${toPlural(days, "день", "дня", "дней")} назад`;
  }

  return new Intl.DateTimeFormat("ru-RU", {
    day: "numeric",
    month: "short",
    year: "numeric",
  })
    .format(createdAt)
    .toUpperCase();
};

const iconByKind = {
  success: (
    <svg viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth="2" />
      <path d="m8.5 12.5 2.2 2.2 4.8-5" fill="none" stroke="currentColor" strokeWidth="2" />
    </svg>
  ),
  info: (
    <svg viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth="2" />
      <path d="M12 7v5l3 2" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  ),
  warning: (
    <svg viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth="2" />
      <path d="M12 7.4v6.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
      <circle cx="12" cy="17" r="1" fill="currentColor" />
    </svg>
  ),
  neutral: (
    <svg viewBox="0 0 24 24" aria-hidden>
      <path
        d="M12 4a5 5 0 0 0-5 5v2.8c0 .5-.2 1-.5 1.4L5 15h14l-1.5-1.8a2 2 0 0 1-.5-1.4V9a5 5 0 0 0-5-5Z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinejoin="round"
      />
      <path d="M10 18a2 2 0 0 0 4 0" stroke="currentColor" strokeWidth="1.8" />
    </svg>
  ),
};

export default async function NotificationsPage() {
  let notifications: NotificationItem[] = [];

  try {
    notifications = await apiServerGet<NotificationItem[]>("/notifications?limit=80");
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
        <header className={styles.header}>
          <h1 className={styles.title}>Уведомления</h1>
          <ClearNotificationsButton disabled={notifications.length === 0} />
        </header>

        {notifications.length > 0 ? (
          <section className={styles.list}>
            {notifications.map((notification) => {
              const kind =
                notification.kind === "success" ||
                notification.kind === "info" ||
                notification.kind === "warning"
                  ? notification.kind
                  : "neutral";

              return (
                <article key={notification.id} className={styles.card}>
                  <div className={`${styles.iconWrap} ${styles[`iconWrap${kind}`]}`}>
                    <span className={`${styles.icon} ${styles[`icon${kind}`]}`}>{iconByKind[kind]}</span>
                  </div>

                  <div className={styles.cardBody}>
                    <div className={styles.cardHead}>
                      <h2 className={styles.cardTitle}>{notification.title}</h2>
                      <time className={styles.cardTime}>{formatRelative(notification.createdAt)}</time>
                    </div>
                    <p className={styles.cardMessage}>{notification.message}</p>
                  </div>
                </article>
              );
            })}
          </section>
        ) : null}

        <section className={styles.bottomState}>
          <div className={styles.bottomIcon} aria-hidden>
            {iconByKind.neutral}
          </div>
          <p className={styles.bottomText}>Все уведомления просмотрены</p>
        </section>
      </div>

      <AppMenu />
    </main>
  );
}
