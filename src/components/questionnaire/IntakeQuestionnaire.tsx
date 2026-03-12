import { useState, useEffect, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { ArrowLeft, ArrowRight, Sparkles, RefreshCw, Zap, RotateCcw } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { CalendarIcon } from "lucide-react";
import { format, parse } from "date-fns";
import { cn } from "@/lib/utils";
import StepIndicator from "./StepIndicator";
import Step1Location from "./steps/Step1Location";
import Step2Transportation from "./steps/Step2Transportation";
import Step3Energy from "./steps/Step3Energy";
import Step4Food from "./steps/Step4Food";
import Step5DealBreakers from "./steps/Step5DealBreakers";
import Step6Enhancers from "./steps/Step6Enhancers";
import OptionCard from "./OptionCard";
import { QuestionnaireData, initialQuestionnaireData, DATE_TYPES, OCCASIONS } from "./types";

interface IntakeQuestionnaireProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  existingData?: QuestionnaireData | null;
  onSubmit: (data: QuestionnaireData) => void;
}

const STEP_LABELS = ["Location", "Travel", "Vibe", "Food", "Avoid", "Extras"];
const TOTAL_STEPS = 6;
const STORAGE_KEY = "dateGenie_questionnaireProgress";

interface StoredProgress {
  data: QuestionnaireData;
  step: number;
  timestamp: number;
}

