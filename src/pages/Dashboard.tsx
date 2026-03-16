import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Plus, LogOut, Map, History, Camera, Gift, MessageCircle, Shield, Settings, Music, BookOpen } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/useAuth";
import { useIsAdmin } from "@/hooks/useIsAdmin";
import { useDatePlans, SavedDatePlan } from "@/hooks/useDatePlans";
import { useDateMemories } from "@/hooks/useDateMemories";
import { useUserPreferences } from "@/hooks/useUserPreferences";
import IntakeQuestionnaire from "@/components/questionnaire/IntakeQuestionnaire";
import { QuestionnaireData } from "@/components/questionnaire/types";
import { useGenerateDatePlan } from "@/hooks/useGenerateDatePlan";
import GeneratingOverlay from "@/components/datePlan/GeneratingOverlay";
import DatePlanResult from "@/components/datePlan/DatePlanResult";
import DateHistory from "@/components/datePlan/DateHistory";
import DateMap from "@/components/map/DateMap";
import logo from "@/assets/logo.png";
import MemoryGallery from "@/components/memories/MemoryGallery";
import PhotoPrompt from "@/components/memories/PhotoPrompt";
import { savedPlanToDatePlan } from "@/lib/planUtils";
import GiftSuggestionsList from "@/components/datePlan/GiftSuggestionsList";
import ConversationStartersList from "@/components/datePlan/ConversationStartersList";
import PlaylistCollection from "@/components/playlist/PlaylistCollection";
import SaveTheDateDialog from "@/components/datePlan/SaveTheDateDialog";
import PlaybookView from "@/components/playbook/PlaybookView";
import { ErrorBoundary, SectionFallback } from "@/components/ui/error-boundary";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";

