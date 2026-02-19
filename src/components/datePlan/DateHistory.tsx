import { SavedDatePlan } from "@/hooks/useDatePlans";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Calendar, Clock, MapPin, Trash2, Eye, Download, FileText, Mail, CalendarPlus, MessageSquare, Loader2, CheckCircle2, Star } from "lucide-react";
import { format, isPast, isToday, isTomorrow, differenceInDays } from "date-fns";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { savedPlanToDatePlan } from "@/lib/planUtils";
import { generatePDF } from "@/lib/pdfUtils";
import { generateGoogleCalendarUrl, downloadICSFile } from "@/lib/calendarUtils";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import RatingDialog from "./RatingDialog";

interface DateHistoryProps {
  plans: SavedDatePlan[];
  onViewPlan: (plan: SavedDatePlan) => void;
  onDeletePlan: (planId: string) => void;
  onMarkCompleted: (planId: string) => void;
  onRatePlan: (planId: string, rating: number, notes?: string) => void;
}

const DateHistory = ({ plans, onViewPlan, onDeletePlan, onMarkCompleted, onRatePlan }: DateHistoryProps) => {
  const { toast } = useToast();
  const [emailDialogOpen, setEmailDialogOpen] = useState(false);
  const [smsDialogOpen, setSmsDialogOpen] = useState(false);
  const [ratingDialogOpen, setRatingDialogOpen] = useState(false);
  const [selectedPlanForEmail, setSelectedPlanForEmail] = useState<SavedDatePlan | null>(null);
  const [selectedPlanForSMS, setSelectedPlanForSMS] = useState<SavedDatePlan | null>(null);
  const [selectedPlanForRating, setSelectedPlanForRating] = useState<SavedDatePlan | null>(null);
  const [email, setEmail] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [isSendingEmail, setIsSendingEmail] = useState(false);
  const [isSendingSMS, setIsSendingSMS] = useState(false);

  const handleOpenRatingDialog = (plan: SavedDatePlan) => {
    setSelectedPlanForRating(plan);
    setRatingDialogOpen(true);
  };

  const handleSubmitRating = (rating: number, notes?: string) => {
    if (selectedPlanForRating) {
      onRatePlan(selectedPlanForRating.id, rating, notes);
      setSelectedPlanForRating(null);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "generated":
        return "bg-blue-500/10 text-blue-500 border-blue-500/20";
      case "scheduled":
        return "bg-amber-500/10 text-amber-500 border-amber-500/20";
      case "completed":
        return "bg-green-500/10 text-green-500 border-green-500/20";
      case "confirmed":
        return "bg-primary/10 text-primary border-primary/20";
      default:
        return "bg-muted text-muted-foreground";
    }
  };

  const getDateLabel = (dateScheduled: string | null) => {
    if (!dateScheduled) return null;
    const date = new Date(dateScheduled);
    if (isToday(date)) return { text: "Today!", color: "text-green-600" };
    if (isTomorrow(date)) return { text: "Tomorrow", color: "text-amber-600" };
    if (isPast(date)) return { text: "Past", color: "text-muted-foreground" };
    const daysUntil = differenceInDays(date, new Date());
    if (daysUntil <= 7) return { text: `In ${daysUntil} days`, color: "text-primary" };
    return null;
  };

  const handleDownloadPDF = async (plan: SavedDatePlan) => {
    try {
      await generatePDF(savedPlanToDatePlan(plan));
      toast({
        title: "PDF Downloaded!",
        description: "Your date plan has been saved as a PDF.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to generate PDF.",
        variant: "destructive",
      });
    }
  };

  const handleOpenSMSDialog = (plan: SavedDatePlan) => {
    setSelectedPlanForSMS(plan);
    setSmsDialogOpen(true);
  };

  const handleSendSMS = async () => {
    if (!selectedPlanForSMS || !phoneNumber.trim()) return;
    setIsSendingSMS(true);
    try {
      const datePlan = savedPlanToDatePlan(selectedPlanForSMS);
      const { error } = await supabase.functions.invoke("send-date-plan-sms", {
        body: {
          phoneNumber: phoneNumber.trim(),
          plan: datePlan,
          scheduledDate: selectedPlanForSMS.date_scheduled,
        },
      });
      if (error) throw error;
      toast({
        title: "Text Sent! 📱",
        description: `Your date plan has been texted to ${phoneNumber}.`,
      });
      setSmsDialogOpen(false);
      setPhoneNumber("");
      setSelectedPlanForSMS(null);
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to send text.",
        variant: "destructive",
      });
    } finally {
      setIsSendingSMS(false);
    }
  };

  const handleOpenEmailDialog = (plan: SavedDatePlan) => {
    setSelectedPlanForEmail(plan);
    setEmailDialogOpen(true);
  };

  const handleSendEmail = async () => {
    if (!selectedPlanForEmail || !email.trim()) return;
    setIsSendingEmail(true);
    try {
      const datePlan = savedPlanToDatePlan(selectedPlanForEmail);
      const { error } = await supabase.functions.invoke("send-date-plan-email", {
        body: {
          email: email.trim(),
          plan: datePlan,
          scheduledDate: selectedPlanForEmail.date_scheduled,
        },
      });
      if (error) throw error;
      toast({
        title: "Email Sent! 💌",
        description: `Your date plan has been sent to ${email}.`,
      });
      setEmailDialogOpen(false);
      setEmail("");
      setSelectedPlanForEmail(null);
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to send email.",
        variant: "destructive",
      });
    } finally {
      setIsSendingEmail(false);
    }
  };

  const handleAddToGoogleCalendar = (plan: SavedDatePlan) => {
    const datePlan = savedPlanToDatePlan(plan);
    const url = generateGoogleCalendarUrl(datePlan, plan.date_scheduled || undefined);
    window.open(url, "_blank");
    toast({ title: "Opening Google Calendar", description: "Add your date to your calendar!" });
  };

  const handleDownloadICS = (plan: SavedDatePlan) => {
    const datePlan = savedPlanToDatePlan(plan);
    downloadICSFile(datePlan, plan.date_scheduled || undefined);
    toast({ title: "Calendar file downloaded!", description: "Open the .ics file to add to your calendar app." });
  };

  if (plans.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <p>No date history yet. Create your first date plan!</p>
      </div>
    );
  }

  // Separate scheduled/confirmed dates from others
  const scheduledPlans = plans.filter(p => p.date_scheduled && !isPast(new Date(p.date_scheduled)));
  const otherPlans = plans.filter(p => !p.date_scheduled || isPast(new Date(p.date_scheduled)));

  return (
    <>
      {/* Upcoming Dates Section */}
      {scheduledPlans.length > 0 && (
        <div className="mb-8">
          <h3 className="font-display text-lg mb-4 flex items-center gap-2">
            <CalendarPlus className="w-5 h-5 text-primary" />
            Upcoming Dates
          </h3>
          <div className="space-y-4">
            {scheduledPlans.map((plan) => (
              <PlanCard
                key={plan.id}
                plan={plan}
                onViewPlan={onViewPlan}
                onDeletePlan={onDeletePlan}
                onMarkCompleted={onMarkCompleted}
                onOpenRatingDialog={handleOpenRatingDialog}
                onDownloadPDF={handleDownloadPDF}
                onOpenSMSDialog={handleOpenSMSDialog}
                onOpenEmailDialog={handleOpenEmailDialog}
                onAddToGoogleCalendar={handleAddToGoogleCalendar}
                onDownloadICS={handleDownloadICS}
                getStatusColor={getStatusColor}
                getDateLabel={getDateLabel}
                isUpcoming
              />
            ))}
          </div>
        </div>
      )}

      {/* All Plans Section */}
      <div className="space-y-4">
        {scheduledPlans.length > 0 && otherPlans.length > 0 && (
          <h3 className="font-display text-lg mb-4">All Plans</h3>
        )}
        {otherPlans.map((plan) => (
          <PlanCard
            key={plan.id}
            plan={plan}
            onViewPlan={onViewPlan}
            onDeletePlan={onDeletePlan}
            onMarkCompleted={onMarkCompleted}
            onOpenRatingDialog={handleOpenRatingDialog}
            onDownloadPDF={handleDownloadPDF}
            onOpenSMSDialog={handleOpenSMSDialog}
            onOpenEmailDialog={handleOpenEmailDialog}
            onAddToGoogleCalendar={handleAddToGoogleCalendar}
            onDownloadICS={handleDownloadICS}
            getStatusColor={getStatusColor}
            getDateLabel={getDateLabel}
          />
        ))}
      </div>

      {/* Email Dialog */}
      <Dialog open={emailDialogOpen} onOpenChange={setEmailDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Email Your Date Plan</DialogTitle>
            <DialogDescription>
              We'll send a beautifully formatted email with all the details.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="email">Email address</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSendEmail()}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEmailDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSendEmail} disabled={isSendingEmail}>
              {isSendingEmail ? "Sending..." : "Send Email"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* SMS Dialog */}
      <Dialog open={smsDialogOpen} onOpenChange={setSmsDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Text Your Date Plan</DialogTitle>
            <DialogDescription>
              We'll send a text message with your date plan details.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="phone">Phone number</Label>
              <Input
                id="phone"
                type="tel"
                placeholder="(555) 123-4567"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSendSMS()}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSmsDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSendSMS} disabled={isSendingSMS}>
              {isSendingSMS ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <MessageSquare className="w-4 h-4 mr-2" />
                  Send Text
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Rating Dialog */}
      <RatingDialog
        open={ratingDialogOpen}
        onOpenChange={setRatingDialogOpen}
        planTitle={selectedPlanForRating?.title || ""}
        currentRating={selectedPlanForRating?.rating}
        currentNotes={selectedPlanForRating?.rating_notes}
        onSubmit={handleSubmitRating}
      />
    </>
  );
};

