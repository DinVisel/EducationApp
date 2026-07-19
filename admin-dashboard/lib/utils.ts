import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/// Merge conditional Tailwind class lists, de-duplicating conflicts.
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