const Dashboard = () => {
  const { user, loading: authLoading, signOut } = useAuth();
  const { isAdmin } = useIsAdmin();
  const navigate = useNavigate();
  const { toast } = useToast();
  const { plans, savePlan, deletePlan, updatePlanStatus, ratePlan } = useDatePlans();
  const { memories, uploadMemory, deleteMemory } = useDateMemories();
  const { savePreferences, getQuestionnaireDefaults, loading: prefsLoading } = useUserPreferences();
  const { 
    generatePlans, 
    isGenerating, 
    datePlans, 
    selectedPlanIndex, 
    selectPlan,
    clearPendingPlans,
    hasPendingPlans,
    isViewingMode,
    setViewingPlan,
    updatePlanGifts,
  } = useGenerateDatePlan();

  const [questionnaireOpen, setQuestionnaireOpen] = useState(false);
  const [savedPreferences, setSavedPreferences] = useState<QuestionnaireData | null>(null);
  const [resultOpen, setResultOpen] = useState(false);

  // Load saved preferences from database on mount
  useEffect(() => {
    if (!prefsLoading) {
      const defaults = getQuestionnaireDefaults();
      if (defaults) {
        setSavedPreferences(defaults);
      }
    }
  }, [prefsLoading, getQuestionnaireDefaults]);
  const [savedPlanIds, setSavedPlanIds] = useState<Set<number>>(new Set());
  const [allPlansSaved, setAllPlansSaved] = useState(false);
  const [photoPromptOpen, setPhotoPromptOpen] = useState(false);
  const [saveTheDateOpen, setSaveTheDateOpen] = useState(false);
  const [lastSavedPlan, setLastSavedPlan] = useState<typeof datePlans[0] | null>(null);
  const [activeTab, setActiveTab] = useState("history");
  const [playbookOpen, setPlaybookOpen] = useState(false);

  // Redirect if not authenticated
  if (!authLoading && !user) {
    navigate("/login");
    return null;
  }

  const handleQuestionnaireSubmit = async (data: QuestionnaireData) => {
    setSavedPreferences(data);
    setQuestionnaireOpen(false);
    setSavedPlanIds(new Set());
    setAllPlansSaved(false);

    // Save preferences from the questionnaire first (no date plan generation here)
    await savePreferences(data);

    // Then generate date plans
    const generatedPlans = await generatePlans(data);
    if (generatedPlans && generatedPlans.length > 0) {
      setResultOpen(true);
    }
  };

  const handleRegenerate = async () => {
    if (savedPreferences) {
      setSavedPlanIds(new Set());
      setAllPlansSaved(false);
      await generatePlans(savedPreferences);
    }
  };

  const handleSavePlan = async () => {
    const currentPlan = datePlans[selectedPlanIndex];
    if (currentPlan) {
      const saved = await savePlan(currentPlan);
      if (saved) {
        setSavedPlanIds(prev => new Set([...prev, selectedPlanIndex]));
        // Show Save the Date dialog after successful save
        setLastSavedPlan(currentPlan);
        setSaveTheDateOpen(true);
      }
    }
  };

  const handleSaveAllPlans = async () => {
    let successCount = 0;
    for (let i = 0; i < datePlans.length; i++) {
      if (!savedPlanIds.has(i)) {
        const saved = await savePlan(datePlans[i]);
        if (saved) {
          successCount++;
        }
      }
    }
    if (successCount > 0) {
      setAllPlansSaved(true);
      setSavedPlanIds(new Set(datePlans.map((_, i) => i)));
      clearPendingPlans(); // Clear from localStorage since all are saved
      toast({
        title: `Saved ${successCount} plans! ✨`,
        description: "All date plan options have been saved to your collection.",
      });
    }
  };

  // Show pending plans dialog if there are unsaved plans from a previous session
  const handleResumePendingPlans = () => {
    if (hasPendingPlans && !resultOpen) {
      setResultOpen(true);
    }
  };

  const handleViewPlan = (plan: SavedDatePlan) => {
    // Convert saved plan format to DatePlan format and use viewing mode
    setViewingPlan(savedPlanToDatePlan(plan));
    setResultOpen(true);
  };

  const handleLogout = async () => {
    await signOut();
    toast({ title: "Signed out", description: "See you next time!" });
    navigate("/");
  };

  if (authLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 rounded-lg gradient-gold animate-pulse" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {isGenerating && <GeneratingOverlay />}

      <header className="border-b border-border sticky top-0 bg-background/95 backdrop-blur-lg z-40 safe-area-top">
        <div className="container px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-14 sm:h-16">
            <div className="flex items-center gap-2">
              <img src={logo} alt="Your Date Genie" className="h-8 sm:h-10 w-auto" />
            </div>
            <div className="flex items-center gap-1 sm:gap-2">
              <span className="text-xs sm:text-sm text-muted-foreground hidden sm:block truncate max-w-[150px]">
                {user?.email}
              </span>
              <Button variant="ghost" size="icon" className="h-9 w-9 sm:h-10 sm:w-10" onClick={() => navigate('/preferences')} title="My Preferences">
                <Settings className="w-4 h-4" />
              </Button>
              {isAdmin && (
                <Button variant="ghost" size="icon" className="h-9 w-9 sm:h-10 sm:w-10" onClick={() => navigate('/admin')} title="Admin">
                  <Shield className="w-4 h-4" />
                </Button>
              )}
              <Button variant="ghost" size="sm" onClick={handleLogout} className="h-9 sm:h-10 px-2 sm:px-3">
                <LogOut className="w-4 h-4 sm:mr-2" />
                <span className="hidden sm:inline">Sign Out</span>
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="container px-4 sm:px-6 lg:px-8 py-4 sm:py-8 pb-safe">
        <div className="max-w-5xl mx-auto">
          {/* Pending plans banner */}
          {hasPendingPlans && !resultOpen && (
            <div className="mb-4 sm:mb-6 p-3 sm:p-4 rounded-lg bg-primary/10 border border-primary/30 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4">
              <div>
                <p className="font-medium text-primary text-sm sm:text-base">You have unsaved date plans!</p>
                <p className="text-xs sm:text-sm text-muted-foreground">
                  You generated {datePlans.length} plan{datePlans.length !== 1 ? "s" : ""} that haven't been saved yet.
                </p>
              </div>
              <Button onClick={handleResumePendingPlans} className="gradient-gold text-primary-foreground w-full sm:w-auto" size="sm">
                Review Plans
              </Button>
            </div>
          )}

          {/* Magical Tools */}
          <section className="mb-6">
            <h2 className="font-display text-lg sm:text-xl text-foreground mb-3">Magical Tools</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => setPlaybookOpen(true)}
                className="flex items-center gap-3 p-4 rounded-lg border border-border bg-card text-card-foreground shadow-sm hover:bg-accent/50 hover:border-primary/30 transition-colors text-left"
              >
                <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center shrink-0">
                  <BookOpen className="h-5 w-5 text-primary" />
                </div>
                <div>
                  <p className="font-semibold text-foreground">The Playbook</p>
                  <p className="text-xs text-muted-foreground">Opinionated date advice for your situation</p>
                </div>
              </button>
            </div>
          </section>

          <div className="flex items-center justify-between mb-4 sm:mb-6 gap-2">
            <h1 className="font-display text-2xl sm:text-3xl">Your Date Plans</h1>
            <Button className="gradient-gold text-primary-foreground text-sm sm:text-base" onClick={() => setQuestionnaireOpen(true)} size="sm">
              <Plus className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">New Plan</span>
            </Button>
          </div>

          <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4 sm:space-y-6">
            <TabsList className="grid w-full grid-cols-6 h-auto p-1">
              <TabsTrigger value="history" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <History className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">History</span>
              </TabsTrigger>
              <TabsTrigger value="map" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <Map className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">Map</span>
              </TabsTrigger>
              <TabsTrigger value="gifts" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <Gift className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">Gifts</span>
              </TabsTrigger>
              <TabsTrigger value="convos" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <MessageCircle className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">Convos</span>
              </TabsTrigger>
              <TabsTrigger value="music" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <Music className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">Music</span>
              </TabsTrigger>
              <TabsTrigger value="memories" className="gap-1 sm:gap-2 py-2 sm:py-2.5 text-xs sm:text-sm flex-col sm:flex-row">
                <Camera className="w-4 h-4" />
                <span className="hidden xs:inline sm:inline">Memories</span>
              </TabsTrigger>
            </TabsList>

            <TabsContent value="history">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load date history" />}>
                <DateHistory 
                  plans={plans} 
                  onViewPlan={handleViewPlan} 
                  onDeletePlan={deletePlan} 
                  onMarkCompleted={(planId) => {
                    updatePlanStatus(planId, "completed");
                    toast({
                      title: "Date Completed! 🎉",
                      description: "Your date has been marked as completed.",
                    });
                  }}
                  onRatePlan={ratePlan}
                />
              </ErrorBoundary>
            </TabsContent>

            <TabsContent value="map">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load map" />}>
                <DateMap plans={plans} />
              </ErrorBoundary>
            </TabsContent>

            <TabsContent value="gifts">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load gift suggestions" />}>
                <p className="text-sm text-muted-foreground mb-3">
                  Saved gifts from date plans and the finder appear here. Your questionnaire preferences (recipient, interests, budget) are used when you search for gifts.
                </p>
                <GiftSuggestionsList plans={plans} />
              </ErrorBoundary>
            </TabsContent>

            <TabsContent value="convos">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load conversation starters" />}>
                <ConversationStartersList plans={plans} />
              </ErrorBoundary>
            </TabsContent>

            <TabsContent value="music">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load playlists" />}>
                <PlaylistCollection />
              </ErrorBoundary>
            </TabsContent>

            <TabsContent value="memories">
              <ErrorBoundary fallback={<SectionFallback message="Unable to load memories" />}>
                <div className="mb-4">
                  <Button variant="outline" onClick={() => setPhotoPromptOpen(true)}>
                    <Camera className="w-4 h-4 mr-2" />
                    Add Memory
                  </Button>
                </div>
                <MemoryGallery memories={memories} onDelete={deleteMemory} />
              </ErrorBoundary>
            </TabsContent>
          </Tabs>
        </div>
      </main>

      <IntakeQuestionnaire
        open={questionnaireOpen}
        onOpenChange={setQuestionnaireOpen}
        existingData={savedPreferences || getQuestionnaireDefaults()}
        onSubmit={handleQuestionnaireSubmit}
        onCloseWithDraft={(draft) => {
        savePreferences(draft, { silent: true });
        setSavedPreferences(draft);
      }}
      />

      <DatePlanResult
        open={resultOpen}
        onOpenChange={setResultOpen}
        plans={datePlans}
        selectedIndex={selectedPlanIndex}
        onSelectPlan={selectPlan}
        onRegenerate={handleRegenerate}
        isRegenerating={isGenerating}
        onSavePlan={isViewingMode ? undefined : handleSavePlan}
        onSaveAllPlans={isViewingMode ? undefined : handleSaveAllPlans}
        isSaved={isViewingMode || savedPlanIds.has(selectedPlanIndex)}
        areAllSaved={isViewingMode || allPlansSaved}
        onCapturePhoto={() => setPhotoPromptOpen(true)}
        isViewingMode={isViewingMode}
        scheduledDate={savedPreferences?.dateScheduled}
        startTime={savedPreferences?.startTime}
        onUpdatePlanGifts={isViewingMode ? undefined : updatePlanGifts}
        onNavigateToGifts={() => { setActiveTab("gifts"); setResultOpen(false); }}
        transportationMode={savedPreferences?.transportationMode}
        questionnaireDataForGifts={savedPreferences}
      />

      <PhotoPrompt
        open={photoPromptOpen}
        onOpenChange={setPhotoPromptOpen}
        onUpload={uploadMemory}
      />

      {/* Save the Date Dialog - shows after saving a plan */}
      {lastSavedPlan && (
        <SaveTheDateDialog
          open={saveTheDateOpen}
          onOpenChange={setSaveTheDateOpen}
          plan={lastSavedPlan}
          scheduledDate={savedPreferences?.dateScheduled}
          startTime={savedPreferences?.startTime}
        />
      )}

      {/* The Playbook - Magical Tools */}
      <Sheet open={playbookOpen} onOpenChange={setPlaybookOpen}>
        <SheetContent side="right" className="w-full sm:max-w-md flex flex-col p-0">
          <SheetHeader className="p-4 pb-0 shrink-0">
            <SheetTitle className="sr-only">The Playbook</SheetTitle>
          </SheetHeader>
          <div className="flex-1 min-h-0 px-4 pb-4">
            <PlaybookView onClose={() => setPlaybookOpen(false)} showClose />
          </div>
        </SheetContent>
      </Sheet>
    </div>
  );
};

export default Dashboard;