interface PlanCardProps {
  plan: SavedDatePlan;
  onViewPlan: (plan: SavedDatePlan) => void;
  onDeletePlan: (planId: string) => void;
  onMarkCompleted: (planId: string) => void;
  onOpenRatingDialog: (plan: SavedDatePlan) => void;
  onDownloadPDF: (plan: SavedDatePlan) => void;
  onOpenSMSDialog: (plan: SavedDatePlan) => void;
  onOpenEmailDialog: (plan: SavedDatePlan) => void;
  onAddToGoogleCalendar: (plan: SavedDatePlan) => void;
  onDownloadICS: (plan: SavedDatePlan) => void;
  getStatusColor: (status: string) => string;
  getDateLabel: (date: string | null) => { text: string; color: string } | null;
  isUpcoming?: boolean;
}

const PlanCard = ({
  plan,
  onViewPlan,
  onDeletePlan,
  onMarkCompleted,
  onOpenRatingDialog,
  onDownloadPDF,
  onOpenSMSDialog,
  onOpenEmailDialog,
  onAddToGoogleCalendar,
  onDownloadICS,
  getStatusColor,
  getDateLabel,
  isUpcoming,
}: PlanCardProps) => {
  const dateLabel = getDateLabel(plan.date_scheduled);

  return (
    <Card className={`hover:shadow-lg transition-shadow ${isUpcoming ? "border-primary/30 bg-primary/5" : ""}`}>
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 flex-wrap">
              <CardTitle className="font-display text-xl">{plan.title}</CardTitle>
              {dateLabel && (
                <span className={`text-sm font-medium ${dateLabel.color}`}>
                  {dateLabel.text}
                </span>
              )}
            </div>
            {plan.tagline && (
              <p className="text-muted-foreground italic mt-1">{plan.tagline}</p>
            )}
          </div>
          <div className="flex items-center gap-2">
            {/* Rating Stars Display */}
            {plan.rating && (
              <div className="flex items-center gap-0.5 mr-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <Star
                    key={star}
                    className={`w-4 h-4 ${
                      star <= plan.rating!
                        ? "fill-yellow-400 text-yellow-400"
                        : "text-muted-foreground/30"
                    }`}
                  />
                ))}
              </div>
            )}
            <Badge variant="outline" className={getStatusColor(plan.status)}>
              {plan.status}
            </Badge>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground mb-4">
          {plan.total_duration && (
            <span className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              {plan.total_duration}
            </span>
          )}
          {plan.estimated_cost && (
            <span className="flex items-center gap-1">
              💰 {plan.estimated_cost}
            </span>
          )}
          <span className="flex items-center gap-1">
            <MapPin className="w-4 h-4" />
            {plan.stops.length} stops
          </span>
          {plan.date_scheduled && (
            <span className="flex items-center gap-1">
              <Calendar className="w-4 h-4" />
              {format(new Date(plan.date_scheduled), "MMM d, yyyy")}
            </span>
          )}
        </div>
        
        <div className="flex items-center gap-2 text-sm mb-4">
          {plan.stops.slice(0, 4).map((stop, i) => (
            <span key={i} className="text-xl" title={stop.name}>
              {stop.emoji}
            </span>
          ))}
          {plan.stops.length > 4 && (
            <span className="text-muted-foreground">+{plan.stops.length - 4} more</span>
          )}
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          <Button variant="outline" size="sm" onClick={() => onViewPlan(plan)}>
            <Eye className="w-4 h-4 mr-2" />
            View Plan
          </Button>

          {/* Mark as Completed Button - only show if not already completed */}
          {plan.status !== "completed" && (
            <Button 
              variant="outline" 
              size="sm" 
              className="text-green-600 hover:text-green-700 hover:bg-green-50 border-green-200"
              onClick={() => onMarkCompleted(plan.id)}
            >
              <CheckCircle2 className="w-4 h-4 mr-2" />
              Mark Completed
            </Button>
          )}

          {/* Rate Button - only show for completed dates */}
          {plan.status === "completed" && (
            <Button 
              variant="outline" 
              size="sm" 
              className="text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50 border-yellow-200"
              onClick={() => onOpenRatingDialog(plan)}
            >
              <Star className="w-4 h-4 mr-2" />
              {plan.rating ? "Update Rating" : "Rate Date"}
            </Button>
          )}
          
          {/* Quick Export Dropdown */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm">
                <Download className="w-4 h-4 mr-2" />
                Export
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" className="w-48">
              <DropdownMenuItem onClick={() => onDownloadPDF(plan)}>
                <FileText className="w-4 h-4 mr-2" />
                Download PDF
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onOpenSMSDialog(plan)}>
                <MessageSquare className="w-4 h-4 mr-2" />
                Text Plan
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => onOpenEmailDialog(plan)}>
                <Mail className="w-4 h-4 mr-2" />
                Email Plan
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => onAddToGoogleCalendar(plan)}>
                <Calendar className="w-4 h-4 mr-2" />
                Google Calendar
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onDownloadICS(plan)}>
                <Calendar className="w-4 h-4 mr-2" />
                Apple Calendar (.ics)
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <Button
            variant="ghost"
            size="sm"
            className="text-destructive hover:text-destructive"
            onClick={() => onDeletePlan(plan.id)}
          >
            <Trash2 className="w-4 h-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default DateHistory;
