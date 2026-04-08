import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { QuestionnaireData, initialQuestionnaireData } from "@/components/questionnaire/types";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/useAuth";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface UserPreferences {
  id: string;
  preferred_location: string | null;
  energy_level: string | null;
  food_preferences: string[] | null;
  deal_breakers: string[] | null;
  budget_range: string | null;
  // Location
  default_city: string | null;
  default_neighborhood: string | null;
  /** Full departure address; synced with questionnaire `startingAddress` and iOS `defaultStartingPoint`. */
  default_starting_point: string | null;
  transportation_mode: string | null;
  travel_radius: string | null;
  activity_preferences: string[] | null;
  drink_preferences: string[] | null;
  dietary_restrictions: string[] | null;
  allergies: string[] | null;
  accessibility_needs: string[] | null;
  smoking_preference: string | null;
  smoking_activities: string[] | null;
  // Identity
  gender: string | null;
  partner_gender: string | null;
  love_languages: string[] | null;
  partner_love_languages: string[] | null;
  // Relationship context
  relationship_stage: string | null;
  conversation_topics: string[] | null;
  additional_notes: string | null;
  // Gift preferences
  gift_recipient: string | null;
  gift_interests: string[] | null;
  gift_budget: string | null;
  gift_occasion: string | null;
  gift_notes: string | null;
  gift_recipient_identity: string | null;
  gift_style: string[] | null;
  gift_favorite_brands: string | null;
  gift_sizes: string | null;
  updated_at?: string | null;
}

export interface GiftPreferences {
  gift_recipient: string;
  gift_interests: string[];
  gift_budget: string;
  gift_occasion: string;
  gift_notes: string;
  gift_recipient_identity?: string;
  gift_style?: string[];
  gift_favorite_brands?: string;
  gift_sizes?: string;
}

/** Builds the denormalized preferred_location string safely. */
function buildPreferredLocation(city: string | null | undefined, neighborhood: string | null | undefined): string | null {
  const parts = [city, neighborhood].map(s => s?.trim()).filter(Boolean);
  return parts.length > 0 ? parts.join(", ") : null;
}

// ─── Context ─────────────────────────────────────────────────────────────────

interface UserPreferencesContextValue {
  preferences: UserPreferences | null;
  loading: boolean;
  refetch: () => Promise<void>;
  savePreferences: (data: QuestionnaireData, options?: { silent?: boolean }) => Promise<void>;
  getQuestionnaireDefaults: () => QuestionnaireData | null;
  getGiftPreferences: () => GiftPreferences;
  saveGiftPreferences: (giftPrefs: GiftPreferences) => Promise<void>;
}

const UserPreferencesContext = createContext<UserPreferencesContextValue | null>(null);

// ─── Provider ────────────────────────────────────────────────────────────────

