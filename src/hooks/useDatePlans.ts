import { useState, useEffect, useCallback, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import { DatePlan, GiftSuggestion, ConversationStarter } from "@/types/datePlan";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "./useAuth";
import { Json } from "@/integrations/supabase/types";

export interface SavedDatePlan {
  id: string;
  title: string;
  tagline: string | null;
  total_duration: string | null;
  estimated_cost: string | null;
  stops: DatePlan["stops"];
  genie_secret_touch: DatePlan["genieSecretTouch"] | null;
  packing_list: string[] | null;
  weather_note: string | null;
  status: string;
  date_scheduled: string | null;
  created_at: string;
  updated_at: string;
  // Relationship enhancers
  gift_suggestions: GiftSuggestion[] | null;
  conversation_starters: ConversationStarter[] | null;
  // Rating
  rating: number | null;
  rating_notes: string | null;
}

export function useDatePlans() {
  const [plans, setPlans] = useState<SavedDatePlan[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { user } = useAuth();
  
  // Track mounted state to prevent state updates after unmount
  const isMounted = useRef(true);
  // Track fetch in progress to prevent duplicate calls
  const fetchInProgress = useRef(false);
  // Track last user ID to detect user changes
  const lastUserId = useRef<string | null>(null);

  const fetchPlans = useCallback(async () => {
    // Prevent duplicate fetches
    if (fetchInProgress.current) {
      return;
    }

    if (!user) {
      setPlans([]);
      setLoading(false);
      lastUserId.current = null;
      return;
    }

    // Skip if already fetched for this user (prevent double fetch on mount)
    if (lastUserId.current === user.id && plans.length > 0) {
      setLoading(false);
      return;
    }

    fetchInProgress.current = true;

    try {
      const { data, error } = await supabase
        .from("date_plans")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false });

      if (error) throw error;

      if (!isMounted.current) return;

      // Transform data to match our interface with safe fallbacks
      const transformedData: SavedDatePlan[] = (data || []).map((plan) => ({
        ...plan,
        stops: Array.isArray(plan.stops) 
          ? (plan.stops as unknown as DatePlan["stops"]) 
          : [],
        genie_secret_touch: plan.genie_secret_touch 
          ? (plan.genie_secret_touch as unknown as DatePlan["genieSecretTouch"]) 
          : null,
        gift_suggestions: Array.isArray(plan.gift_suggestions) 
          ? (plan.gift_suggestions as unknown as GiftSuggestion[]) 
          : null,
        conversation_starters: Array.isArray(plan.conversation_starters) 
          ? (plan.conversation_starters as unknown as ConversationStarter[]) 
          : null,
        rating: typeof plan.rating === 'number' ? plan.rating : null,
        rating_notes: plan.rating_notes || null,
      }));

      setPlans(transformedData);
      lastUserId.current = user.id;
    } catch (error) {
      console.error("Error fetching plans:", error);
      if (isMounted.current) {
        toast({
          title: "Error",
          description: "Failed to load your date plans.",
          variant: "destructive",
        });
      }
    } finally {
      if (isMounted.current) {
        setLoading(false);
      }
      fetchInProgress.current = false;
    }
  }, [user, toast]); // Note: plans removed from deps to prevent infinite loop

  useEffect(() => {
    isMounted.current = true;
    
    // Reset last user ID when user changes to force refetch
    if (user?.id !== lastUserId.current) {
      lastUserId.current = null;
    }
    
    fetchPlans();

    return () => {
      isMounted.current = false;
    };
  }, [user?.id, fetchPlans]);

  const savePlan = async (plan: DatePlan): Promise<SavedDatePlan | null> => {
    if (!user) {
      toast({
        title: "Not signed in",
        description: "Please sign in to save plans.",
        variant: "destructive",
      });
      return null;
    }

    try {
      const { data, error } = await supabase
        .from("date_plans")
        .insert({
          user_id: user.id,
          title: plan.title,
          tagline: plan.tagline,
          total_duration: plan.totalDuration,
          estimated_cost: plan.estimatedCost,
          stops: plan.stops as unknown as Json,
          genie_secret_touch: plan.genieSecretTouch as unknown as Json,
          packing_list: plan.packingList,
          weather_note: plan.weatherNote,
          status: "generated",
          gift_suggestions: (plan.giftSuggestions || []) as unknown as Json,
          conversation_starters: (plan.conversationStarters || []) as unknown as Json,
        })
        .select()
        .single();

      if (error) throw error;

      const savedPlan: SavedDatePlan = {
        ...data,
        stops: data.stops as unknown as DatePlan["stops"],
        genie_secret_touch: data.genie_secret_touch as unknown as DatePlan["genieSecretTouch"],
        gift_suggestions: (data.gift_suggestions as unknown as GiftSuggestion[]) || null,
        conversation_starters: (data.conversation_starters as unknown as ConversationStarter[]) || null,
        rating: data.rating || null,
        rating_notes: data.rating_notes || null,
      };

      setPlans((prev) => [savedPlan, ...prev]);
      toast({
        title: "Plan saved! ✨",
        description: "Your date plan has been saved to your collection.",
      });
      return savedPlan;
    } catch (error) {
      console.error("Error saving plan:", error);
      toast({
        title: "Error",
        description: "Failed to save your date plan.",
        variant: "destructive",
      });
      return null;
    }
  };

  const updatePlanStatus = async (planId: string, status: string, dateScheduled?: Date) => {
    try {
      const { error } = await supabase
        .from("date_plans")
        .update({ 
          status,
          date_scheduled: dateScheduled?.toISOString() || null,
        })
        .eq("id", planId);

      if (error) throw error;

      setPlans((prev) =>
        prev.map((p) =>
          p.id === planId
            ? { ...p, status, date_scheduled: dateScheduled?.toISOString() || null }
            : p
        )
      );
    } catch (error) {
      console.error("Error updating plan status:", error);
    }
  };

  const ratePlan = async (planId: string, rating: number, notes?: string) => {
    try {
      const { error } = await supabase
        .from("date_plans")
        .update({ 
          rating,
          rating_notes: notes || null,
        })
        .eq("id", planId);

      if (error) throw error;

      setPlans((prev) =>
        prev.map((p) =>
          p.id === planId
            ? { ...p, rating, rating_notes: notes || null }
            : p
        )
      );

      toast({
        title: "Rating saved! ⭐",
        description: "Thanks for your feedback!",
      });
    } catch (error) {
      console.error("Error rating plan:", error);
      toast({
        title: "Error",
        description: "Failed to save rating.",
        variant: "destructive",
      });
    }
  };

  const deletePlan = async (planId: string) => {
    try {
      const { error } = await supabase.from("date_plans").delete().eq("id", planId);
      if (error) throw error;

      setPlans((prev) => prev.filter((p) => p.id !== planId));
      toast({
        title: "Plan deleted",
        description: "Your date plan has been removed.",
      });
    } catch (error) {
      console.error("Error deleting plan:", error);
      toast({
        title: "Error",
        description: "Failed to delete the plan.",
        variant: "destructive",
      });
    }
  };

  return {
    plans,
    loading,
    savePlan,
    updatePlanStatus,
    deletePlan,
    ratePlan,
    refetch: fetchPlans,
  };
}
