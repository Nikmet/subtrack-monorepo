"use client";

import Link from "next/link";

import { CategoryStatItem } from "../category-stat-item/category-stat-item";
import { formatMoney } from "@/app/utils/home-formatters";
import type { CardStat, CategoryStat, HomeCurrency } from "@/app/types/home";

import styles from "./analytics-section.module.css";

type AnalyticsSectionProps = {
  categoryStats: CategoryStat[];
  categoryTotal: number;
  cardStats: CardStat[];
  cardTotal: number;
  currency: HomeCurrency;
};

export function AnalyticsSection({
  categoryStats,
  categoryTotal,
  cardStats,
  cardTotal,
  currency,
}: AnalyticsSectionProps) {
  return (
    <aside className={styles.rightColumn}>
      <section className={styles.categorySection}>
        <div className={styles.analyticsHeader}>
          <h2 className={styles.analyticsTitle}>Аналитика</h2>
          <p className={styles.analyticsTotal}>{formatMoney(categoryTotal, currency)} /мес</p>
        </div>

        {categoryStats.length > 0 ? (
          <div className={styles.categoryList}>
            {categoryStats.map((item, index) => (
              <CategoryStatItem key={item.name} item={item} index={index} currency={currency} />
            ))}
          </div>
        ) : (
          <div className={styles.categoryEmpty}>
            <p className={styles.categoryEmptyText}>
              Добавьте подписки, чтобы увидеть структуру расходов по категориям.
            </p>
            <Link href="/search" className={styles.categoryEmptyLink}>
              Добавить подписку
            </Link>
          </div>
        )}
      </section>

      <section className={styles.cardsSection}>
        <div className={styles.cardsHeader}>
          <h3 className={styles.cardsTitle}>По карточкам</h3>
          <p className={styles.cardsTotal}>{formatMoney(cardTotal, currency)} /мес</p>
        </div>

        {cardStats.length > 0 ? (
          <div className={styles.cardsList}>
            {cardStats.map((item) => (
              <article key={item.label} className={styles.cardRow}>
                <div className={styles.cardRowMain}>
                  <p className={styles.cardLabel}>{item.label}</p>
                  <p className={styles.cardMeta}>
                    {item.subscriptionsCount} подписок • {Math.round(item.share)}%
                  </p>
                </div>
                <p className={styles.cardAmount}>{formatMoney(item.amount, currency)}</p>
              </article>
            ))}
          </div>
        ) : (
          <p className={styles.cardsEmptyText}>Нет данных по способам оплаты.</p>
        )}
      </section>
    </aside>
  );
}
