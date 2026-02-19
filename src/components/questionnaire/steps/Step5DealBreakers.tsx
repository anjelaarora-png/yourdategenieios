import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import OptionCard from "../OptionCard";
import { QuestionnaireData, COMMON_ALLERGIES, HARD_NOS, ACCESSIBILITY_OPTIONS, SMOKING_PREFERENCES, SMOKING_ACTIVITIES } from "../types";

interface Step4Props {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const Step4DealBreakers = ({ data, onChange }: Step4Props) => {
  const toggleAllergy = (value: string) => {
    if (value === "none") {
      onChange({ allergies: ["none"] });
      return;
    }
    const current = data.allergies.filter((v) => v !== "none");
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ allergies: updated });
  };

  const toggleHardNo = (value: string) => {
    const current = data.hardNos;
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ hardNos: updated });
  };

  const toggleAccessibility = (value: string) => {
    if (value === "none") {
      onChange({ accessibilityNeeds: ["none"] });
      return;
    }
    const current = data.accessibilityNeeds.filter((v) => v !== "none");
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ accessibilityNeeds: updated });
  };

  const toggleSmokingActivity = (value: string) => {
    if (value === "none") {
      onChange({ smokingActivities: ["none"] });
      return;
    }
    const current = (data.smokingActivities || []).filter((v) => v !== "none");
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ smokingActivities: updated });
  };

  return (
    <div className="space-y-5 sm:space-y-8">
      <div className="text-center mb-2 sm:mb-4">
        <h2 className="font-display text-xl sm:text-3xl mb-1 sm:mb-2">Deal Breakers</h2>
        <p className="text-muted-foreground text-sm sm:text-base">What should we definitely avoid?</p>
      </div>

      {/* Allergies */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          ⚠️ Any food allergies? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(important!)</span>
        </Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {COMMON_ALLERGIES.map((allergy) => (
            <OptionCard
              key={allergy.value}
              selected={data.allergies.includes(allergy.value)}
              onClick={() => toggleAllergy(allergy.value)}
              emoji={allergy.emoji}
              label={allergy.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Hard No's */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          🚫 Hard no's? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(pick any)</span>
        </Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {HARD_NOS.map((item) => (
            <OptionCard
              key={item.value}
              selected={data.hardNos.includes(item.value)}
              onClick={() => toggleHardNo(item.value)}
              emoji={item.emoji}
              label={item.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Accessibility & Comfort Needs */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          ♿ Accessibility <span className="text-muted-foreground font-normal text-xs sm:text-sm">(select any)</span>
        </Label>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:gap-3">
          {ACCESSIBILITY_OPTIONS.map((option) => (
            <OptionCard
              key={option.value}
              selected={data.accessibilityNeeds.includes(option.value)}
              onClick={() => toggleAccessibility(option.value)}
              emoji={option.emoji}
              label={option.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Smoking Preference */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">🌬️ Smoke & Vibe</Label>
        <p className="text-xs sm:text-sm text-muted-foreground -mt-1">Venue preference</p>
        <div className="grid grid-cols-3 gap-2 sm:gap-3">
          {SMOKING_PREFERENCES.map((option) => (
            <OptionCard
              key={option.value}
              selected={data.smokingPreference === option.value}
              onClick={() => onChange({ smokingPreference: option.value })}
              emoji={option.emoji}
              label={option.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Smoking Activities */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          💨 Interested in? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(optional)</span>
        </Label>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:gap-3">
          {SMOKING_ACTIVITIES.map((option) => (
            <OptionCard
              key={option.value}
              selected={(data.smokingActivities || []).includes(option.value)}
              onClick={() => toggleSmokingActivity(option.value)}
              emoji={option.emoji}
              label={option.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Additional Notes */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">📝 Anything else?</Label>
        <Textarea
          placeholder="E.g., Partner loves surprises, we have a dog that needs walking by 9pm..."
          value={data.additionalNotes}
          onChange={(e) => onChange({ additionalNotes: e.target.value })}
          className="bg-card border-border min-h-[80px] sm:min-h-[100px] resize-none text-sm"
        />
      </div>
    </div>
  );
};

export default Step4DealBreakers;
