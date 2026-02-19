import { useState } from "react";
import { DatePlan } from "@/types/datePlan";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  DropdownMenuLabel,
  DropdownMenuGroup,
} from "@/components/ui/dropdown-menu";
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
import { Download, FileText, Mail, Calendar, Loader2, MessageSquare, Share2, Smartphone } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { generatePDF } from "@/lib/pdfUtils";
import { generateGoogleCalendarUrl, downloadICSFile } from "@/lib/calendarUtils";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";

interface ExportMenuProps {
  plan: DatePlan;
  scheduledDate?: string;
  startTime?: string;
}

const ExportMenu = ({ plan, scheduledDate, startTime }: ExportMenuProps) => {
  const { toast } = useToast();
  const { user } = useAuth();
  const [emailDialogOpen, setEmailDialogOpen] = useState(false);
  const [smsDialogOpen, setSmsDialogOpen] = useState(false);
  const [email, setEmail] = useState(user?.email || "");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [isSendingEmail, setIsSendingEmail] = useState(false);
  const [isSendingSMS, setIsSendingSMS] = useState(false);
  const [isGeneratingPDF, setIsGeneratingPDF] = useState(false);

  const handleDownloadPDF = async () => {
    setIsGeneratingPDF(true);
    try {
      await generatePDF(plan);
      toast({
        title: "PDF Downloaded!",
        description: "Your date plan has been saved as a PDF.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Failed to generate PDF. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsGeneratingPDF(false);
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

    setIsSendingSMS(true);
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

      toast({
        title: "Text Sent! 📱",
        description: `Your date plan has been texted to ${phoneNumber}.`,
      });
      setSmsDialogOpen(false);
      setPhoneNumber("");
    } catch (error) {
      console.error("Failed to send SMS:", error);
      toast({
        title: "Error",
        description: "Failed to send text. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSendingSMS(false);
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

    setIsSendingEmail(true);
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

      toast({
        title: "Email Sent! 💌",
        description: `Your date plan has been sent to ${email}.`,
      });
      setEmailDialogOpen(false);
      setEmail("");
    } catch (error) {
      console.error("Failed to send email:", error);
      toast({
        title: "Error",
        description: "Failed to send email. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsSendingEmail(false);
    }
  };

  const handleAddToGoogleCalendar = () => {
    const url = generateGoogleCalendarUrl(plan, scheduledDate, startTime);
    window.open(url, "_blank");
    toast({
      title: "Opening Google Calendar",
      description: "Add your date to your calendar!",
    });
  };

  const handleDownloadICS = () => {
    downloadICSFile(plan, scheduledDate, startTime);
    toast({
      title: "Calendar file downloaded!",
      description: "Open the .ics file to add to your calendar app.",
    });
  };

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" size="sm" className="gap-1">
            <Share2 className="w-4 h-4" />
            <span className="hidden sm:inline">Share</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-56">
          {/* Share Section */}
          <DropdownMenuLabel className="text-xs text-muted-foreground">
            Share Plan
          </DropdownMenuLabel>
          <DropdownMenuGroup>
            <DropdownMenuItem onClick={() => setEmailDialogOpen(true)}>
              <Mail className="w-4 h-4 mr-2" />
              Email Save the Date
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => setSmsDialogOpen(true)}>
              <Smartphone className="w-4 h-4 mr-2" />
              Text to Phone
            </DropdownMenuItem>
          </DropdownMenuGroup>
          
          <DropdownMenuSeparator />
          
          {/* Download Section */}
          <DropdownMenuLabel className="text-xs text-muted-foreground">
            Download
          </DropdownMenuLabel>
          <DropdownMenuGroup>
            <DropdownMenuItem onClick={handleDownloadPDF} disabled={isGeneratingPDF}>
              {isGeneratingPDF ? (
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              ) : (
                <FileText className="w-4 h-4 mr-2" />
              )}
              Download PDF
            </DropdownMenuItem>
          </DropdownMenuGroup>
          
          <DropdownMenuSeparator />
          
          {/* Calendar Section */}
          <DropdownMenuLabel className="text-xs text-muted-foreground">
            Add to Calendar
          </DropdownMenuLabel>
          <DropdownMenuGroup>
            <DropdownMenuItem onClick={handleAddToGoogleCalendar}>
              <Calendar className="w-4 h-4 mr-2" />
              Google Calendar
            </DropdownMenuItem>
            <DropdownMenuItem onClick={handleDownloadICS}>
              <Calendar className="w-4 h-4 mr-2" />
              Apple Calendar (.ics)
            </DropdownMenuItem>
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>

      <Dialog open={emailDialogOpen} onOpenChange={setEmailDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Mail className="w-5 h-5 text-primary" />
              Save the Date Email
            </DialogTitle>
            <DialogDescription>
              Send a beautiful email with your complete date plan - perfect for sharing with your partner!
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
                onKeyDown={(e) => e.key === "Enter" && !isSendingEmail && handleSendEmail()}
              />
              <p className="text-xs text-muted-foreground">
                Includes itinerary, venue details, packing list, and romantic tips.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEmailDialogOpen(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleSendEmail} 
              disabled={isSendingEmail}
              className="gradient-gold text-primary-foreground"
            >
              {isSendingEmail ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Mail className="w-4 h-4 mr-2" />
                  Send Save the Date
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={smsDialogOpen} onOpenChange={setSmsDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Smartphone className="w-5 h-5 text-primary" />
              Text Your Date Plan
            </DialogTitle>
            <DialogDescription>
              Send a text with your date plan - great for quick reference or sharing with your date!
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
                onKeyDown={(e) => e.key === "Enter" && !isSendingSMS && handleSendSMS()}
              />
              <p className="text-xs text-muted-foreground">
                US numbers can omit country code. International numbers need +country code.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSmsDialogOpen(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleSendSMS} 
              disabled={isSendingSMS}
              className="gradient-gold text-primary-foreground"
            >
              {isSendingSMS ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Smartphone className="w-4 h-4 mr-2" />
                  Send Text
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
};

export default ExportMenu;
