"use client";

import {
  ArcElement,
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  Filler,
  Legend,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip,
  type ChartOptions,
} from "chart.js";
import { Bar, Doughnut, Line } from "react-chartjs-2";

import type { AnalyticsResponse } from "./types";
import styles from "../admin.module.css";

ChartJS.register(ArcElement, BarElement, CategoryScale, Filler, Legend, LineElement, LinearScale, PointElement, Tooltip);

type AnalyticsChartsProps = {
  analytics: AnalyticsResponse;
};

const chartTextColor = "#38516d";
const chartGridColor = "rgba(103, 131, 163, 0.18)";

export function AnalyticsCharts({ analytics }: AnalyticsChartsProps) {
  const labels = analytics.months.map((item) => item.label);
  const registrationsData = analytics.months.map((item) => item.registrationsCount);
  const userSubscriptionsData = analytics.months.map((item) => item.userSubscriptionsCreatedCount);
  const catalogSubscriptionsData = analytics.months.map((item) => item.commonSubscriptionsCreatedCount);

  const sharedPlugins = {
    legend: {
      labels: {
        color: chartTextColor,
        boxWidth: 10,
        boxHeight: 10,
        usePointStyle: true,
        pointStyle: "circle" as const,
        padding: 18,
      },
    },
    tooltip: {
      backgroundColor: "rgba(16, 35, 63, 0.92)",
      titleColor: "#f8fbff",
      bodyColor: "#d7e8fb",
      padding: 12,
      cornerRadius: 12,
    },
  };

  const trendOptions: ChartOptions<"line"> = {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 600 },
    plugins: sharedPlugins,
    scales: {
      x: {
        grid: { display: false },
        ticks: { color: chartTextColor },
      },
      y: {
        beginAtZero: true,
        ticks: { precision: 0, color: chartTextColor },
        grid: { color: chartGridColor },
      },
    },
  };

  const barOptions: ChartOptions<"bar"> = {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 600 },
    plugins: sharedPlugins,
    scales: {
      x: {
        grid: { display: false },
        ticks: { color: chartTextColor },
      },
      y: {
        beginAtZero: true,
        ticks: { precision: 0, color: chartTextColor },
        grid: { color: chartGridColor },
      },
    },
  };

  const doughnutOptions: ChartOptions<"doughnut"> = {
    responsive: true,
    maintainAspectRatio: false,
    animation: { duration: 600 },
    cutout: "68%",
    plugins: {
      ...sharedPlugins,
      legend: {
        position: "bottom",
        labels: {
          color: chartTextColor,
          boxWidth: 10,
          boxHeight: 10,
          usePointStyle: true,
          pointStyle: "circle",
          padding: 16,
        },
      },
    },
  };

  const trendData = {
    labels,
    datasets: [
      {
        label: "Регистрации",
        data: registrationsData,
        borderColor: "#0f7a82",
        backgroundColor: "rgba(15, 122, 130, 0.14)",
        pointBackgroundColor: "#0f7a82",
        pointBorderColor: "#ffffff",
        pointHoverRadius: 5,
        borderWidth: 3,
        tension: 0.35,
        fill: true,
      },
      {
        label: "Подписки пользователей",
        data: userSubscriptionsData,
        borderColor: "#1b63c8",
        backgroundColor: "rgba(27, 99, 200, 0.08)",
        pointBackgroundColor: "#1b63c8",
        pointBorderColor: "#ffffff",
        pointHoverRadius: 5,
        borderWidth: 3,
        tension: 0.35,
        fill: false,
      },
      {
        label: "Подписки каталога",
        data: catalogSubscriptionsData,
        borderColor: "#d17a14",
        backgroundColor: "rgba(209, 122, 20, 0.08)",
        pointBackgroundColor: "#d17a14",
        pointBorderColor: "#ffffff",
        pointHoverRadius: 5,
        borderWidth: 3,
        tension: 0.35,
        fill: false,
      },
    ],
  };

  const totalsData = {
    labels: ["Регистрации", "Подписки пользователей", "Подписки каталога"],
    datasets: [
      {
        data: [
          analytics.summary.registrationsTotal,
          analytics.summary.userSubscriptionsCreatedTotal,
          analytics.summary.commonSubscriptionsCreatedTotal,
        ],
        backgroundColor: ["#0f7a82", "#1b63c8", "#d17a14"],
        borderColor: "#f6fbff",
        borderWidth: 4,
        hoverOffset: 4,
      },
    ],
  };

  const barData = {
    labels,
    datasets: [
      {
        label: "Регистрации",
        data: registrationsData,
        backgroundColor: "#b7ece7",
        borderRadius: 10,
      },
      {
        label: "Подписки пользователей",
        data: userSubscriptionsData,
        backgroundColor: "#bdd3ff",
        borderRadius: 10,
      },
      {
        label: "Подписки каталога",
        data: catalogSubscriptionsData,
        backgroundColor: "#ffd7a6",
        borderRadius: 10,
      },
    ],
  };

  return (
    <div className={styles.analyticsVisualGrid}>
      <article className={`${styles.chartPanel} ${styles.chartPanelPrimary}`}>
        <div className={styles.chartHeader}>
          <div>
            <p className={styles.chartEyebrow}>Динамика по месяцам</p>
            <h3 className={styles.chartTitle}>Как росли регистрации и подписки</h3>
          </div>
          <p className={styles.chartMeta}>Сравнение трех потоков внутри {analytics.selectedYear} года</p>
        </div>
        <div className={styles.chartCanvasTall}>
          <Line data={trendData} options={trendOptions} />
        </div>
      </article>

      <article className={styles.chartPanel}>
        <div className={styles.chartHeader}>
          <div>
            <p className={styles.chartEyebrow}>Структура</p>
            <h3 className={styles.chartTitle}>Годовое распределение событий</h3>
          </div>
        </div>
        <div className={styles.chartCanvasSquare}>
          <Doughnut data={totalsData} options={doughnutOptions} />
        </div>
      </article>

      <article className={`${styles.chartPanel} ${styles.chartPanelWide}`}>
        <div className={styles.chartHeader}>
          <div>
            <p className={styles.chartEyebrow}>Помесячный поток</p>
            <h3 className={styles.chartTitle}>Где был пик активности</h3>
          </div>
          <p className={styles.chartMeta}>Столбцы помогают быстро сравнить месяцы без чтения таблицы</p>
        </div>
        <div className={styles.chartCanvasMedium}>
          <Bar data={barData} options={barOptions} />
        </div>
      </article>
    </div>
  );
}
