import { useState } from "react";
import { Calendar, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Calendar as CalendarPicker } from "@/components/ui/calendar";
import { DatePlan } from "@/types/datePlan";

interface SaveDatePickerModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  plan: DatePlan;
  onConfirm: (plan: DatePlan, date: Date) => void;
}

function nextSaturday(): Date {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const day = today.getDay(); // 0=Sun … 6=Sat
  const daysUntilSat = day === 6 ? 7 : 6 - day;
  const sat = new Date(today);
  sat.setDate(today.getDate() + daysUntilSat);
  return sat;
}

const tomorrow = (() => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 1);
  return d;
})();

export default function SaveDatePickerModal({
  open,
  onOpenChange,
  plan,
  onConfirm,
}: SaveDatePickerModalProps) {
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(
    nextSaturday()
  );

  const handleConfirm = () => {
    if (!selectedDate) return;
    onConfirm(plan, selectedDate);
    onOpenChange(false);
  };

  const handleCancel = () => {
    onOpenChange(false);
  };

  const formattedDate = selectedDate
    ? selectedDate.toLocaleDateString("en-US", {
        weekday: "long",
        month: "long",
        day: "numeric",
        year: "numeric",
      })
    : null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm p-0 overflow-hidden">
        <DialogHeader className="px-6 pt-6 pb-2">
          <div className="flex items-center justify-between">
            <DialogTitle className="font-display text-xl flex items-center gap-2">
              <Calendar className="w-5 h-5 text-primary flex-shrink-0" />
              When's your date?
            </DialogTitle>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-muted-foreground"
              onClick={handleCancel}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
          <p className="text-sm text-muted-foreground mt-1">
            Choose a day for{" "}
            <span className="font-medium text-foreground">"{plan.title}"</span>
          </p>
        </DialogHeader>

        <div className="flex justify-center border-y border-border bg-muted/20 py-2">
          <CalendarPicker
            mode="single"
            selected={selectedDate}
            onSelect={setSelectedDate}
            disabled={{ before: tomorrow }}
            initialFocus
          />
        </div>

        {formattedDate && (
          <div className="px-6 py-3 bg-primary/5 border-b border-border">
            <p className="text-sm text-center text-muted-foreground">
              Selected:{" "}
              <span className="font-semibold text-foreground">
                {formattedDate}
              </span>
            </p>
          </div>
        )}

        <div className="flex flex-col gap-2 px-6 py-4">
          <Button
            onClick={handleConfirm}
            disabled={!selectedDate}
            className="w-full gradient-gold text-primary-foreground font-semibold"
          >
            <Calendar className="w-4 h-4 mr-2" />
            Confirm &amp; Save Plan
          </Button>
          <Button variant="ghost" onClick={handleCancel} className="w-full">
            Cancel
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
