/**
 * Google Directions API: get travel time and distance between points for a given travel mode.
 * Used to set accurate travelTimeFromPrevious, travelDistanceFromPrevious, and travelMode on each stop.
 */

export type TravelMode = "WALKING" | "DRIVING" | "TRANSIT" | "BICYCLING";

const MODE_MAP: Record<string, TravelMode> = {
  walking: "WALKING",
  driving: "DRIVING",
  rideshare: "DRIVING",
  "public-transit": "TRANSIT",
  transit: "TRANSIT",
  biking: "BICYCLING",
};

export function toGoogleTravelMode(preference?: string): TravelMode {
  if (!preference) return "WALKING";
  const key = preference.toLowerCase().trim();
  return MODE_MAP[key] ?? "WALKING";
}

export function toAppTravelMode(googleMode: TravelMode): string {
  const map: Record<TravelMode, string> = {
    WALKING: "walking",
    DRIVING: "driving",
    TRANSIT: "public-transit",
    BICYCLING: "biking",
  };
  return map[googleMode] ?? "walking";
}

export interface LatLng {
  latitude: number;
  longitude: number;
}

export interface LegResult {
  durationText: string;
  distanceText: string;
  durationValue: number;
  distanceValue: number;
}

/**
 * Get directions from origin to destination with optional waypoints.
 * Returns one leg per segment: origin→waypoint0, waypoint0→waypoint1, ..., waypointN→destination.
 */
export async function getDirections(
  origin: LatLng,
  destination: LatLng,
  waypoints: LatLng[],
  travelMode: TravelMode,
  apiKey: string
): Promise<LegResult[]> {
  if (!apiKey) return [];
  const points = [origin, ...waypoints, destination];
  if (points.length < 2) return [];

  const legs: LegResult[] = [];
  // Request one segment at a time to get accurate per-leg data (Directions API waypoints limit and clarity)
  for (let i = 0; i < points.length - 1; i++) {
    const from = points[i];
    const to = points[i + 1];
    const url =
      `https://maps.googleapis.com/maps/api/directions/json?` +
      `origin=${from.latitude},${from.longitude}` +
      `&destination=${to.latitude},${to.longitude}` +
      `&mode=${travelMode.toLowerCase()}` +
      `&key=${apiKey}`;
    try {
      const res = await fetch(url);
      if (!res.ok) continue;
      const data = await res.json();
      if (data.status !== "OK" || !data.routes?.[0]?.legs?.[0]) continue;
      const leg = data.routes[0].legs[0];
      legs.push({
        durationText: leg.duration?.text ?? "",
        distanceText: leg.distance?.text ?? "",
        durationValue: leg.duration?.value ?? 0,
        distanceValue: leg.distance?.value ?? 0,
      });
    } catch {
      // leave leg empty / use AI values
    }
  }
  return legs;
}
