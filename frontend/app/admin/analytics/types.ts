export type AnalyticsMonth = {
  month: number;
  label: string;
  registrationsCount: number;
  userSubscriptionsCreatedCount: number;
  commonSubscriptionsCreatedCount: number;
};

export type AnalyticsResponse = {
  selectedYear: number;
  availableYears: number[];
  summary: {
    registrationsTotal: number;
    userSubscriptionsCreatedTotal: number;
    commonSubscriptionsCreatedTotal: number;
    activeSubscriptionsAnnualTotalRub: number;
  };
  months: AnalyticsMonth[];
};
