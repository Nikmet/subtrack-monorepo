"use client";

import { useEffect, useState } from "react";

import { SubscriptionListItem } from "../subscription-list-item/subscription-list-item";
import type {
  HomeCurrency,
  SubscriptionListItem as SubscriptionListItemType,
} from "@/app/types/home";

import styles from "./subscriptions-section.module.css";

type SubscriptionsSectionProps = {
  subscriptions: SubscriptionListItemType[];
  currency: HomeCurrency;
  onEdit: (item: SubscriptionListItemType) => void;
  onDelete: (item: SubscriptionListItemType) => void;
  isBusy?: boolean;
};

export function SubscriptionsSection({
  subscriptions,
  currency,
  onEdit,
  onDelete,
  isBusy = false,
}: SubscriptionsSectionProps) {
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  useEffect(() => {
    if (!openMenuId) {
      return;
    }

    if (isBusy || !subscriptions.some((item) => item.id === openMenuId)) {
      setOpenMenuId(null);
    }
  }, [isBusy, openMenuId, subscriptions]);

  return (
    <section className={styles.subscriptionsSection}>
      <h2 className={styles.sectionTitle}>Мои подписки</h2>

      {subscriptions.length > 0 ? (
        <div className={styles.subscriptionsList}>
          {subscriptions.map((item) => (
            <SubscriptionListItem
              key={item.id}
              item={item}
              currency={currency}
              isMenuOpen={openMenuId === item.id}
              onMenuOpen={setOpenMenuId}
              onMenuClose={() => setOpenMenuId(null)}
              onEdit={onEdit}
              onDelete={onDelete}
              isBusy={isBusy}
            />
          ))}
        </div>
      ) : (
        <div className={styles.emptyState}>
          Подписок пока нет. Добавьте первую подписку через поиск.
        </div>
      )}
    </section>
  );
}
