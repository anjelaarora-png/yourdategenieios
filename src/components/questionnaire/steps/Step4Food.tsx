import { Label } from "@/components/ui/label";
import OptionCard from "../OptionCard";
import {
  QuestionnaireData,
  CUISINES,
  DIETARY_RESTRICTIONS,
  DRINK_PREFERENCES,
  BUDGET_RANGES,
} from "../types";

interface Step3Props {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const Step3Food = ({ data, onChange }: Step3Props) => {
  const toggleCuisine = (value: string) => {
    const current = data.cuisinePreferences;
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ cuisinePreferences: updated });
  };

  const toggleDietary = (value: string) => {
    if (value === "none") {
      onChange({ dietaryRestrictions: ["none"] });
      return;
    }
    const current = data.dietaryRestrictions.filter((v) => v !== "none");
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    onChange({ dietaryRestrictions: updated });
  };

  return (
    <div className="space-y-5 sm:space-y-8">
      <div className="text-center mb-2 sm:mb-4">
        <h2 className="font-display text-xl sm:text-3xl mb-1 sm:mb-2">Food & Drinks</h2>
        <p className="text-muted-foreground text-sm sm:text-base">What's on the menu?</p>
      </div>

      {/* Cuisines */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          🍽️ Favorite cuisines? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(pick any)</span>
        </Label>
        <div className="grid grid-cols-3 sm:grid-cols-5 gap-2 sm:gap-3">
          {CUISINES.map((cuisine) => (
            <OptionCard
              key={cuisine.value}
              selected={data.cuisinePreferences.includes(cuisine.value)}
              onClick={() => toggleCuisine(cuisine.value)}
              emoji={cuisine.emoji}
              label={cuisine.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Dietary Restrictions */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          🥗 Any dietary needs? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(pick any)</span>
        </Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {DIETARY_RESTRICTIONS.map((diet) => (
            <OptionCard
              key={diet.value}
              selected={data.dietaryRestrictions.includes(diet.value)}
              onClick={() => toggleDietary(diet.value)}
              emoji={diet.emoji}
              label={diet.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Drink Preferences */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">
          🥂 Preferred beverages? <span className="text-muted-foreground font-normal text-xs sm:text-sm">(pick any)</span>
        </Label>
        <div className="grid grid-cols-3 sm:grid-cols-5 gap-2 sm:gap-3">
          {DRINK_PREFERENCES.map((drink) => (
            <OptionCard
              key={drink.value}
              selected={data.drinkPreferences.includes(drink.value)}
              onClick={() => {
                const current = data.drinkPreferences;
                const updated = current.includes(drink.value)
                  ? current.filter((v) => v !== drink.value)
                  : [...current, drink.value];
                onChange({ drinkPreferences: updated });
              }}
              emoji={drink.emoji}
              label={drink.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Budget */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">💰 Budget for the date?</Label>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
          {BUDGET_RANGES.map((budget) => (
            <OptionCard
              key={budget.value}
              selected={data.budgetRange === budget.value}
              onClick={() => onChange({ budgetRange: budget.value })}
              label={budget.label}
              description={budget.desc}
              compact
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Step3Food;
