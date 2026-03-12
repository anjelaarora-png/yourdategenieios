import { useEffect, useRef, useState } from "react";
import { DatePlanStop } from "@/types/datePlan";
import { Loader2, Navigation, Car, Footprints, Train, Bike, ExternalLink } from "lucide-react";
import { Button } from "@/components/ui/button";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface RouteMapProps {
  stops: DatePlanStop[];
  transportationMode?: string;
  className?: string;
}

const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

// Extend Window interface for Google Maps
declare global {
  interface Window {
    google: any;
    initMap: () => void;
  }
}

// Type aliases for Google Maps objects
type GoogleMap = google.maps.Map;
type DirectionsRenderer = google.maps.DirectionsRenderer;

// Map transportation modes to Google Maps travel modes
const getTravelMode = (mode?: string): google.maps.TravelMode => {
  if (!window.google) return "WALKING" as unknown as google.maps.TravelMode;
  
  switch (mode?.toLowerCase()) {
    case "walking":
      return window.google.maps.TravelMode.WALKING;
    case "driving":
    case "rideshare":
      return window.google.maps.TravelMode.DRIVING;
    case "public-transit":
    case "transit":
      return window.google.maps.TravelMode.TRANSIT;
    case "biking":
      return window.google.maps.TravelMode.BICYCLING;
    default:
      return window.google.maps.TravelMode.WALKING;
  }
};

const getTravelModeLabel = (mode?: string): string => {
  switch (mode?.toLowerCase()) {
    case "walking":
      return "walk";
    case "driving":
    case "rideshare":
      return "drive";
    case "public-transit":
    case "transit":
      return "transit";
    case "biking":
      return "bike ride";
    default:
      return "travel";
  }
};

const getTravelModeIcon = (mode?: string) => {
  switch (mode?.toLowerCase()) {
    case "walking":
      return <Footprints className="w-4 h-4" />;
    case "driving":
    case "rideshare":
      return <Car className="w-4 h-4" />;
    case "public-transit":
    case "transit":
      return <Train className="w-4 h-4" />;
    case "biking":
      return <Bike className="w-4 h-4" />;
    default:
      return <Car className="w-4 h-4" />;
  }
};

// Fix default marker icons for Leaflet
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

// Leaflet-based fallback map component
const LeafletRouteMap = ({ 
  verifiedStops, 
  effectiveMode, 
  className 
}: { 
  verifiedStops: DatePlanStop[]; 
  effectiveMode: string; 
  className: string;
}) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    // Initialize map
    const map = L.map(mapRef.current);
    mapInstanceRef.current = map;

    // Add tile layer (OpenStreetMap - free, no API key needed)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);

    // Create custom numbered marker icons
    const createNumberedIcon = (number: number) => {
      return L.divIcon({
        className: "custom-marker",
        html: `<div style="
          background: linear-gradient(135deg, #d4a853, #e8c37a);
          width: 32px;
          height: 32px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 12px rgba(0,0,0,0.3);
          border: 3px solid white;
          font-weight: bold;
          font-size: 14px;
          color: #1a1a1a;
        ">${number}</div>`,
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32],
      });
    };

    // Add markers for each stop
    const markers: L.LatLng[] = [];
    
    verifiedStops.forEach((stop, index) => {
      const lat = Number(stop.latitude);
      const lng = Number(stop.longitude);
      
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        const marker = L.marker([lat, lng], { 
          icon: createNumberedIcon(index + 1) 
        }).addTo(map);

        markers.push(L.latLng(lat, lng));

        marker.bindPopup(`
          <div style="min-width: 200px;">
            <h3 style="margin: 0 0 8px; font-weight: 600; font-size: 16px;">${stop.emoji || "📍"} ${stop.name}</h3>
            <p style="margin: 0 0 4px; color: #666; font-size: 14px;">${stop.venueType || "Venue"}</p>
            <p style="margin: 0 0 8px; font-size: 13px;">${stop.description || ""}</p>
            ${stop.address ? `<p style="margin: 0; font-size: 12px; color: #888;">📍 ${stop.address}</p>` : ""}
          </div>
        `);
      }
    });

    // Draw route line connecting all stops
    if (markers.length > 1) {
      const routeLine = L.polyline(markers, {
        color: "#d4a853",
        weight: 4,
        opacity: 0.8,
        dashArray: "10, 10", // Dashed line to indicate it's not actual routing
      }).addTo(map);
    }

    // Fit bounds to show all markers
    if (markers.length > 0) {
      const bounds = L.latLngBounds(markers);
      map.fitBounds(bounds, { padding: [50, 50] });
    } else {
      map.setView([40.7128, -74.006], 12); // Default to NYC
    }

    setIsLoading(false);

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [verifiedStops]);

  const openInGoogleMaps = () => {
    if (verifiedStops.length === 0) return;

    const o = verifiedStops[0];
    const d = verifiedStops[verifiedStops.length - 1];
    const wayStops = verifiedStops.slice(1, -1);
    const origin = o.placeId ? `place_id:${o.placeId}` : `${o.latitude},${o.longitude}`;
    const destination = d.placeId ? `place_id:${d.placeId}` : `${d.latitude},${d.longitude}`;
    const waypoints = wayStops
      .map((s) => (s.placeId ? `place_id:${s.placeId}` : `${s.latitude},${s.longitude}`))
      .join("|");

    const getGoogleMapsTravelMode = (mode?: string) => {
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

    const q = new URLSearchParams({ api: "1", origin, destination, travelmode: getGoogleMapsTravelMode(effectiveMode) });
    if (waypoints) q.set("waypoints", waypoints);
    window.open(`https://www.google.com/maps/dir/?${q.toString()}`, "_blank");
  };

  return (
    <div className={`relative ${className}`}>
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-background/80 z-10 rounded-lg">
          <Loader2 className="w-8 h-8 animate-spin text-primary" />
        </div>
      )}
      
      <div
        ref={mapRef}
        className="w-full h-[350px] rounded-lg overflow-hidden border border-border"
      />
      
      {!isLoading && (
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mt-3 gap-2">
          <div className="flex items-center gap-3 text-sm text-muted-foreground flex-wrap">
            <span className="flex items-center gap-1.5">
              {getTravelModeIcon(effectiveMode)} {verifiedStops.length} stop{verifiedStops.length !== 1 ? "s" : ""}
            </span>
            <span className="text-xs bg-muted px-2 py-1 rounded">
              Open in Google Maps for turn-by-turn directions
            </span>
          </div>
          <Button
            variant="default"
            size="sm"
            onClick={openInGoogleMaps}
            className="gap-2 gradient-gold text-primary-foreground hover:opacity-90 border-0"
          >
            <ExternalLink className="w-4 h-4" />
            Get Directions
          </Button>
        </div>
      )}
    </div>
  );
};

