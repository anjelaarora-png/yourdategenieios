import { useState, useRef } from "react";
import { ArrowLeft, Bookmark, Share2, MapPin, Clock, DollarSign, Sparkles, ChevronLeft, ChevronRight, Navigation, Phone, Globe, Check, Gift, MessageCircle, CheckCircle, AlertCircle, Music } from "lucide-react";
import { DatePlan, GiftSuggestion, ConversationStarter } from "@/types/datePlan";

interface MobileDatePlanResultProps {
  plans: DatePlan[];
  selectedIndex: number;
  onSelectPlan: (index: number) => void;
  onSavePlan: (plan: DatePlan) => Promise<unknown>;
  onBack: () => void;
}

const MobileDatePlanResult = ({
  plans,
  selectedIndex,
  onSelectPlan,
  onSavePlan,
  onBack,
}: MobileDatePlanResultProps) => {
  const [isSaved, setIsSaved] = useState(false);
  const [showGifts, setShowGifts] = useState(false);
  const [showConvos, setShowConvos] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const plan = plans[selectedIndex];

  if (!plan) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-5">
        <div className="text-center">
          <div className="w-16 h-16 rounded-full bg-muted mx-auto mb-4 flex items-center justify-center">
            <MapPin className="w-8 h-8 text-muted-foreground" />
          </div>
          <p className="text-muted-foreground mb-4">No date plan available</p>
          <button onClick={onBack} className="text-primary font-medium">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const handleSave = async () => {
    await onSavePlan(plan);
    setIsSaved(true);
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: plan.title,
          text: `Check out this date plan: ${plan.title} - ${plan.tagline}`,
        });
      } catch {
        // User cancelled share
      }
    }
  };

  const safeStops = Array.isArray(plan.stops) ? plan.stops : [];
  const safeGifts = Array.isArray(plan.giftSuggestions) ? plan.giftSuggestions : [];
  const safeConvos = Array.isArray(plan.conversationStarters) ? plan.conversationStarters : [];

  return (
    <div className="min-h-screen bg-background pb-28">
      {/* Header */}
      <div className="fixed top-0 left-0 right-0 z-50 mobile-nav">
        <div className="flex items-center justify-between h-11 px-4">
          <button onClick={onBack} className="haptic-button p-2 -ml-2 flex items-center gap-1 text-primary">
            <ChevronLeft className="w-5 h-5" />
            <span className="text-sm">Back</span>
          </button>
          <span className="text-sm font-medium">Your Date Plan</span>
          <div className="flex items-center gap-2">
            <button onClick={handleShare} className="haptic-button p-2">
              <Share2 className="w-5 h-5" />
            </button>
            <button onClick={handleSave} className="haptic-button p-2" disabled={isSaved}>
              <Bookmark className={`w-5 h-5 ${isSaved ? "fill-primary text-primary" : ""}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Plan selector (if multiple) */}
      {plans.length > 1 && (
        <div className="pt-16 px-5 pb-2 bg-background sticky top-11 z-40 border-b border-border">
          <div className="flex items-center justify-between">
            <button
              onClick={() => onSelectPlan(Math.max(0, selectedIndex - 1))}
              disabled={selectedIndex === 0}
              className="haptic-button p-2 disabled:opacity-30"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <div className="text-center">
              <p className="text-xs text-muted-foreground">Option {selectedIndex + 1} of {plans.length}</p>
              <p className="font-medium truncate max-w-[200px]">{plan.title}</p>
            </div>
            <button
              onClick={() => onSelectPlan(Math.min(plans.length - 1, selectedIndex + 1))}
              disabled={selectedIndex === plans.length - 1}
              className="haptic-button p-2 disabled:opacity-30"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {/* Content */}
      <div ref={scrollRef} className={`px-5 ${plans.length > 1 ? "pt-4" : "pt-20"}`}>
        {/* Plan header */}
        <div className="text-center mb-6">
          <h1 className="text-2xl font-bold mb-2">{plan.title}</h1>
          <p className="text-muted-foreground italic mb-4">{plan.tagline}</p>
          <div className="flex items-center justify-center gap-3">
            <span className="flex items-center gap-1 text-sm bg-muted px-3 py-1.5 rounded-full">
              <Clock className="w-4 h-4" />
              {plan.totalDuration}
            </span>
            <span className="flex items-center gap-1 text-sm bg-muted px-3 py-1.5 rounded-full">
              <DollarSign className="w-4 h-4" />
              {plan.estimatedCost}
            </span>
          </div>
        </div>

        {/* Action buttons row */}
        <div className="flex gap-2 mb-6">
          {safeGifts.length > 0 && (
            <button
              onClick={() => setShowGifts(true)}
              className="flex-1 ios-card flex items-center justify-center gap-2 py-3 haptic-button"
            >
              <Gift className="w-5 h-5 text-rose-500" />
              <span className="text-sm font-medium">Gifts</span>
            </button>
          )}
          {safeConvos.length > 0 && (
            <button
              onClick={() => setShowConvos(true)}
              className="flex-1 ios-card flex items-center justify-center gap-2 py-3 haptic-button"
            >
              <MessageCircle className="w-5 h-5 text-blue-500" />
              <span className="text-sm font-medium">Convos</span>
            </button>
          )}
          <button className="flex-1 ios-card flex items-center justify-center gap-2 py-3 haptic-button">
            <Music className="w-5 h-5 text-green-500" />
            <span className="text-sm font-medium">Playlist</span>
          </button>
        </div>

        {/* Timeline */}
        {safeStops.length > 0 ? (
          <div className="relative">
            <div className="absolute left-5 top-0 bottom-0 w-0.5 bg-gradient-to-b from-primary via-primary/50 to-primary/20" />

            <div className="space-y-4">
              {safeStops.map((stop, index) => (
                <StopCard key={index} stop={stop} index={index} />
              ))}
            </div>
          </div>
        ) : (
          <div className="ios-card text-center py-8">
            <MapPin className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
            <p className="text-muted-foreground">No venues found for this location</p>
          </div>
        )}

        {/* Genie's Secret Touch */}
        {plan.genieSecretTouch && (
          <div className="mt-6 p-4 rounded-2xl bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl gradient-gold flex items-center justify-center shrink-0">
                <Sparkles className="w-5 h-5 text-primary-foreground" />
              </div>
              <div>
                <p className="text-xs text-primary font-medium mb-1">✨ Genie's Secret Touch</p>
                <p className="font-semibold mb-1">{plan.genieSecretTouch.title}</p>
                <p className="text-sm text-muted-foreground">{plan.genieSecretTouch.description}</p>
              </div>
            </div>
          </div>
        )}

        {/* Packing list */}
        {plan.packingList && plan.packingList.length > 0 && (
          <div className="mt-6 ios-card">
            <h3 className="font-semibold mb-3 flex items-center gap-2">
              📦 What to Bring
            </h3>
            <div className="flex flex-wrap gap-2">
              {plan.packingList.map((item, i) => (
                <span key={i} className="text-sm bg-muted px-3 py-1 rounded-full">
                  {item}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Fixed bottom button */}
      <div className="fixed bottom-0 left-0 right-0 px-5 pb-8 pt-4 bg-gradient-to-t from-background via-background to-transparent">
        <button
          onClick={handleSave}
          disabled={isSaved}
          className={`ios-button w-full flex items-center justify-center gap-2 ${
            isSaved ? "bg-green-500 text-white" : "ios-button-primary"
          }`}
        >
          {isSaved ? (
            <>
              <Check className="w-5 h-5" />
              Saved to Your Plans
            </>
          ) : (
            <>
              <Bookmark className="w-5 h-5" />
              Save This Date Plan
            </>
          )}
        </button>
      </div>

      {/* Gift Sheet */}
      {showGifts && (
        <Sheet title="Gift Suggestions" onClose={() => setShowGifts(false)}>
          <div className="space-y-3">
            {safeGifts.map((gift, i) => (
              <GiftCard key={i} gift={gift} />
            ))}
          </div>
        </Sheet>
      )}

      {/* Conversation Sheet */}
      {showConvos && (
        <Sheet title="Conversation Starters" onClose={() => setShowConvos(false)}>
          <div className="space-y-3">
            {safeConvos.map((convo, i) => (
              <ConvoCard key={i} convo={convo} />
            ))}
          </div>
        </Sheet>
      )}
    </div>
  );
};

// Stop Card Component
interface StopCardProps {
  stop: DatePlan["stops"][0];
  index: number;
}

const StopCard = ({ stop, index }: StopCardProps) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="relative pl-12">
      {/* Timeline dot */}
      <div className="absolute left-3 w-5 h-5 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shadow-lg">
        {index + 1}
      </div>

      <button
        onClick={() => setExpanded(!expanded)}
        className="ios-card w-full text-left haptic-button"
      >
        <div className="flex items-start gap-3">
          <span className="text-2xl">{stop.emoji}</span>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="font-semibold truncate">{stop.name}</h3>
              {stop.validated ? (
                <CheckCircle className="w-4 h-4 text-green-500 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 text-amber-500 shrink-0" />
              )}
            </div>
            <p className="text-sm text-muted-foreground">{stop.venueType}</p>
            <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
              <span className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {stop.timeSlot}
              </span>
              {stop.estimatedCostPerPerson && (
                <span className="flex items-center gap-1">
                  <DollarSign className="w-3 h-3" />
                  {stop.estimatedCostPerPerson}/person
                </span>
              )}
            </div>
          </div>
        </div>

        {expanded && (
          <div className="mt-4 pt-4 border-t border-border space-y-3">
            <p className="text-sm">{stop.description}</p>

            {stop.address && (
              <p className="text-sm text-muted-foreground flex items-start gap-2">
                <MapPin className="w-4 h-4 shrink-0 mt-0.5" />
                {stop.address}
              </p>
            )}

            <div className="bg-muted/50 rounded-lg p-3 space-y-2">
              <p className="text-sm">
                <span className="text-primary font-medium">Why this fits: </span>
                {stop.whyItFits}
              </p>
              <p className="text-sm">
                <span className="text-primary font-medium">💝 Tip: </span>
                {stop.romanticTip}
              </p>
            </div>

            {/* Action buttons */}
            <div className="flex gap-2 pt-2">
              {stop.address && (
                <a
                  href={`https://maps.google.com/?q=${encodeURIComponent(stop.address)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 py-2 bg-primary/10 text-primary rounded-lg text-sm font-medium"
                  onClick={(e) => e.stopPropagation()}
                >
                  <Navigation className="w-4 h-4" />
                  Directions
                </a>
              )}
              {stop.phoneNumber && (
                <a
                  href={`tel:${stop.phoneNumber}`}
                  className="flex items-center justify-center gap-2 py-2 px-4 bg-muted rounded-lg text-sm font-medium"
                  onClick={(e) => e.stopPropagation()}
                >
                  <Phone className="w-4 h-4" />
                  Call
                </a>
              )}
              {stop.websiteUrl && (
                <a
                  href={stop.websiteUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center gap-2 py-2 px-4 bg-muted rounded-lg text-sm font-medium"
                  onClick={(e) => e.stopPropagation()}
                >
                  <Globe className="w-4 h-4" />
                  Website
                </a>
              )}
            </div>
          </div>
        )}
      </button>
    </div>
  );
};

