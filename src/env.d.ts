declare namespace App {
  interface Locals {
    user: import("@supabase/supabase-js").User | null;
    household: import("@/types").Household | null;
  }
}
