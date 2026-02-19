import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import OptionCard from "../OptionCard";
import { QuestionnaireData, DATE_TYPES, OCCASIONS, IDENTITY_OPTIONS, isSoloDate } from "../types";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { CalendarIcon, Clock, User, Heart } from "lucide-react";
import { format, parse } from "date-fns";
import { cn } from "@/lib/utils";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

interface Step1Props {
  data: QuestionnaireData;
  onChange: (updates: Partial<QuestionnaireData>) => void;
}

const TIME_OPTIONS = [
  { value: "08:00", label: "8:00 AM" },
  { value: "09:00", label: "9:00 AM" },
  { value: "10:00", label: "10:00 AM" },
  { value: "11:00", label: "11:00 AM" },
  { value: "12:00", label: "12:00 PM" },
  { value: "13:00", label: "1:00 PM" },
  { value: "14:00", label: "2:00 PM" },
  { value: "15:00", label: "3:00 PM" },
  { value: "16:00", label: "4:00 PM" },
  { value: "17:00", label: "5:00 PM" },
  { value: "18:00", label: "6:00 PM" },
  { value: "19:00", label: "7:00 PM" },
  { value: "20:00", label: "8:00 PM" },
  { value: "21:00", label: "9:00 PM" },
  { value: "22:00", label: "10:00 PM" },
];

