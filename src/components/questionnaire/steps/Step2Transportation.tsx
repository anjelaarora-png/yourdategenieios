import { QuestionnaireData, TRANSPORTATION_MODES, TRAVEL_RADIUS } from "../types";
import OptionCard from "../OptionCard";
import { Car, MapPin } from "lucide-react";

interface Step2Props {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const Step2Transportation = ({ data, onChange }: Step2Props) => {
  return (
    <div className="space-y-5 sm:space-y-8 animate-fade-in py-2 sm:py-4">
      {/* Transportation Mode */}
      <div className="space-y-3 sm:space-y-4">
        <div className="flex items-center gap-2">
          <Car className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
          <h3 className="font-semibold text-base sm:text-lg">How will you get around?</h3>
        </div>
        <p className="text-xs sm:text-sm text-muted-foreground">
          This helps us plan routes and estimate travel times.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:gap-3">
          {TRANSPORTATION_MODES.map((mode) => (
            <OptionCard
              key={mode.value}
              label={mode.label}
              emoji={mode.emoji}
              selected={data.transportationMode === mode.value}
              onClick={() => onChange({ transportationMode: mode.value })}
              description={mode.desc}
              compact
            />
          ))}
        </div>
      </div>

      {/* Travel Radius */}
      <div className="space-y-3 sm:space-y-4">
        <div className="flex items-center gap-2">
          <MapPin className="w-4 h-4 sm:w-5 sm:h-5 text-primary" />
          <h3 className="font-semibold text-base sm:text-lg">How far are you willing to travel?</h3>
        </div>
        <p className="text-xs sm:text-sm text-muted-foreground">
          Set your comfort zone for the date.
        </p>
        <div className="grid grid-cols-2 gap-2 sm:gap-3">
          {TRAVEL_RADIUS.map((radius) => (
            <OptionCard
              key={radius.value}
              label={radius.label}
              emoji={radius.emoji}
              selected={data.travelRadius === radius.value}
              onClick={() => onChange({ travelRadius: radius.value })}
              description={`${radius.distance}`}
              compact
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Step2Transportation;