export function UserPreferencesProvider({ children }: { children: React.ReactNode }) {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { user } = useAuth();

  const fetchPreferences = useCallback(async () => {
    if (!user) {
      setPreferences(null);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from("user_preferences")
        .select("*")
        .eq("user_id", user.id)
        .maybeSingle();

      if (error) throw error;
      setPreferences(data);
    } catch (error) {
      console.error("Error fetching preferences:", error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    fetchPreferences();
  }, [fetchPreferences]);

  const savePreferences = useCallback(async (
    questionnaireData: QuestionnaireData,
    options?: { silent?: boolean },
  ) => {
    if (!user) return;
    const silent = options?.silent === true;

    const prefsToSave = {
      user_id: user.id,
      // Location — use structured fields; derive preferred_location safely
      default_city: questionnaireData.city || null,
      default_neighborhood: questionnaireData.neighborhood || null,
      default_starting_point: questionnaireData.startingAddress?.trim() || null,
      preferred_location: buildPreferredLocation(questionnaireData.city, questionnaireData.neighborhood),
      // Transportation
      transportation_mode: questionnaireData.transportationMode || null,
      travel_radius: questionnaireData.travelRadius || null,
      // Energy & Activities
      energy_level: questionnaireData.energyLevel || null,
      activity_preferences: questionnaireData.activityPreferences || [],
      // Food & Drinks
      food_preferences: questionnaireData.cuisinePreferences || [],
      dietary_restrictions: questionnaireData.dietaryRestrictions?.filter(d => d !== "none") || [],
      drink_preferences: questionnaireData.drinkPreferences?.length ? questionnaireData.drinkPreferences : null,
      budget_range: questionnaireData.budgetRange || null,
      // Deal Breakers
      allergies: questionnaireData.allergies?.filter(a => a !== "none") || [],
      deal_breakers: questionnaireData.hardNos || [],
      accessibility_needs: questionnaireData.accessibilityNeeds?.filter(a => a !== "none") || [],
      smoking_preference: questionnaireData.smokingPreference || null,
      smoking_activities: questionnaireData.smokingActivities?.filter(s => s !== "none") || [],
      // Identity & relationship context
      gender: questionnaireData.userIdentity || null,
      partner_gender: questionnaireData.partnerIdentity || null,
      love_languages: questionnaireData.userLoveLanguages?.length ? questionnaireData.userLoveLanguages : null,
      partner_love_languages: questionnaireData.partnerLoveLanguages?.length ? questionnaireData.partnerLoveLanguages : null,
      relationship_stage: questionnaireData.relationshipStage || null,
      conversation_topics: questionnaireData.conversationTopics?.length ? questionnaireData.conversationTopics : null,
      additional_notes: questionnaireData.additionalNotes || null,
      // Gift preferences
      gift_recipient: questionnaireData.giftRecipient || null,
      gift_interests: questionnaireData.partnerInterests || [],
      gift_budget: questionnaireData.giftBudget || null,
      gift_occasion: questionnaireData.occasion || null,
      gift_notes: questionnaireData.giftRecipientNotes || null,
      gift_recipient_identity: (questionnaireData.recipientIdentity ?? questionnaireData.partnerIdentity) || null,
      gift_style: questionnaireData.giftStyle?.length ? questionnaireData.giftStyle : null,
      gift_favorite_brands: questionnaireData.favoriteBrandsOrStores || null,
      gift_sizes: questionnaireData.recipientSizes || null,
    };

    try {
      if (preferences) {
        const { error } = await supabase
          .from("user_preferences")
          .update(prefsToSave)
          .eq("id", preferences.id);

        if (error) throw error;
      } else {
        const { data, error } = await supabase
          .from("user_preferences")
          .insert(prefsToSave)
          .select()
          .single();

        if (error) throw error;
        setPreferences(data);
      }

      if (!silent) {
        toast({
          title: "Preferences saved!",
          description: "Your preferences will pre-fill future questionnaires.",
        });
      }

      // Re-fetch so all consumers get the updated row immediately
      await fetchPreferences();
    } catch (error) {
      console.error("Error saving preferences:", error);
      toast({
        title: "Couldn't save preferences",
        description: "Your date plan was created, but preferences weren't saved.",
        variant: "destructive",
      });
    }
  }, [user, preferences, toast, fetchPreferences]);

  const getQuestionnaireDefaults = useCallback((): QuestionnaireData | null => {
    if (!preferences) return null;

    return {
      ...initialQuestionnaireData,
      // Location
      city: preferences.default_city || "",
      neighborhood: preferences.default_neighborhood || "",
      startingAddress: preferences.default_starting_point || "",
      // Transportation
      transportationMode: preferences.transportation_mode || "",
      travelRadius: preferences.travel_radius || "",
      // Energy & Activities
      energyLevel: preferences.energy_level || "",
      activityPreferences: preferences.activity_preferences || [],
      // Food & Drinks
      cuisinePreferences: preferences.food_preferences || [],
      dietaryRestrictions: preferences.dietary_restrictions?.length
        ? preferences.dietary_restrictions
        : [],
      drinkPreferences: preferences.drink_preferences || [],
      budgetRange: preferences.budget_range || "",
      // Deal Breakers
      allergies: preferences.allergies?.length ? preferences.allergies : [],
      hardNos: preferences.deal_breakers || [],
      accessibilityNeeds: preferences.accessibility_needs?.length
        ? preferences.accessibility_needs
        : [],
      smokingPreference: preferences.smoking_preference || "",
      smokingActivities: preferences.smoking_activities || [],
      // Identity & relationship context
      userIdentity: preferences.gender || "",
      partnerIdentity: preferences.partner_gender || "",
      userLoveLanguages: preferences.love_languages || [],
      partnerLoveLanguages: preferences.partner_love_languages || [],
      relationshipStage: preferences.relationship_stage || "",
      conversationTopics: preferences.conversation_topics || [],
      additionalNotes: preferences.additional_notes || "",
      // Gift preferences
      giftRecipient: preferences.gift_recipient || "",
      partnerInterests: preferences.gift_interests || [],
      giftBudget: preferences.gift_budget || "",
      occasion: preferences.gift_occasion || "",
      giftRecipientNotes: preferences.gift_notes || "",
      recipientIdentity: preferences.gift_recipient_identity || "",
      giftStyle: preferences.gift_style || [],
      favoriteBrandsOrStores: preferences.gift_favorite_brands || "",
      recipientSizes: preferences.gift_sizes || "",
    };
  }, [preferences]);

  const getGiftPreferences = useCallback((): GiftPreferences => {
    return {
      gift_recipient: preferences?.gift_recipient || "",
      gift_interests: preferences?.gift_interests || [],
      gift_budget: preferences?.gift_budget || "",
      gift_occasion: preferences?.gift_occasion || "",
      gift_notes: preferences?.gift_notes || "",
      gift_recipient_identity: preferences?.gift_recipient_identity || undefined,
      gift_style: preferences?.gift_style || undefined,
      gift_favorite_brands: preferences?.gift_favorite_brands || undefined,
      gift_sizes: preferences?.gift_sizes || undefined,
    };
  }, [preferences]);

  const saveGiftPreferences = useCallback(async (giftPrefs: GiftPreferences) => {
    if (!user) return;

    const prefsToSave: Record<string, unknown> = {
      user_id: user.id,
      gift_recipient: giftPrefs.gift_recipient || null,
      gift_interests: giftPrefs.gift_interests || [],
      gift_budget: giftPrefs.gift_budget || null,
      gift_occasion: giftPrefs.gift_occasion || null,
      gift_notes: giftPrefs.gift_notes || null,
    };
    if (giftPrefs.gift_recipient_identity !== undefined)
      prefsToSave.gift_recipient_identity = giftPrefs.gift_recipient_identity || null;
    if (giftPrefs.gift_style !== undefined)
      prefsToSave.gift_style = giftPrefs.gift_style?.length ? giftPrefs.gift_style : null;
    if (giftPrefs.gift_favorite_brands !== undefined)
      prefsToSave.gift_favorite_brands = giftPrefs.gift_favorite_brands || null;
    if (giftPrefs.gift_sizes !== undefined)
      prefsToSave.gift_sizes = giftPrefs.gift_sizes || null;

    try {
      if (preferences) {
        const { error } = await supabase
          .from("user_preferences")
          .update(prefsToSave)
          .eq("id", preferences.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from("user_preferences")
          .insert(prefsToSave)
          .select()
          .single();

        if (error) throw error;
      }

      await fetchPreferences();
    } catch (error) {
      console.error("Error saving gift preferences:", error);
    }
  }, [user, preferences, fetchPreferences]);

  return (
    <UserPreferencesContext.Provider
      value={{
        preferences,
        loading,
        refetch: fetchPreferences,
        savePreferences,
        getQuestionnaireDefaults,
        getGiftPreferences,
        saveGiftPreferences,
      }}
    >
      {children}
    </UserPreferencesContext.Provider>
  );
}

// ─── Hook ────────────────────────────────────────────────────────────────────

export function useUserPreferences() {
  const ctx = useContext(UserPreferencesContext);
  if (!ctx) {
    throw new Error("useUserPreferences must be used inside <UserPreferencesProvider>");
  }
  return ctx;
}
