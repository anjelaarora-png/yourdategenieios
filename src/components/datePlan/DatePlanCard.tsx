import { DatePlan } from "@/types/datePlan";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Clock, DollarSign, Sparkles, Package, Cloud, Calendar, CheckCircle, AlertCircle, MapPin, Car, Footprints, Train, Bike, Phone, Navigation, Globe } from "lucide-react";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { generateVenueSearchUrl } from "@/lib/linkUtils";

interface VenueReservationInfo {
  name: string;
  venueType: string;
  validated?: boolean;
  placeId?: string;
  address?: string;
  phoneNumber?: string;
}

interface DatePlanCardProps {
  plan: DatePlan;
  onMakeReservation?: (stop: VenueReservationInfo) => void;
  onGetMoreGifts?: () => void;
}

const DatePlanCard = ({ plan, onMakeReservation, onGetMoreGifts }: DatePlanCardProps) => {

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

  // Safe getters for optional plan properties
  const safeStops = Array.isArray(plan.stops) ? plan.stops : [];
  const safeGiftSuggestions = Array.isArray(plan.giftSuggestions) ? plan.giftSuggestions : [];
  const safeConversationStarters = Array.isArray(plan.conversationStarters) ? plan.conversationStarters : [];
  const safePackingList = Array.isArray(plan.packingList) ? plan.packingList : [];
  const safeGenieTouch = plan.genieSecretTouch && typeof plan.genieSecretTouch === 'object' 
    ? plan.genieSecretTouch 
    : { title: '', description: '', emoji: '✨' };

  const getTravelIcon = (mode?: string) => {
    switch (mode?.toLowerCase()) {
      case "walking":
        return <Footprints className="w-3 h-3" />;
      case "driving":
      case "rideshare":
        return <Car className="w-3 h-3" />;
      case "transit":
      case "public-transit":
        return <Train className="w-3 h-3" />;
      case "biking":
        return <Bike className="w-3 h-3" />;
      default:
        return <Car className="w-3 h-3" />;
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center space-y-2">
        <h2 className="font-display text-3xl sm:text-4xl text-foreground">{plan.title || 'Your Date Plan'}</h2>
        <p className="text-muted-foreground italic text-lg">{plan.tagline || 'A special experience awaits'}</p>
        <div className="flex items-center justify-center gap-4 pt-2">
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
        
        <div className="space-y-4">
          {safeStops.map((stop, index) => {
            // Skip invalid stops
            if (!stop || typeof stop !== 'object') return null;
            
            return (
            <div key={index} className="relative pl-16">
              {/* Travel indicator between stops */}
              {stop.travelTimeFromPrevious && typeof stop.travelTimeFromPrevious === 'string' && (
                <div className="absolute left-[14px] -top-3 transform -translate-y-full">
                  <div className="flex items-center gap-1.5 bg-muted/80 backdrop-blur-sm rounded-full px-2 py-1 text-xs text-muted-foreground border border-border/50 shadow-sm">
                    {getTravelIcon(stop.travelMode)}
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
              {/* Timeline dot */}
              <div className="absolute left-4 w-5 h-5 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shadow-lg">
                {stop.order}
              </div>
              
              <Card className="border-border bg-card hover:shadow-lg transition-shadow">
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1">
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
                          <MapPin className="w-3 h-3" />
                          {stop.address}
                        </p>
                      )}
                      {/* Hours - Always visible when available */}
                      {stop.openingHours && stop.openingHours.length > 0 && (
                        <div className="mt-2 text-xs text-muted-foreground">
                          <div className="flex items-center gap-1 mb-1">
                            <Clock className="w-3 h-3" />
                            <span className="font-medium">Hours:</span>
                          </div>
                          <div className="ml-4 space-y-0.5">
                            {stop.openingHours.map((line, i) => (
                              <p key={i}>{line}</p>
                            ))}
                          </div>
                        </div>
                      )}
                      {/* Venue links */}
                      <div className="flex flex-wrap items-center gap-2 mt-2">
                        {/* Website or Google Maps profile */}
                        <a
                          href={stop.websiteUrl || (stop.placeId 
                            ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                            : generateVenueSearchUrl(stop.name, stop.address?.split(",").pop()?.trim()))}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs text-primary hover:underline flex items-center gap-1"
                        >
                          <Globe className="w-3 h-3" />
                          {stop.websiteUrl ? "Website" : "Google Maps Profile"}
                        </a>
                        {/* View on Google Maps */}
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
                    <div className="flex items-center gap-2">
                      {onMakeReservation && isRestaurantOrBar(stop.venueType) && (
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
                      <Badge variant="outline" className="shrink-0">
                        {stop.timeSlot}
                      </Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  <p className="text-foreground">{stop.description}</p>
                  
                  <div className="bg-muted/50 rounded-lg p-3 space-y-2">
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
                  <div className="flex items-center justify-between">
                    <span className="font-medium flex items-center gap-2">
                      <span>{gift.emoji}</span>
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
                    <Badge variant="outline" className="text-xs">{gift.priceRange}</Badge>
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
