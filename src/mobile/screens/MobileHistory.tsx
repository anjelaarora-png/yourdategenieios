import { useState } from "react";
import { MapPin, Clock, Star, Calendar, ChevronRight, Trash2, CheckCircle } from "lucide-react";
import { SavedDatePlan } from "@/hooks/useDatePlans";

interface MobileHistoryProps {
  plans: SavedDatePlan[];
  onViewPlan: (plan: SavedDatePlan) => void;
  onDeletePlan: (planId: string) => void;
  onMarkComplete: (planId: string) => void;
}

const MobileHistory = ({ plans, onViewPlan, onDeletePlan, onMarkComplete }: MobileHistoryProps) => {
  const [filter, setFilter] = useState<"all" | "upcoming" | "completed">("all");
  const [swipedId, setSwipedId] = useState<string | null>(null);

  const filteredPlans = plans.filter((plan) => {
    if (filter === "upcoming") return plan.status === "planned";
    if (filter === "completed") return plan.status === "completed";
    return true;
  });

  const groupedPlans = filteredPlans.reduce((acc, plan) => {
    const date = plan.created_at
      ? new Date(plan.created_at).toLocaleDateString("en-US", { month: "long", year: "numeric" })
      : "Unknown Date";
    if (!acc[date]) acc[date] = [];
    acc[date].push(plan);
    return acc;
  }, {} as Record<string, SavedDatePlan[]>);

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="px-5 pt-14 pb-4">
        <h1 className="large-title mb-1">Date History</h1>
        <p className="text-muted-foreground">All your saved date plans</p>
      </div>

      {/* Filter */}
      <div className="px-5 mb-4">
        <div className="ios-segmented">
          <button
            onClick={() => setFilter("all")}
            className={`ios-segment ${filter === "all" ? "active" : ""}`}
          >
            All ({plans.length})
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
      </div>

      {/* Plans list */}
      <div className="px-5">
        {Object.keys(groupedPlans).length === 0 ? (
          <div className="ios-card text-center py-12">
            <Calendar className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
            <p className="text-muted-foreground">No date plans found</p>
          </div>
        ) : (
          Object.entries(groupedPlans).map(([month, monthPlans]) => (
            <div key={month} className="mb-6">
              <h3 className="section-header">{month}</h3>
              <div className="space-y-2">
                {monthPlans.map((plan) => (
                  <PlanRow
                    key={plan.id}
                    plan={plan}
                    isSwiped={swipedId === plan.id}
                    onSwipe={() => setSwipedId(swipedId === plan.id ? null : plan.id)}
                    onView={() => onViewPlan(plan)}
                    onDelete={() => onDeletePlan(plan.id)}
                    onMarkComplete={() => onMarkComplete(plan.id)}
                  />
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

interface PlanRowProps {
  plan: SavedDatePlan;
  isSwiped: boolean;
  onSwipe: () => void;
  onView: () => void;
  onDelete: () => void;
  onMarkComplete: () => void;
}

const PlanRow = ({ plan, isSwiped, onSwipe, onView, onDelete, onMarkComplete }: PlanRowProps) => {
  const isCompleted = plan.status === "completed";
  const stopCount = plan.stops?.length || 0;

  return (
    <div className="relative overflow-hidden rounded-xl">
      {/* Swipe actions */}
      <div className="absolute inset-y-0 right-0 flex">
        {!isCompleted && (
          <button
            onClick={onMarkComplete}
            className="w-20 bg-green-500 flex items-center justify-center text-white"
          >
            <CheckCircle className="w-6 h-6" />
          </button>
        )}
        <button
          onClick={onDelete}
          className="w-20 bg-red-500 flex items-center justify-center text-white"
        >
          <Trash2 className="w-6 h-6" />
        </button>
      </div>

      {/* Card content */}
      <button
        onClick={isSwiped ? onSwipe : onView}
        onContextMenu={(e) => {
          e.preventDefault();
          onSwipe();
        }}
        className={`ios-card w-full text-left haptic-button transition-transform ${
          isSwiped ? "-translate-x-40" : ""
        }`}
      >
        <div className="flex items-start gap-3">
          <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
            <span className="text-2xl">{plan.stops?.[0]?.emoji || "✨"}</span>
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="font-semibold truncate">{plan.title}</h3>
              {plan.rating && (
                <div className="flex items-center gap-0.5 shrink-0">
                  <Star className="w-3 h-3 text-amber-500 fill-amber-500" />
                  <span className="text-xs">{plan.rating}</span>
                </div>
              )}
            </div>

            <p className="text-sm text-muted-foreground truncate mb-2">{plan.tagline}</p>

            <div className="flex items-center gap-3 text-xs text-muted-foreground">
              <span className="flex items-center gap-1">
                <MapPin className="w-3 h-3" />
                {stopCount} stops
              </span>
              <span className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {plan.total_duration}
              </span>
              {isCompleted && (
                <span className="px-2 py-0.5 bg-green-500/10 text-green-600 rounded-full font-medium">
                  Done
                </span>
              )}
            </div>
          </div>

          <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0 mt-3" />
        </div>
      </button>
    </div>
  );
};

export default MobileHistory;
