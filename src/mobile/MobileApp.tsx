import { useState, useEffect } from "react";
import { useAuth } from "@/hooks/useAuth";
import MobileOnboarding from "./screens/MobileOnboarding";
import MobileAuth from "./screens/MobileAuth";
import MobileHome from "./screens/MobileHome";
import MobileQuestionnaire from "./screens/MobileQuestionnaire";
import MobileDatePlanResult from "./screens/MobileDatePlanResult";
import MobileHistory from "./screens/MobileHistory";
import MobileProfile from "./screens/MobileProfile";
import MobilePlaylists from "./screens/MobilePlaylists";
import MobileTabBar from "./components/MobileTabBar";
import { QuestionnaireData } from "@/components/questionnaire/types";
import { useGenerateDatePlan } from "@/hooks/useGenerateDatePlan";
import { useDatePlans, SavedDatePlan } from "@/hooks/useDatePlans";
import { savedPlanToDatePlan } from "@/lib/planUtils";
import "./styles/mobile.css";

export type MobileScreen = 
  | "onboarding"
  | "auth"
  | "home"
  | "questionnaire"
  | "result"
  | "history"
  | "map"
  | "gifts"
  | "music"
  | "memories"
  | "profile"
  | "preferences";

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
    setViewingPlan 
  } = useGenerateDatePlan();
  
  const { plans: savedPlans, savePlan, deletePlan, updatePlanStatus } = useDatePlans();

  // Update screen when auth state changes
  useEffect(() => {
    if (!authLoading) {
      if (!hasSeenOnboarding) {
        setCurrentScreen("onboarding");
      } else if (!user) {
        setCurrentScreen("auth");
      } else {
        setCurrentScreen("home");
      }
    }
  }, [user, authLoading, hasSeenOnboarding]);

  const handleOnboardingComplete = () => {
    localStorage.setItem("dateGenie_onboardingSeen", "true");
    setHasSeenOnboarding(true);
    setCurrentScreen("auth");
  };

  const handleAuthSuccess = () => {
    setCurrentScreen("home");
  };

  const handleCreatePlan = () => {
    setCurrentScreen("questionnaire");
  };

  const handleQuestionnaireSubmit = async (data: QuestionnaireData) => {
    const plans = await generatePlans(data);
    if (plans && plans.length > 0) {
      setCurrentScreen("result");
    }
  };

  const handleViewSavedPlan = (plan: SavedDatePlan) => {
    setViewingPlan(savedPlanToDatePlan(plan));
    setCurrentScreen("result");
  };

  const handleTabChange = (tab: TabId) => {
    setActiveTab(tab);
    if (tab === "create") {
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

  if (authLoading) {
    return (
      <div className="mobile-container flex items-center justify-center min-h-screen">
        <div className="w-16 h-16 rounded-2xl gradient-gold animate-pulse" />
      </div>
    );
  }

  const showTabBar = user && !["onboarding", "auth", "questionnaire", "result"].includes(currentScreen);

  return (
    <div className="mobile-container bg-background">
      {currentScreen === "onboarding" && (
        <MobileOnboarding onComplete={handleOnboardingComplete} />
      )}
      
      {currentScreen === "auth" && (
        <MobileAuth onSuccess={handleAuthSuccess} />
      )}
      
      {currentScreen === "home" && (
        <MobileHome 
          savedPlans={savedPlans}
          onCreatePlan={handleCreatePlan}
        />
      )}
      
      {currentScreen === "questionnaire" && (
        <MobileQuestionnaire 
          onSubmit={handleQuestionnaireSubmit}
          onBack={handleBack}
          isGenerating={isGenerating}
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
