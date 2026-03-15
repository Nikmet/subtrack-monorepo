import type { Metadata } from "next";

import { LandingContent } from "./landing-content";

export const metadata: Metadata = {
  title: "SubTrack | Subscription Control",
  description: "Track subscriptions, upcoming charges, and spending analytics across web and Android.",
  alternates: {
    canonical: "/landing",
  },
  openGraph: {
    title: "SubTrack",
    description: "Subscription control, spending analytics, and upcoming charge visibility across web and Android.",
    url: "/landing",
    type: "website",
    images: [
      {
        url: "/landing/dashboard-shot.png",
        width: 1600,
        height: 1100,
        alt: "SubTrack dashboard interface",
      },
    ],
  },
};

export default function LandingPage() {
  return <LandingContent />;
}