// Sheet Component
const Sheet = ({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) => (
  <>
    <div className="ios-sheet-backdrop" onClick={onClose} />
    <div className="ios-sheet max-h-[70vh] overflow-hidden flex flex-col">
      <div className="swipe-indicator" />
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold">{title}</h2>
        <button onClick={onClose} className="text-primary text-sm font-medium">
          Done
        </button>
      </div>
      <div className="overflow-y-auto flex-1">
        {children}
      </div>
    </div>
  </>
);

// Gift Card
const GiftCard = ({ gift }: { gift: GiftSuggestion }) => (
  <div className="ios-card">
    <div className="flex items-start gap-3">
      <span className="text-2xl">{gift.emoji}</span>
      <div className="flex-1">
        <div className="flex items-center justify-between mb-1">
          <h4 className="font-medium">{gift.name}</h4>
          <span className="text-xs bg-muted px-2 py-1 rounded-full">{gift.priceRange}</span>
        </div>
        <p className="text-sm text-muted-foreground mb-2">{gift.description}</p>
        <p className="text-xs text-muted-foreground">
          <span className="text-primary font-medium">Where to buy:</span> {gift.whereToBuy}
        </p>
      </div>
    </div>
  </div>
);

// Conversation Card
const ConvoCard = ({ convo }: { convo: ConversationStarter }) => (
  <div className="ios-card">
    <div className="flex items-start gap-3">
      <span className="text-2xl">{convo.emoji}</span>
      <div>
        <p className="font-medium mb-1">{convo.question}</p>
        <span className="text-xs bg-muted px-2 py-1 rounded-full">{convo.category}</span>
      </div>
    </div>
  </div>
);

export default MobileDatePlanResult;
