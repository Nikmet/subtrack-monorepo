"use client";

import { useEffect, useMemo, useState, type FormEvent } from "react";

import { SubscriptionIcon } from "@/app/components/subscription-icon/subscription-icon";
import { formatMoney } from "@/app/utils/home-formatters";
import { formatPaymentMethodLabel } from "@/app/utils/payment-method-formatters";
import { formatPeriodLabel } from "@/app/utils/subscription-formatters";
import type { HomeCurrency, SubscriptionListItem } from "@/app/types/home";

import styles from "./home-subscription-editor.module.css";

export type HomePaymentMethod = {
  id: string;
  bankId: string;
  cardNumber: string;
  isDefault: boolean;
  label: string;
  bank: {
    name: string;
    iconLink: string;
  };
};

export type HomeBank = {
  id: string;
  name: string;
  iconLink: string;
};

export type UpdateSubscriptionPayload = {
  nextPaymentAt: string;
  paymentMethodId: string;
  newPaymentMethodBankId: string;
  newPaymentMethodCardNumber: string;
};

type HomeSubscriptionEditorProps = {
  item: SubscriptionListItem;
  currency: HomeCurrency;
  paymentMethods: HomePaymentMethod[];
  banks: HomeBank[];
  isSubmitting: boolean;
  errorMessage: string | null;
  onClose: () => void;
  onSubmit: (payload: UpdateSubscriptionPayload) => void;
};

const NEW_PAYMENT_METHOD_VALUE = "__new__";

const toDateInputValue = (value: Date | string | null) => {
  if (!value) {
    return "";
  }

  const parsed = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return "";
  }

  const month = `${parsed.getMonth() + 1}`.padStart(2, "0");
  const day = `${parsed.getDate()}`.padStart(2, "0");

  return `${parsed.getFullYear()}-${month}-${day}`;
};

export function HomeSubscriptionEditor({
  item,
  currency,
  paymentMethods,
  banks,
  isSubmitting,
  errorMessage,
  onClose,
  onSubmit,
}: HomeSubscriptionEditorProps) {
  const defaultPaymentMethodId = useMemo(() => {
    if (item.paymentMethodId) {
      return item.paymentMethodId;
    }

    if (paymentMethods.length === 0) {
      return NEW_PAYMENT_METHOD_VALUE;
    }

    return (
      paymentMethods.find((method) => method.isDefault)?.id ??
      paymentMethods[0]?.id ??
      NEW_PAYMENT_METHOD_VALUE
    );
  }, [item.paymentMethodId, paymentMethods]);

  const [nextPaymentAt, setNextPaymentAt] = useState(
    toDateInputValue(item.nextPaymentAt),
  );
  const [paymentMethodId, setPaymentMethodId] = useState(defaultPaymentMethodId);
  const [newPaymentMethodBankId, setNewPaymentMethodBankId] = useState(
    banks[0]?.id ?? "",
  );
  const [newPaymentMethodCardNumber, setNewPaymentMethodCardNumber] = useState("");

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !isSubmitting) {
        onClose();
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [isSubmitting, onClose]);

  const showNewPaymentMethodForm = paymentMethodId === NEW_PAYMENT_METHOD_VALUE;
  const hasPaymentOption = paymentMethods.length > 0 || banks.length > 0;

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    onSubmit({
      nextPaymentAt,
      paymentMethodId: showNewPaymentMethodForm ? "" : paymentMethodId,
      newPaymentMethodBankId: showNewPaymentMethodForm ? newPaymentMethodBankId : "",
      newPaymentMethodCardNumber: showNewPaymentMethodForm
        ? newPaymentMethodCardNumber
        : "",
    });
  };

  return (
    <div className={styles.backdrop} onClick={isSubmitting ? undefined : onClose}>
      <div
        className={styles.dialog}
        role="dialog"
        aria-modal="true"
        aria-label={`Редактировать ${item.typeName}`}
        onClick={(event) => event.stopPropagation()}
      >
        <div className={styles.header}>
          <h3 className={styles.title}>Редактировать подписку</h3>
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
          <SubscriptionIcon
            src={item.typeImage}
            name={item.typeName}
            wrapperClassName={styles.serviceIconWrap}
            imageClassName={styles.serviceIcon}
            fallbackClassName={styles.serviceIconFallback}
          />
          <div className={styles.serviceText}>
            <p className={styles.serviceName}>{item.typeName}</p>
            <p className={styles.serviceMeta}>
              {item.categoryName} • {formatMoney(item.price, currency)} •{" "}
              {formatPeriodLabel(item.period)}
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="edit-next-payment">
              Дата оплаты
            </label>
            <input
              id="edit-next-payment"
              className={styles.input}
              type="date"
              value={nextPaymentAt}
              onChange={(event) => setNextPaymentAt(event.target.value)}
              required
            />
          </div>

          <div className={styles.fieldGroup}>
            <label className={styles.label} htmlFor="edit-payment-method">
              Способ оплаты
            </label>
            <select
              id="edit-payment-method"
              className={styles.input}
              value={paymentMethodId}
              onChange={(event) => setPaymentMethodId(event.target.value)}
              required
              disabled={!hasPaymentOption}
            >
              {paymentMethods.map((method) => (
                <option key={method.id} value={method.id}>
                  {formatPaymentMethodLabel(method.bank.name, method.cardNumber)}
                  {method.isDefault ? " (по умолчанию)" : ""}
                </option>
              ))}
              {banks.length > 0 ? (
                <option value={NEW_PAYMENT_METHOD_VALUE}>Новая карта</option>
              ) : null}
            </select>
          </div>

          {showNewPaymentMethodForm ? (
            <>
              <div className={styles.fieldGroup}>
                <label className={styles.label} htmlFor="edit-bank">
                  Банк
                </label>
                <select
                  id="edit-bank"
                  className={styles.input}
                  value={newPaymentMethodBankId}
                  onChange={(event) => setNewPaymentMethodBankId(event.target.value)}
                  required
                >
                  {banks.map((bank) => (
                    <option key={bank.id} value={bank.id}>
                      {bank.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className={styles.fieldGroup}>
                <label className={styles.label} htmlFor="edit-card-number">
                  Номер карты
                </label>
                <input
                  id="edit-card-number"
                  className={styles.input}
                  type="text"
                  placeholder="Например, **** 4242"
                  value={newPaymentMethodCardNumber}
                  onChange={(event) => setNewPaymentMethodCardNumber(event.target.value)}
                  minLength={4}
                  maxLength={24}
                  required
                />
              </div>
            </>
          ) : null}

          {errorMessage ? <p className={styles.error}>{errorMessage}</p> : null}

          <button
            type="submit"
            className={styles.submitButton}
            disabled={isSubmitting || !hasPaymentOption}
          >
            {isSubmitting ? "Сохранение..." : "Сохранить"}
          </button>
        </form>
      </div>
    </div>
  );
}
