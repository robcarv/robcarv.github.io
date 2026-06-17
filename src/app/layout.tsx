import type { Metadata } from "next";
import "./globals.css";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Robert Carvalho · QA Automation Engineer",
  description: "QA Automation Engineer at IBM. Homelab enthusiast with 3 Raspberry Pis, TrueNAS storage, and 55+ Docker services.",
  openGraph: {
    title: "Robert Carvalho · QA Automation Engineer",
    description: "QA Automation Engineer at IBM. Homelab enthusiast.",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full flex flex-col bg-gray-950 text-gray-200">
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
