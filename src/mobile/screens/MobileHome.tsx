import { useState } from "react";
import { Plus, MapPin, Clock, ChevronRight, Sparkles, Star, Calendar } from "lucide-react";
import { useAuth } from "@/hooks/useAuth";
import { SavedDatePlan } from "@/hooks/useDatePlans";
import logo from "@/assets/logo.png";

interface MobileHomeProps {
  savedPlans: SavedDatePlan[];
  onCreatePlan: () => void;
}

const MobileHome = ({ savedPlans, onCreatePlan }: MobileHomeProps) => {
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

      {/* Quick create card */}
      <div className="px-5 mb-6">
        <button
          onClick={onCreatePlan}
          className="w-full p-5 rounded-2xl bg-gradient-to-br from-primary/10 via-primary/5 to-transparent border border-primary/20 text-left haptic-button active:scale-[0.98] transition-transform"
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-10 h-10 rounded-xl gradient-gold flex items-center justify-center">
                  <Sparkles className="w-5 h-5 text-primary-foreground" />
                </div>
                <span className="text-xs font-medium text-primary uppercase tracking-wide">
                  AI Powered
                </span>
              </div>
              <h3 className="text-xl font-bold mb-1">Plan a New Date</h3>
              <p className="text-muted-foreground text-sm">
                Tell us your preferences and get a personalized itinerary in seconds
              </p>
            </div>
            <ChevronRight className="w-5 h-5 text-muted-foreground mt-1" />
          </div>
        </button>
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
                onClick={onCreatePlan}
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
