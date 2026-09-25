import type { APIRoute } from "astro";
import { z } from "astro/zod";
import { createClient } from "@/lib/supabase";

export const prerender = false;

const householdSchema = z.object({
  name: z
    .string({ error: "Podaj nazwę gospodarstwa" })
    .trim()
    .min(1, "Podaj nazwę gospodarstwa")
    .max(80, "Nazwa może mieć najwyżej 80 znaków"),
});

const UNIQUE_VIOLATION = "23505";

export const POST: APIRoute = async (context) => {
  const failure = (message: string) => context.redirect(`/household/new?error=${encodeURIComponent(message)}`);

  const supabase = createClient(context.request.headers, context.cookies);
  if (!supabase) {
    return failure("Supabase nie jest skonfigurowany");
  }
  if (!context.locals.user) {
    return context.redirect("/auth/signin");
  }

  const form = await context.request.formData();
  const parsed = householdSchema.safeParse({ name: form.get("name") });
  if (!parsed.success) {
    return failure(parsed.error.issues[0]?.message ?? "Nieprawidłowa nazwa gospodarstwa");
  }

  const { error } = await supabase.rpc("create_household", { p_name: parsed.data.name });
  if (error) {
    return failure(
      error.code === UNIQUE_VIOLATION
        ? "Masz już gospodarstwo"
        : "Nie udało się założyć gospodarstwa. Spróbuj ponownie.",
    );
  }

  return context.redirect("/dashboard");
};