const Step1Location = ({ data, onChange }: Step1Props) => {
  const selectedDate = data.dateScheduled 
    ? parse(data.dateScheduled, "yyyy-MM-dd", new Date())
    : undefined;

  const isSolo = isSoloDate(data.dateType);

  return (
    <div className="space-y-5 sm:space-y-6">
      <div className="text-center mb-2 sm:mb-4">
        <h2 className="font-display text-xl sm:text-3xl mb-1 sm:mb-2">Where & When</h2>
        <p className="text-muted-foreground text-sm sm:text-base">Tell us the basics</p>
      </div>

      {/* Location */}
      <div className="space-y-3 sm:space-y-4">
        <Label className="text-sm sm:text-base font-medium">📍 Where's this happening?</Label>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3">
          <div>
            <Input
              placeholder="City (e.g., Austin, TX)"
              value={data.city}
              onChange={(e) => onChange({ city: e.target.value })}
              onBlur={() => {
                const normalized = data.city
                  .trim()
                  .replace(/\s+/g, " ")
                  // Ensure comma before 2-letter state when users type "city  nj"
                  .replace(/\b([A-Za-z .'-]+?)\s+([A-Za-z]{2})$/i, (_m, city, st) =>
                    `${String(city).trim()}, ${String(st).toUpperCase()}`
                  );
                if (normalized !== data.city) onChange({ city: normalized });
              }}
              className="bg-card border-border"
            />
          </div>
          <div>
            <Input
              placeholder="Neighborhood (optional)"
              value={data.neighborhood}
              onChange={(e) => onChange({ neighborhood: e.target.value })}
              onBlur={() => {
                const normalized = data.neighborhood.trim().replace(/\s+/g, " ");
                if (normalized !== data.neighborhood) onChange({ neighborhood: normalized });
              }}
              className="bg-card border-border"
            />
          </div>
        </div>
        <div>
          <Input
            placeholder="Starting address or intersection (e.g., 123 Main St or Main St & 5th Ave)"
            value={data.startingAddress}
            onChange={(e) => onChange({ startingAddress: e.target.value })}
            className="bg-card border-border"
          />
          <p className="text-xs text-muted-foreground mt-1">
            Where will you be departing from? This helps us plan your route.
          </p>
        </div>
      </div>

      {/* Date & Time */}
      <div className="space-y-3 sm:space-y-4">
        <Label className="text-sm sm:text-base font-medium">📅 When is your date?</Label>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3">
          <Popover>
            <PopoverTrigger asChild>
              <Button
                variant="outline"
                className={cn(
                  "w-full justify-start text-left font-normal bg-card border-border",
                  !data.dateScheduled && "text-muted-foreground"
                )}
              >
                <CalendarIcon className="mr-2 h-4 w-4" />
                {data.dateScheduled 
                  ? format(selectedDate!, "PPP")
                  : "Pick a date"}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="start">
              <Calendar
                mode="single"
                selected={selectedDate}
                onSelect={(date) => 
                  onChange({ dateScheduled: date ? format(date, "yyyy-MM-dd") : "" })
                }
                disabled={(date) => date < new Date(new Date().setHours(0, 0, 0, 0))}
                initialFocus
              />
            </PopoverContent>
          </Popover>
          
          <Select
            value={data.startTime}
            onValueChange={(value) => onChange({ startTime: value })}
          >
            <SelectTrigger className="bg-card border-border">
              <div className="flex items-center gap-2">
                <Clock className="h-4 w-4 text-muted-foreground" />
                <SelectValue placeholder="Start time" />
              </div>
            </SelectTrigger>
            <SelectContent>
              {TIME_OPTIONS.map((time) => (
                <SelectItem key={time.value} value={time.value}>
                  {time.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <p className="text-xs text-muted-foreground">
          This helps us find venues that are open and make time-appropriate suggestions.
        </p>
      </div>

      {/* Date Type */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">💫 What kind of date is this?</Label>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:gap-3">
          {DATE_TYPES.map((type) => (
            <OptionCard
              key={type.value}
              selected={data.dateType === type.value}
              onClick={() => onChange({ dateType: type.value })}
              emoji={type.emoji}
              label={type.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Occasion */}
      <div className="space-y-3">
        <Label className="text-sm sm:text-base font-medium">🎁 Any special occasion?</Label>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:gap-3">
          {OCCASIONS.map((occasion) => (
            <OptionCard
              key={occasion.value}
              selected={data.occasion === occasion.value}
              onClick={() => onChange({ occasion: occasion.value })}
              emoji={occasion.emoji}
              label={occasion.label}
              compact
            />
          ))}
        </div>
      </div>

      {/* Identity Section - moved from Step 6 */}
      <div className="space-y-3 p-3 rounded-lg border border-border bg-card">
        <Label className="text-sm sm:text-base font-medium flex items-center gap-2">
          <User className="w-4 h-4" />
          About You
        </Label>
        <div className={isSolo ? "" : "grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4"}>
          <div>
            <Label className="text-xs sm:text-sm text-muted-foreground mb-2 block">I identify as</Label>
            <div className="grid grid-cols-2 gap-1.5 sm:gap-2">
              {IDENTITY_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => onChange({ userIdentity: option.value })}
                  className={`flex items-center gap-1.5 sm:gap-2 px-2 sm:px-3 py-2 rounded-lg border text-xs sm:text-sm transition-all min-h-[40px] ${
                    data.userIdentity === option.value
                      ? "border-primary bg-primary/10 text-foreground"
                      : "border-border bg-background text-muted-foreground hover:border-primary/50"
                  }`}
                >
                  <span className="text-sm sm:text-base">{option.emoji}</span>
                  <span className="truncate">{option.label}</span>
                </button>
              ))}
            </div>
          </div>

          {!isSolo && (
            <div>
              <Label className="text-xs sm:text-sm text-muted-foreground mb-2 block flex items-center gap-1">
                <Heart className="w-3 h-3" />
                My partner identifies as
              </Label>
              <div className="grid grid-cols-2 gap-1.5 sm:gap-2">
                {IDENTITY_OPTIONS.map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => onChange({ partnerIdentity: option.value })}
                    className={`flex items-center gap-1.5 sm:gap-2 px-2 sm:px-3 py-2 rounded-lg border text-xs sm:text-sm transition-all min-h-[40px] ${
                      data.partnerIdentity === option.value
                        ? "border-primary bg-primary/10 text-foreground"
                        : "border-border bg-background text-muted-foreground hover:border-primary/50"
                    }`}
                  >
                    <span className="text-sm sm:text-base">{option.emoji}</span>
                    <span className="truncate">{option.label}</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Step1Location;
