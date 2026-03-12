import { DatePlan, GiftSuggestion } from "@/types/datePlan";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { RefreshCw, Save, Camera, SaveAll, Music, MapPin, Users, ExternalLink, Navigation, Gift } from "lucide-react";
import DatePlanCard from "./DatePlanCard";
import PlanSelector from "./PlanSelector";
import ExportMenu from "./ExportMenu";
import { useToast } from "@/hooks/use-toast";
import { useState } from "react";
import ReservationWidget from "@/components/reservations/ReservationWidget";
import PlaylistWidget from "@/components/playlist/PlaylistWidget";
import RouteMap from "@/components/map/RouteMap";
import PartnerShareDialog from "@/components/sharing/PartnerShareDialog";
import { supabase } from "@/integrations/supabase/client";
import { useSavedGifts } from "@/hooks/useSavedGifts";

interface DatePlanResultProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  plans: DatePlan[];
  selectedIndex: number;
  onSelectPlan: (index: number) => void;
  onRegenerate: () => void;
  isRegenerating?: boolean;
  onSavePlan?: () => void;
  onSaveAllPlans?: () => void;
  isSaved?: boolean;
  areAllSaved?: boolean;
  onCapturePhoto?: () => void;
  isViewingMode?: boolean;
  scheduledDate?: string;
  startTime?: string;
  onUpdatePlanGifts?: (planIndex: number, newGifts: GiftSuggestion[]) => void;
  onNavigateToGifts?: () => void;
  /** Transportation mode from questionnaire (drive, transit, walk, etc.) for route map and "Open Full Route" */
  transportationMode?: string;
}

