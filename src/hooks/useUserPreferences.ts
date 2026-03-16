import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/integrations/supabase/client";
import { QuestionnaireData, initialQuestionnaireData } from "@/components/questionnaire/types";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "./useAuth";

export interface UserPreferences {
  id: string;
  preferred_location: string | null;
  energy_level: string | null;
  food_preferences: string[] | null;
  deal_breakers: string[] | null;
  budget_range: string | null;
  // Location fields
  default_city: string | null;
  default_neighborhood: string | null;
  transportation_mode: string | null;
  travel_radius: string | null;
  activity_preferences: string[] | null;
  drink_preferences: string[] | null;
  dietary_restrictions: string[] | null;
  allergies: string[] | null;
  accessibility_needs: string[] | null;
  smoking_preference: string | null;
  smoking_activities: string[] | null;
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
  gender: string | null;
  partner_gender: string | null;
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

export function useUserPreferences() {
  const [preferences, setPreferences] = useState<UserPreferences | null>(null);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { user } = useAuth();

  const fetchPreferences = async () => {
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
  };

  useEffect(() => {
    fetchPreferences();
  }, [user]);

  const savePreferences = async (questionnaireData: QuestionnaireData, options?: { silent?: boolean }) => {
    if (!user) return;
    const silent = options?.silent === true;

    const prefsToSave = {
      user_id: user.id,
      // Location
      default_city: questionnaireData.city || null,
      default_neighborhood: questionnaireData.neighborhood || null,
      preferred_location: `${questionnaireData.city}${questionnaireData.neighborhood ? `, ${questionnaireData.neighborhood}` : ""}`,
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
      // Gift preferences (from questionnaire Step 6)
      gift_recipient: questionnaireData.giftRecipient || null,
      gift_interests: questionnaireData.partnerInterests || [],
      gift_budget: questionnaireData.giftBudget || null,
      gift_occasion: questionnaireData.occasion || null,
      gift_notes: questionnaireData.giftRecipientNotes || null,
      gift_recipient_identity: questionnaireData.partnerIdentity || null,
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
      // Refetch to get updated data
      fetchPreferences();
    } catch (error) {
      console.error("Error saving preferences:", error);
      toast({
        title: "Couldn't save preferences",
        description: "Your date plan was created, but preferences weren't saved.",
        variant: "destructive",
      });
    }
  };

  // Convert saved preferences back to questionnaire format
  const getQuestionnaireDefaults = useCallback((): QuestionnaireData | null => {
    if (!preferences) return null;

    return {
      ...initialQuestionnaireData,
      // Location (user can update per date)
      city: preferences.default_city || "",
      neighborhood: preferences.default_neighborhood || "",
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
      allergies: preferences.allergies?.length 
        ? preferences.allergies 
        : [],
      hardNos: preferences.deal_breakers || [],
      accessibilityNeeds: preferences.accessibility_needs?.length 
        ? preferences.accessibility_needs 
        : [],
      smokingPreference: preferences.smoking_preference || "",
      smokingActivities: preferences.smoking_activities || [],
      // Gift preferences (Step 6) – carried to Gifts tab and next questionnaire
      giftRecipient: preferences.gift_recipient || "",
      partnerInterests: preferences.gift_interests || [],
      giftBudget: preferences.gift_budget || "",
      giftRecipientNotes: preferences.gift_notes || "",
      partnerIdentity: preferences.gift_recipient_identity || "",
      giftStyle: preferences.gift_style || [],
      favoriteBrandsOrStores: preferences.gift_favorite_brands || "",
      recipientSizes: preferences.gift_sizes || "",
    };
  }, [preferences]);

  // Get gift preferences for the gift finder
  const getGiftPreferences = (): GiftPreferences => {
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
  };

  // Save gift preferences separately
  const saveGiftPreferences = async (giftPrefs: GiftPreferences) => {
    if (!user) return;

    const prefsToSave: Record<string, unknown> = {
      user_id: user.id,
      gift_recipient: giftPrefs.gift_recipient || null,
      gift_interests: giftPrefs.gift_interests || [],
      gift_budget: giftPrefs.gift_budget || null,
      gift_occasion: giftPrefs.gift_occasion || null,
      gift_notes: giftPrefs.gift_notes || null,
    };
    if (giftPrefs.gift_recipient_identity !== undefined) prefsToSave.gift_recipient_identity = giftPrefs.gift_recipient_identity || null;
    if (giftPrefs.gift_style !== undefined) prefsToSave.gift_style = giftPrefs.gift_style?.length ? giftPrefs.gift_style : null;
    if (giftPrefs.gift_favorite_brands !== undefined) prefsToSave.gift_favorite_brands = giftPrefs.gift_favorite_brands || null;
    if (giftPrefs.gift_sizes !== undefined) prefsToSave.gift_sizes = giftPrefs.gift_sizes || null;

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
      
      // Refetch to get updated data
      fetchPreferences();
    } catch (error) {
      console.error("Error saving gift preferences:", error);
    }
  };

  return {
    preferences,
    loading,
    savePreferences,
    getQuestionnaireDefaults,
    getGiftPreferences,
    saveGiftPreferences,
    refetch: fetchPreferences,
  };
}
