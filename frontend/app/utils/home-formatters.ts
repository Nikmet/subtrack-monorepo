import type { HomeCurrency } from "@/app/types/home";

const rubFormatter = new Intl.NumberFormat("ru-RU", {
  maximumFractionDigits: 0,
});

const usdFormatter = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const eurFormatter = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const nextPaymentDateFormatter = new Intl.DateTimeFormat("ru-RU", {
  day: "numeric",
  month: "short",
});

const toValidDate = (value: Date | string | null | undefined): Date | null => {
  if (!value) {
    return null;
  }

  const date = value instanceof Date ? value : new Date(value);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date;
};

export const formatMoney = (value: number, currency: HomeCurrency) => {
  if (currency === "usd") {
    return `$${usdFormatter.format(value)}`;
  }

  if (currency === "eur") {
    return `€${eurFormatter.format(value)}`;
  }

  return `${rubFormatter.format(Math.round(value))} ₽`;
};

export const formatNextPayment = (value: Date | string | null | undefined) => {
  const parsedDate = toValidDate(value);

  if (!parsedDate) {
    return "дата списания не указана";
  }

  return `следующий платёж ${nextPaymentDateFormatter.format(parsedDate)}`;
};

export const formatNextPaymentShort = (
  value: Date | string | null | undefined,
) => {
  const parsedDate = toValidDate(value);

  if (!parsedDate) {
    return "Не указана";
  }

  return nextPaymentDateFormatter.format(parsedDate);
};

export const formatSubscriptionCount = (count: number) => {
  const mod10 = count % 10;
  const mod100 = count % 100;

  if (mod10 === 1 && mod100 !== 11) {
    return `${count} активная подписка`;
  }

  if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
    return `${count} активные подписки`;
  }

  return `${count} активных подписок`;
};
