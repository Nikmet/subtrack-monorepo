export const normalizeCardNumberInput = (value: string) =>
  value
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[^\d* ]/g, "");

export const formatPaymentMethodLabel = (bankName: string, cardNumber: string) => {
  const safeBank = bankName.trim() || "Банк";
  const safeCardNumber = cardNumber.trim() || "****";
  return `${safeBank} • ${safeCardNumber}`;
};

export const formatRub = (value: number) =>
  `${new Intl.NumberFormat("ru-RU", { maximumFractionDigits: 0 }).format(Math.round(value))}₽`;

export const DEFAULT_BAN_REASON = "Аккаунт заблокирован администратором.";
