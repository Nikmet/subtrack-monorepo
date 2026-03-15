import Link from "next/link";
import { redirect } from "next/navigation";

import { AppMenu } from "@/app/components/app-menu/app-menu";
import { NewSubscriptionForm } from "@/app/components/subscriptions/new-subscription-form";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import styles from "./new-subscription.module.css";

export const dynamic = "force-dynamic";

export default async function NewSubscriptionPage() {
  try {
    await apiServerGet<{ user: { id: string } }>("/auth/me");
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <section className={styles.hero}>
          <div className={styles.heroMain}>
            <Link href="/search" className={styles.backButton}>
              <span className={styles.backArrow} aria-hidden="true">
                ←
              </span>
              К поиску
            </Link>

            <div className={styles.heroCopy}>
              <p className={styles.eyebrow}>Новая общая подписка</p>
              <h1 className={styles.title}>Добавьте сервис, которого пока нет в каталоге</h1>
              <p className={styles.description}>
                Заполните карточку сервиса, укажите стоимость и, если есть, ссылку на кабинет управления.
                После проверки подписка появится в общем каталоге и ее можно будет быстро подключать.
              </p>
            </div>

            <div className={styles.heroMetrics}>
              <article className={styles.metricCard}>
                <span className={styles.metricLabel}>Что понадобится</span>
                <strong className={styles.metricValue}>Название, цена и иконка</strong>
              </article>
              <article className={styles.metricCard}>
                <span className={styles.metricLabel}>Модерация</span>
                <strong className={styles.metricValue}>Обычно занимает несколько минут</strong>
              </article>
            </div>
          </div>

          <aside className={styles.heroAside}>
            <div className={styles.asideBadge}>Совет</div>
            <p className={styles.asideTitle}>Лучше всего работают реальные данные сервиса</p>
            <p className={styles.asideText}>
              Добавьте точное название, официальный логотип и ссылку на страницу управления. Так карточка
              быстрее пройдет модерацию и будет полезнее для всех пользователей.
            </p>
          </aside>
        </section>

        <section className={styles.contentGrid}>
          <div className={styles.formShell}>
            <div className={styles.formHeader}>
              <div>
                <p className={styles.formEyebrow}>Форма отправки</p>
                <h2 className={styles.formTitle}>Заполните данные подписки</h2>
              </div>
              <p className={styles.formText}>
                Все поля можно заполнить за минуту. Ссылку на управление добавляйте по желанию.
              </p>
            </div>

            <NewSubscriptionForm />
          </div>

          <aside className={styles.sidePanel}>
            <article className={styles.sideCard}>
              <span className={styles.sideCardIndex}>01</span>
              <h2 className={styles.sideCardTitle}>Подготовьте иконку</h2>
              <p className={styles.sideCardText}>
                Лучше загружать квадратный логотип без лишнего фона. Так карточка будет аккуратнее смотреться
                в поиске и на главной.
              </p>
            </article>

            <article className={styles.sideCard}>
              <span className={styles.sideCardIndex}>02</span>
              <h2 className={styles.sideCardTitle}>Укажите реальную цену</h2>
              <p className={styles.sideCardText}>
                Стоимость и период должны совпадать с тем, как сервис действительно списывает деньги.
              </p>
            </article>

            <article className={styles.sideCardAccent}>
              <p className={styles.sideCardLead}>Что будет дальше</p>
              <ul className={styles.timeline}>
                <li className={styles.timelineItem}>Заявка уходит на модерацию</li>
                <li className={styles.timelineItem}>После публикации подписка появится в каталоге</li>
                <li className={styles.timelineItem}>Ее можно будет привязать к своим платежам</li>
              </ul>
            </article>
          </aside>
        </section>
      </div>

      <AppMenu />
    </main>
  );
}
