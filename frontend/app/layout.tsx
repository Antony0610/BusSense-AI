import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BusSense AI — Climate-Smart Public Bus Intelligence Platform",
  description: "Next-generation public transit intelligence combining CCTV occupancy estimation, real-time GPS telemetry, explainable crowd forecasting, and smart journey recommendations across Kerala.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="light">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
      </head>
      <body className="bg-surface font-body-md text-on-surface antialiased min-h-screen flex flex-col selection:bg-secondary-fixed selection:text-on-secondary-fixed">
        {children}
      </body>
    </html>
  );
}
