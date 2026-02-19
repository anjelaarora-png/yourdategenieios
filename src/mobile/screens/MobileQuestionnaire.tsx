import { useState, useRef, useEffect } from "react";
import { ArrowLeft, ArrowRight, Sparkles, MapPin, Car, Zap, UtensilsCrossed, ShieldAlert, Gift, Check } from "lucide-react";
import { QuestionnaireData, initialQuestionnaireData, DATE_TYPES, OCCASIONS, ENERGY_LEVELS, ACTIVITIES, TIME_OF_DAY, DURATIONS, CUISINES, DIETARY_RESTRICTIONS, BUDGET_RANGES, TRANSPORTATION_MODES, TRAVEL_RADIUS, COMMON_ALLERGIES, HARD_NOS } from "@/components/questionnaire/types";

interface MobileQuestionnaireProps {
  onSubmit: (data: QuestionnaireData) => void;
  onBack: () => void;
  isGenerating: boolean;
}

const STEPS = [
  { id: "location", icon: MapPin, title: "Where & When", color: "text-blue-500" },
  { id: "transport", icon: Car, title: "Getting Around", color: "text-purple-500" },
  { id: "vibe", icon: Zap, title: "The Vibe", color: "text-amber-500" },
  { id: "food", icon: UtensilsCrossed, title: "Food & Drinks", color: "text-rose-500" },
  { id: "avoid", icon: ShieldAlert, title: "Deal Breakers", color: "text-red-500" },
  { id: "extras", icon: Gift, title: "Finishing Touch", color: "text-pink-500" },
];

const MobileQuestionnaire = ({ onSubmit, onBack, isGenerating }: MobileQuestionnaireProps) => {
  const [step, setStep] = useState(0);
  const [data, setData] = useState<QuestionnaireData>(initialQuestionnaireData);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    contentRef.current?.scrollTo({ top: 0, behavior: "smooth" });
  }, [step]);

  const handleChange = (updates: Partial<QuestionnaireData>) => {
    setData((prev) => ({ ...prev, ...updates }));
  };

  const toggleArrayItem = (key: keyof QuestionnaireData, value: string) => {
    const current = data[key] as string[];
    const updated = current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value];
    handleChange({ [key]: updated });
  };

  const canProceed = () => {
    switch (step) {
      case 0:
        return data.city.trim() !== "" && data.dateType !== "";
      case 1:
        return data.transportationMode !== "" && data.travelRadius !== "";
      case 2:
        return data.energyLevel !== "" && data.timeOfDay !== "";
      case 3:
        return data.budgetRange !== "";
      default:
        return true;
    }
  };

  const handleNext = () => {
    if (step < STEPS.length - 1) {
      setStep(step + 1);
    } else {
      onSubmit(data);
    }
  };

  const handlePrev = () => {
    if (step > 0) {
      setStep(step - 1);
    } else {
      onBack();
    }
  };

  const progress = ((step + 1) / STEPS.length) * 100;
  const CurrentIcon = STEPS[step].icon;

  return (
    <div className="min-h-screen flex flex-col bg-background">
      {/* Header */}
      <div className="px-5 pt-14 pb-4">
        <div className="flex items-center justify-between mb-4">
          <button onClick={handlePrev} className="haptic-button p-2 -ml-2">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <span className="text-sm text-muted-foreground">
            Step {step + 1} of {STEPS.length}
          </span>
          <div className="w-10" />
        </div>

        {/* Progress bar */}
        <div className="h-1 bg-muted rounded-full overflow-hidden">
          <div
            className="h-full gradient-gold transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Step header */}
      <div className="px-5 pb-4">
        <div className="flex items-center gap-3 mb-2">
          <div className={`w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center`}>
            <CurrentIcon className={`w-5 h-5 ${STEPS[step].color}`} />
          </div>
          <h1 className="text-2xl font-bold">{STEPS[step].title}</h1>
        </div>
      </div>

      {/* Content */}
      <div ref={contentRef} className="flex-1 overflow-y-auto px-5 pb-32">
        {step === 0 && <StepLocation data={data} onChange={handleChange} />}
        {step === 1 && <StepTransport data={data} onChange={handleChange} />}
        {step === 2 && <StepVibe data={data} onChange={handleChange} onToggle={toggleArrayItem} />}
        {step === 3 && <StepFood data={data} onChange={handleChange} onToggle={toggleArrayItem} />}
        {step === 4 && <StepAvoid data={data} onToggle={toggleArrayItem} />}
        {step === 5 && <StepExtras data={data} onChange={handleChange} />}
      </div>

      {/* Fixed bottom action */}
      <div className="fixed bottom-0 left-0 right-0 px-5 pb-8 pt-4 bg-gradient-to-t from-background via-background to-transparent">
        <button
          onClick={handleNext}
          disabled={!canProceed() || isGenerating}
          className="ios-button ios-button-primary w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {isGenerating ? (
            <>
              <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
              Creating Your Plan...
            </>
          ) : step === STEPS.length - 1 ? (
            <>
              <Sparkles className="w-5 h-5" />
              Generate Date Plan
            </>
          ) : (
            <>
              Continue
              <ArrowRight className="w-5 h-5" />
            </>
          )}
        </button>
      </div>
    </div>
  );
};

