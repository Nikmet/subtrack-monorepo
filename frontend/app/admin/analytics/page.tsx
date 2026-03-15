import Link from "next/link";
import { redirect } from "next/navigation";

import { requireAdminUser } from "@/lib/auth-guards";
import { apiServerGet } from "@/lib/api/server";
import { ApiClientError } from "@/lib/api/types";

import { AnalyticsCharts } from "./analytics-charts";
import type { AnalyticsResponse } from "./types";
import styles from "../admin.module.css";

export const dynamic = "force-dynamic";

type AdminAnalyticsPageProps = {
  searchParams: Promise<{
    year?: string;
  }>;
};

const rubFormatter = new Intl.NumberFormat("ru-RU", {
  maximumFractionDigits: 0,
});

const formatRub = (value: number) => `${rubFormatter.format(Math.round(value))} RUB`;

export default async function AdminAnalyticsPage({ searchParams }: AdminAnalyticsPageProps) {
  await requireAdminUser();

  const params = await searchParams;
  const year = (params.year ?? "").trim();
  const query = new URLSearchParams();
  if (/^\d{4}$/.test(year)) {
    query.set("year", year);
  }

  let analytics: AnalyticsResponse;
  try {
    analytics = await apiServerGet<AnalyticsResponse>(`/admin/analytics?${query.toString()}`);
  } catch (error) {
    if (error instanceof ApiClientError && error.status === 401) {
      redirect("/login");
    }
    throw error;
  }

  const summaryCards = [
    {
      label: "Регистрации",
      value: analytics.summary.registrationsTotal.toString(),
      hint: `Обычные пользователи за ${analytics.selectedYear} год`,
      tone: styles.statCardAqua,
    },
    {
      label: "Подписки пользователей",
      value: analytics.summary.userSubscriptionsCreatedTotal.toString(),
      hint: `Создано пользователями за ${analytics.selectedYear} год`,
      tone: styles.statCardBlue,
    },
    {
      label: "Подписки каталога",
      value: analytics.summary.commonSubscriptionsCreatedTotal.toString(),
      hint: `Создано в каталоге за ${analytics.selectedYear} год`,
      tone: styles.statCardAmber,
    },
    {
      label: "Текущая годовая сумма активных подписок",
      value: formatRub(analytics.summary.activeSubscriptionsAnnualTotalRub),
      hint: "Snapshot по всем активным UserSubscription, annualized",
      tone: styles.statCardIndigo,
    },
  ];

  const peakMonth = analytics.months.reduce((best, current) => {
    const currentTotal =
      current.registrationsCount + current.userSubscriptionsCreatedCount + current.commonSubscriptionsCreatedCount;
    const bestTotal = best.registrationsCount + best.userSubscriptionsCreatedCount + best.commonSubscriptionsCreatedCount;
    return currentTotal > bestTotal ? current : best;
  }, analytics.months[0]);

  const conversionShare =
    analytics.summary.registrationsTotal > 0
      ? Math.round((analytics.summary.userSubscriptionsCreatedTotal / analytics.summary.registrationsTotal) * 100)
      : 0;

  return (
    <main className={styles.page}>
      <div className={styles.container}>
        <header className={styles.header}>
          <Link href="/admin" className={styles.backLink}>
            {"<- Back to admin panel"}
          </Link>
          <h1 className={styles.title}>Аналитика</h1>
        </header>

        <section className={styles.analyticsHero}>
          <div className={styles.analyticsHeroCopy}>
            <p className={styles.analyticsHeroEyebrow}>Admin intelligence</p>
            <h2 className={styles.analyticsHeroTitle}>Рост аудитории, подписок и каталога в одном экране</h2>
            <p className={styles.analyticsHeroText}>
              Графики показывают динамику по месяцам, а карточки фиксируют ключевые итоги года. Годовая сумма активных
              подписок вынесена отдельно, чтобы ее не путать с метриками создания.
            </p>

            <form action="/admin/analytics" method="GET" className={styles.analyticsToolbar}>
              <div className={styles.selectWrap}>
                <label htmlFor="year" className={styles.fieldLabel}>
                  Год
                </label>
                <select id="year" name="year" className={styles.input} defaultValue={analytics.selectedYear.toString()}>
                  {analytics.availableYears.map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))}
                </select>
              </div>
              <button type="submit" className={styles.publishButton}>
                Обновить
              </button>
            </form>
          </div>

          <aside className={styles.analyticsHeroAside}>
            <article className={styles.analyticsSpotlight}>
              <p className={styles.analyticsSpotlightLabel}>Пиковый месяц</p>
              <p className={styles.analyticsSpotlightValue}>{peakMonth.label}</p>
              <p className={styles.analyticsSpotlightText}>
                {peakMonth.registrationsCount + peakMonth.userSubscriptionsCreatedCount + peakMonth.commonSubscriptionsCreatedCount}{" "}
                суммарных событий
              </p>
            </article>

            <article className={styles.analyticsSpotlight}>
              <p className={styles.analyticsSpotlightLabel}>Конверсия в user subscriptions</p>
              <p className={styles.analyticsSpotlightValue}>{conversionShare}%</p>
              <p className={styles.analyticsSpotlightText}>Соотношение созданных подписок пользователей к регистрациям</p>
            </article>
          </aside>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Итоги</h2>
          <div className={styles.summaryGrid}>
            {summaryCards.map((card) => (
              <article key={card.label} className={`${styles.statCard} ${card.tone}`}>
                <p className={styles.statLabel}>{card.label}</p>
                <p className={styles.statValue}>{card.value}</p>
                <p className={styles.statHint}>{card.hint}</p>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.section}>
          <AnalyticsCharts analytics={analytics} />
        </section>

        <section className={styles.section}>
          <div className={styles.analyticsTableShell}>
            <div className={styles.analyticsTableHeader}>
              <div>
                <p className={styles.chartEyebrow}>Схема по месяцам</p>
                <h2 className={styles.sectionTitle}>Детальная раскладка</h2>
              </div>
              <p className={styles.chartMeta}>Таблица оставлена для точных значений и сверки с диаграммами</p>
            </div>

            <div className={styles.analyticsTable}>
              <div className={styles.analyticsTableHead}>
                <p className={styles.analyticsHeadCell}>Месяц</p>
                <p className={styles.analyticsHeadCell}>Регистрации</p>
                <p className={styles.analyticsHeadCell}>Подписки пользователей</p>
                <p className={styles.analyticsHeadCell}>Подписки каталога</p>
              </div>

              {analytics.months.map((item) => (
                <div key={item.month} className={styles.analyticsTableRow}>
                  <p className={styles.analyticsMonthCell}>{item.label}</p>

                  <div className={styles.analyticsMetricCell}>
                    <p className={styles.analyticsMetricValue}>{item.registrationsCount}</p>
                    <p className={styles.analyticsMetricLabel}>Регистрации USER</p>
                  </div>

                  <div className={styles.analyticsMetricCell}>
                    <p className={styles.analyticsMetricValue}>{item.userSubscriptionsCreatedCount}</p>
                    <p className={styles.analyticsMetricLabel}>Созданные UserSubscription</p>
                  </div>

                  <div className={styles.analyticsMetricCell}>
                    <p className={styles.analyticsMetricValue}>{item.commonSubscriptionsCreatedCount}</p>
                    <p className={styles.analyticsMetricLabel}>Созданные CommonSubscription</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
