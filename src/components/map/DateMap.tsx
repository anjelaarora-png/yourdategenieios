import { useEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { SavedDatePlan } from "@/hooks/useDatePlans";
import { MapPin } from "lucide-react";

interface DateMapProps {
  plans: SavedDatePlan[];
  className?: string;
}

// Fix default marker icons for Leaflet
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

const DateMap = ({ plans, className = "" }: DateMapProps) => {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [hasValidMarkers, setHasValidMarkers] = useState(false);

  // Check if there are any VERIFIED stops with coordinates
  const validStopsCount = plans.reduce((count, plan) => {
    return (
      count +
      plan.stops.filter((stop) => {
        if (!stop.validated) return false;
        const lat = Number(stop.latitude);
        const lng = Number(stop.longitude);
        return Number.isFinite(lat) && Number.isFinite(lng) && lat !== 0 && lng !== 0;
      }).length
    );
  }, 0);

  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    // Initialize map centered on US
    mapInstanceRef.current = L.map(mapRef.current).setView([39.8283, -98.5795], 4);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(mapInstanceRef.current);

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapInstanceRef.current) return;

    // Clear existing markers
    mapInstanceRef.current.eachLayer((layer) => {
      if (layer instanceof L.Marker) {
        mapInstanceRef.current?.removeLayer(layer);
      }
    });

    // Create custom icon
    const customIcon = L.divIcon({
      className: "custom-marker",
      html: `<div style="background: linear-gradient(135deg, hsl(45, 90%, 51%), hsl(45, 90%, 61%)); width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.3); border: 3px solid white;">
        <span style="font-size: 16px;">✨</span>
      </div>`,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
      popupAnchor: [0, -32],
    });

    // Add markers for each VERIFIED stop in each plan (only those with validated coordinates)
    const validMarkers: L.LatLng[] = [];

    plans.forEach((plan) => {
      plan.stops.forEach((stop) => {
        if (!stop.validated) return;

        const lat = Number(stop.latitude);
        const lng = Number(stop.longitude);

        if (Number.isFinite(lat) && Number.isFinite(lng) && lat !== 0 && lng !== 0) {
          const marker = L.marker([lat, lng], { icon: customIcon }).addTo(
            mapInstanceRef.current!
          );

          validMarkers.push(L.latLng(lat, lng));

          marker.bindPopup(`
            <div style="min-width: 200px;">
              <h3 style="margin: 0 0 8px; font-weight: 600;">${stop.emoji || "📍"} ${stop.name}</h3>
              <p style="margin: 0 0 4px; color: #666; font-size: 14px;">${stop.venueType || "Venue"}</p>
              <p style="margin: 0; font-size: 13px;">${stop.description || ""}</p>
              ${stop.address ? `<p style="margin: 4px 0 0; font-size: 12px; color: #888;">📍 ${stop.address}</p>` : ""}
              <hr style="margin: 8px 0; border: none; border-top: 1px solid #eee;" />
              <small style="color: #888;">From: ${plan.title}</small>
            </div>
          `);
        }
      });
    });

    setHasValidMarkers(validMarkers.length > 0);

    // Fit bounds if there are valid markers
    if (validMarkers.length > 0) {
      const bounds = L.latLngBounds(validMarkers);
      mapInstanceRef.current.fitBounds(bounds, { padding: [50, 50] });
    }
  }, [plans]);

  // Show empty state if no plans or no validated stops
  if (plans.length === 0) {
    return (
      <div className={`flex flex-col items-center justify-center bg-muted rounded-lg p-8 gap-3 h-[400px] ${className}`}>
        <MapPin className="w-12 h-12 text-muted-foreground" />
        <p className="text-muted-foreground text-center">
          No saved date plans yet. Generate and save a plan to see your venues here!
        </p>
      </div>
    );
  }

  return (
    <div className="relative">
      <div
        ref={mapRef}
        className={`w-full h-[400px] rounded-lg overflow-hidden border border-border ${className}`}
      />
      {!hasValidMarkers && validStopsCount === 0 && (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-background/80 rounded-lg gap-2">
          <MapPin className="w-8 h-8 text-muted-foreground" />
          <p className="text-muted-foreground text-center text-sm px-4">
            Your saved plans don't have verified location data. 
            Generate new plans to see venues on the map.
          </p>
        </div>
      )}
    </div>
  );
};

export default DateMap;
