/**
 * Re-exports from the shared UserPreferencesContext so that existing import
 * paths (`@/hooks/useUserPreferences`) continue to work without change.
 *
 * All state now lives in UserPreferencesProvider (see src/contexts/UserPreferencesContext.tsx).
 * A single fetch/save updates every consumer in the tree simultaneously.
 */
export {
  useUserPreferences,
  UserPreferencesProvider,
} from "@/contexts/UserPreferencesContext";

export type {
  UserPreferences,
  GiftPreferences,
} from "@/contexts/UserPreferencesContext";
