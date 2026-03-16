import { useState, useEffect } from "react";
import { useAuth } from "@/hooks/useAuth";
import MobileOnboarding from "./screens/MobileOnboarding";
import MobileAuth from "./screens/MobileAuth";
import MobilePlanDateWelcome from "./screens/MobilePlanDateWelcome";
import MobileHome from "./screens/MobileHome";
import MobileQuestionnaire from "./screens/MobileQuestionnaire";
import MobileDatePlanResult from "./screens/MobileDatePlanResult";
import MobileHistory from "./screens/MobileHistory";
import MobileProfile from "./screens/MobileProfile";
import MobilePlaylists from "./screens/MobilePlaylists";
import MobileSettingsScreen from "./screens/MobileSettingsScreen";
import MobileNotificationsScreen from "./screens/MobileNotificationsScreen";
import MobileHelpScreen from "./screens/MobileHelpScreen";
import MobileTabBar from "./components/MobileTabBar";
import PlaybookView from "@/components/playbook/PlaybookView";
import { QuestionnaireData } from "@/components/questionnaire/types";
import { useGenerateDatePlan } from "@/hooks/useGenerateDatePlan";
import { useDatePlans, SavedDatePlan } from "@/hooks/useDatePlans";
import { useUserPreferences } from "@/hooks/useUserPreferences";
import { savedPlanToDatePlan } from "@/lib/planUtils";
import type { PlanIntent } from "./screens/MobileHome";
import "./styles/mobile.css";

export type MobileScreen = 
  | "onboarding"
  | "auth"
  | "welcome"
  | "home"
  | "questionnaire"
  | "result"
  | "history"
  | "map"
  | "gifts"
  | "music"
  | "memories"
  | "profile"
  | "preferences"
  | "notifications"
  | "settings"
  | "help"
  | "playbook";

export type TabId = "home" | "history" | "create" | "music" | "profile";