const DatePlanResult = ({ 
  open, 
  onOpenChange, 
  plans,
  selectedIndex,
  onSelectPlan,
  onRegenerate,
  isRegenerating,
  onSavePlan,
  onSaveAllPlans,
  isSaved,
  areAllSaved,
  onCapturePhoto,
  isViewingMode = false,
  scheduledDate,
  startTime,
  onUpdatePlanGifts,
  onNavigateToGifts,
  transportationMode,
}: DatePlanResultProps) => {
  
  const { toast } = useToast();
  const { purchasedGiftNames } = useSavedGifts();
  const [reservationOpen, setReservationOpen] = useState(false);
  const [playlistOpen, setPlaylistOpen] = useState(false);
  const [partnerShareOpen, setPartnerShareOpen] = useState(false);
  const [showMap, setShowMap] = useState(false);
  const [confirmCloseOpen, setConfirmCloseOpen] = useState(false);
  const [isLoadingGifts, setIsLoadingGifts] = useState(false);
  const [selectedVenue, setSelectedVenue] = useState<{
    name: string;
    type: string;
    validated?: boolean;
    placeId?: string;
    address?: string;
    phoneNumber?: string;
  } | null>(null);

  const plan = plans?.[selectedIndex];
  const hasAnyStops = plan?.stops && plan.stops.length > 0;
  const hasUnsavedPlans = !areAllSaved && !isSaved && !isViewingMode;

  // #region agent log
  fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'DatePlanResult.tsx:84',message:'Component render state',data:{plansLength:plans?.length,selectedIndex,hasPlan:!!plan,isRegenerating,isViewingMode,open},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,B,C,D'})}).catch(()=>{});
  // #endregion

  const handleClose = (newOpen: boolean) => {
    if (!newOpen && hasUnsavedPlans) {
      // User is trying to close with unsaved plans
      setConfirmCloseOpen(true);
    } else {
      onOpenChange(newOpen);
    }
  };

  const handleConfirmClose = () => {
    setConfirmCloseOpen(false);
    onOpenChange(false);
  };

  const handleMakeReservation = (stop: {
    name: string;
    venueType: string;
    validated?: boolean;
    placeId?: string;
    address?: string;
    phoneNumber?: string;
  }) => {
    setSelectedVenue({
      name: stop.name,
      type: stop.venueType,
      validated: stop.validated,
      placeId: stop.placeId,
      address: stop.address,
      phoneNumber: stop.phoneNumber,
    });
    setReservationOpen(true);
  };

  const handleGetMoreGifts = async () => {
    if (isLoadingGifts || !onUpdatePlanGifts || !plan) return;
    
    setIsLoadingGifts(true);
    try {
      const { data, error } = await supabase.functions.invoke("generate-more-gifts", {
        body: {
          planTitle: plan.title,
          occasion: plan.tagline,
          existingGifts: plan.giftSuggestions || [],
          purchasedGiftNames: purchasedGiftNames.length > 0 ? purchasedGiftNames : undefined,
        },
      });

      if (error) throw error;

      if (data?.gifts && Array.isArray(data.gifts)) {
        const existingGifts = plan.giftSuggestions || [];
        const newGifts = [...existingGifts, ...data.gifts];
        onUpdatePlanGifts(selectedIndex, newGifts);
        toast({
          title: "New gift ideas added!",
          description: `Added ${data.gifts.length} more suggestions.`,
        });
      }
    } catch (error) {
      console.error("Error getting more gifts:", error);
      toast({
        title: "Couldn't get more gifts",
        description: "Please try again in a moment.",
        variant: "destructive",
      });
    } finally {
      setIsLoadingGifts(false);
    }
  };

  return (
    <>
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className="sm:max-w-3xl w-[95vw] max-h-[90vh] h-[95vh] sm:h-auto overflow-hidden flex flex-col p-0">
          {/* Header with extra right padding to avoid X button */}
          <DialogHeader className="flex flex-row items-center justify-between space-y-0 px-4 sm:px-6 pt-4 sm:pt-6 pb-2 pr-12 sm:pr-14 border-b border-border flex-shrink-0">
            <DialogTitle className="font-display text-base sm:text-xl truncate">
              {isViewingMode ? "Saved Date Plan" : "Your Date Plans"}
            </DialogTitle>
            {plan && (
              <div className="flex items-center gap-1 sm:gap-2 flex-shrink-0">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setPartnerShareOpen(true)}
                  className="gap-1 h-8 sm:h-9 px-2 sm:px-3"
                >
                  <Users className="w-4 h-4" />
                  <span className="hidden sm:inline">Invite Partner</span>
                </Button>
                <ExportMenu plan={plan} scheduledDate={scheduledDate} startTime={startTime} />
              </div>
            )}
          </DialogHeader>

          {/* Scrollable content area */}
          <div className="flex-1 overflow-y-auto px-4 sm:px-6 py-4 ios-scroll-fix">
            {(() => {
              // #region agent log
              fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'DatePlanResult.tsx:181',message:'Rendering content branch',data:{hasPlan:!!plan,isRegenerating,willShowNoPlanMessage:!plan},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,B,D'})}).catch(()=>{});
              // #endregion
              return null;
            })()}
            {!plan ? (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                {(() => {
                  // #region agent log
                  fetch('http://127.0.0.1:7242/ingest/461790ca-3254-4dd1-9432-46904ed53ab0',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'DatePlanResult.tsx:189',message:'SHOWING NO PLAN AVAILABLE MESSAGE',data:{isRegenerating},timestamp:Date.now(),sessionId:'debug-session',hypothesisId:'A,B,D'})}).catch(()=>{});
                  // #endregion
                  return null;
                })()}
                <p className="text-muted-foreground">No date plan available.</p>
                <Button
                  variant="outline"
                  onClick={() => onOpenChange(false)}
                  className="mt-4"
                >
                  Close
                </Button>
              </div>
            ) : (
              <>
                {/* Only show plan selector when viewing multiple generated plans */}
                {!isViewingMode && plans.length > 1 && (
                  <div className="mb-4">
                    <PlanSelector
                      plans={plans}
                      selectedIndex={selectedIndex}
                      onSelect={onSelectPlan}
                    />
                  </div>
                )}

                <DatePlanCard 
                  plan={plan} 
                  onMakeReservation={handleMakeReservation} 
                  onGetMoreGifts={onUpdatePlanGifts ? handleGetMoreGifts : undefined}
                />

                {/* Route Map Section - Only visible when toggled on */}
                {showMap && hasAnyStops && (
                  <div className="mt-6 pt-6 border-t border-border">
                    <h3 className="font-display text-lg mb-4 flex items-center gap-2">
                      <MapPin className="w-5 h-5 text-primary" />
                      Your Route
                    </h3>
                    
                    {/* Stops Summary List - Numbered 1, 2, 3... */}
                    <div className="bg-muted/50 rounded-lg p-4 mb-4">
                      <div className="flex flex-col gap-3">
                        {plan.stops.map((stop, index) => (
                          <div key={index} className="flex items-start gap-3">
                            <div className="w-7 h-7 rounded-full bg-primary flex items-center justify-center text-sm text-primary-foreground font-bold shrink-0 mt-0.5">
                              {index + 1}
                            </div>
                            <div className="flex-1 min-w-0">
                              <span className="text-sm font-medium block">
                                {stop.emoji} {stop.name}
                              </span>
                              <span className="text-xs text-muted-foreground block">
                                {stop.venueType}
                              </span>
                              {stop.address && (
                                <span className="text-xs text-muted-foreground/70 block mt-0.5">
                                  {stop.address}
                                </span>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Google Maps Button with all stops - use coordinates when available so route starts at your location */}
                    <Button
                      variant="default"
                      className="w-full gap-2 gradient-gold text-primary-foreground hover:opacity-90 mb-4"
                      onClick={() => {
                        const stops = plan.stops || [];
                        if (stops.length === 0) return;
                        const originStop = stops[0];
                        const destStop = stops[stops.length - 1];
                        const wayStops = stops.length > 2 ? stops.slice(1, -1) : [];
                        // Prefer lat/lng so route always starts at the right place (e.g. "Your location"); avoid address parsing that can show wrong city
                        const hasCoord = (s: typeof originStop) =>
                          typeof s.latitude === "number" && typeof s.longitude === "number" && Number.isFinite(s.latitude) && Number.isFinite(s.longitude);
                        const toParam = (s: typeof originStop) =>
                          s.placeId ? `place_id:${s.placeId}` : hasCoord(s) ? `${s.latitude},${s.longitude}` : encodeURIComponent(s.address || s.name || "");
                        const origin = toParam(originStop);
                        const destination = toParam(destStop);
                        const waypoints = wayStops.map(toParam).join("|");
                        const getTravelMode = (mode?: string) => {
                          switch (mode?.toLowerCase()) {
                            case "walking": return "walking";
                            case "driving":
                            case "rideshare": return "driving";
                            case "public-transit":
                            case "transit": return "transit";
                            case "biking": return "bicycling";
                            default: return "walking";
                          }
                        };
                        const q = new URLSearchParams();
                        q.set("api", "1");
                        q.set("origin", origin);
                        q.set("destination", destination);
                        q.set("travelmode", getTravelMode(transportationMode));
                        if (waypoints) q.set("waypoints", waypoints);
                        window.open(`https://www.google.com/maps/dir/?${q.toString()}`, "_blank");
                      }}
                    >
                      <Navigation className="w-4 h-4" />
                      Open Full Route in Google Maps
                      <ExternalLink className="w-4 h-4" />
                    </Button>

                    {/* Interactive Map - use questionnaire transport mode */}
                    <RouteMap stops={plan.stops} transportationMode={transportationMode} className="mt-2" />
                  </div>
                )}
              </>
            )}
          </div>

          {/* Fixed footer - only show when we have a plan */}
          {plan && (
            <div className="flex-shrink-0 p-4 sm:p-6 pt-3 sm:pt-4 border-t border-border bg-background safe-area-bottom">
              {/* Mobile: Stack buttons vertically */}
              <div className="flex flex-col sm:flex-row sm:flex-wrap sm:items-center sm:justify-between gap-3">
                {/* Action buttons row */}
                <div className="flex flex-wrap gap-2 justify-center sm:justify-start">
                  {!isViewingMode && (
                    <Button
                      variant="outline"
                      onClick={onRegenerate}
                      disabled={isRegenerating}
                      size="sm"
                      className="gap-1.5 h-9"
                    >
                      <RefreshCw className={`w-4 h-4 ${isRegenerating ? "animate-spin" : ""}`} />
                      <span className="hidden xs:inline">Regenerate</span>
                    </Button>
                  )}
                  {hasAnyStops && (
                    <Button
                      variant={showMap ? "default" : "outline"}
                      onClick={() => setShowMap(!showMap)}
                      size="sm"
                      className="gap-1.5 h-9"
                    >
                      <MapPin className="w-4 h-4" />
                      <span className="hidden xs:inline">{showMap ? "Hide Route" : "View Route"}</span>
                    </Button>
                  )}
                  <Button
                    variant="outline"
                    onClick={() => setPlaylistOpen(true)}
                    size="sm"
                    className="gap-1.5 h-9"
                  >
                    <Music className="w-4 h-4" />
                    <span className="hidden xs:inline">Playlist</span>
                  </Button>
                  {onCapturePhoto && (
                    <Button variant="outline" onClick={onCapturePhoto} size="sm" className="gap-1.5 h-9">
                      <Camera className="w-4 h-4" />
                      <span className="hidden xs:inline">Memory</span>
                    </Button>
                  )}
                </div>
                
                {/* Save/Done buttons row */}
                <div className="flex gap-2 justify-center sm:justify-end">
                  {onNavigateToGifts && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={onNavigateToGifts}
                      className="gap-1.5 h-9 text-muted-foreground"
                    >
                      <Gift className="w-4 h-4" />
                      View saved gifts
                    </Button>
                  )}
                  {onSaveAllPlans && !areAllSaved && plans.length > 1 && (
                    <Button
                      variant="outline"
                      onClick={onSaveAllPlans}
                      size="sm"
                      className="gap-1.5 h-9"
                    >
                      <SaveAll className="w-4 h-4" />
                      <span className="hidden xs:inline">Save All</span>
                    </Button>
                  )}
                  {onSavePlan && !isSaved && (
                    <Button
                      variant="outline"
                      onClick={onSavePlan}
                      size="sm"
                      className="gap-1.5 h-9"
                    >
                      <Save className="w-4 h-4" />
                      Save
                    </Button>
                  )}
                  <Button
                    onClick={() => handleClose(false)}
                    size="sm"
                    className="gradient-gold text-primary-foreground hover:opacity-90 h-9 px-4"
                  >
                    Done
                  </Button>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Confirmation dialog for closing without saving */}
      <AlertDialog open={confirmCloseOpen} onOpenChange={setConfirmCloseOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Unsaved Date Plans</AlertDialogTitle>
            <AlertDialogDescription>
              You have {plans.length} date plan{plans.length !== 1 ? "s" : ""} that haven't been saved yet. 
              Don't worry - they'll be waiting for you when you come back. But if you want to keep them 
              in your collection, save them now!
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Keep Reviewing</AlertDialogCancel>
            <AlertDialogAction onClick={handleConfirmClose}>
              Close Anyway
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {selectedVenue && (
        <ReservationWidget
          venueName={selectedVenue.name}
          venueType={selectedVenue.type}
          validated={selectedVenue.validated}
          placeId={selectedVenue.placeId}
          address={selectedVenue.address}
          phoneNumber={selectedVenue.phoneNumber}
          open={reservationOpen}
          onOpenChange={setReservationOpen}
        />
      )}

      {plan && (
        <>
          <PlaylistWidget
            datePlan={plan}
            open={playlistOpen}
            onOpenChange={setPlaylistOpen}
          />

          <PartnerShareDialog
            plan={plan}
            open={partnerShareOpen}
            onOpenChange={setPartnerShareOpen}
          />
        </>
      )}
    </>
  );
};

export default DatePlanResult;