const RouteMap = ({ stops, transportationMode, className = "" }: RouteMapProps) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<GoogleMap | null>(null);
  const directionsRendererRef = useRef<DirectionsRenderer | null>(null);
  const overlaysRef = useRef<google.maps.OverlayView[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [mapReady, setMapReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [totalDistance, setTotalDistance] = useState<string>("");
  const [totalDuration, setTotalDuration] = useState<string>("");
  const [routeLegs, setRouteLegs] = useState<Array<{ from: number; to: number; distance: string; duration: string }>>([]);
  const [selectedMode, setSelectedMode] = useState<string>(() => transportationMode || "walking");
  const [useLeaflet, setUseLeaflet] = useState(!GOOGLE_MAPS_API_KEY);
  
  // Keep selectedMode in sync when prop changes (e.g. from questionnaire)
  useEffect(() => {
    if (transportationMode) setSelectedMode(transportationMode);
  }, [transportationMode]);

  // Use selected mode for directions (user can override via selector)
  const effectiveMode = selectedMode || transportationMode || stops.find(s => s.travelMode)?.travelMode || "walking";

  // Filter stops with coordinates (don't require validated flag)
  const stopsWithCoords = stops.filter((stop) => {
    const lat = Number(stop.latitude);
    const lng = Number(stop.longitude);
    return Number.isFinite(lat) && Number.isFinite(lng) && lat !== 0 && lng !== 0;
  });

  // If no Google Maps API key, use Leaflet fallback
  if (useLeaflet) {
    if (stopsWithCoords.length === 0) {
      // No coordinates available - show individual venue links
      return (
        <div className={`bg-muted/50 rounded-lg p-4 ${className}`}>
          <p className="text-sm text-muted-foreground mb-3">
            Click on each venue below to view it on Google Maps:
          </p>
          <div className="space-y-2">
            {stops.map((stop, index) => (
              <a
                key={index}
                href={stop.placeId 
                  ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                  : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(stop.address || stop.name)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 p-2 rounded-md hover:bg-muted transition-colors"
              >
                <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shrink-0">
                  {index + 1}
                </div>
                <span className="text-sm text-primary hover:underline">{stop.name}</span>
                <ExternalLink className="w-3 h-3 text-muted-foreground ml-auto" />
              </a>
            ))}
          </div>
        </div>
      );
    }
    
    return <LeafletRouteMap verifiedStops={stopsWithCoords} effectiveMode={effectiveMode} className={className} />;
  }

  // Effect 1: Load Google Maps script and initialize map once
  useEffect(() => {
    if (useLeaflet) return;

    if (!GOOGLE_MAPS_API_KEY) {
      setUseLeaflet(true);
      return;
    }

    const initMap = () => {
      if (!mapRef.current || !window.google) return;

      // Default center
      const defaultCenter = { lat: 40.7128, lng: -74.006 }; // NYC

      mapInstanceRef.current = new window.google.maps.Map(mapRef.current, {
        center: defaultCenter,
        zoom: 14,
        styles: [
          {
            featureType: "poi",
            elementType: "labels",
            stylers: [{ visibility: "off" }],
          },
        ],
        mapTypeControl: false,
        streetViewControl: false,
        fullscreenControl: true,
      });

      directionsRendererRef.current = new window.google.maps.DirectionsRenderer({
        map: mapInstanceRef.current,
        suppressMarkers: true,
        polylineOptions: {
          strokeColor: "#d4a853",
          strokeWeight: 4,
          strokeOpacity: 0.8,
        },
      });

      setMapReady(true);
      setIsLoading(false);
    };

    // Load Google Maps script if not already loaded
    if (!window.google) {
      const script = document.createElement("script");
      script.src = `https://maps.googleapis.com/maps/api/js?key=${GOOGLE_MAPS_API_KEY}&libraries=places`;
      script.async = true;
      script.defer = true;
      script.onload = initMap;
      script.onerror = () => {
        console.warn("Failed to load Google Maps, falling back to Leaflet");
        setUseLeaflet(true);
      };
      document.head.appendChild(script);
    } else {
      initMap();
    }

    return () => {
      if (directionsRendererRef.current) {
        directionsRendererRef.current.setMap(null);
      }
    };
  }, [useLeaflet]);

  // Effect 2: Recalculate route when stops or selected transport mode changes
  useEffect(() => {
    if (!mapReady || !mapInstanceRef.current) return;
    
    calculateRoute();
  }, [mapReady, stops, effectiveMode]);

  // Clear previous markers and overlays
  const clearMarkers = () => {
    overlaysRef.current.forEach(overlay => overlay.setMap(null));
    overlaysRef.current = [];
  };

  const calculateRoute = async () => {
    if (!mapInstanceRef.current || !window.google) {
      setIsLoading(false);
      return;
    }

    // Clear previous markers/overlays
    clearMarkers();
    
    // Clear previous directions (set to null instead of empty object to avoid type issues)
    if (directionsRendererRef.current) {
      directionsRendererRef.current.set("directions", null);
    }

    // Reset totals and legs
    setTotalDistance("");
    setTotalDuration("");
    setRouteLegs([]);

    if (stopsWithCoords.length === 0) {
      setIsLoading(false);
      return;
    }

    if (stopsWithCoords.length === 1) {
      // If only one stop, just show a marker
      const lat = Number(stopsWithCoords[0].latitude);
      const lng = Number(stopsWithCoords[0].longitude);
      addCustomMarker(stopsWithCoords[0], 1);
      mapInstanceRef.current.setCenter({ lat, lng });
      mapInstanceRef.current.setZoom(15);
      setIsLoading(false);
      return;
    }

    const directionsService = new window.google.maps.DirectionsService();

    const origin = {
      lat: Number(stopsWithCoords[0].latitude),
      lng: Number(stopsWithCoords[0].longitude),
    };
    const destination = {
      lat: Number(stopsWithCoords[stopsWithCoords.length - 1].latitude),
      lng: Number(stopsWithCoords[stopsWithCoords.length - 1].longitude),
    };

    const waypoints = stopsWithCoords.slice(1, -1).map((stop) => ({
      location: { lat: Number(stop.latitude), lng: Number(stop.longitude) },
      stopover: true,
    }));

    try {
      const result = await directionsService.route({
        origin,
        destination,
        waypoints,
        travelMode: getTravelMode(effectiveMode),
        optimizeWaypoints: false, // Keep order as planned
      });

      if (directionsRendererRef.current) {
        directionsRendererRef.current.setDirections(result);
      }

      // Add custom markers for each stop
      stopsWithCoords.forEach((stop, index) => {
        addCustomMarker(stop, index + 1);
      });

      // Calculate totals and per-leg info
      let distance = 0;
      let duration = 0;
      const legs = result.routes[0].legs.map((leg, i) => {
        const d = leg.distance?.value || 0;
        const t = leg.duration?.value || 0;
        distance += d;
        duration += t;
        return {
          from: i + 1,
          to: i + 2,
          distance: leg.distance?.text || "",
          duration: leg.duration?.text || "",
        };
      });
      setRouteLegs(legs);
      setTotalDistance(`${(distance / 1000).toFixed(1)} km`);
      setTotalDuration(`${Math.round(duration / 60)} min ${getTravelModeLabel(effectiveMode)}`);
    } catch (err) {
      console.error("Directions error:", err);
      // Fallback: just show markers without route
      stopsWithCoords.forEach((stop, index) => {
        addCustomMarker(stop, index + 1);
      });
      fitBoundsToMarkers();
    }

    setIsLoading(false);
  };

  const addCustomMarker = (stop: DatePlanStop, order: number) => {
    if (!mapInstanceRef.current || !window.google) return;

    const lat = Number(stop.latitude);
    const lng = Number(stop.longitude);

    // Create custom marker element
    const markerElement = document.createElement("div");
    markerElement.innerHTML = `
      <div style="
        background: linear-gradient(135deg, #d4a853, #e8c37a);
        width: 36px;
        height: 36px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        border: 3px solid white;
        font-weight: bold;
        font-size: 14px;
        color: #1a1a1a;
      ">${order}</div>
    `;

    const overlay = new window.google.maps.OverlayView();
    overlay.onAdd = function () {
      const panes = this.getPanes();
      panes?.overlayMouseTarget.appendChild(markerElement);
    };
    overlay.draw = function () {
      const projection = this.getProjection();
      const position = projection.fromLatLngToDivPixel(
        new window.google.maps.LatLng(lat, lng)
      );
      if (position) {
        markerElement.style.position = "absolute";
        markerElement.style.left = position.x - 18 + "px";
        markerElement.style.top = position.y - 18 + "px";
        markerElement.style.cursor = "pointer";
      }
    };
    overlay.onRemove = function () {
      markerElement.remove();
    };
    overlay.setMap(mapInstanceRef.current);
    overlaysRef.current.push(overlay);

    // Info window
    const infoWindow = new window.google.maps.InfoWindow({
      content: `
        <div style="min-width: 200px; padding: 4px;">
          <h3 style="margin: 0 0 4px; font-weight: 600; font-size: 16px;">${stop.emoji || "📍"} ${stop.name}</h3>
          <p style="margin: 0 0 4px; color: #666; font-size: 13px;">${stop.venueType || "Venue"}</p>
          <p style="margin: 0 0 8px; font-size: 12px;">${stop.description || ""}</p>
          ${stop.address ? `<p style="margin: 0; font-size: 11px; color: #888;">📍 ${stop.address}</p>` : ""}
        </div>
      `,
    });

    markerElement.addEventListener("click", () => {
      infoWindow.setPosition(new window.google.maps.LatLng(lat, lng));
      infoWindow.open(mapInstanceRef.current);
    });
  };

  const fitBoundsToMarkers = () => {
    if (!mapInstanceRef.current || !window.google || stopsWithCoords.length === 0) return;

    const bounds = new window.google.maps.LatLngBounds();
    stopsWithCoords.forEach((stop) => {
      bounds.extend({ lat: Number(stop.latitude), lng: Number(stop.longitude) });
    });
    mapInstanceRef.current.fitBounds(bounds, 50);
  };

  const openInGoogleMaps = () => {
    if (stopsWithCoords.length === 0) return;

    const o = stopsWithCoords[0];
    const d = stopsWithCoords[stopsWithCoords.length - 1];
    const wayStops = stopsWithCoords.slice(1, -1);
    const origin = o.placeId ? `place_id:${o.placeId}` : `${o.latitude},${o.longitude}`;
    const destination = d.placeId ? `place_id:${d.placeId}` : `${d.latitude},${d.longitude}`;
    const waypoints = wayStops
      .map((s) => (s.placeId ? `place_id:${s.placeId}` : `${s.latitude},${s.longitude}`))
      .join("|");

    const getGoogleMapsTravelMode = (mode?: string) => {
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

    const q = new URLSearchParams({ api: "1", origin, destination, travelmode: getGoogleMapsTravelMode(effectiveMode) });
    if (waypoints) q.set("waypoints", waypoints);
    window.open(`https://www.google.com/maps/dir/?${q.toString()}`, "_blank");
  };

  // If we have an error or no API key, fall back to Leaflet
  if (error || useLeaflet) {
    if (stopsWithCoords.length === 0) {
      // No coordinates - show venue links
      return (
        <div className={`bg-muted/50 rounded-lg p-4 ${className}`}>
          <p className="text-sm text-muted-foreground mb-3">
            Click on each venue below to view it on Google Maps:
          </p>
          <div className="space-y-2">
            {stops.map((stop, index) => (
              <a
                key={index}
                href={stop.placeId 
                  ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                  : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(stop.address || stop.name)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 p-2 rounded-md hover:bg-muted transition-colors"
              >
                <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shrink-0">
                  {index + 1}
                </div>
                <span className="text-sm text-primary hover:underline">{stop.name}</span>
                <ExternalLink className="w-3 h-3 text-muted-foreground ml-auto" />
              </a>
            ))}
          </div>
        </div>
      );
    }
    return <LeafletRouteMap verifiedStops={stopsWithCoords} effectiveMode={effectiveMode} className={className} />;
  }

  if (stopsWithCoords.length === 0) {
    // No coordinates - show venue links
    return (
      <div className={`bg-muted/50 rounded-lg p-4 ${className}`}>
        <p className="text-sm text-muted-foreground mb-3">
          Click on each venue below to view it on Google Maps:
        </p>
        <div className="space-y-2">
          {stops.map((stop, index) => (
            <a
              key={index}
              href={stop.placeId 
                ? `https://www.google.com/maps/place/?q=place_id:${stop.placeId}`
                : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(stop.address || stop.name)}`}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 p-2 rounded-md hover:bg-muted transition-colors"
            >
              <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center text-xs text-primary-foreground font-bold shrink-0">
                {index + 1}
              </div>
              <span className="text-sm text-primary hover:underline">{stop.name}</span>
              <ExternalLink className="w-3 h-3 text-muted-foreground ml-auto" />
            </a>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className={`relative ${className}`}>
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-background/80 z-10 rounded-lg">
          <Loader2 className="w-8 h-8 animate-spin text-primary" />
        </div>
      )}
      
      <div
        ref={mapRef}
        className="w-full h-[350px] rounded-lg overflow-hidden border border-border"
      />
      
      {!isLoading && (
        <>
          {/* Transport mode selector */}
          <div className="flex items-center gap-1 mt-3 p-1.5 rounded-lg bg-muted/50 w-fit">
            <button
              type="button"
              onClick={() => setSelectedMode("walking")}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors ${
                effectiveMode === "walking" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
              }`}
            >
              <Footprints className="w-4 h-4" />
              Walk
            </button>
            <button
              type="button"
              onClick={() => setSelectedMode("driving")}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors ${
                effectiveMode === "driving" || effectiveMode === "rideshare" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
              }`}
            >
              <Car className="w-4 h-4" />
              Drive
            </button>
            <button
              type="button"
              onClick={() => setSelectedMode("public-transit")}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors ${
                effectiveMode === "public-transit" || effectiveMode === "transit" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
              }`}
            >
              <Train className="w-4 h-4" />
              Transit
            </button>
            <button
              type="button"
              onClick={() => setSelectedMode("biking")}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors ${
                effectiveMode === "biking" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted"
              }`}
            >
              <Bike className="w-4 h-4" />
              Bike
            </button>
          </div>

          {/* Per-leg distance & time */}
          {routeLegs.length > 0 && (
            <div className="mt-3 space-y-1.5">
              <p className="text-xs font-medium text-muted-foreground">Time & distance between stops</p>
              <ul className="space-y-1">
                {routeLegs.map((leg, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm">
                    <span className="font-medium text-foreground">Stop {leg.from} → {leg.to}</span>
                    <span className="text-muted-foreground">
                      {leg.duration}{leg.distance ? ` · ${leg.distance}` : ""}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          <div className="flex items-center justify-between mt-3 flex-wrap gap-2">
            <div className="flex items-center gap-4 text-sm text-muted-foreground">
              {totalDistance && (
                <span className="flex items-center gap-1.5">
                  📍 {totalDistance}
                </span>
              )}
              {totalDuration && (
                <span className="flex items-center gap-1.5">
                  {getTravelModeIcon(effectiveMode)} {totalDuration}
                </span>
              )}
              <span className="text-xs">
                ({stopsWithCoords.length} stop{stopsWithCoords.length !== 1 ? "s" : ""} on map)
              </span>
            </div>
            <Button
              variant="default"
              size="sm"
              onClick={openInGoogleMaps}
              className="gap-2 gradient-gold text-primary-foreground hover:opacity-90 border-0"
            >
              <Navigation className="w-4 h-4" />
              Open in Google Maps
            </Button>
          </div>
        </>
      )}
    </div>
  );
};

export default RouteMap;