const MobileApp = () => {
  const { user, loading: authLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<TabId>("home");
  
  // Check localStorage synchronously on init
  const getInitialOnboardingState = () => {
    if (typeof window === "undefined") return false;
    return localStorage.getItem("dateGenie_onboardingSeen") === "true";
  };
  
  const [hasSeenOnboarding, setHasSeenOnboarding] = useState(getInitialOnboardingState);
  
  // Determine initial screen based on auth and onboarding state
  const getInitialScreen = (): MobileScreen => {
    if (!getInitialOnboardingState()) return "onboarding";
    return "auth"; // Will switch to home if user is logged in
  };
  
  const [currentScreen, setCurrentScreen] = useState<MobileScreen>(getInitialScreen);
  
  const { 
    generatePlans, 
    isGenerating, 
    datePlans, 
    selectedPlanIndex, 
    selectPlan,
    setViewingPlan,
    hasPendingPlans,
  } = useGenerateDatePlan();
  
  const { plans: savedPlans, savePlan, deletePlan, updatePlanStatus } = useDatePlans();
  const { getQuestionnaireDefaults, savePreferences, loading: prefsLoading } = useUserPreferences();

  const isNewUser = !prefsLoading && !getQuestionnaireDefaults() && savedPlans.length === 0;

  // Update screen when auth state changes
  useEffect(() => {
    if (!authLoading) {
      if (!hasSeenOnboarding) {
        setCurrentScreen("onboarding");
      } else if (!user) {
        setCurrentScreen("auth");
      } else if (isNewUser) {
        setCurrentScreen("welcome");
      } else {
        setCurrentScreen("home");
      }
    }
  }, [user, authLoading, hasSeenOnboarding, isNewUser]);

  const handleOnboardingComplete = () => {
    localStorage.setItem("dateGenie_onboardingSeen", "true");
    setHasSeenOnboarding(true);
    setCurrentScreen("auth");
  };

  const handleAuthSuccess = () => {
    if (isNewUser) {
      setCurrentScreen("welcome");
    } else {
      setCurrentScreen("home");
    }
  };

  const handleWelcomeContinue = () => {
    setCurrentScreen("questionnaire");
  };

  const [questionnaireIntent, setQuestionnaireIntent] = useState<PlanIntent | undefined>();

  const handleCreatePlan = (intent?: PlanIntent) => {
    setQuestionnaireIntent(intent);
    setCurrentScreen("questionnaire");
  };

  const handleQuestionnaireSubmit = async (data: QuestionnaireData) => {
    await savePreferences(data);
    const plans = await generatePlans(data);
    if (plans && plans.length > 0) {
      setCurrentScreen("result");
    }
  };

  const handleViewSavedPlan = (plan: SavedDatePlan) => {
    setViewingPlan(savedPlanToDatePlan(plan));
    setCurrentScreen("result");
  };

  const handleReviewUnsavedPlans = () => {
    setCurrentScreen("result");
    setActiveTab("home");
  };

  const handleTabChange = (tab: TabId) => {
    setActiveTab(tab);
    if (tab === "create") {
      setQuestionnaireIntent(undefined);
      setCurrentScreen("questionnaire");
    } else if (tab === "home") {
      setCurrentScreen("home");
    } else if (tab === "history") {
      setCurrentScreen("history");
    } else if (tab === "music") {
      setCurrentScreen("music");
    } else if (tab === "profile") {
      setCurrentScreen("profile");
    }
  };

  const handleBack = () => {
    setCurrentScreen("home");
    setActiveTab("home");
  };

  const handleNavigate = (screen: string) => {
    setCurrentScreen(screen as MobileScreen);
  };

  const handleBackToProfile = () => {
    setCurrentScreen("profile");
  };

  if (authLoading) {
    return (
      <div className="mobile-container flex items-center justify-center min-h-screen">
        <div className="w-16 h-16 rounded-2xl gradient-gold animate-pulse" />
      </div>
    );
  }

  const showTabBar = user && !["onboarding", "auth", "welcome", "questionnaire", "result", "preferences", "playbook"].includes(currentScreen);

  return (
    <div className="mobile-container bg-background">
      {currentScreen === "onboarding" && (
        <MobileOnboarding onComplete={handleOnboardingComplete} />
      )}
      
      {currentScreen === "auth" && (
        <MobileAuth onSuccess={handleAuthSuccess} />
      )}

      {currentScreen === "welcome" && (
        <MobilePlanDateWelcome onContinue={handleWelcomeContinue} />
      )}
      
      {currentScreen === "home" && (
        <MobileHome 
          savedPlans={savedPlans}
          onCreatePlan={handleCreatePlan}
          hasPendingPlans={hasPendingPlans}
          onReviewUnsavedPlans={handleReviewUnsavedPlans}
          hasSavedPreferences={!!getQuestionnaireDefaults()}
          savedPreferences={getQuestionnaireDefaults()}
          onNavigate={handleNavigate}
        />
      )}
      
      {currentScreen === "questionnaire" && (
        <MobileQuestionnaire 
          onSubmit={handleQuestionnaireSubmit}
          onBack={handleBack}
          isGenerating={isGenerating}
          existingData={questionnaireIntent === "fresh" ? null : getQuestionnaireDefaults()}
          intent={questionnaireIntent}
        />
      )}
      
      {currentScreen === "result" && (
        <MobileDatePlanResult
          plans={datePlans}
          selectedIndex={selectedPlanIndex}
          onSelectPlan={selectPlan}
          onSavePlan={savePlan}
          onBack={handleBack}
        />
      )}

      {currentScreen === "history" && (
        <MobileHistory
          plans={savedPlans}
          onViewPlan={handleViewSavedPlan}
          onDeletePlan={deletePlan}
          onMarkComplete={(planId) => updatePlanStatus(planId, "completed")}
        />
      )}

      {currentScreen === "music" && (
        <MobilePlaylists />
      )}

      {currentScreen === "profile" && (
        <MobileProfile onNavigate={handleNavigate} />
      )}

      {currentScreen === "preferences" && (
        <MobileQuestionnaire
          existingData={getQuestionnaireDefaults()}
          intent="useLast"
          onSubmit={async (data) => {
            await savePreferences(data);
            setCurrentScreen("profile");
          }}
          onBack={handleBackToProfile}
          isGenerating={false}
        />
      )}

      {currentScreen === "notifications" && (
        <MobileNotificationsScreen onBack={handleBackToProfile} />
      )}

      {currentScreen === "settings" && (
        <MobileSettingsScreen onBack={handleBackToProfile} />
      )}

      {currentScreen === "help" && (
        <MobileHelpScreen onBack={handleBackToProfile} />
      )}

      {currentScreen === "playbook" && (
        <div className="min-h-screen bg-background pb-24">
          <div className="sticky top-0 z-10 bg-background/95 backdrop-blur border-b border-border px-4 py-3 flex items-center gap-2">
            <button
              type="button"
              onClick={() => { setCurrentScreen("home"); setActiveTab("home"); }}
              className="p-2 -m-2 rounded-lg hover:bg-muted text-foreground"
              aria-label="Back"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="font-display text-lg font-semibold text-foreground">The Playbook</h1>
          </div>
          <div className="p-4">
            <PlaybookView showClose={false} />
          </div>
        </div>
      )}

      {showTabBar && (
        <MobileTabBar 
          activeTab={activeTab} 
          onTabChange={handleTabChange} 
        />
      )}
    </div>
  );
};

export default MobileApp;
