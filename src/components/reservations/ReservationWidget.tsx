import { useState, useMemo } from "react";
import { Button } from "@/components/ui/button";
import { Calendar, Clock, Users, ExternalLink, Phone, AlertCircle, MapPin } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  detectRegionFromAddress,
  getTopTwoPlatformsForRegion,
  PLATFORM_ICONS,
  type ReservationPlatformConfig,
} from "@/lib/reservationPlatforms";
import { cn } from "@/lib/utils";

/** Hex (without #) to rgba string with given alpha, for chip background. */
function hexToRgba(hex: string, alpha: number): string {
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

interface ReservationWidgetProps {
  venueName: string;
  venueType: string;
  validated?: boolean;
  placeId?: string;
  address?: string;
  phoneNumber?: string;
  /** Direct OpenTable/Resy or venue booking URL — shown as primary CTA when set */
  bookingUrl?: string;
  /** Preferred platform for label (e.g. "Reserve on OpenTable") */
  reservationPlatform?: 'opentable' | 'resy' | string;
  websiteUrl?: string;
  openingHours?: string[];
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onReservationMade?: () => void;
}

const ReservationWidget = ({
  venueName,
  venueType,
  validated,
  placeId,
  address,
  phoneNumber,
  bookingUrl,
  reservationPlatform,
  websiteUrl,
  openingHours,
  open,
  onOpenChange,
  onReservationMade,
}: ReservationWidgetProps) => {
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [partySize, setPartySize] = useState("2");

  // Detect region and get top two dining reservation platforms for that country
  const { region, platforms } = useMemo(() => {
    const detectedRegion = detectRegionFromAddress(address);
    const list = getTopTwoPlatformsForRegion(detectedRegion);
    return { region: detectedRegion, platforms: list };
  }, [address]);

  const handlePlatformClick = (platform: ReservationPlatformConfig) => {
    const url = platform.getUrl({ venueName, date, time, partySize, address });
    window.open(url, "_blank", "noopener,noreferrer");
    onReservationMade?.();
  };

  const handleCall = () => {
    if (phoneNumber) {
      window.location.href = `tel:${phoneNumber.replace(/[^0-9+]/g, "")}`;
    }
  };

  const handleGoogleSearch = () => {
    const searchQuery = encodeURIComponent(`${venueName} ${address || ""} reservations`);
    window.open(`https://www.google.com/search?q=${searchQuery}`, "_blank", "noopener,noreferrer");
  };

  const handleViewOnMaps = () => {
    if (placeId) {
      window.open(`https://www.google.com/maps/place/?q=place_id:${placeId}`, "_blank", "noopener,noreferrer");
    } else if (address) {
      const query = encodeURIComponent(address);
      window.open(`https://www.google.com/maps/search/?api=1&query=${query}`, "_blank", "noopener,noreferrer");
    }
  };

  // Generate time slots
  const timeSlots = [];
  for (let h = 11; h <= 22; h++) {
    for (const m of ["00", "30"]) {
      const hour = h > 12 ? h - 12 : h;
      const ampm = h >= 12 ? "PM" : "AM";
      timeSlots.push({
        value: `${h.toString().padStart(2, "0")}:${m}`,
        label: `${hour}:${m} ${ampm}`,
      });
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display text-2xl">Make a Reservation</DialogTitle>
          <DialogDescription>
            Book a table at <span className="font-semibold">{venueName}</span>
            {address && (
              <span className="block mt-2 text-muted-foreground font-normal">
                <MapPin className="inline w-3.5 h-3.5 mr-1" />
                {address}
              </span>
            )}
          </DialogDescription>
        </DialogHeader>

        {(websiteUrl || (openingHours && openingHours.length > 0)) && (
          <div className="rounded-lg border border-border bg-muted/30 p-3 text-sm space-y-2">
            {websiteUrl && (
              <a href={websiteUrl} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline flex items-center gap-1.5">
                <ExternalLink className="w-3.5 h-3.5" />
                Website
              </a>
            )}
            {openingHours && openingHours.length > 0 && (
              <div>
                <p className="font-medium text-muted-foreground mb-1">Hours</p>
                <ul className="text-muted-foreground space-y-0.5">
                  {openingHours.slice(0, 7).map((line, i) => (
                    <li key={i}>{line}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        )}

        {bookingUrl && (reservationPlatform === "opentable" || reservationPlatform === "resy") && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Reserve directly</p>
            <Button
              className="w-full gap-2"
              onClick={() => {
                window.open(bookingUrl, "_blank", "noopener,noreferrer");
                onReservationMade?.();
              }}
            >
              <ExternalLink className="w-4 h-4" />
              Reserve on {reservationPlatform === "opentable" ? "OpenTable" : "Resy"}
            </Button>
          </div>
        )}

        <div className="space-y-4 mt-4">
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              Date
            </Label>
            <Input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              min={new Date().toISOString().split("T")[0]}
            />
          </div>

          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <Clock className="w-4 h-4" />
              Time
            </Label>
            <Select value={time} onValueChange={setTime}>
              <SelectTrigger>
                <SelectValue placeholder="Select a time" />
              </SelectTrigger>
              <SelectContent>
                {timeSlots.map((slot) => (
                  <SelectItem key={slot.value} value={slot.value}>
                    {slot.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <Users className="w-4 h-4" />
              Party Size
            </Label>
            <Select value={partySize} onValueChange={setPartySize}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {[1, 2, 3, 4, 5, 6, 7, 8].map((size) => (
                  <SelectItem key={size} value={size.toString()}>
                    {size} {size === 1 ? "person" : "people"}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="border-t border-border pt-4 mt-4">
            <p className="text-sm font-medium text-foreground mb-1">Reserve a table</p>
            <p className="text-xs text-muted-foreground mb-3">Select date & time above, then tap a platform to open it.</p>
            <div className="grid grid-cols-2 gap-3">
              {platforms.map((platform) => {
                const iconConfig = PLATFORM_ICONS[platform.id];
                const brandColor = iconConfig?.color ?? "6b7280";
                const hasLogo = iconConfig?.slug != null;
                const isDisabled = !date || !time;
                const bgStyle =
                  isDisabled ? undefined : {
                    backgroundColor: hexToRgba(brandColor, 0.14),
                    borderColor: `#${brandColor}`,
                  };
                return (
                  <button
                    key={platform.id}
                    type="button"
                    onClick={() => handlePlatformClick(platform)}
                    disabled={isDisabled}
                    className={cn(
                      "flex items-center gap-3 rounded-xl border-2 p-3 text-left transition-all duration-200",
                      !isDisabled &&
                        "hover:shadow-lg hover:brightness-[1.02] active:scale-[0.98] active:brightness-[0.98]",
                      "disabled:pointer-events-none disabled:opacity-50 disabled:cursor-not-allowed",
                      "cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
                      isDisabled && "border-border bg-muted/40"
                    )}
                    style={!isDisabled ? bgStyle : undefined}
                    aria-label={`Reserve on ${platform.name}`}
                  >
                    <span
                      className={cn(
                        "flex shrink-0 items-center justify-center rounded-lg w-10 h-10",
                        hasLogo ? "bg-white/80" : "text-white"
                      )}
                      style={!hasLogo ? { backgroundColor: `#${brandColor}` } : undefined}
                    >
                      {hasLogo ? (
                        <img
                          src={`https://cdn.simpleicons.org/${iconConfig.slug}/${brandColor}`}
                          alt=""
                          className="w-6 h-6 object-contain"
                          width={24}
                          height={24}
                        />
                      ) : (
                        <span className="text-sm font-bold leading-none">
                          {platform.name.charAt(0)}
                        </span>
                      )}
                    </span>
                    <span
                      className={cn(
                        "font-semibold text-sm truncate",
                        isDisabled ? "text-muted-foreground" : "text-foreground"
                      )}
                    >
                      {platform.name}
                    </span>
                    <ExternalLink
                      className={cn(
                        "w-4 h-4 shrink-0 ml-auto",
                        isDisabled ? "text-muted-foreground" : "text-foreground/70"
                      )}
                      aria-hidden
                    />
                  </button>
                );
              })}
            </div>
          </div>

          {/* Fallback Option */}
          <Alert className="bg-muted/50 border-amber-500/30">
            <AlertCircle className="h-4 w-4 text-amber-500" />
            <AlertDescription className="text-sm">
              <span className="font-medium">
                Prefer to call or find the website?
              </span>
              <p className="mt-1 text-muted-foreground">
                Some restaurants take reservations by phone or their own website.
              </p>
              <div className="flex gap-2 mt-3">
                {phoneNumber && (
                  <Button variant="outline" size="sm" onClick={handleCall} className="gap-1">
                    <Phone className="w-3 h-3" />
                    Call Restaurant
                  </Button>
                )}
                <Button variant="outline" size="sm" onClick={handleViewOnMaps} className="gap-1">
                  <MapPin className="w-3 h-3" />
                  {placeId ? "View on Google Maps" : "View on Maps"}
                </Button>
                <Button variant="outline" size="sm" onClick={handleGoogleSearch} className="gap-1">
                  <ExternalLink className="w-3 h-3" />
                  Find Website
                </Button>
              </div>
            </AlertDescription>
          </Alert>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default ReservationWidget;
