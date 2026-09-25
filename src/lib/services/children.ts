import { z } from "astro/zod";
import type { Child } from "@/types";

/** Dates are compared as YYYY-MM-DD strings in the caregivers' time zone (Workers run in UTC). */
const TIME_ZONE = "Europe/Warsaw";
export const MIN_BIRTH_DATE = "2000-01-01";

export const CHILD_COLUMNS = "id, household_id, display_name, birth_date, weight_kg, weight_measured_at";

export interface ChildRow {
  id: string;
  household_id: string;
  display_name: string;
  birth_date: string;
  weight_kg: number | string;
  weight_measured_at: string;
}

export function toChild(row: ChildRow): Child {
  return {
    id: row.id,
    householdId: row.household_id,
    displayName: row.display_name,
    birthDate: row.birth_date,
    weightKg: Number(row.weight_kg),
    weightMeasuredAt: row.weight_measured_at,
  };
}

/** Today's date as YYYY-MM-DD in {@link TIME_ZONE}; compute once per request and pass to the schemas. */
export function today(now = new Date()): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(now);
  const part = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return `${part("year")}-${part("month")}-${part("day")}`;
}

const weightKg = z
  .string({ error: "Podaj wagę" })
  .trim()
  .regex(/^\d{1,3}([.,]\d{1,2})?$/, "Podaj wagę w kg, np. 12,5")
  .transform((value) => Number(value.replace(",", ".")))
  .pipe(z.number().min(0.5, "Waga musi wynosić co najmniej 0,5 kg").max(150, "Waga może wynosić najwyżej 150 kg"));

function weightMeasuredAt(todayDate: string) {
  return z.iso
    .date({ error: "Podaj poprawną datę pomiaru" })
    .refine((value) => value <= todayDate, "Data pomiaru nie może być w przyszłości")
    .optional()
    .transform((value) => value ?? todayDate);
}

export function childSchema(todayDate: string) {
  return z
    .object({
      displayName: z
        .string({ error: "Podaj imię lub przydomek" })
        .trim()
        .min(1, "Podaj imię lub przydomek")
        .max(60, "Imię może mieć najwyżej 60 znaków"),
      birthDate: z.iso
        .date({ error: "Podaj poprawną datę urodzenia" })
        .refine((value) => value >= MIN_BIRTH_DATE, "Data urodzenia nie może być wcześniejsza niż 2000-01-01")
        .refine((value) => value <= todayDate, "Data urodzenia nie może być w przyszłości"),
      weightKg,
      weightMeasuredAt: weightMeasuredAt(todayDate),
    })
    .refine((data) => data.weightMeasuredAt >= data.birthDate, {
      message: "Data pomiaru nie może być wcześniejsza niż data urodzenia",
      path: ["weightMeasuredAt"],
    });
}

export function weightUpdateSchema(todayDate: string, birthDate: string, lastMeasuredAt: string) {
  return z.object({
    weightKg,
    weightMeasuredAt: weightMeasuredAt(todayDate)
      .refine((value) => value >= birthDate, "Data pomiaru nie może być wcześniejsza niż data urodzenia")
      .refine((value) => value >= lastMeasuredAt, "Data pomiaru nie może być wcześniejsza niż data ostatniego pomiaru"),
  });
}

/** Form fields arrive as string | File | null; empty or missing values become undefined. */
export function formText(form: FormData, name: string): string | undefined {
  const value = form.get(name);
  return typeof value === "string" && value !== "" ? value : undefined;
}

export function formatDate(isoDate: string): string {
  return new Date(`${isoDate}T00:00:00Z`).toLocaleDateString("pl-PL", { timeZone: "UTC" });
}

export function formatWeight(kg: number): string {
  return `${new Intl.NumberFormat("pl-PL", { maximumFractionDigits: 2 }).format(kg)} kg`;
}
