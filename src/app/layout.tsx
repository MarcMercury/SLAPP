import type { Metadata } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const jetbrains = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "SLAPP — Story Layering And Production Platform",
  description:
    "The Story Layering And Production Platform. Write, storyboard, and shape narratives with deep object intelligence and AI-assisted story building.",
  icons: {
    icon: "/Images/slapp-icon.png",
    apple: "/Images/slapp-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrains.variable} h-full dark`}>
      <body className="h-full bg-surface-0 text-text-primary antialiased">
        {children}
      </body>
    </html>
  );
}
