import { Label } from "@/components/ui/label";
import OptionCard from "../OptionCard";
import {
  QuestionnaireData,
  ENERGY_LEVELS,
  ACTIVITIES,
  TIME_OF_DAY,
  DURATIONS,
} from "../types";

interface Step2Props {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const Step2Energy = ({ data, onChange }: Step2Props) => {
  const toggleActivity = (value: string) => {
    const current = data.activityPreferences;
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ activityPreferences: updated });
  };

  return (
    <div className="space-y-5 sm:space-y-8">
      <div className="text-center mb-2 sm:mb-4">
        <h2 className="font-display text-xl sm:text-3xl mb-1 sm:mb-2">Vibe Check</h2>
        <p className="text-muted-foreground text-sm sm:text-base">Set the energy for your date</p>
      </div>

      {/* Energy Level */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">⚡ What's the energy level?</Label>
        <div className="grid grid-cols-2 gap-2 sm:gap-3">
          {ENERGY_LEVELS.map((level) => (
            <OptionCard
              key={level.value}
              selected={data.energyLevel === level.value}
              onClick={() => onChange({ energyLevel: level.value })}
              emoji={level.emoji}
              label={level.label}
              description={level.desc}
              compact
            />
          ))}
        </div>
      </div>

      {/* Activities */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          🎯 What sounds fun? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(pick any)</span>
        </Label>
        <div className="grid grid-cols-3 sm:grid-cols-4 gap-2 sm:gap-3">
          {ACTIVITIES.map((activity) => (
            <OptionCard
              key={activity.value}
              selected={data.activityPreferences.includes(activity.value)}
              onClick={() => toggleActivity(activity.value)}
              emoji={activity.emoji}
              label={activity.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Time of Day */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">🕐 When are you thinking?</Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {TIME_OF_DAY.map((time) => (
            <OptionCard
              key={time.value}
              selected={data.timeOfDay === time.value}
              onClick={() => onChange({ timeOfDay: time.value })}
              emoji={time.emoji}
              label={time.label}
              description={time.time}
              compact
            />
          ))}
        </div>
      </div>

      {/* Duration */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">⏱️ How long do you have?</Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {DURATIONS.map((duration) => (
            <OptionCard
              key={duration.value}
              selected={data.duration === duration.value}
              onClick={() => onChange({ duration: duration.value })}
              label={duration.label}
              description={duration.time}
              compact
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Step2Energy;
