import { useState } from "react";
import { DatePlan, GiftSuggestion } from "@/types/datePlan";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Clock, DollarSign, Sparkles, Package, Cloud, Calendar, CheckCircle, AlertCircle, MapPin, Car, Footprints, Train, Bike, Phone, Navigation, Globe, Heart, ExternalLink, ShoppingBag, ChevronDown, ChevronUp } from "lucide-react";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { generateVenueSearchUrl } from "@/lib/linkUtils";
import { useSavedGifts } from "@/hooks/useSavedGifts";
import { useToast } from "@/hooks/use-toast";

interface VenueReservationInfo {
  name: string;
  venueType: string;
  validated?: boolean;
  placeId?: string;
  address?: string;
  phoneNumber?: string;
  /** Direct OpenTable/Resy or venue booking URL — use for dinner/restaurants */
  bookingUrl?: string;
  /** Preferred platform when bookingUrl is set (e.g. "opentable", "resy") */
  reservationPlatform?: 'opentable' | 'resy' | string;
  websiteUrl?: string;
  openingHours?: string[];
}

interface DatePlanCardProps {
  plan: DatePlan;
  onMakeReservation?: (stop: VenueReservationInfo) => void;
  onGetMoreGifts?: () => void;
  /** Selected transportation mode for travel icons between stops (walking, driving, etc.). */
  transportationMode?: string;
}

function inferReservationPlatform(bookingUrl?: string): 'opentable' | 'resy' | string | undefined {
  if (!bookingUrl) return undefined;
  const lower = bookingUrl.toLowerCase();
  if (lower.includes('opentable.com')) return 'opentable';
  if (lower.includes('resy.com')) return 'resy';
  return undefined;
}

