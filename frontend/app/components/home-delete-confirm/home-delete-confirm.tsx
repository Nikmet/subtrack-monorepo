"use client";

import { useEffect } from "react";

import styles from "./home-delete-confirm.module.css";

type HomeDeleteConfirmProps = {
  subscriptionName: string;
  isSubmitting: boolean;
  onClose: () => void;
  onConfirm: () => void;
};

export function HomeDeleteConfirm({
  subscriptionName,
  isSubmitting,
  onClose,
  onConfirm,
}: HomeDeleteConfirmProps) {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !isSubmitting) {
        onClose();
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [isSubmitting, onClose]);

  return (
    <div className={styles.backdrop} onClick={isSubmitting ? undefined : onClose}>
      <div
        className={styles.dialog}
        role="dialog"
        aria-modal="true"
        aria-label={`Удалить ${subscriptionName}`}
        onClick={(event) => event.stopPropagation()}
      >
        <div className={styles.header}>
          <h3 className={styles.title}>Удалить подписку</h3>
          <button
            type="button"
            className={styles.closeButton}
            onClick={onClose}
            disabled={isSubmitting}
            aria-label="Закрыть"
          >
            ×
          </button>
        </div>

        <div className={styles.serviceCard}>
          <p className={styles.serviceLabel}>Сервис</p>
          <p className={styles.serviceName}>{subscriptionName}</p>
        </div>

        <p className={styles.message}>
          Подписка будет удалена с главного экрана. Это действие можно будет
          повторить только через повторное добавление сервиса.
        </p>

        <div className={styles.actions}>
          <button
            type="button"
            className={styles.secondaryButton}
            onClick={onClose}
            disabled={isSubmitting}
          >
            Отмена
          </button>
          <button
            type="button"
            className={styles.dangerButton}
            onClick={onConfirm}
            disabled={isSubmitting}
          >
            {isSubmitting ? "Удаление..." : "Удалить"}
          </button>
        </div>
      </div>
    </div>
  );
}
