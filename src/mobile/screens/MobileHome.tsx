import { useState } from "react";
import { Plus, MapPin, Clock, ChevronRight, Sparkles, Star, Calendar, RotateCcw, FileText, Zap } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { SavedDatePlan } from "@/hooks/useDatePlans";
import { QuestionnaireData } from "@/components/questionnaire/types";
import logo from "@/assets/logo.png";

const QUESTIONNAIRE_PROGRESS_KEY = "dateGenie_questionnaireProgress";

export type PlanIntent = "fresh" | "useLast" | "resume";

interface MobileHomeProps {
  savedPlans: SavedDatePlan[];
  onCreatePlan: (intent?: PlanIntent) => void;
  hasPendingPlans?: boolean;
  onReviewUnsavedPlans?: () => void;
  hasSavedPreferences?: boolean;
  savedPreferences?: QuestionnaireData | null;
}

const MobileHome = ({ 
  savedPlans, 
  onCreatePlan, 
  hasPendingPlans = false, 
  onReviewUnsavedPlans,
  hasSavedPreferences = false,
  savedPreferences,
}: MobileHomeProps) => {
  const hasUnsavedProgress = (() => {
    try {
      const stored = localStorage.getItem(QUESTIONNAIRE_PROGRESS_KEY);
      if (!stored) return false;
      const parsed = JSON.parse(stored);
      return Date.now() - parsed.timestamp < 24 * 60 * 60 * 1000 && parsed.step > 1;
    } catch {
      return false;
    }
  })();
  const { user } = useAuth();
  const [filter, setFilter] = useState<"all" | "upcoming" | "completed">("all");

  const firstName = user?.email?.split("@")[0] || "there";

  const filteredPlans = savedPlans.filter((plan) => {
    if (filter === "upcoming") return plan.status === "planned";
    if (filter === "completed") return plan.status === "completed";
    return true;
  });

  const upcomingCount = savedPlans.filter((p) => p.status === "planned").length;

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="px-5 pt-14 pb-4">
        <div className="flex items-center justify-between mb-6">
          <img src={logo} alt="Your Date Genie" className="h-9 w-auto" />
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
            <span className="text-primary font-semibold text-sm">
              {firstName.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>

        {/* Greeting */}
        <h1 className="large-title mb-1">
          Hi, {firstName.charAt(0).toUpperCase() + firstName.slice(1)} 👋
        </h1>
        <p className="text-muted-foreground text-lg">
          Ready for your next adventure?
        </p>
      </div>

      {/* Unsaved plans banner */}
      {hasPendingPlans && onReviewUnsavedPlans && (
        <div className="px-5 mb-4">
          <div className="p-4 rounded-2xl bg-primary/10 border border-primary/30">
            <p className="font-medium text-primary text-sm mb-1">You have unsaved date plans!</p>
            <p className="text-xs text-muted-foreground mb-3">
              Pick up where you left off and save your plans.
            </p>
            <button
              onClick={onReviewUnsavedPlans}
              className="ios-button ios-button-primary w-full flex items-center justify-center gap-2 text-sm"
            >
              <FileText className="w-4 h-4" />
              Review Plans
            </button>
          </div>
        </div>
      )}

      {/* Plan your next date - with options for returning users */}
      <div className="px-5 mb-6">
        <div className="w-full p-5 rounded-2xl bg-gradient-to-br from-primary/10 via-primary/5 to-transparent border border-primary/20">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-10 h-10 rounded-xl gradient-gold flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xs font-medium text-primary uppercase tracking-wide">
              AI Powered
            </span>
          </div>
          <h3 className="text-xl font-bold mb-2">Plan Your Next Date</h3>
          
          {(hasSavedPreferences || hasUnsavedProgress) ? (
            <div className="space-y-2 mt-3">
              <button
                onClick={() => onCreatePlan("fresh")}
                className="w-full flex items-center gap-3 p-3 rounded-xl border border-border bg-card/50 text-left haptic-button active:scale-[0.99]"
              >
                <RotateCcw className="w-5 h-5 text-primary shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-foreground">Start Fresh</p>
                  <p className="text-xs text-muted-foreground">New preferences for this date</p>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
              </button>
              {hasSavedPreferences && savedPreferences && (
                <button
                  onClick={() => onCreatePlan("useLast")}
                  className="w-full flex items-center gap-3 p-3 rounded-xl border border-border bg-card/50 text-left haptic-button active:scale-[0.99]"
                >
                  <Zap className="w-5 h-5 text-primary shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-foreground">Use & Generate from Last Plan</p>
                    <p className="text-xs text-muted-foreground">
                      {savedPreferences.city}{savedPreferences.neighborhood ? `, ${savedPreferences.neighborhood}` : ""}
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
                </button>
              )}
              {hasUnsavedProgress && (
                <button
                  onClick={() => onCreatePlan("resume")}
                  className="w-full flex items-center gap-3 p-3 rounded-xl border border-primary/40 bg-primary/5 text-left haptic-button active:scale-[0.99]"
                >
                  <FileText className="w-5 h-5 text-primary shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-foreground">Pick Up Where You Left Off</p>
                    <p className="text-xs text-muted-foreground">Resume your unfinished questionnaire</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-primary shrink-0" />
                </button>
              )}
            </div>
          ) : (
            <button
              onClick={() => onCreatePlan()}
              className="w-full flex items-start justify-between mt-2 text-left haptic-button active:scale-[0.98] transition-transform"
            >
              <p className="text-muted-foreground text-sm flex-1">
                Tell us your preferences and get a personalized itinerary in seconds
              </p>
              <ChevronRight className="w-5 h-5 text-muted-foreground mt-1 shrink-0" />
            </button>
          )}
        </div>
      </div>

      {/* Stats row */}
      <div className="px-5 mb-6">
        <div className="grid grid-cols-3 gap-3">
          <div className="ios-card text-center">
            <p className="text-2xl font-bold text-primary">{savedPlans.length}</p>
            <p className="text-xs text-muted-foreground">Total Plans</p>
          </div>
          <div className="ios-card text-center">
            <p className="text-2xl font-bold text-blue-500">{upcomingCount}</p>
            <p className="text-xs text-muted-foreground">Upcoming</p>
          </div>
          <div className="ios-card text-center">
            <p className="text-2xl font-bold text-green-500">
              {savedPlans.filter((p) => p.status === "completed").length}
            </p>
            <p className="text-xs text-muted-foreground">Completed</p>
          </div>
        </div>
      </div>

      {/* Recent plans section */}
      <div className="px-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Your Date Plans</h2>
        </div>

        {/* Filter tabs */}
        <div className="ios-segmented mb-4">
          <button
            onClick={() => setFilter("all")}
            className={`ios-segment ${filter === "all" ? "active" : ""}`}
          >
            All
          </button>
          <button
            onClick={() => setFilter("upcoming")}
            className={`ios-segment ${filter === "upcoming" ? "active" : ""}`}
          >
            Upcoming
          </button>
          <button
            onClick={() => setFilter("completed")}
            className={`ios-segment ${filter === "completed" ? "active" : ""}`}
          >
            Completed
          </button>
        </div>

        {/* Plans list */}
        {filteredPlans.length === 0 ? (
          <div className="ios-card text-center py-12">
            <div className="w-16 h-16 rounded-full bg-muted mx-auto mb-4 flex items-center justify-center">
              <Calendar className="w-8 h-8 text-muted-foreground" />
            </div>
            <p className="text-muted-foreground mb-4">
              {filter === "all"
                ? "No date plans yet"
                : filter === "upcoming"
                ? "No upcoming dates"
                : "No completed dates"}
            </p>
            {filter === "all" && (
              <button
                onClick={() => onCreatePlan()}
                className="text-primary font-medium flex items-center gap-1 mx-auto"
              >
                <Plus className="w-4 h-4" />
                Create your first plan
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            {filteredPlans.slice(0, 5).map((plan) => (
              <DatePlanCard key={plan.id} plan={plan} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

interface DatePlanCardProps {
  plan: SavedDatePlan;
}

const DatePlanCard = ({ plan }: DatePlanCardProps) => {
  const stopCount = plan.stops?.length || 0;
  const isCompleted = plan.status === "completed";

  return (
    <button className="ios-card w-full text-left haptic-button active:scale-[0.98] transition-transform">
      <div className="flex items-start gap-3">
        {/* Emoji indicator */}
        <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
          <span className="text-2xl">{plan.stops?.[0]?.emoji || "✨"}</span>
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-semibold truncate">{plan.title}</h3>
            {plan.rating && (
              <div className="flex items-center gap-0.5 shrink-0">
                <Star className="w-3 h-3 text-amber-500 fill-amber-500" />
                <span className="text-xs text-muted-foreground">{plan.rating}</span>
              </div>
            )}
          </div>

          <p className="text-sm text-muted-foreground truncate mb-2">{plan.tagline}</p>

          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <MapPin className="w-3 h-3" />
              {stopCount} {stopCount === 1 ? "stop" : "stops"}
            </span>
            <span className="flex items-center gap-1">
              <Clock className="w-3 h-3" />
              {plan.total_duration}
            </span>
            {isCompleted && (
              <span className="px-2 py-0.5 bg-green-500/10 text-green-600 rounded-full text-xs font-medium">
                Completed
              </span>
            )}
          </div>
        </div>

        <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0 mt-3" />
      </div>
    </button>
  );
};

export default MobileHome;
