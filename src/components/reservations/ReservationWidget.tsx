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

interface ReservationWidgetProps {
  venueName: string;
  venueType: string;
  validated?: boolean;
  placeId?: string;
  address?: string;
  phoneNumber?: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onReservationMade?: () => void;
}

// Region detection and platform configuration
type Region = 'us' | 'uk' | 'eu' | 'au' | 'asia' | 'india' | 'other';

interface ReservationPlatform {
  name: string;
  getUrl: (params: { venueName: string; date: string; time: string; partySize: string; address?: string }) => string;
  regions: Region[];
}

// Detect region from address
const detectRegion = (address?: string): Region => {
  if (!address) return 'us';
  
  const lowerAddr = address.toLowerCase();
  
  // Country patterns
  const patterns: Array<{ pattern: RegExp; region: Region }> = [
    // US patterns
    { pattern: /\b(usa|united states|u\.s\.a?\.|, [a-z]{2} \d{5})/i, region: 'us' },
    { pattern: /\b(ny|nyc|ca|tx|fl|wa|il|pa|oh|ga|nc|mi|nj|va|az|ma|tn|in|mo|md|wi|mn|co|al|sc|la|ky|or|ok|ct|ut|ia|nv|ar|ms|ks|nm|ne|wv|id|hi|nh|me|mt|ri|de|sd|nd|ak|vt|dc|wy)\b/i, region: 'us' },
    // UK patterns  
    { pattern: /\b(uk|united kingdom|england|scotland|wales|london|manchester|birmingham|liverpool|leeds|glasgow|edinburgh)\b/i, region: 'uk' },
    { pattern: /\b[a-z]{1,2}\d{1,2}[a-z]?\s?\d[a-z]{2}\b/i, region: 'uk' }, // UK postcode
    // EU patterns
    { pattern: /\b(france|germany|spain|italy|netherlands|belgium|austria|switzerland|portugal|ireland|denmark|sweden|norway|finland|greece|poland|czech|hungary)\b/i, region: 'eu' },
    { pattern: /\b(paris|berlin|munich|madrid|barcelona|rome|milan|amsterdam|brussels|vienna|zurich|lisbon|dublin|copenhagen|stockholm)\b/i, region: 'eu' },
    // Australia patterns
    { pattern: /\b(australia|sydney|melbourne|brisbane|perth|adelaide|canberra|nsw|vic|qld|wa|sa|tas|nt|act)\b/i, region: 'au' },
    // Asia patterns (excluding India)
    { pattern: /\b(japan|tokyo|osaka|singapore|hong kong|south korea|seoul|taiwan|taipei|thailand|bangkok|vietnam|malaysia|indonesia|philippines)\b/i, region: 'asia' },
    // India patterns
    { pattern: /\b(india|mumbai|delhi|bangalore|bengaluru|chennai|hyderabad|kolkata|pune|ahmedabad|jaipur|lucknow|surat)\b/i, region: 'india' },
  ];
  
  for (const { pattern, region } of patterns) {
    if (pattern.test(lowerAddr)) {
      return region;
    }
  }
  
  return 'us'; // Default to US
};

