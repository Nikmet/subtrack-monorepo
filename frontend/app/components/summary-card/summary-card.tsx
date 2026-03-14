"use client";

import {
  ArrowRightLeft,
  DollarSign,
  Euro,
  RussianRuble,
  type LucideIcon,
} from "lucide-react";

import { formatMoney, formatSubscriptionCount } from "@/app/utils/home-formatters";
import type { HomeCurrency } from "@/app/types/home";

import styles from "./summary-card.module.css";

type SummaryCardProps = {
  monthlyTotal: number;
  subscriptionsCount: number;
  currency: HomeCurrency;
  isLoading?: boolean;
  onCurrencyCycle: () => void;
};

const currencyMeta: Record<HomeCurrency, { label: string; icon: LucideIcon }> = {
  rub: { label: "RUB", icon: RussianRuble },
  usd: { label: "USD", icon: DollarSign },
  eur: { label: "EUR", icon: Euro },
};

export function SummaryCard({
  monthlyTotal,
  subscriptionsCount,
  currency,
  isLoading = false,
  onCurrencyCycle,
}: SummaryCardProps) {
  const activeCurrency = currencyMeta[currency];
  const CurrencyIcon = activeCurrency.icon;

  return (
    <aside className={styles.summaryCard}>
      <div className={styles.summaryHeader}>
        <p className={styles.summaryLabel}>Ежемесячные расходы</p>
        <button
          type="button"
          className={styles.currencyButton}
          onClick={onCurrencyCycle}
          disabled={isLoading}
          aria-label={`Текущая валюта ${activeCurrency.label}. Нажмите, чтобы переключить.`}
        >
          <span className={styles.currencyIconWrap}>
            <CurrencyIcon size={15} />
          </span>
          <span>{activeCurrency.label}</span>
          <ArrowRightLeft size={14} />
        </button>
      </div>
      <div className={styles.summaryAmountRow}>
        <p className={styles.summaryAmount}>{formatMoney(monthlyTotal, currency)}</p>
        <span className={styles.summaryPerMonth}>/мес</span>
      </div>
      <div className={styles.summaryBadge}>
        <span className={styles.summaryBadgeDot} aria-hidden />
        {formatSubscriptionCount(subscriptionsCount)}
      </div>
    </aside>
  );
}