const DatePlanCard = ({ plan, onMakeReservation, onGetMoreGifts, transportationMode }: DatePlanCardProps) => {
  const { toast } = useToast();
  // Itinerary = venues only; exclude starting point if it was ever included as a stop
  const itineraryStops = (Array.isArray(plan.stops) ? plan.stops : []).filter(
    (s) => s && s.venueType !== "Starting point" && s.name !== "Your location"
  );
  const { toggleSavedGift, isSaved, markAsPurchased, isPurchased } = useSavedGifts();

  const handleSaveGift = (gift: GiftSuggestion) => {
    const wasSaved = isSaved(gift);
    toggleSavedGift(gift);
    toast({
      title: wasSaved ? "Removed from saved gifts" : "Saved to My Gifts",
      description: wasSaved ? undefined : "Find it anytime under the Gifts tab.",
    });
  };

  const handleMarkAsBought = (gift: GiftSuggestion) => {
    markAsPurchased(gift);
    toast({ title: "Marked as bought", description: "Won't be recommended again." });
  };

  // Defensive check for plan object
  if (!plan || typeof plan !== 'object') {
    return (
      <div className="flex items-center justify-center p-8 text-muted-foreground">
        Unable to display date plan. Please try regenerating.
      </div>
    );
  }

  const isRestaurantOrBar = (venueType?: string) => {
    if (!venueType || typeof venueType !== 'string') return false;
    const types = ["restaurant", "bar", "dining", "cafe", "bistro", "tavern", "eatery"];
    return types.some((t) => venueType.toLowerCase().includes(t));
  };

  // Safe getters for optional plan properties; timeline shows only itinerary (venues), numbered 1, 2, 3...
  const safeStops = itineraryStops;
  const safeGiftSuggestions = Array.isArray(plan.giftSuggestions) ? plan.giftSuggestions : [];
  const safeConversationStarters = Array.isArray(plan.conversationStarters) ? plan.conversationStarters : [];
  const safePackingList = Array.isArray(plan.packingList) ? plan.packingList : [];
  const safeGenieTouch = plan.genieSecretTouch && typeof plan.genieSecretTouch === 'object' 
    ? plan.genieSecretTouch 
    : { title: '', description: '', emoji: '✨' };

  /** Resolve travel mode for icon: prefer stop.travelMode, else infer from travelTimeFromPrevious text (e.g. "Drive 15 mins"), else questionnaire transportationMode. */
  const resolveTravelMode = (stop: { travelMode?: string; travelTimeFromPrevious?: string }) => {
    if (stop.travelMode && stop.travelMode.trim()) return stop.travelMode.trim();
    const text = (stop.travelTimeFromPrevious || "").toLowerCase();
    if (/driv|car|drive/.test(text)) return "driving";
    if (/uber|lyft|taxi|rideshare/.test(text)) return "rideshare";
    if (/transit|bus|train|subway|metro/.test(text)) return "transit";
    if (/bike|cycl/.test(text)) return "biking";
    if (/walk|foot/.test(text)) return "walking";
    return transportationMode || "";
  };

  const getTravelIcon = (mode?: string) => {
    const m = (mode || "").toLowerCase();
    if (m.includes("driv") || m === "car" || m === "drive" || m === "driving" || m === "rideshare") return <Car className="w-3 h-3" />;
    if (m === "walking" || m.includes("walk") || m.includes("foot")) return <Footprints className="w-3 h-3" />;
    if (m === "transit" || m === "public-transit" || m.includes("transit") || m.includes("bus") || m.includes("train")) return <Train className="w-3 h-3" />;
    if (m === "biking" || m.includes("bike") || m.includes("cycl")) return <Bike className="w-3 h-3" />;
    return <Footprints className="w-3 h-3" />;
  };

  const [expandedHoursStopIndex, setExpandedHoursStopIndex] = useState<number | null>(null);

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="text-center space-y-1.5">
        <h2 className="font-display text-3xl sm:text-4xl text-foreground">{plan.title || 'Your Date Plan'}</h2>
        <p className="text-muted-foreground italic text-lg">{plan.tagline || 'A special experience awaits'}</p>
        <div className="flex items-center justify-center gap-3 pt-1.5">
          <Badge variant="secondary" className="gap-1">
            <Clock className="w-3 h-3" />
            {plan.totalDuration || '3-4 hours'}
          </Badge>
          <Badge variant="secondary" className="gap-1">
            <DollarSign className="w-3 h-3" />
            {plan.estimatedCost || '$50-100'}
          </Badge>
        </div>
      </div>

      {/* Timeline */}
      {safeStops.length > 0 ? (
      <div className="relative">
        <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-gradient-to-b from-primary via-primary/50 to-primary/20" />
        
        <div className="space-y-3">
          {safeStops.map((stop, index) => {
            // Skip invalid stops
            if (!stop || typeof stop !== 'object') return null;
            
            return (
            <div key={index} className="relative pl-16">
              {/* Travel indicator between stops */}
              {stop.travelTimeFromPrevious && typeof stop.travelTimeFromPrevious === 'string' && (
                <div className="absolute left-[14px] -top-3 transform -translate-y-full">
                  <div className="flex items-center gap-1.5 bg-muted/80 backdrop-blur-sm rounded-full px-2 py-1 text-xs text-muted-foreground border border-border/50 shadow-sm">
                    {getTravelIcon(resolveTravelMode(stop))}
                    <span>{stop.travelTimeFromPrevious}</span>
                    {stop.travelDistanceFromPrevious && (
                      <>
                        <span className="text-muted-foreground/50">•</span>
                        <span>{stop.travelDistanceFromPrevious}</span>
                      </>
                    )}
                  </div>
                </div>
              )}
              {/* Timeline dot: step number is position in itinerary (1, 2, 3...) */}
              <div className="absolute left-4 w-5 h-5 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shadow-lg">
                {index + 1}
              </div>
              
              <Card className="border-border bg-card hover:shadow-lg transition-shadow">
                <CardHeader className="pb-1.5 pt-4 px-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <h3 className="font-display text-xl flex items-center gap-2">
                        <span>{stop.emoji}</span>
                        {stop.name}
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              {stop.validated ? (
                                <CheckCircle className="w-4 h-4 text-green-500" />
                              ) : (
                                <AlertCircle className="w-4 h-4 text-amber-500" />
                              )}
                            </TooltipTrigger>
                            <TooltipContent>
                              {stop.validated ? "Verified venue" : "Unverified venue"}
                            </TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      </h3>
                      <p className="text-sm text-muted-foreground">{stop.venueType}</p>
                      {stop.address && (
                        <p className="text-xs text-muted-foreground/70 flex items-center gap-1 mt-0.5">
                          <MapPin className="w-3 h-3 shrink-0" />
                          {stop.address}
                        </p>
                      )}
                      {/* Hours - collapsed by default, expand on tap */}
                      {stop.openingHours && stop.openingHours.length > 0 && (
                        <div className="mt-1.5 text-xs text-muted-foreground">
                          <button
                            type="button"
                            onClick={() => setExpandedHoursStopIndex(expandedHoursStopIndex === index ? null : index)}
                            className="flex items-center gap-1.5 font-medium hover:text-foreground/80 transition-colors"
                          >
                            <Clock className="w-3 h-3" />
                            <span>Hours{stop.validated ? " (from Google)" : ""}</span>
                            {expandedHoursStopIndex === index ? (
                              <ChevronUp className="w-3 h-3" />
                            ) : (
                              <ChevronDown className="w-3 h-3" />
                            )}
                          </button>
                          {expandedHoursStopIndex === index && (
                            <div className="ml-4 mt-1 space-y-0.5">
                              {stop.openingHours.map((line, i) => (
                                <p key={i}>{line}</p>
                              ))}
                            </div>
                          )}
                        </div>
                      )}
                      {/* Venue links */}
                      <div className="flex flex-wrap items-center gap-2 mt-1.5">
                        {stop.websiteUrl && (
                          <a
                            href={stop.websiteUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-primary hover:underline flex items-center gap-1"
                          >
                            <Globe className="w-3 h-3" />
                            Website{stop.validated ? " (Google)" : ""}
                          </a>
                        )}
                        <a
                          href={stop.placeId
                            ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                            : generateVenueSearchUrl(stop.name, stop.address?.split(",").pop()?.trim())}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs text-primary hover:underline flex items-center gap-1"
                        >
                          <MapPin className="w-3 h-3" />
                          {stop.placeId ? "View on Maps (business)" : "Search on Maps"}
                        </a>
                        <button
                          onClick={() => {
                            const mapUrl = stop.placeId
                              ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                              : generateVenueSearchUrl(stop.name, stop.address?.split(",").pop()?.trim());
                            window.open(mapUrl, "_blank", "noopener,noreferrer");
                          }}
                          className="text-xs text-primary hover:underline flex items-center gap-1 cursor-pointer"
                        >
                          <Navigation className="w-3 h-3" />
                          Directions
                        </button>
                        {stop.phoneNumber && (
                          <a
                            href={`tel:${stop.phoneNumber.replace(/[^0-9+]/g, "")}`}
                            className="text-xs text-muted-foreground hover:text-foreground flex items-center gap-1"
                          >
                            <Phone className="w-3 h-3" />
                            {stop.phoneNumber}
                          </a>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-2 flex-wrap">
                      {onMakeReservation && isRestaurantOrBar(stop.venueType) && (
                        <>
                          {stop.bookingUrl && (inferReservationPlatform(stop.bookingUrl) === 'opentable' || inferReservationPlatform(stop.bookingUrl) === 'resy') ? (
                            <>
                              <Button
                                variant="default"
                                size="sm"
                                onClick={() => window.open(stop.bookingUrl!, "_blank", "noopener,noreferrer")}
                                className="gap-1"
                              >
                                <Calendar className="w-3 h-3" />
                                Reserve on {inferReservationPlatform(stop.bookingUrl) === 'opentable' ? 'OpenTable' : 'Resy'}
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() =>
                                  onMakeReservation({
                                    name: stop.name,
                                    venueType: stop.venueType,
                                    validated: stop.validated,
                                    placeId: stop.placeId,
                                    address: stop.address,
                                    phoneNumber: stop.phoneNumber,
                                    bookingUrl: stop.bookingUrl,
                                    reservationPlatform: inferReservationPlatform(stop.bookingUrl),
                                    websiteUrl: stop.websiteUrl,
                                    openingHours: stop.openingHours,
                                  })
                                }
                                className="gap-1"
                              >
                                More options
                              </Button>
                            </>
                          ) : (
                            <TooltipProvider>
                              <Tooltip>
                                <TooltipTrigger asChild>
                                  <span>
                                    <Button
                                      variant="outline"
                                      size="sm"
                                      onClick={() =>
                                        onMakeReservation({
                                          name: stop.name,
                                          venueType: stop.venueType,
                                          validated: stop.validated,
                                          placeId: stop.placeId,
                                          address: stop.address,
                                          phoneNumber: stop.phoneNumber,
                                          bookingUrl: stop.bookingUrl,
                                          reservationPlatform: inferReservationPlatform(stop.bookingUrl),
                                          websiteUrl: stop.websiteUrl,
                                          openingHours: stop.openingHours,
                                        })
                                      }
                                      className="gap-1"
                                    >
                                      <Calendar className="w-3 h-3" />
                                      Reserve
                                    </Button>
                                  </span>
                                </TooltipTrigger>
                                {!stop.validated && (
                                  <TooltipContent>
                                    <p>Venue isn't verified yet — reservation links still work.</p>
                                  </TooltipContent>
                                )}
                              </Tooltip>
                            </TooltipProvider>
                          )}
                        </>
                      )}
                      <Badge variant="outline" className="shrink-0">
                        {stop.timeSlot}
                      </Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-2.5 px-4 pb-4">
                  <p className="text-foreground text-sm">{stop.description}</p>
                  
                  <div className="bg-muted/50 rounded-lg p-2.5 space-y-1.5">
                    <p className="text-sm">
                      <span className="font-medium text-primary">Why this fits: </span>
                      <span className="text-muted-foreground">{stop.whyItFits}</span>
                    </p>
                    <p className="text-sm">
                      <span className="font-medium text-primary">💝 Romantic tip: </span>
                      <span className="text-muted-foreground">{stop.romanticTip}</span>
                    </p>
                  </div>
                  
                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <span>Duration: {stop.duration || 'Not specified'}</span>
                    {stop.estimatedCostPerPerson && typeof stop.estimatedCostPerPerson === 'string' && (
                      <Badge variant="outline" className="text-xs">
                        <DollarSign className="w-3 h-3 mr-1" />
                        {stop.estimatedCostPerPerson}/person
                      </Badge>
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>
            );
          })}
        </div>
      </div>
      ) : (
        <div className="flex flex-col items-center justify-center p-8 bg-muted rounded-lg gap-4 text-center">
          <MapPin className="w-12 h-12 text-muted-foreground/50" />
          <div>
            <p className="text-foreground font-medium mb-1">Venues couldn't be loaded</p>
            <p className="text-muted-foreground text-sm max-w-md">
              We had trouble finding verified venues for this location. Try regenerating with a major city like "Austin, TX" or "New York, NY" for best results.
            </p>
          </div>
        </div>
      )}
      {/* Genie's Secret Touch */}
      {safeGenieTouch.title && (
      <Card className="border-primary/30 bg-gradient-to-br from-primary/5 to-primary/10">
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-full gradient-gold flex items-center justify-center shrink-0">
              <Sparkles className="w-6 h-6 text-primary-foreground" />
            </div>
            <div>
              <h3 className="font-display text-xl mb-1 flex items-center gap-2">
                {safeGenieTouch.emoji || '✨'} Genie's Secret Touch
              </h3>
              <p className="font-medium text-primary">{safeGenieTouch.title}</p>
              <p className="text-muted-foreground mt-1">{safeGenieTouch.description || ''}</p>
            </div>
          </div>
        </CardContent>
      </Card>
      )}

      {/* Gift Suggestions */}
      {safeGiftSuggestions.length > 0 && (
        <Card className="border-primary/20 bg-gradient-to-br from-rose-500/5 to-pink-500/10">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between mb-4">
              <h4 className="font-display text-lg flex items-center gap-2">
                🎁 Gift Suggestions
              </h4>
              {onGetMoreGifts && (
                <Button variant="outline" size="sm" onClick={onGetMoreGifts} className="gap-1">
                  <Sparkles className="w-3 h-3" />
                  Get More Ideas
                </Button>
              )}
            </div>
            <div className="space-y-3">
              {safeGiftSuggestions.map((gift, i) => (
                <div key={i} className="bg-background/50 rounded-lg p-3 space-y-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-medium flex items-center gap-2 flex-wrap">
                      <div className="relative w-8 h-8 shrink-0 flex items-center justify-center rounded overflow-hidden bg-muted">
                        <span className="text-base">{gift.emoji}</span>
                        {gift.imageUrl && (
                          <img src={gift.imageUrl} alt={gift.name} className="absolute inset-0 w-full h-full object-cover" onError={(e) => { e.currentTarget.style.display = "none"; }} />
                        )}
                      </div>
                      {gift.purchaseUrl ? (
                        <a
                          href={gift.purchaseUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="hover:text-primary hover:underline"
                        >
                          {gift.name}
                        </a>
                      ) : (
                        gift.name
                      )}
                    </span>
                    <div className="flex items-center gap-1.5 shrink-0">
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8"
                              onClick={() => handleSaveGift(gift)}
                            >
                              <Heart
                                className={`w-4 h-4 ${
                                  isSaved(gift) ? "text-primary fill-primary" : "text-muted-foreground"
                                }`}
                              />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>
                            {isSaved(gift) ? "Remove from Saved Gifts" : "Save to Gifts tab"}
                          </TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                      {!isPurchased(gift) ? (
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button
                                type="button"
                                variant="ghost"
                                size="sm"
                                className="h-8 gap-1 text-xs"
                                onClick={() => handleMarkAsBought(gift)}
                              >
                                <ShoppingBag className="w-3.5 h-3.5" />
                                Bought
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>Mark as bought so it won&apos;t be recommended again</TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      ) : (
                        <Badge variant="secondary" className="text-xs gap-0.5">
                          <CheckCircle className="w-3 h-3" />
                          Bought
                        </Badge>
                      )}
                      <Badge variant="outline" className="text-xs">{gift.priceRange}</Badge>
                    </div>
                  </div>
                  <p className="text-sm text-muted-foreground">{gift.description}</p>
                  <p className="text-xs text-muted-foreground">
                    <span className="text-primary font-medium">Where to buy:</span> {gift.whereToBuy}
                  </p>
                  <p className="text-xs text-muted-foreground italic">{gift.whyItFits}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Conversation Starters */}
      {safeConversationStarters.length > 0 && (
        <Card className="border-primary/20 bg-gradient-to-br from-blue-500/5 to-indigo-500/10">
          <CardContent className="pt-6">
            <h4 className="font-display text-lg mb-4 flex items-center gap-2">
              💬 Conversation Starters
            </h4>
            <div className="grid gap-2 sm:grid-cols-2">
              {safeConversationStarters.map((convo, i) => (
                <div key={i} className="bg-background/50 rounded-lg p-3 flex items-start gap-2">
                  <span className="text-lg shrink-0">{convo.emoji}</span>
                  <div>
                    <p className="text-sm font-medium text-foreground">{convo.question}</p>
                    <Badge variant="secondary" className="text-xs mt-1">{convo.category}</Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Footer info */}
      <div className="grid sm:grid-cols-2 gap-4">
        {safePackingList.length > 0 && (
          <Card className="border-border">
            <CardContent className="pt-4">
              <h4 className="font-medium flex items-center gap-2 mb-2">
                <Package className="w-4 h-4 text-primary" />
                What to Bring
              </h4>
              <ul className="text-sm text-muted-foreground space-y-1">
                {safePackingList.map((item, i) => (
                  <li key={i} className="flex items-center gap-2">
                    <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                    {item}
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        )}
        
        {plan.weatherNote && (
          <Card className="border-border">
            <CardContent className="pt-4">
              <h4 className="font-medium flex items-center gap-2 mb-2">
                <Cloud className="w-4 h-4 text-primary" />
                Weather Note
              </h4>
              <p className="text-sm text-muted-foreground">{plan.weatherNote}</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
};

export default DatePlanCard;
