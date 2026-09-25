import { defineMiddleware } from "astro:middleware";
import { createClient } from "@/lib/supabase";
import type { Household } from "@/types";

const PROTECTED_ROUTES = ["/dashboard", "/household", "/children"];
const HOUSEHOLD_ROUTES = ["/dashboard", "/children"];
const ONBOARDING_ROUTE = "/household/new";

function matches(pathname: string, routes: string[]) {
  return routes.some((route) => pathname === route || pathname.startsWith(`${route}/`));
}

export const onRequest = defineMiddleware(async (context, next) => {
  const supabase = createClient(context.request.headers, context.cookies);
  context.locals.user = null;
  context.locals.household = null;

  if (supabase) {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    context.locals.user = user ?? null;

    if (user) {
      const { data, error } = await supabase
        .from("household_members")
        .select("households (id, name)")
        .eq("user_id", user.id)
        .maybeSingle<{ households: Household | null }>();

      if (error) {
        return new Response("Nie udało się wczytać danych gospodarstwa. Odśwież stronę za chwilę.", {
          status: 503,
          headers: { "Content-Type": "text/plain; charset=utf-8" },
        });
      }
      context.locals.household = data?.households ?? null;
    }
  }

  const { pathname } = context.url;

  if (matches(pathname, PROTECTED_ROUTES) && !context.locals.user) {
    return context.redirect("/auth/signin");
  }
  if (matches(pathname, HOUSEHOLD_ROUTES) && !context.locals.household) {
    return context.redirect(ONBOARDING_ROUTE);
  }
  if (matches(pathname, [ONBOARDING_ROUTE]) && context.locals.household) {
    return context.redirect("/dashboard");
  }

  return next();
});
