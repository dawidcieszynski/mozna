export interface Household {
  id: string;
  name: string;
}

export interface Child {
  id: string;
  householdId: string;
  displayName: string;
  /** YYYY-MM-DD */
  birthDate: string;
  weightKg: number;
  /** YYYY-MM-DD */
  weightMeasuredAt: string;
}
