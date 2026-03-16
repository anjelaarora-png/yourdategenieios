import { useState, useEffect, useCallback } from "react";
import { QuestionnaireData } from "@/components/questionnaire/types";
import { DatePlan, GiftSuggestion } from "@/types/datePlan";
import { useToast } from "@/hooks/use-toast";
import { getClientTimeZone, getClientLocaleRegion } from "@/lib/currency";

const GENERATE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/generate-date-plan`;
const STORAGE_KEY = "pending_date_plans";
const MAX_RETRIES = 1; // Reduced to avoid long waits
const RETRY_DELAY_MS = 1000;

interface StoredPlans {
  plans: DatePlan[];
  selectedIndex: number;
  timestamp: number;
}

export function useGenerateDatePlan() {
  const [isGenerating, setIsGenerating] = useState(false);
  const [datePlans, setDatePlans] = useState<DatePlan[]>([]);
  const [selectedPlanIndex, setSelectedPlanIndex] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [isViewingMode, setIsViewingMode] = useState(false); // True when viewing saved plan
  const { toast } = useToast();

  // Load pending plans from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const data: StoredPlans = JSON.parse(stored);
        // Only restore if less than 24 hours old
        const hoursSinceStored = (Date.now() - data.timestamp) / (1000 * 60 * 60);
        if (hoursSinceStored < 24 && data.plans.length > 0) {
          setDatePlans(data.plans);
          setSelectedPlanIndex(data.selectedIndex);
          setIsViewingMode(false);
        } else {
          localStorage.removeItem(STORAGE_KEY);
        }
      } catch {
        localStorage.removeItem(STORAGE_KEY);
      }
    }
  }, []);

  // Save pending plans to localStorage whenever they change (only when not in viewing mode)
  useEffect(() => {
    if (datePlans.length > 0 && !isViewingMode) {
      const data: StoredPlans = {
        plans: datePlans,
        selectedIndex: selectedPlanIndex,
        timestamp: Date.now(),
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    }
  }, [datePlans, selectedPlanIndex, isViewingMode]);

  const generatePlans = async (preferences: QuestionnaireData): Promise<DatePlan[] | null> => {
    const startTime = Date.now();
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'useGenerateDatePlan.ts:58',message:'generatePlans called',data:{hasExistingPlans:datePlans.length,isCurrentlyGenerating:isGenerating},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,C'})}).catch(()=>{});
    // #endregion
    
    // Clear old cached plans when generating new ones (ensures fresh results on regenerate)
    localStorage.removeItem(STORAGE_KEY);
    setDatePlans([]);
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'useGenerateDatePlan.ts:68',message:'After setDatePlans([]) - plans cleared',data:{},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,C'})}).catch(()=>{});
    // #endregion
    
    setIsGenerating(true);
    
    // #region agent log
    fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'useGenerateDatePlan.ts:73',message:'After setIsGenerating(true)',data:{},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'C'})}).catch(()=>{});
    // #endregion
    
    setError(null);
    setIsViewingMode(false);

    // Helper for retry delay
    const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
    
    let lastError: string = "Unknown error";
    let attempt = 0;

    while (attempt <= MAX_RETRIES) {
      try {
        // Add timeout using AbortController (important for iOS WebView)
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 60000); // 60s timeout


        const payload = {
          ...preferences,
          timeZone: preferences.timeZone ?? getClientTimeZone(),
          countryCode: preferences.countryCode ?? getClientLocaleRegion(),
        };
        const response = await fetch(GENERATE_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY}`,
          },
          body: JSON.stringify({ preferences: payload }),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);


        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          const errorMessage = errorData.error || "Failed to generate date plans";
          
          // Don't retry on client errors (4xx) except 429
          if (response.status >= 400 && response.status < 500 && response.status !== 429 && response.status !== 408) {
            if (response.status === 402) {
              toast({
                title: "Service unavailable",
                description: "The AI service is temporarily unavailable. Please try again later.",
                variant: "destructive",
              });
            } else {
              toast({
                title: "Oops!",
                description: errorMessage,
                variant: "destructive",
              });
            }
            setError(errorMessage);
            setIsGenerating(false);
            return null;
          }
          
          // Retry on 429 (rate limit), 5xx errors, or timeout
          lastError = errorMessage;
          if (response.status === 429) {
            lastError = "Rate limited. Retrying...";
          }
          throw new Error(lastError);
        }

        const data = await response.json();
        
        
        if (data.datePlans && Array.isArray(data.datePlans) && data.datePlans.length > 0) {
          // Show results - works for any location
          setDatePlans(data.datePlans);
          setSelectedPlanIndex(0);
          
          // Count venues
          const totalStops = data.datePlans.reduce((sum: number, plan: DatePlan) => 
            sum + (plan.stops?.length || 0), 0
          );
          const verifiedStops = data.datePlans.reduce((sum: number, plan: DatePlan) => 
            sum + (plan.stops?.filter(s => s.validated).length || 0), 0
          );
          
          if (verifiedStops > 0) {
            toast({
              title: "Your date plans are ready! ✨",
              description: `We've found ${verifiedStops} verified venues for your perfect date.`,
            });
          } else {
            toast({
              title: "Your date plans are ready! ✨",
              description: `We've crafted ${data.datePlans.length} perfect options with ${totalStops} venue ideas.`,
            });
          }
          setIsGenerating(false);
          return data.datePlans;
        } else {
          throw new Error("Invalid response format - no plans returned");
        }
      } catch (err) {
        // Handle abort (timeout)
        if (err instanceof Error && err.name === 'AbortError') {
          lastError = "Request timed out. Please try again.";
        } else {
          lastError = err instanceof Error ? err.message : "Something went wrong";
        }
        
        attempt++;
        
        if (attempt <= MAX_RETRIES) {
          console.log(`[GenerateDatePlan] Retry attempt ${attempt}/${MAX_RETRIES} after error: ${lastError}`);
          await delay(RETRY_DELAY_MS * attempt); // Exponential backoff
        }
      }
    }

    // All retries exhausted
    setError(lastError);
    
    // Provide specific error messages based on the failure type
    let errorDescription = "Please check your connection and try again.";
    if (lastError === "Request timed out. Please try again.") {
      errorDescription = lastError;
    } else if (lastError.includes("stops")) {
      errorDescription = "The AI had trouble creating venues. Please try again with a different city or fewer preferences.";
    }
    
    toast({
      title: "Couldn't generate plans",
      description: errorDescription,
      variant: "destructive",
    });
    setIsGenerating(false);
    return null;
  };

  const selectPlan = (index: number) => {
    if (index >= 0 && index < datePlans.length) {
      setSelectedPlanIndex(index);
    }
  };

  // Set a single saved plan for viewing (from history)
  const setViewingPlan = useCallback((plan: DatePlan) => {
    setDatePlans([plan]);
    setSelectedPlanIndex(0);
    setIsViewingMode(true);
  }, []);

  const getCurrentPlan = (): DatePlan | null => {
    return datePlans[selectedPlanIndex] || null;
  };

  const reset = useCallback(() => {
    setDatePlans([]);
    setSelectedPlanIndex(0);
    setError(null);
    setIsViewingMode(false);
  }, []);

  // Clear pending plans from storage (call after saving)
  const clearPendingPlans = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    reset();
  }, [reset]);

  // Update gifts for a specific plan
  const updatePlanGifts = useCallback((planIndex: number, newGifts: GiftSuggestion[]) => {
    setDatePlans(prev => {
      const updated = [...prev];
      if (updated[planIndex]) {
        updated[planIndex] = {
          ...updated[planIndex],
          giftSuggestions: newGifts,
        };
      }
      return updated;
    });
  }, []);

  // Check if there are pending unsaved plans (only when not in viewing mode)
  const hasPendingPlans = datePlans.length > 0 && !isViewingMode;

  return {
    generatePlans,
    isGenerating,
    datePlans,
    selectedPlanIndex,
    selectPlan,
    getCurrentPlan,
    error,
    reset,
    clearPendingPlans,
    hasPendingPlans,
    isViewingMode,
    setViewingPlan,
    updatePlanGifts,
  };
}
