import { useState, useMemo } from "react";
import type { ReservationPlatformConfig } from "@/lib/reservationPlatforms";
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
} from "@/lib/reservationPlatforms";
import { cn } from "@/lib/utils";

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
  const [failedIconSlugs, setFailedIconSlugs] = useState<Set<string>>(new Set());

  // Detect region and get top two dining reservation platforms for that country
  const { region, platforms } = useMemo(() => {
    const detectedRegion = detectRegionFromAddress(address);
    const list = getTopTwoPlatformsForRegion(detectedRegion);
    return { region: detectedRegion, platforms: list };
  }, [address]);

  const handlePlatformClick = (platform: ReservationPlatformConfig) => {
    // Use restaurant's actual booking page when we have a direct link for this platform
    const useDirectLink =
      bookingUrl &&
      (platform.id === reservationPlatform || platform.id === inferPlatformFromUrl(bookingUrl));
    const today = new Date().toISOString().slice(0, 10);
    const url = useDirectLink
      ? bookingUrl!
      : platform.getUrl({
          venueName: venueName || "Restaurant",
          date: date || today,
          time: time || "19:00",
          partySize,
          address,
        });
    window.open(url, "_blank", "noopener,noreferrer");
    onReservationMade?.();
  };

  function inferPlatformFromUrl(url: string): string | undefined {
    const lower = url.toLowerCase();
    if (lower.includes("opentable.com")) return "opentable";
    if (lower.includes("resy.com")) return "resy";
    return undefined;
  }

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
                const slug = iconConfig?.slug;
                const hasLogo = slug != null && !failedIconSlugs.has(platform.id);
                const useDirectLink =
                  !!bookingUrl &&
                  (platform.id === reservationPlatform || platform.id === inferPlatformFromUrl(bookingUrl));
                return (
                  <button
                    key={platform.id}
                    type="button"
                    onClick={() => handlePlatformClick(platform)}
                    className={cn(
                      "flex items-center gap-3 rounded-xl border-2 p-3 text-left transition-all duration-200",
                      "border-border bg-card text-foreground",
                      "hover:bg-accent/50 hover:border-accent hover:shadow-md active:scale-[0.98]",
                      "cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                    )}
                    aria-label={`Reserve on ${platform.name}${useDirectLink ? " (direct link)" : ""}`}
                  >
                    <span
                      className={cn(
                        "flex shrink-0 items-center justify-center rounded-lg w-10 h-10 border border-border",
                        hasLogo ? "bg-muted" : "text-white"
                      )}
                      style={
                        hasLogo
                          ? { borderColor: `#${brandColor}40` }
                          : { backgroundColor: `#${brandColor}` }
                      }
                    >
                      {hasLogo && slug ? (
                        <img
                          src={`https://cdn.simpleicons.org/${slug}/${brandColor}`}
                          alt=""
                          className="w-6 h-6 object-contain"
                          width={24}
                          height={24}
                          onError={() => setFailedIconSlugs((s) => new Set(s).add(platform.id))}
                        />
                      ) : (
                        <span className="text-sm font-bold leading-none">
                          {platform.name.charAt(0)}
                        </span>
                      )}
                    </span>
                    <span
                      className={cn(
                        "font-semibold text-sm text-foreground flex-1 min-w-0 break-words"
                      )}
                      style={{ wordBreak: "break-word" }}
                    >
                      {platform.name}
                    </span>
                    <ExternalLink
                      className="w-4 h-4 shrink-0 text-foreground/70"
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
