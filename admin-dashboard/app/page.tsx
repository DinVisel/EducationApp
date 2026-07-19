"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { isAuthenticated } from "@/lib/auth";

/// Entry route: bounce to the dashboard or the login screen.
export default function IndexPage() {
  const router = useRouter();
  useEffect(() => {
    router.replace(isAuthenticated() ? "/overview" : "/login");
  }, [router]);
  return null;
}
