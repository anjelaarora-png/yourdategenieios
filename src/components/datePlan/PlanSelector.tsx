import { DatePlan } from "@/types/datePlan";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { Check, MapPin, Clock, DollarSign } from "lucide-react";

interface PlanSelectorProps {
  plans: DatePlan[];
  selectedIndex: number;
  onSelect: (index: number) => void;
}

const PlanSelector = ({ plans, selectedIndex, onSelect }: PlanSelectorProps) => {
  if (plans.length <= 1) return null;

  return (
    <div className="mb-6">
      <h3 className="text-sm font-medium text-muted-foreground mb-3">Choose your date style:</h3>
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {plans.map((plan, index) => {
          const isSelected = index === selectedIndex;
          const stops = plan.stops ?? [];
          const validatedCount = stops.filter(s => s.validated).length;
          const totalStops = stops.length;

          return (
            <button
              key={index}
              onClick={() => onSelect(index)}
              className={cn(
                "relative p-4 rounded-lg border-2 text-left transition-all",
                "hover:border-primary/50 hover:bg-primary/5",
                isSelected
                  ? "border-primary bg-primary/10 shadow-md"
                  : "border-border bg-card"
              )}
            >
              {isSelected && (
                <div className="absolute top-2 right-2">
                  <Check className="w-5 h-5 text-primary" />
                </div>
              )}

              <Badge variant="secondary" className="mb-2 text-xs">
                Option {String.fromCharCode(65 + index)}
              </Badge>

              <h4 className="font-display font-semibold text-sm mb-1 pr-6">
                {plan.optionLabel || plan.title}
              </h4>

              <p className="text-xs text-muted-foreground line-clamp-2 mb-3">
                {plan.tagline}
              </p>

              <div className="flex flex-wrap gap-2 text-xs text-muted-foreground">
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {plan.totalDuration}
                </span>
                <span className="flex items-center gap-1">
                  <DollarSign className="w-3 h-3" />
                  {plan.estimatedCost}
                </span>
              </div>

              {validatedCount > 0 && (
                <div className="mt-2 flex items-center gap-1 text-xs text-green-600">
                  <MapPin className="w-3 h-3" />
                  {validatedCount}/{totalStops} venues verified
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default PlanSelector;
