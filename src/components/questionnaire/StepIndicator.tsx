import { cn } from "@/lib/utils";
import { Check } from "lucide-react";

interface StepIndicatorProps {
  currentStep: number;
  totalSteps: number;
  labels: string[];
}

const StepIndicator = ({ currentStep, totalSteps, labels }: StepIndicatorProps) => {
  return (
    <div className="w-full mb-4 sm:mb-6">
      <div className="flex items-center justify-between">
        {Array.from({ length: totalSteps }, (_, i) => i + 1).map((step) => (
          <div key={step} className="flex items-center flex-1 last:flex-none">
            <div className="flex flex-col items-center">
              <div
                className={cn(
                  "w-8 h-8 sm:w-10 sm:h-10 rounded-full flex items-center justify-center font-semibold text-sm sm:text-base transition-all",
                  step < currentStep
                    ? "gradient-gold text-primary-foreground"
                    : step === currentStep
                    ? "border-2 border-primary bg-primary/10 text-primary"
                    : "border-2 border-muted bg-muted/50 text-muted-foreground"
                )}
              >
                {step < currentStep ? (
                  <Check className="w-4 h-4 sm:w-5 sm:h-5" />
                ) : (
                  step
                )}
              </div>
              <span
                className={cn(
                  "text-[10px] sm:text-xs mt-1 sm:mt-2 text-center max-w-[50px] sm:max-w-none truncate",
                  step === currentStep
                    ? "text-primary font-medium"
                    : "text-muted-foreground"
                )}
              >
                {labels[step - 1]}
              </span>
            </div>
            {step < totalSteps && (
              <div
                className={cn(
                  "flex-1 h-0.5 mx-1 sm:mx-2",
                  step < currentStep ? "bg-primary" : "bg-muted"
                )}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default StepIndicator;
