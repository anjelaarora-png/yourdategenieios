import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Copy, Check, Users, Mail, MessageSquare, Share2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { DatePlan } from "@/types/datePlan";

interface PartnerShareDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  plan: DatePlan;
  planId?: string;
}

const PartnerShareDialog = ({ open, onOpenChange, plan, planId }: PartnerShareDialogProps) => {
  const { toast } = useToast();
  const [copied, setCopied] = useState(false);
  const [partnerEmail, setPartnerEmail] = useState("");

  // Generate a shareable summary
  const generateShareText = () => {
    const stops = (plan.stops ?? []).map((s, i) => `${i + 1}. ${s.emoji} ${s.name} (${s.timeSlot})`).join("\n");
    
    return `🌟 You're invited to a date! 🌟

${plan.title}
"${plan.tagline}"

📍 Our stops:
${stops}

⏰ Total time: ${plan.totalDuration}
💰 Estimated cost: ${plan.estimatedCost}

${plan.genieSecretTouch ? `✨ Special touch: ${plan.genieSecretTouch.title}` : ""}

Created with Your Date Genie 💕`;
  };

  const shareText = generateShareText();

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(shareText);
      setCopied(true);
      toast({
        title: "Copied!",
        description: "Date plan copied to clipboard.",
      });
      setTimeout(() => setCopied(false), 2000);
    } catch {
      toast({
        title: "Couldn't copy",
        description: "Please try selecting and copying manually.",
        variant: "destructive",
      });
    }
  };

  const handleShareViaText = () => {
    const encodedText = encodeURIComponent(shareText);
    window.open(`sms:?body=${encodedText}`, "_blank");
  };

  const handleShareViaEmail = () => {
    const subject = encodeURIComponent(`You're invited: ${plan.title} 💕`);
    const body = encodeURIComponent(shareText);
    window.open(`mailto:${partnerEmail}?subject=${subject}&body=${body}`, "_blank");
  };

  const handleShareViaWhatsApp = () => {
    const encodedText = encodeURIComponent(shareText);
    window.open(`https://wa.me/?text=${encodedText}`, "_blank");
  };

  const handleNativeShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: plan.title,
          text: shareText,
        });
      } catch (err) {
        if ((err as Error).name !== "AbortError") {
          handleCopy();
        }
      }
    } else {
      handleCopy();
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display text-2xl flex items-center gap-2">
            <Users className="w-6 h-6" />
            Share with Partner
          </DialogTitle>
          <DialogDescription>
            Invite your partner to see the date plan!
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {/* Preview */}
          <div className="bg-muted rounded-lg p-4 max-h-48 overflow-y-auto">
            <pre className="text-xs whitespace-pre-wrap font-sans">{shareText}</pre>
          </div>

          {/* Quick share buttons */}
          <div className="grid grid-cols-2 gap-3">
            <Button variant="outline" onClick={handleShareViaText} className="gap-2">
              <MessageSquare className="w-4 h-4" />
              Text Message
            </Button>
            <Button variant="outline" onClick={handleShareViaWhatsApp} className="gap-2">
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
              </svg>
              WhatsApp
            </Button>
          </div>

          {/* Email */}
          <div className="space-y-2">
            <Label className="text-sm font-medium">Send via email</Label>
            <div className="flex gap-2">
              <Input
                type="email"
                placeholder="partner@email.com"
                value={partnerEmail}
                onChange={(e) => setPartnerEmail(e.target.value)}
              />
              <Button onClick={handleShareViaEmail} disabled={!partnerEmail} className="gap-2 shrink-0">
                <Mail className="w-4 h-4" />
                Send
              </Button>
            </div>
          </div>

          {/* Copy / Native share */}
          <div className="flex gap-3">
            <Button variant="outline" onClick={handleCopy} className="flex-1 gap-2">
              {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
              {copied ? "Copied!" : "Copy to Clipboard"}
            </Button>
            <Button onClick={handleNativeShare} className="flex-1 gap-2 gradient-gold text-primary-foreground">
              <Share2 className="w-4 h-4" />
              Share
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default PartnerShareDialog;
