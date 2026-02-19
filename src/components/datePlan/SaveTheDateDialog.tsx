import { useState } from "react";
import { DatePlan } from "@/types/datePlan";
import { Button } from "@/components/ui/button";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Mail, MessageSquare, FileText, Loader2, CheckCircle, Calendar } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { generatePDF } from "@/lib/pdfUtils";
import { useAuth } from "@/hooks/useAuth";

interface SaveTheDateDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  plan: DatePlan;
  scheduledDate?: string;
  startTime?: string;
}

type SendStatus = "idle" | "sending" | "sent" | "error";

const SaveTheDateDialog = ({
  open,
  onOpenChange,
  plan,
  scheduledDate,
  startTime,
}: SaveTheDateDialogProps) => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [email, setEmail] = useState(user?.email || "");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [emailStatus, setEmailStatus] = useState<SendStatus>("idle");
  const [smsStatus, setSmsStatus] = useState<SendStatus>("idle");
  const [pdfStatus, setPdfStatus] = useState<SendStatus>("idle");
  const [activeTab, setActiveTab] = useState("email");

  const formatDateForDisplay = (dateStr?: string) => {
    if (!dateStr) return "Date not set";
    try {
      return new Date(dateStr).toLocaleDateString("en-US", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
      });
    } catch {
      return dateStr;
    }
  };

  const handleSendEmail = async () => {
    if (!email.trim()) {
      toast({
        title: "Email required",
        description: "Please enter an email address.",
        variant: "destructive",
      });
      return;
    }

    setEmailStatus("sending");
    try {
      const { error } = await supabase.functions.invoke("send-date-plan-email", {
        body: {
          email: email.trim(),
          plan,
          scheduledDate,
          startTime,
        },
      });

      if (error) throw error;

      setEmailStatus("sent");
      toast({
        title: "Save the Date sent! 💌",
        description: `Your date plan has been emailed to ${email}.`,
      });
    } catch (error) {
      console.error("Failed to send email:", error);
      setEmailStatus("error");
      toast({
        title: "Error",
        description: "Failed to send email. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleSendSMS = async () => {
    if (!phoneNumber.trim()) {
      toast({
        title: "Phone number required",
        description: "Please enter a phone number.",
        variant: "destructive",
      });
      return;
    }

    setSmsStatus("sending");
    try {
      const { error } = await supabase.functions.invoke("send-date-plan-sms", {
        body: {
          phoneNumber: phoneNumber.trim(),
          plan,
          scheduledDate,
          startTime,
        },
      });

      if (error) throw error;

      setSmsStatus("sent");
      toast({
        title: "Save the Date texted! 📱",
        description: `Your date plan has been texted to ${phoneNumber}.`,
      });
    } catch (error) {
      console.error("Failed to send SMS:", error);
      setSmsStatus("error");
      toast({
        title: "Error",
        description: "Failed to send text. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleDownloadPDF = async () => {
    setPdfStatus("sending");
    try {
      await generatePDF(plan);
      setPdfStatus("sent");
      toast({
        title: "PDF Downloaded! 📄",
        description: "Your date plan has been saved as a PDF.",
      });
    } catch (error) {
      console.error("Failed to generate PDF:", error);
      setPdfStatus("error");
      toast({
        title: "Error",
        description: "Failed to generate PDF. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleClose = () => {
    // Reset states when closing
    setEmailStatus("idle");
    setSmsStatus("idle");
    setPdfStatus("idle");
    onOpenChange(false);
  };

  const renderStatusButton = (
    status: SendStatus,
    idleContent: React.ReactNode,
    onClick: () => void
  ) => {
    switch (status) {
      case "sending":
        return (
          <Button disabled className="w-full">
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            Sending...
          </Button>
        );
      case "sent":
        return (
          <Button disabled variant="outline" className="w-full text-green-600">
            <CheckCircle className="w-4 h-4 mr-2" />
            Sent!
          </Button>
        );
      case "error":
        return (
          <Button onClick={onClick} variant="destructive" className="w-full">
            Try Again
          </Button>
        );
      default:
        return (
          <Button onClick={onClick} className="w-full gradient-gold text-primary-foreground">
            {idleContent}
          </Button>
        );
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="font-display text-xl sm:text-2xl flex items-center gap-2">
            <Calendar className="w-5 h-5 sm:w-6 sm:h-6 text-primary flex-shrink-0" />
            Save the Date! ✨
          </DialogTitle>
          <DialogDescription className="text-sm">
            Your date plan has been saved! Share it via email, text, or download as PDF.
          </DialogDescription>
        </DialogHeader>

        {/* Date Preview */}
        <div className="bg-muted/50 rounded-lg p-3 sm:p-4 my-2 border border-border">
          <h3 className="font-display text-base sm:text-lg text-foreground">{plan.title}</h3>
          <p className="text-xs sm:text-sm text-muted-foreground italic mb-2">{plan.tagline}</p>
          <div className="flex flex-col xs:flex-row xs:items-center gap-2 xs:gap-4 text-xs sm:text-sm">
            <span className="flex items-center gap-1">
              📅 {formatDateForDisplay(scheduledDate)}
            </span>
            {startTime && (
              <span className="flex items-center gap-1">
                🕐 {startTime}
              </span>
            )}
          </div>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-3 h-auto">
            <TabsTrigger value="email" className="gap-1.5 py-2.5 text-xs sm:text-sm">
              <Mail className="w-4 h-4" />
              <span className="hidden xs:inline">Email</span>
            </TabsTrigger>
            <TabsTrigger value="text" className="gap-1.5 py-2.5 text-xs sm:text-sm">
              <MessageSquare className="w-4 h-4" />
              <span className="hidden xs:inline">Text</span>
            </TabsTrigger>
            <TabsTrigger value="pdf" className="gap-1.5 py-2.5 text-xs sm:text-sm">
              <FileText className="w-4 h-4" />
              <span className="hidden xs:inline">PDF</span>
            </TabsTrigger>
          </TabsList>

          <TabsContent value="email" className="space-y-4 mt-4">
            <div className="space-y-2">
              <Label htmlFor="email">Send to email</Label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && emailStatus === "idle" && handleSendEmail()}
                disabled={emailStatus === "sending" || emailStatus === "sent"}
              />
              <p className="text-xs text-muted-foreground">
                We'll send a beautifully formatted email with all the details.
              </p>
            </div>
            {renderStatusButton(
              emailStatus,
              <>
                <Mail className="w-4 h-4 mr-2" />
                Send Save the Date
              </>,
              handleSendEmail
            )}
          </TabsContent>

          <TabsContent value="text" className="space-y-4 mt-4">
            <div className="space-y-2">
              <Label htmlFor="phone">Send to phone</Label>
              <Input
                id="phone"
                type="tel"
                placeholder="(555) 123-4567"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && smsStatus === "idle" && handleSendSMS()}
                disabled={smsStatus === "sending" || smsStatus === "sent"}
              />
              <p className="text-xs text-muted-foreground">
                Perfect for sharing with your date or partner!
              </p>
            </div>
            {renderStatusButton(
              smsStatus,
              <>
                <MessageSquare className="w-4 h-4 mr-2" />
                Text Save the Date
              </>,
              handleSendSMS
            )}
          </TabsContent>

          <TabsContent value="pdf" className="space-y-4 mt-4">
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">
                Download a beautiful PDF with your complete date plan - perfect for printing
                or sharing offline.
              </p>
              <div className="bg-muted/30 rounded-lg p-3 text-sm">
                <p className="font-medium mb-1">PDF includes:</p>
                <ul className="text-muted-foreground space-y-1">
                  <li>• Complete itinerary with all stops</li>
                  <li>• Addresses and venue details</li>
                  <li>• Genie's Secret Touch</li>
                  <li>• Packing list & weather notes</li>
                  {plan.giftSuggestions && plan.giftSuggestions.length > 0 && (
                    <li>• Gift suggestions</li>
                  )}
                  {plan.conversationStarters && plan.conversationStarters.length > 0 && (
                    <li>• Conversation starters</li>
                  )}
                </ul>
              </div>
            </div>
            {renderStatusButton(
              pdfStatus,
              <>
                <FileText className="w-4 h-4 mr-2" />
                Download PDF
              </>,
              handleDownloadPDF
            )}
          </TabsContent>
        </Tabs>

        <DialogFooter className="mt-4">
          <Button variant="outline" onClick={handleClose}>
            Done
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default SaveTheDateDialog;
