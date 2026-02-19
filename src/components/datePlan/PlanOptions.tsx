import { useState } from "react";
import { DatePlan, DatePlanStop } from "@/types/datePlan";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Check, Clock, DollarSign, MapPin } from "lucide-react";
import { cn } from "@/lib/utils";

interface PlanOptionsProps {
  options: DatePlanStop[];
  timeSlot: string;
  onSelect: (stop: DatePlanStop) => void;
  selectedStop?: DatePlanStop;
}

const PlanOptions = ({ options, timeSlot, onSelect, selectedStop }: PlanOptionsProps) => {
  return (
    <div className="space-y-4">
      <h3 className="font-display text-lg flex items-center gap-2">
        <Clock className="w-4 h-4 text-primary" />
        Options for {timeSlot}
      </h3>
      
      <div className="grid gap-4 sm:grid-cols-3">
        {options.map((option, index) => {
          const isSelected = selectedStop?.name === option.name;
          
          return (
            <Card
              key={index}
              className={cn(
                "cursor-pointer transition-all hover:shadow-lg",
                isSelected && "ring-2 ring-primary bg-primary/5"
              )}
              onClick={() => onSelect(option)}
            >
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between">
                  <span className="text-2xl">{option.emoji}</span>
                  {isSelected && (
                    <div className="w-6 h-6 rounded-full gradient-gold flex items-center justify-center">
                      <Check className="w-4 h-4 text-primary-foreground" />
                    </div>
                  )}
                </div>
                <CardTitle className="font-display text-lg">{option.name}</CardTitle>
                <p className="text-sm text-muted-foreground">{option.venueType}</p>
              </CardHeader>
              <CardContent className="space-y-2">
                <p className="text-sm">{option.description}</p>
                <div className="flex items-center gap-4 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {option.duration}
                  </span>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
};

export default PlanOptions;
