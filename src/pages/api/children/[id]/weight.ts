import type { APIRoute } from "astro";
import { z } from "astro/zod";
import { createClient } from "@/lib/supabase";
import { formText, today, weightUpdateSchema } from "@/lib/services/children";

export const prerender = false;

const NOT_FOUND_MESSAGE = "Nie znaleziono dziecka";

export const POST: APIRoute = async (context) => {
  const toDashboard = (message: string) => context.redirect(`/dashboard?error=${encodeURIComponent(message)}`);

  const supabase = createClient(context.request.headers, context.cookies);
  if (!supabase) {
    return toDashboard("Supabase nie jest skonfigurowany");
  }
  if (!context.locals.user) {
    return context.redirect("/auth/signin");
  }
  if (!context.locals.household) {
    return context.redirect("/household/new");
  }

  const id = z.uuid().safeParse(context.params.id);
  if (!id.success) {
    return toDashboard(NOT_FOUND_MESSAGE);
  }
  const childPath = `/children/${id.data}`;

  // RLS hides children of other households, so "foreign" and "missing" look the same.
  const { data: child, error: readError } = await supabase
    .from("children")
    .select("birth_date, weight_measured_at")
    .eq("id", id.data)
    .maybeSingle<{ birth_date: string; weight_measured_at: string }>();
  if (readError || !child) {
    return toDashboard(NOT_FOUND_MESSAGE);
  }

  const form = await context.request.formData();
  const parsed = weightUpdateSchema(today(), child.birth_date, child.weight_measured_at).safeParse({
    weightKg: formText(form, "weightKg"),
    weightMeasuredAt: formText(form, "weightMeasuredAt"),
  });
  if (!parsed.success) {
    const message = parsed.error.issues[0]?.message ?? "Nieprawidłowe dane wagi";
    return context.redirect(`${childPath}?error=${encodeURIComponent(message)}`);
  }

  const { data: updated, error } = await supabase
    .from("children")
    .update({ weight_kg: parsed.data.weightKg, weight_measured_at: parsed.data.weightMeasuredAt })
    .eq("id", id.data)
    .select("id");

  if (error) {
    return context.redirect(
      `${childPath}?error=${encodeURIComponent("Nie udało się zapisać wagi. Spróbuj ponownie.")}`,
    );
  }
  if (updated.length === 0) {
    return toDashboard(NOT_FOUND_MESSAGE);
  }

  return context.redirect(childPath);
};
