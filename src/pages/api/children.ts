import type { APIRoute } from "astro";
import { createClient } from "@/lib/supabase";
import { childSchema, formText, today } from "@/lib/services/children";

export const prerender = false;

export const POST: APIRoute = async (context) => {
  const failure = (message: string) => context.redirect(`/dashboard?error=${encodeURIComponent(message)}`);

  const supabase = createClient(context.request.headers, context.cookies);
  if (!supabase) {
    return failure("Supabase nie jest skonfigurowany");
  }
  if (!context.locals.user) {
    return context.redirect("/auth/signin");
  }
  const { household } = context.locals;
  if (!household) {
    return context.redirect("/household/new");
  }

  const form = await context.request.formData();
  const parsed = childSchema(today()).safeParse({
    displayName: formText(form, "displayName"),
    birthDate: formText(form, "birthDate"),
    weightKg: formText(form, "weightKg"),
    weightMeasuredAt: formText(form, "weightMeasuredAt"),
  });
  if (!parsed.success) {
    return failure(parsed.error.issues[0]?.message ?? "Nieprawidłowe dane dziecka");
  }

  const { data, error } = await supabase
    .from("children")
    .insert({
      household_id: household.id,
      display_name: parsed.data.displayName,
      birth_date: parsed.data.birthDate,
      weight_kg: parsed.data.weightKg,
      weight_measured_at: parsed.data.weightMeasuredAt,
    })
    .select("id")
    .single<{ id: string }>();

  if (error) {
    return failure("Nie udało się dodać dziecka. Spróbuj ponownie.");
  }

  return context.redirect(`/children/${data.id}`);
};
