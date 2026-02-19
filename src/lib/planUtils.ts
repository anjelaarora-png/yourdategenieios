import { DatePlan } from "@/types/datePlan";
import { SavedDatePlan } from "@/hooks/useDatePlans";

/**
 * Convert a SavedDatePlan (from database) to DatePlan format (used by components)
 */
export function savedPlanToDatePlan(saved: SavedDatePlan): DatePlan {
  return {
    title: saved.title,
    tagline: saved.tagline || "",
    totalDuration: saved.total_duration || "",
    estimatedCost: saved.estimated_cost || "",
    stops: saved.stops,
    genieSecretTouch: saved.genie_secret_touch || { title: "", description: "", emoji: "✨" },
    packingList: saved.packing_list || [],
    weatherNote: saved.weather_note || "",
    giftSuggestions: saved.gift_suggestions || undefined,
    conversationStarters: saved.conversation_starters || undefined,
  };
}