const IntakeQuestionnaire = ({
  open,
  onOpenChange,
  existingData,
  onSubmit,
}: IntakeQuestionnaireProps) => {
  const [step, setStep] = useState(1);
  const [data, setData] = useState<QuestionnaireData>(initialQuestionnaireData);
  const [showWelcomePrompt, setShowWelcomePrompt] = useState(false);
  const [showExistingPrompt, setShowExistingPrompt] = useState(false);
  const [showResumePrompt, setShowResumePrompt] = useState(false);
  const [showQuickDetails, setShowQuickDetails] = useState(false);
  const [quickData, setQuickData] = useState<Partial<QuestionnaireData>>({});
  const [storedProgress, setStoredProgress] = useState<StoredProgress | null>(null);
  const [hasViewedEnhancers, setHasViewedEnhancers] = useState(false);

  // Load stored progress from localStorage
  const loadStoredProgress = useCallback((): StoredProgress | null => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored) as StoredProgress;
        // Only use if less than 24 hours old
        if (Date.now() - parsed.timestamp < 24 * 60 * 60 * 1000) {
          return parsed;
        }
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
    return null;
  }, []);

  // Save progress to localStorage
  const saveProgress = useCallback((currentData: QuestionnaireData, currentStep: number) => {
    const progress: StoredProgress = {
      data: currentData,
      step: currentStep,
      timestamp: Date.now(),
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
  }, []);

  // Clear stored progress
  const clearProgress = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  useEffect(() => {
    if (open) {
      const progress = loadStoredProgress();
      setStoredProgress(progress);
      
      if (existingData) {
        // User has saved preferences
        setShowExistingPrompt(true);
        setShowWelcomePrompt(false);
      } else if (progress && progress.step > 1) {
        // User has in-progress questionnaire
        setShowResumePrompt(true);
        setShowWelcomePrompt(false);
      } else if (!existingData && !progress) {
        // First-time user - show welcome
        setShowWelcomePrompt(true);
      } else {
        setData(initialQuestionnaireData);
        setStep(1);
      }
    }
  }, [open, existingData, loadStoredProgress]);

  // Save progress whenever data or step changes
  useEffect(() => {
    if (open && !showWelcomePrompt && !showExistingPrompt && !showResumePrompt) {
      saveProgress(data, step);
    }
  }, [data, step, open, showWelcomePrompt, showExistingPrompt, showResumePrompt, saveProgress]);

  // Reset viewed state when step changes
  useEffect(() => {
    if (step !== 6) {
      setHasViewedEnhancers(false);
    }
  }, [step]);

  const handleChange = (updates: Partial<QuestionnaireData>) => {
    setData((prev) => ({ ...prev, ...updates }));
  };

  const handleUseExisting = () => {
    if (existingData) {
      setData(existingData);
    }
    setShowExistingPrompt(false);
    setShowResumePrompt(false);
    setStep(1);
  };

  const handleShowQuickDetails = () => {
    if (!existingData) return;
    setQuickData({
      dateType: existingData.dateType || "",
      occasion: existingData.occasion || "",
      dateScheduled: existingData.dateScheduled || "",
      startTime: existingData.startTime || "",
    });
    setShowExistingPrompt(false);
    setShowQuickDetails(true);
  };

  const handleQuickGenerate = () => {
    if (!existingData) return;
    clearProgress();

    const payload: QuestionnaireData = {
      ...existingData,
      dateType: quickData.dateType || "casual",
      occasion: quickData.occasion || "none",
      dateScheduled: quickData.dateScheduled || "",
      startTime: quickData.startTime || "19:00",
      timeOfDay: quickData.startTime 
        ? parseInt(quickData.startTime.split(":")[0]) < 12 ? "morning" 
          : parseInt(quickData.startTime.split(":")[0]) < 17 ? "afternoon" 
          : parseInt(quickData.startTime.split(":")[0]) < 21 ? "evening" 
          : "night"
        : "evening",
      duration: existingData.duration || "half-day",
    };

    onSubmit(payload);
    onOpenChange(false);
    setShowQuickDetails(false);
    setStep(1);
  };

  const handleStartFresh = () => {
    setData(initialQuestionnaireData);
    clearProgress();
    setShowExistingPrompt(false);
    setShowResumePrompt(false);
    setShowQuickDetails(false);
    setStep(1);
  };

  const handleResumeProgress = () => {
    if (storedProgress) {
      setData(storedProgress.data);
      setStep(storedProgress.step);
    }
    setShowResumePrompt(false);
  };

  const handleClearAndRestart = () => {
    setData(initialQuestionnaireData);
    clearProgress();
    setStep(1);
  };

  const handleNext = () => {
    if (step < TOTAL_STEPS) {
      setStep(step + 1);
    } else {
      clearProgress(); // Clear progress on successful submit
      onSubmit(data);
      onOpenChange(false);
      setStep(1);
    }
  };

  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    }
  };

  const isStepValid = () => {
    switch (step) {
      case 1:
        return data.city.trim() !== "" && data.dateType !== "";
      case 2:
        return data.transportationMode !== "" && data.travelRadius !== "";
      case 3:
        return data.energyLevel !== "";
      case 4:
        return data.budgetRange !== "";
      case 5:
        return true;
      case 6:
        // Step 6 is fully optional - users can skip or fill in
        return true;
      default:
        return true;
    }
  };

  const renderStep = () => {
    switch (step) {
      case 1:
        return <Step1Location data={data} onChange={handleChange} />;
      case 2:
        return <Step2Transportation data={data} onChange={handleChange} />;
      case 3:
        return <Step3Energy data={data} onChange={handleChange} />;
      case 4:
        return <Step4Food data={data} onChange={handleChange} />;
      case 5:
        return <Step5DealBreakers data={data} onChange={handleChange} />;
      case 6:
        return <Step6Enhancers data={data} onChange={handleChange} />;
      default:
        return null;
    }
  };

  const handleSkipExtras = () => {
    clearProgress();
    onSubmit(data);
    onOpenChange(false);
    setStep(1);
  };

  // Welcome prompt for first-time users
  if (showWelcomePrompt) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-display text-2xl">Your Perfect Date Awaits ✨</DialogTitle>
            <DialogDescription>
              We&apos;re so excited to help you plan something special. To create a personalized itinerary that feels <em>just right</em>, we need to learn a bit about your preferences.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-3 my-4">
            <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
              <span className="text-lg">📍</span>
              <div>
                <p className="font-medium text-sm">Where you love to go</p>
                <p className="text-xs text-muted-foreground">Your favorite neighborhoods and travel style</p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
              <span className="text-lg">🍽️</span>
              <div>
                <p className="font-medium text-sm">Food & vibe preferences</p>
                <p className="text-xs text-muted-foreground">Cuisines, budget, and the energy you&apos;re after</p>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
              <span className="text-lg">✨</span>
              <div>
                <p className="font-medium text-sm">Your personal touch</p>
                <p className="text-xs text-muted-foreground">Deal-breakers, extras, and what makes it magical</p>
              </div>
            </div>
          </div>

          <p className="text-xs text-muted-foreground text-center mb-4">
            It only takes a few minutes — and we&apos;ll remember your answers for next time.
          </p>

          <Button
            className="w-full gradient-gold text-primary-foreground hover:opacity-90"
            onClick={() => {
              setShowWelcomePrompt(false);
              setData(initialQuestionnaireData);
              setStep(1);
            }}
          >
            <Sparkles className="w-4 h-4 mr-2" />
            Let&apos;s Get Started
          </Button>
        </DialogContent>
      </Dialog>
    );
  }

  // Existing preferences prompt
  if (showExistingPrompt && existingData) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-display text-2xl">Welcome Back! 👋</DialogTitle>
            <DialogDescription>
              We found your previous preferences. Would you like to use them or start fresh?
            </DialogDescription>
          </DialogHeader>
          
          <div className="bg-muted/50 rounded-lg p-4 my-4">
            <h4 className="font-medium mb-2">Your saved preferences:</h4>
            <div className="text-sm text-muted-foreground space-y-1">
              <p>📍 {existingData.city}{existingData.neighborhood ? `, ${existingData.neighborhood}` : ""}</p>
              {existingData.cuisinePreferences.length > 0 && (
                <p>🍽️ Cuisines: {existingData.cuisinePreferences.slice(0, 3).join(", ")}{existingData.cuisinePreferences.length > 3 ? "..." : ""}</p>
              )}
              {existingData.dietaryRestrictions.length > 0 && existingData.dietaryRestrictions[0] !== "none" && (
                <p>🥗 Dietary: {existingData.dietaryRestrictions.join(", ")}</p>
              )}
              {existingData.allergies.length > 0 && existingData.allergies[0] !== "none" && (
                <p>⚠️ Allergies: {existingData.allergies.join(", ")}</p>
              )}
            </div>
          </div>

          <div className="flex flex-col gap-3">
            <div className="flex flex-col sm:flex-row gap-3">
              <Button
                variant="outline"
                className="flex-1"
                onClick={handleStartFresh}
              >
                <RefreshCw className="w-4 h-4 mr-2" />
                Start Fresh
              </Button>
              <Button
                className="flex-1 gradient-gold text-primary-foreground hover:opacity-90"
                onClick={handleUseExisting}
              >
                <Sparkles className="w-4 h-4 mr-2" />
                Use & Update
              </Button>
            </div>

            <Button
              variant="outline"
              className="w-full"
              onClick={handleShowQuickDetails}
            >
              <Zap className="w-4 h-4 mr-2" />
              Quick Generate
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  // Quick details mini-step before generating
  if (showQuickDetails && existingData) {
    const TIME_OPTIONS = [
      { value: "08:00", label: "8:00 AM" },
      { value: "09:00", label: "9:00 AM" },
      { value: "10:00", label: "10:00 AM" },
      { value: "11:00", label: "11:00 AM" },
      { value: "12:00", label: "12:00 PM" },
      { value: "13:00", label: "1:00 PM" },
      { value: "14:00", label: "2:00 PM" },
      { value: "15:00", label: "3:00 PM" },
      { value: "16:00", label: "4:00 PM" },
      { value: "17:00", label: "5:00 PM" },
      { value: "18:00", label: "6:00 PM" },
      { value: "19:00", label: "7:00 PM" },
      { value: "20:00", label: "8:00 PM" },
      { value: "21:00", label: "9:00 PM" },
      { value: "22:00", label: "10:00 PM" },
    ];

    const selectedDate = quickData.dateScheduled
      ? parse(quickData.dateScheduled, "yyyy-MM-dd", new Date())
      : undefined;

    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-display text-2xl">Quick Details ⚡</DialogTitle>
            <DialogDescription>
              Just a few quick questions for this date
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6 my-4">
            {/* Date Type */}
            <div className="space-y-3">
              <Label className="text-base font-medium">💑 What kind of date?</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {DATE_TYPES.map((type) => (
                  <OptionCard
                    key={type.value}
                    label={type.label}
                    emoji={type.emoji}
                    selected={quickData.dateType === type.value}
                    onClick={() => setQuickData({ ...quickData, dateType: type.value })}
                    compact
                  />
                ))}
              </div>
            </div>

            {/* Occasion */}
            <div className="space-y-3">
              <Label className="text-base font-medium">🎉 Any special occasion?</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {OCCASIONS.map((occ) => (
                  <OptionCard
                    key={occ.value}
                    label={occ.label}
                    emoji={occ.emoji}
                    selected={quickData.occasion === occ.value}
                    onClick={() => setQuickData({ ...quickData, occasion: occ.value })}
                    compact
                  />
                ))}
              </div>
            </div>

            {/* Date & Time */}
            <div className="space-y-3">
              <Label className="text-base font-medium">📅 When?</Label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <Popover>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={cn(
                        "w-full justify-start text-left font-normal",
                        !quickData.dateScheduled && "text-muted-foreground"
                      )}
                    >
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {quickData.dateScheduled
                        ? format(selectedDate!, "PPP")
                        : "Pick a date"}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar
                      mode="single"
                      selected={selectedDate}
                      onSelect={(date) => {
                        if (date) {
                          setQuickData({
                            ...quickData,
                            dateScheduled: format(date, "yyyy-MM-dd"),
                          });
                        }
                      }}
                      disabled={(date) => date < new Date()}
                      initialFocus
                    />
                  </PopoverContent>
                </Popover>

                <Select
                  value={quickData.startTime || ""}
                  onValueChange={(val) => setQuickData({ ...quickData, startTime: val })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Start time" />
                  </SelectTrigger>
                  <SelectContent>
                    {TIME_OPTIONS.map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>

          <div className="flex gap-3">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => {
                setShowQuickDetails(false);
                setShowExistingPrompt(true);
              }}
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
            <Button
              className="flex-1 gradient-gold text-primary-foreground hover:opacity-90"
              onClick={handleQuickGenerate}
              disabled={!quickData.dateType}
            >
              <Zap className="w-4 h-4 mr-2" />
              Generate!
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  // Resume in-progress prompt
  if (showResumePrompt && storedProgress) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="font-display text-2xl">Continue Where You Left Off? 📝</DialogTitle>
            <DialogDescription>
              You have an unfinished questionnaire. Would you like to resume or start over?
            </DialogDescription>
          </DialogHeader>
          
          <div className="bg-muted/50 rounded-lg p-4 my-4">
            <h4 className="font-medium mb-2">Your progress:</h4>
            <div className="text-sm text-muted-foreground space-y-1">
              <p>📍 Step {storedProgress.step} of {TOTAL_STEPS}: {STEP_LABELS[storedProgress.step - 1]}</p>
              {storedProgress.data.city && (
                <p>🏙️ Location: {storedProgress.data.city}{storedProgress.data.neighborhood ? `, ${storedProgress.data.neighborhood}` : ""}</p>
              )}
              {storedProgress.data.dateType && (
                <p>💑 Date type: {storedProgress.data.dateType}</p>
              )}
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-3">
            <Button
              variant="outline"
              className="flex-1"
              onClick={handleStartFresh}
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Start Fresh
            </Button>
            <Button
              className="flex-1 gradient-gold text-primary-foreground hover:opacity-90"
              onClick={handleResumeProgress}
            >
              <Sparkles className="w-4 h-4 mr-2" />
              Continue
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl w-[95vw] max-h-[90vh] sm:max-h-[85vh] flex flex-col p-0 overflow-hidden">
        <div className="flex flex-col h-full min-h-0">
          {/* Fixed header - extra padding to avoid close button (top-right X) */}
          <div className="flex-shrink-0 px-3 sm:px-6 pt-12 sm:pt-10 pb-2 pr-10 sm:pr-12">
            <StepIndicator
              currentStep={step}
              totalSteps={TOTAL_STEPS}
              labels={STEP_LABELS}
            />
          </div>

          {/* Scrollable content */}
          <div 
            className="flex-1 overflow-y-auto px-3 sm:px-6 pb-4 min-h-0"
            onScroll={(e) => {
              if (step === 6) {
                const target = e.target as HTMLDivElement;
                // Mark as viewed if user scrolls past 50% of content
                if (target.scrollTop > target.scrollHeight * 0.3) {
                  setHasViewedEnhancers(true);
                }
              }
            }}
          >
            <div className="min-h-[300px] sm:min-h-[400px]">{renderStep()}</div>
          </div>

          {/* Fixed footer */}
          <div className="flex-shrink-0 px-3 sm:px-6 py-3 sm:py-4 border-t border-border bg-background">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1 sm:gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleBack}
                  disabled={step === 1}
                  className="gap-1 sm:gap-2 px-2 sm:px-4"
                >
                  <ArrowLeft className="w-4 h-4" />
                  <span className="hidden sm:inline">Back</span>
                </Button>
                
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleClearAndRestart}
                  className="text-muted-foreground hover:text-destructive gap-1 px-2 sm:px-3"
                >
                  <RotateCcw className="w-3 h-3" />
                  <span className="hidden sm:inline">Clear</span>
                </Button>
              </div>

              <div className="flex items-center gap-2">
                {step === TOTAL_STEPS && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleSkipExtras}
                    className="gap-1 px-3"
                  >
                    Skip
                  </Button>
                )}
                
                <Button
                  onClick={handleNext}
                  disabled={!isStepValid() || (step === TOTAL_STEPS && !hasViewedEnhancers)}
                  size="sm"
                  className="gap-1 sm:gap-2 gradient-gold text-primary-foreground hover:opacity-90 px-3 sm:px-4"
                >
                  {step === TOTAL_STEPS ? (
                    <>
                      <Sparkles className="w-4 h-4" />
                      <span className="hidden sm:inline">Create My Plan</span>
                      <span className="sm:hidden">Create</span>
                    </>
                  ) : (
                    <>
                      <span>Next</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </Button>
              </div>
            </div>
            
            {step === TOTAL_STEPS && !hasViewedEnhancers && (
              <p className="text-xs text-muted-foreground text-center mt-2">
                Scroll down to explore gift & conversation options, or tap Skip to continue
              </p>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default IntakeQuestionnaire;
