export const homeCurrencyValues = ["rub", "usd", "eur"] as const;

export type HomeCurrency = (typeof homeCurrencyValues)[number];

type CurrencyRates = {
  usd: number;
  eur: number;
};

const cbrDailyUrl = "https://www.cbr.ru/scripts/XML_daily.asp";

const parseDecimal = (value: string) => {
  const normalized = value.replace(",", ".").trim();
  const parsed = Number(normalized);

  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Invalid decimal value: ${value}`);
  }

  return parsed;
};

const extractValuteBlock = (xml: string, charCode: "USD" | "EUR") => {
  const pattern = new RegExp(`<Valute\\b[^>]*>[\\s\\S]*?<CharCode>${charCode}</CharCode>([\\s\\S]*?)</Valute>`, "i");
  const match = pattern.exec(xml);

  if (!match) {
    throw new Error(`Currency ${charCode} not found in CBR response`);
  }

  return match[0];
};

const extractTagValue = (block: string, tag: "Nominal" | "Value") => {
  const match = new RegExp(`<${tag}>([^<]+)</${tag}>`, "i").exec(block);

  if (!match) {
    throw new Error(`Tag ${tag} not found in currency block`);
  }

  return match[1];
};

const parseRate = (xml: string, charCode: "USD" | "EUR") => {
  const block = extractValuteBlock(xml, charCode);
  const nominal = parseDecimal(extractTagValue(block, "Nominal"));
  const value = parseDecimal(extractTagValue(block, "Value"));

  return value / nominal;
};

export async function loadCbrCurrencyRates(signal?: AbortSignal): Promise<CurrencyRates> {
  const response = await fetch(cbrDailyUrl, {
    method: "GET",
    headers: {
      accept: "application/xml,text/xml;q=0.9,*/*;q=0.8",
    },
    signal,
  });

  if (!response.ok) {
    throw new Error(`CBR request failed with status ${response.status}`);
  }

  const xml = await response.text();

  return {
    usd: parseRate(xml, "USD"),
    eur: parseRate(xml, "EUR"),
  };
}

export function convertRubAmount(amountRub: number, currency: HomeCurrency, rates: CurrencyRates): number {
  if (currency === "rub") {
    return amountRub;
  }

  if (currency === "usd") {
    return amountRub / rates.usd;
  }

  return amountRub / rates.eur;
}
