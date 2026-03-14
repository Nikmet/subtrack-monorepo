"use client";

import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type CSSProperties,
} from "react";
import { createPortal } from "react-dom";
import { MoreHorizontal } from "lucide-react";

import { SubscriptionIcon } from "@/app/components/subscription-icon/subscription-icon";
import {
  formatMoney,
  formatNextPaymentShort,
} from "@/app/utils/home-formatters";
import { formatPeriodLabel } from "@/app/utils/subscription-formatters";
import type {
  HomeCurrency,
  SubscriptionListItem as SubscriptionListItemType,
} from "@/app/types/home";

import styles from "./subscription-list-item.module.css";

type SubscriptionListItemProps = {
  item: SubscriptionListItemType;
  currency: HomeCurrency;
  isMenuOpen: boolean;
  onMenuOpen: (id: string) => void;
  onMenuClose: () => void;
  onEdit: (item: SubscriptionListItemType) => void;
  onDelete: (item: SubscriptionListItemType) => void;
  isBusy?: boolean;
};

type MenuPosition = {
  top: number;
  left: number;
  originY: "top" | "bottom";
};

const MENU_GAP = 8;
const VIEWPORT_GAP = 12;

function MetricRow({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className={styles.metricRow}>
      <span className={styles.metricLabel}>{label}</span>
      <span className={styles.metricValue}>{value}</span>
    </div>
  );
}

export function SubscriptionListItem({
  item,
  currency,
  isMenuOpen,
  onMenuOpen,
  onMenuClose,
  onEdit,
  onDelete,
  isBusy = false,
}: SubscriptionListItemProps) {
  const triggerRef = useRef<HTMLButtonElement | null>(null);
  const menuRef = useRef<HTMLDivElement | null>(null);
  const [menuPosition, setMenuPosition] = useState<MenuPosition | null>(null);

  useLayoutEffect(() => {
    if (!isMenuOpen) {
      setMenuPosition(null);
      return;
    }

    const updateMenuPosition = () => {
      const trigger = triggerRef.current;
      const menu = menuRef.current;

      if (!trigger || !menu) {
        return;
      }

      const triggerRect = trigger.getBoundingClientRect();
      const menuRect = menu.getBoundingClientRect();
      const menuWidth = menuRect.width || 168;
      const menuHeight = menuRect.height || 120;

      let left = triggerRect.right - menuWidth;
      left = Math.max(
        VIEWPORT_GAP,
        Math.min(left, window.innerWidth - menuWidth - VIEWPORT_GAP),
      );

      let top = triggerRect.bottom + MENU_GAP;
      let originY: MenuPosition["originY"] = "top";

      if (top + menuHeight > window.innerHeight - VIEWPORT_GAP) {
        top = triggerRect.top - menuHeight - MENU_GAP;
        originY = "bottom";
      }

      top = Math.max(VIEWPORT_GAP, top);

      setMenuPosition({
        top,
        left,
        originY,
      });
    };

    updateMenuPosition();
  }, [isMenuOpen]);

  useEffect(() => {
    if (!isMenuOpen) {
      return;
    }

    const onPointerDown = (event: MouseEvent | TouchEvent) => {
      const target = event.target;
      if (!(target instanceof Node)) {
        return;
      }

      if (
        triggerRef.current?.contains(target) ||
        menuRef.current?.contains(target)
      ) {
        return;
      }

      onMenuClose();
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onMenuClose();
      }
    };

    const onViewportChange = () => {
      onMenuClose();
    };

    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("touchstart", onPointerDown);
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("scroll", onViewportChange, true);
    window.addEventListener("resize", onViewportChange);

    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("touchstart", onPointerDown);
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("scroll", onViewportChange, true);
      window.removeEventListener("resize", onViewportChange);
    };
  }, [isMenuOpen, onMenuClose]);

  const title = item.typeName.trim() || "-";
  const statusLabel = item.paymentCardLabel.trim() || "Автосписание";

  const handleEdit = () => {
    onMenuClose();
    onEdit(item);
  };

  const handleDelete = () => {
    onMenuClose();
    onDelete(item);
  };

  const menu = isMenuOpen
    ? createPortal(
        <div
          ref={menuRef}
          className={styles.actionMenu}
          style={
            {
              top: menuPosition?.top ?? 0,
              left: menuPosition?.left ?? 0,
              transformOrigin:
                menuPosition?.originY === "bottom"
                  ? "bottom right"
                  : "top right",
              opacity: menuPosition ? 1 : 0,
              visibility: menuPosition ? "visible" : "hidden",
            } satisfies CSSProperties
          }
        >
          <button
            type="button"
            className={styles.actionMenuItem}
            onClick={handleEdit}
          >
            Редактировать
          </button>
          <button
            type="button"
            className={`${styles.actionMenuItem} ${styles.actionMenuDanger}`}
            onClick={handleDelete}
          >
            Удалить
          </button>
        </div>,
        document.body,
      )
    : null;

  return (
    <>
      <article className={styles.subscriptionCard}>
        <div className={styles.cardTop}>
          <div className={styles.titleGroup}>
            <SubscriptionIcon
              src={item.typeImage}
              name={item.typeName}
              wrapperClassName={styles.subscriptionIconWrap}
              imageClassName={styles.subscriptionIcon}
              fallbackClassName={styles.subscriptionFallback}
            />
            <div className={styles.titleCopy}>
              <h3 className={styles.subscriptionName}>{title}</h3>
              <p className={styles.categoryLabel}>{item.categoryName}</p>
            </div>
          </div>

          <button
            ref={triggerRef}
            type="button"
            className={styles.actionTrigger}
            onClick={() => (isMenuOpen ? onMenuClose() : onMenuOpen(item.id))}
            aria-expanded={isMenuOpen}
            aria-label={`Действия для ${item.typeName}`}
            disabled={isBusy}
          >
            <MoreHorizontal size={18} />
          </button>
        </div>

        <div className={styles.cardDivider} />

        <div className={styles.metricsGrid}>
          <MetricRow
            label="Следующий платёж"
            value={formatNextPaymentShort(item.nextPaymentAt)}
          />
          <MetricRow label="Частота" value={formatPeriodLabel(item.period)} />
        </div>

        <div className={styles.cardDivider} />

        <div className={styles.cardFooter}>
          <div className={styles.priceLine}>
            <span className={styles.subscriptionPrice}>
              {formatMoney(item.monthlyPrice, currency)}
            </span>
            <span className={styles.subscriptionPriceLabel}>/мес</span>
          </div>

          <div className={styles.statusBadge}>
            <span className={styles.statusDot} aria-hidden="true" />
            <span className={styles.statusText}>{statusLabel}</span>
          </div>
        </div>
      </article>
      {menu}
    </>
  );
}