// Reservation platforms configuration
const RESERVATION_PLATFORMS: ReservationPlatform[] = [
  // OpenTable - primarily US, UK, some EU
  {
    name: 'OpenTable',
    getUrl: ({ venueName, date, time, partySize, address }) => {
      const searchQuery = encodeURIComponent(venueName);
      const locationQuery = address ? encodeURIComponent(address.split(",")[0] || '') : "";
      return `https://www.opentable.com/s?covers=${partySize}&dateTime=${date}T${time}&term=${searchQuery}${locationQuery ? `&metroId=&regionId=&neighborhood=${locationQuery}` : ""}`;
    },
    regions: ['us', 'uk', 'au', 'other'],
  },
  // Resy - US cities
  {
    name: 'Resy',
    getUrl: ({ venueName, date, partySize, address }) => {
      const searchQuery = encodeURIComponent(venueName);
      const city = getCitySlugFromAddress(address);
      return `https://resy.com/cities/${city}?query=${searchQuery}&date=${date}&seats=${partySize}`;
    },
    regions: ['us'],
  },
  // TheFork (formerly LaFourchette) - EU & UK
  {
    name: 'TheFork',
    getUrl: ({ venueName, date, time, partySize }) => {
      const searchQuery = encodeURIComponent(venueName);
      return `https://www.thefork.com/search?cityId=&queryText=${searchQuery}&date=${date}&time=${time}&partySize=${partySize}`;
    },
    regions: ['eu', 'uk'],
  },
  // Quandoo - EU, UK, Australia
  {
    name: 'Quandoo',
    getUrl: ({ venueName, date, time, partySize }) => {
      const searchQuery = encodeURIComponent(venueName);
      return `https://www.quandoo.com/en/search?query=${searchQuery}&date=${date}&time=${time}&pax=${partySize}`;
    },
    regions: ['eu', 'uk', 'au'],
  },
  // Zomato - India primarily
  {
    name: 'Zomato',
    getUrl: ({ venueName, address }) => {
      const searchQuery = encodeURIComponent(venueName);
      const city = address?.split(",").slice(-2, -1)[0]?.trim().toLowerCase() || 'mumbai';
      return `https://www.zomato.com/${city}/restaurants?q=${searchQuery}`;
    },
    regions: ['india'],
  },
  // EatApp - Middle East, Asia
  {
    name: 'Eatapp',
    getUrl: ({ venueName }) => {
      const searchQuery = encodeURIComponent(venueName);
      return `https://eat.app/search?q=${searchQuery}`;
    },
    regions: ['asia', 'india'],
  },
  // TableCheck - Japan primarily
  {
    name: 'TableCheck',
    getUrl: ({ venueName, date, time, partySize }) => {
      const searchQuery = encodeURIComponent(venueName);
      return `https://www.tablecheck.com/en/search?query=${searchQuery}&date=${date}&time=${time}&pax=${partySize}`;
    },
    regions: ['asia'],
  },
];

// Get Resy city slug from address
const getCitySlugFromAddress = (addr?: string): string => {
  if (!addr) return "ny";
  const parts = addr.split(",");
  if (parts.length >= 2) {
    const city = parts[parts.length - 2]?.trim().toLowerCase();
    const cityMap: Record<string, string> = {
      "new york": "ny", "nyc": "ny", "manhattan": "ny", "brooklyn": "ny",
      "los angeles": "la", "la": "la",
      "san francisco": "sf", "sf": "sf",
      "chicago": "chi",
      "miami": "mia",
      "austin": "atx",
      "denver": "den",
      "seattle": "sea",
      "boston": "bos",
      "washington": "dc", "dc": "dc",
      "atlanta": "atl",
      "nashville": "nash",
      "houston": "hou",
      "dallas": "dal",
      "philadelphia": "phl",
    };
    for (const [key, value] of Object.entries(cityMap)) {
      if (city?.includes(key)) return value;
    }
  }
  return "ny";
};

const ReservationWidget = ({
  venueName,
  venueType,
  validated,
  placeId,
  address,
  phoneNumber,
  open,
  onOpenChange,
  onReservationMade,
}: ReservationWidgetProps) => {
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [partySize, setPartySize] = useState("2");

  // Detect region and get appropriate platforms
  const { region, platforms } = useMemo(() => {
    const detectedRegion = detectRegion(address);
    const availablePlatforms = RESERVATION_PLATFORMS.filter(p => 
      p.regions.includes(detectedRegion)
    );
    // Always include at least OpenTable as fallback
    if (availablePlatforms.length === 0) {
      availablePlatforms.push(RESERVATION_PLATFORMS[0]); // OpenTable
    }
    return { region: detectedRegion, platforms: availablePlatforms.slice(0, 3) }; // Max 3 platforms
  }, [address]);

  const handlePlatformClick = (platform: ReservationPlatform) => {
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
          </DialogDescription>
        </DialogHeader>

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
            <p className="text-sm text-muted-foreground mb-3">
              Choose a reservation platform:
            </p>
            <div className="flex flex-wrap gap-2">
              {platforms.map((platform) => (
                <Button
                  key={platform.name}
                  variant="outline"
                  className="flex-1 min-w-[100px]"
                  onClick={() => handlePlatformClick(platform)}
                  disabled={!date || !time}
                >
                  <ExternalLink className="w-4 h-4 mr-2" />
                  {platform.name}
                </Button>
              ))}
            </div>
            {region !== 'us' && (
              <p className="text-xs text-muted-foreground mt-2">
                Showing platforms for your region. Results may vary by location.
              </p>
            )}
          </div>

          {/* Fallback Option */}
          <Alert className="bg-muted/50 border-amber-500/30">
            <AlertCircle className="h-4 w-4 text-amber-500" />
            <AlertDescription className="text-sm">
              <span className="font-medium">Not on OpenTable or Resy?</span>
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
