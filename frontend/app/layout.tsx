import type { Metadata } from "next";
import { Roboto } from "next/font/google";
import { Suspense } from "react";

import { TopLoaderProvider } from "@/app/components/top-loader/top-loader-provider";
import { ToasterProvider } from "@/app/components/toast/toaster-provider";
import "./globals.css";

const roboto = Roboto({
  variable: "--font-roboto",
  subsets: ["latin", "cyrillic"],
  weight: ["400", "500", "700", "900"],
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://subtrack.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "SubTrack",
  description: "Subscription tracking and spending analytics in one service.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ru">
      <body className={`${roboto.variable} antialiased`}>
        <Suspense fallback={null}>
          <TopLoaderProvider />
        </Suspense>
        {children}
        <ToasterProvider />
      </body>
    </html>
  );
}