// Step 1: Location
const StepLocation = ({ data, onChange }: { data: QuestionnaireData; onChange: (u: Partial<QuestionnaireData>) => void }) => (
  <div className="space-y-6">
    <div>
      <label className="text-sm font-medium text-muted-foreground mb-2 block">City *</label>
      <input
        type="text"
        value={data.city}
        onChange={(e) => onChange({ city: e.target.value })}
        placeholder="e.g., Austin, TX"
        className="ios-input"
      />
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-2 block">Neighborhood (optional)</label>
      <input
        type="text"
        value={data.neighborhood}
        onChange={(e) => onChange({ neighborhood: e.target.value })}
        placeholder="e.g., Downtown, East Side"
        className="ios-input"
      />
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">What kind of date? *</label>
      <div className="grid grid-cols-2 gap-2">
        {DATE_TYPES.map((type) => (
          <OptionChip
            key={type.value}
            emoji={type.emoji}
            label={type.label}
            selected={data.dateType === type.value}
            onClick={() => onChange({ dateType: type.value })}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Special occasion?</label>
      <div className="grid grid-cols-2 gap-2">
        {OCCASIONS.map((occ) => (
          <OptionChip
            key={occ.value}
            emoji={occ.emoji}
            label={occ.label}
            selected={data.occasion === occ.value}
            onClick={() => onChange({ occasion: occ.value })}
          />
        ))}
      </div>
    </div>
  </div>
);

// Step 2: Transport
const StepTransport = ({ data, onChange }: { data: QuestionnaireData; onChange: (u: Partial<QuestionnaireData>) => void }) => (
  <div className="space-y-6">
    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">How will you travel? *</label>
      <div className="space-y-2">
        {TRANSPORTATION_MODES.map((mode) => (
          <OptionRow
            key={mode.value}
            emoji={mode.emoji}
            label={mode.label}
            description={mode.desc}
            selected={data.transportationMode === mode.value}
            onClick={() => onChange({ transportationMode: mode.value })}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">How far will you travel? *</label>
      <div className="space-y-2">
        {TRAVEL_RADIUS.map((radius) => (
          <OptionRow
            key={radius.value}
            emoji={radius.emoji}
            label={radius.label}
            description={`${radius.distance} - ${radius.desc}`}
            selected={data.travelRadius === radius.value}
            onClick={() => onChange({ travelRadius: radius.value })}
          />
        ))}
      </div>
    </div>
  </div>
);

// Step 3: Vibe
const StepVibe = ({ data, onChange, onToggle }: { data: QuestionnaireData; onChange: (u: Partial<QuestionnaireData>) => void; onToggle: (key: keyof QuestionnaireData, value: string) => void }) => (
  <div className="space-y-6">
    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Energy level *</label>
      <div className="space-y-2">
        {ENERGY_LEVELS.map((level) => (
          <OptionRow
            key={level.value}
            emoji={level.emoji}
            label={level.label}
            description={level.desc}
            selected={data.energyLevel === level.value}
            onClick={() => onChange({ energyLevel: level.value })}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Time of day *</label>
      <div className="grid grid-cols-2 gap-2">
        {TIME_OF_DAY.map((time) => (
          <OptionChip
            key={time.value}
            emoji={time.emoji}
            label={`${time.label} (${time.time})`}
            selected={data.timeOfDay === time.value}
            onClick={() => onChange({ timeOfDay: time.value })}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Duration</label>
      <div className="grid grid-cols-2 gap-2">
        {DURATIONS.map((d) => (
          <OptionChip
            key={d.value}
            label={`${d.label} (${d.time})`}
            selected={data.duration === d.value}
            onClick={() => onChange({ duration: d.value })}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Preferred activities (select all that apply)</label>
      <div className="grid grid-cols-2 gap-2">
        {ACTIVITIES.map((act) => (
          <OptionChip
            key={act.value}
            emoji={act.emoji}
            label={act.label}
            selected={data.activityPreferences.includes(act.value)}
            onClick={() => onToggle("activityPreferences", act.value)}
          />
        ))}
      </div>
    </div>
  </div>
);

// Step 4: Food
const StepFood = ({ data, onChange, onToggle }: { data: QuestionnaireData; onChange: (u: Partial<QuestionnaireData>) => void; onToggle: (key: keyof QuestionnaireData, value: string) => void }) => (
  <div className="space-y-6">
    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Cuisine preferences (select all)</label>
      <div className="grid grid-cols-2 gap-2">
        {CUISINES.map((c) => (
          <OptionChip
            key={c.value}
            emoji={c.emoji}
            label={c.label}
            selected={data.cuisinePreferences.includes(c.value)}
            onClick={() => onToggle("cuisinePreferences", c.value)}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Dietary restrictions</label>
      <div className="grid grid-cols-2 gap-2">
        {DIETARY_RESTRICTIONS.map((d) => (
          <OptionChip
            key={d.value}
            emoji={d.emoji}
            label={d.label}
            selected={data.dietaryRestrictions.includes(d.value)}
            onClick={() => onToggle("dietaryRestrictions", d.value)}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Budget range *</label>
      <div className="grid grid-cols-2 gap-2">
        {BUDGET_RANGES.map((b) => (
          <OptionChip
            key={b.value}
            label={`${b.label} ${b.desc}`}
            selected={data.budgetRange === b.value}
            onClick={() => onChange({ budgetRange: b.value })}
          />
        ))}
      </div>
    </div>
  </div>
);

// Step 5: Avoid
const StepAvoid = ({ data, onToggle }: { data: QuestionnaireData; onToggle: (key: keyof QuestionnaireData, value: string) => void }) => (
  <div className="space-y-6">
    <p className="text-muted-foreground text-sm">Help us avoid anything that might ruin your date. All optional.</p>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Allergies</label>
      <div className="grid grid-cols-2 gap-2">
        {COMMON_ALLERGIES.map((a) => (
          <OptionChip
            key={a.value}
            emoji={a.emoji}
            label={a.label}
            selected={data.allergies.includes(a.value)}
            onClick={() => onToggle("allergies", a.value)}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-3 block">Things to avoid</label>
      <div className="grid grid-cols-2 gap-2">
        {HARD_NOS.map((h) => (
          <OptionChip
            key={h.value}
            emoji={h.emoji}
            label={h.label}
            selected={data.hardNos.includes(h.value)}
            onClick={() => onToggle("hardNos", h.value)}
          />
        ))}
      </div>
    </div>

    <div>
      <label className="text-sm font-medium text-muted-foreground mb-2 block">Anything else we should know?</label>
      <textarea
        value={data.additionalNotes}
        onChange={(e) => onToggle("additionalNotes" as keyof QuestionnaireData, e.target.value)}
        placeholder="Any other preferences or notes..."
        className="ios-input min-h-[100px] resize-none"
      />
    </div>
  </div>
);

// Step 6: Extras
const StepExtras = ({ data, onChange }: { data: QuestionnaireData; onChange: (u: Partial<QuestionnaireData>) => void }) => (
  <div className="space-y-6">
    <p className="text-muted-foreground text-sm">
      Optional extras to make your date even more special ✨
    </p>

    <div className="ios-card">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="text-2xl">🎁</span>
          <div>
            <p className="font-medium">Gift Suggestions</p>
            <p className="text-sm text-muted-foreground">Get personalized gift ideas</p>
          </div>
        </div>
        <Toggle
          checked={data.wantGiftSuggestions}
          onChange={() => onChange({ wantGiftSuggestions: !data.wantGiftSuggestions })}
        />
      </div>
    </div>

    <div className="ios-card">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="text-2xl">💬</span>
          <div>
            <p className="font-medium">Conversation Starters</p>
            <p className="text-sm text-muted-foreground">Break the ice with fun questions</p>
          </div>
        </div>
        <Toggle
          checked={data.wantConversationStarters}
          onChange={() => onChange({ wantConversationStarters: !data.wantConversationStarters })}
        />
      </div>
    </div>

    {data.wantGiftSuggestions && (
      <div>
        <label className="text-sm font-medium text-muted-foreground mb-2 block">
          Tell us about who you're shopping for
        </label>
        <textarea
          value={data.giftRecipientNotes}
          onChange={(e) => onChange({ giftRecipientNotes: e.target.value })}
          placeholder="Their interests, hobbies, favorite things..."
          className="ios-input min-h-[80px] resize-none"
        />
      </div>
    )}
  </div>
);

// Components
const OptionChip = ({ emoji, label, selected, onClick }: { emoji?: string; label: string; selected: boolean; onClick: () => void }) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-2 p-3 rounded-xl border text-left haptic-button transition-all ${
      selected
        ? "bg-primary/10 border-primary text-foreground"
        : "bg-card border-border text-muted-foreground hover:border-primary/50"
    }`}
  >
    {emoji && <span className="text-lg">{emoji}</span>}
    <span className="text-sm font-medium flex-1">{label}</span>
    {selected && <Check className="w-4 h-4 text-primary" />}
  </button>
);

const OptionRow = ({ emoji, label, description, selected, onClick }: { emoji: string; label: string; description: string; selected: boolean; onClick: () => void }) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-3 p-4 rounded-xl border text-left haptic-button transition-all w-full ${
      selected
        ? "bg-primary/10 border-primary"
        : "bg-card border-border hover:border-primary/50"
    }`}
  >
    <span className="text-2xl">{emoji}</span>
    <div className="flex-1">
      <p className="font-medium">{label}</p>
      <p className="text-sm text-muted-foreground">{description}</p>
    </div>
    {selected && <Check className="w-5 h-5 text-primary" />}
  </button>
);

const Toggle = ({ checked, onChange }: { checked: boolean; onChange: () => void }) => (
  <button
    onClick={onChange}
    className={`w-12 h-7 rounded-full transition-colors haptic-button ${
      checked ? "bg-primary" : "bg-muted"
    }`}
  >
    <div
      className={`w-6 h-6 rounded-full bg-white shadow-sm transition-transform ${
        checked ? "translate-x-5" : "translate-x-0.5"
      }`}
    />
  </button>
);

export default MobileQuestionnaire;
