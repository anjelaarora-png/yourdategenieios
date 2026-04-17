// Google Places API validation

interface PlaceValidationResult {
  isValid: boolean;
  isPermanentlyClosed?: boolean;
  officialName?: string; // The verified name from Google Maps
  placeId?: string;
  formattedAddress?: string;
  latitude?: number;
  longitude?: number;
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  businessStatus?: string;
  /** Photo URL from Google Business Profile (Place Details photos) for cards and lists. */
  imageUrl?: string;
  /** Reservation platforms detected from the venue's website URL (e.g. ["opentable", "resy"]). */
  reservationPlatforms?: string[];
}

interface Stop {
  order: number;
  name: string;
  venueType: string;
  timeSlot: string;
  duration: string;
  description: string;
  whyItFits: string;
  romanticTip: string;
  emoji: string;
  placeId?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  validated?: boolean;
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  bookingUrl?: string;
  imageUrl?: string;
  /** Booking platforms this venue is confirmed to be on. */
  reservationPlatforms?: string[];
}

/** Detect reservation platforms from a restaurant's website URL or bookingUrl. */
function detectReservationPlatforms(websiteUrl?: string, bookingUrl?: string): string[] {
  const platforms: Set<string> = new Set();
  for (const url of [websiteUrl, bookingUrl]) {
    if (!url) continue;
    const lower = url.toLowerCase();
    if (lower.includes("opentable.com")) platforms.add("opentable");
    if (lower.includes("resy.com")) platforms.add("resy");
  }
  return Array.from(platforms);
}

// Extract state abbreviation from city string (e.g., "Newark, NJ" -> "NJ")
function extractStateFromCity(city: string): string | null {
  const match = city.match(/,\s*([A-Z]{2})$/i);
  return match ? match[1].toUpperCase() : null;
}

// Common city name variations (official name -> common names)
const cityNameVariations: Record<string, string[]> = {
  'bengaluru': ['bangalore', 'bengaluru'],
  'bangalore': ['bangalore', 'bengaluru'],
  'mumbai': ['mumbai', 'bombay'],
  'bombay': ['mumbai', 'bombay'],
  'chennai': ['chennai', 'madras'],
  'madras': ['chennai', 'madras'],
  'kolkata': ['kolkata', 'calcutta'],
  'calcutta': ['kolkata', 'calcutta'],
  'pune': ['pune', 'poona'],
  'thiruvananthapuram': ['thiruvananthapuram', 'trivandrum'],
  'kochi': ['kochi', 'cochin'],
  'varanasi': ['varanasi', 'benares', 'banaras'],
  'beijing': ['beijing', 'peking'],
  'guangzhou': ['guangzhou', 'canton'],
  'köln': ['köln', 'cologne'],
  'wien': ['wien', 'vienna'],
  'firenze': ['firenze', 'florence'],
  'roma': ['roma', 'rome'],
  'milano': ['milano', 'milan'],
  'napoli': ['napoli', 'naples'],
  'venezia': ['venezia', 'venice'],
  'münchen': ['münchen', 'munich'],
  'praha': ['praha', 'prague'],
  'moskva': ['moskva', 'moscow'],
};

/** Distance in km between two points (Haversine). */
function distanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/** Normalize city for matching: lowercase, trim. Returns also known variations for that city. */
function cityMatchTerms(city: string): string[] {
  const c = city.trim().toLowerCase();
  if (!c) return [];
  const terms = [c];
  for (const [key, vals] of Object.entries(cityNameVariations)) {
    if (key === c || vals.some((v) => v === c)) {
      vals.forEach((v) => terms.push(v));
      break;
    }
  }
  return [...new Set(terms)];
}

/** Verify the place is in the requested city: address contains city (or variation) and/or within maxDistanceKm of city center. */
function isAddressInLocation(
  address: string,
  city: string,
  venueLat?: number,
  venueLon?: number,
  cityCenterLat?: number,
  cityCenterLon?: number,
  maxDistanceKm: number = 150
): boolean {
  const terms = cityMatchTerms(city);
  const addrLower = (address || "").trim().toLowerCase();
  const addressContainsCity = terms.some((t) => addrLower.includes(t));
  if (addressContainsCity) {
    console.log(`[Places API] Address in location: "${address}" contains city "${city}"`);
    return true;
  }
  if (
    typeof venueLat === "number" &&
    typeof venueLon === "number" &&
    typeof cityCenterLat === "number" &&
    typeof cityCenterLon === "number" &&
    Number.isFinite(venueLat) &&
    Number.isFinite(venueLon) &&
    Number.isFinite(cityCenterLat) &&
    Number.isFinite(cityCenterLon)
  ) {
    const km = distanceKm(cityCenterLat, cityCenterLon, venueLat, venueLon);
    if (km <= maxDistanceKm) {
      console.log(`[Places API] Venue within ${km.toFixed(0)} km of city center for "${city}"`);
      return true;
    }
    console.log(`[Places API] WRONG LOCATION: Venue at (${venueLat},${venueLon}) is ${km.toFixed(0)} km from "${city}" center (max ${maxDistanceKm} km). Address: "${address}"`);
    return false;
  }
  if (address) {
    console.log(`[Places API] Cannot verify city (no center); trusting address: "${address}" for "${city}"`);
    return true;
  }
  return false;
}

// Get full state name from abbreviation
function getStateName(abbr: string): string {
  const states: Record<string, string> = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
    'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia',
    'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
    'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri',
    'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
    'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
    'DC': 'District of Columbia'
  };
  return states[abbr.toUpperCase()] || abbr;
}

/** Geocode an address string using Google Geocoding API. Returns formatted address and coordinates or null. */
export async function geocodeAddress(
  address: string,
  apiKey: string
): Promise<{ formatted_address: string; latitude: number; longitude: number } | null> {
  const trimmed = address?.trim();
  if (!trimmed || !apiKey) return null;

  try {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(trimmed)}&key=${apiKey}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
    let response: Response;
    try {
      response = await fetch(url, { signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
    if (!response.ok) return null;
    const data = await response.json();
    if (data.status !== "OK" || !data.results?.length) return null;
    const first = data.results[0];
    const formatted_address = first.formatted_address;
    const lat = first.geometry?.location?.lat;
    const lng = first.geometry?.location?.lng;
    if (typeof lat !== "number" || typeof lng !== "number") return null;
    return { formatted_address, latitude: lat, longitude: lng };
  } catch {
    return null;
  }
}

export type CityCenter = { latitude: number; longitude: number };

export async function validateVenue(
  venueName: string,
  city: string,
  apiKey: string,
  cityCenter?: CityCenter
): Promise<PlaceValidationResult> {
  // Input validation
  if (!venueName || typeof venueName !== 'string' || venueName.trim() === '') {
    console.error("[Places API] Invalid venue name provided");
    return { isValid: false };
  }
  
  if (!city || typeof city !== 'string' || city.trim() === '') {
    console.error("[Places API] Invalid city provided");
    return { isValid: false };
  }
  
  if (!apiKey || typeof apiKey !== 'string') {
    console.error("[Places API] Invalid API key");
    return { isValid: false };
  }

  try {
    // Step 1: Find the place (include name and business_status). Bias results to city area.
    const sanitizedVenue = venueName.trim().slice(0, 200); // Limit length
    const sanitizedCity = city.trim().slice(0, 100);
    const query = encodeURIComponent(`${sanitizedVenue} ${sanitizedCity}`);
    let findUrl = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${query}&inputtype=textquery&fields=place_id,name,formatted_address,geometry,business_status&key=${apiKey}`;
    if (cityCenter && Number.isFinite(cityCenter.latitude) && Number.isFinite(cityCenter.longitude)) {
      const radiusM = 50000; // 50 km - prefer results near the city
      findUrl += `&locationbias=circle:${radiusM}@${cityCenter.latitude},${cityCenter.longitude}`;
      console.log(`[Places API] Using location bias: circle ${radiusM}m around city center`);
    }
    console.log(`[Places API] Finding venue: ${sanitizedVenue} in ${sanitizedCity}`);
    
    // Add timeout to prevent hanging requests
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
    
    let findResponse;
    try {
      findResponse = await fetch(findUrl, { signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
    
    if (!findResponse.ok) {
      console.error("[Places API] Find error:", findResponse.status);
      return { isValid: false };
    }

    const findData = await findResponse.json();
    console.log(`[Places API] Find response status: ${findData.status}`);
    
    if (findData.status !== "OK" || !findData.candidates?.length) {
      console.log(`[Places API] No candidates found for: ${venueName}`);
      return { isValid: false };
    }

    const place = findData.candidates[0];
    const placeId = place.place_id;
    const officialName = place.name; // Get the official name from Google
    const formattedAddress = place.formatted_address;
    const businessStatus = place.business_status;
    const placeLat = place.geometry?.location?.lat;
    const placeLon = place.geometry?.location?.lng;
    console.log(`[Places API] Found: "${officialName}" at "${formattedAddress}" (searched: "${venueName}"), placeId: ${placeId}, status: ${businessStatus}`);

    // CRITICAL: Verify the venue is actually in the requested city (reject e.g. Dubai when user asked Chennai)
    const inLocation = isAddressInLocation(
      formattedAddress,
      city,
      placeLat,
      placeLon,
      cityCenter?.latitude,
      cityCenter?.longitude,
      150
    );
    if (!inLocation) {
      console.log(`[Places API] WRONG LOCATION! Venue "${officialName}" at "${formattedAddress}" is not in "${city}"`);
      return { isValid: false };
    }

    // Check if permanently closed
    if (businessStatus === "CLOSED_PERMANENTLY") {
      console.log(`[Places API] Venue is PERMANENTLY CLOSED: ${officialName}`);
      return { isValid: false, isPermanentlyClosed: true };
    }

    // Step 2: Get place details (website, phone, hours, photos, official name for confirmation)
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,photos&key=${apiKey}`;
    
    const detailsResponse = await fetch(detailsUrl);
    let websiteUrl: string | undefined;
    let phoneNumber: string | undefined;
    let openingHours: string[] | undefined;
    let imageUrl: string | undefined;
    let confirmedName = officialName; // Use the name from find, but details can override

    if (detailsResponse.ok) {
      const detailsData = await detailsResponse.json();
      console.log(`[Places API] Details response status: ${detailsData.status}`);
      if (detailsData.status === "OK" && detailsData.result) {
        // Double-check business status from details
        if (detailsData.result.business_status === "CLOSED_PERMANENTLY") {
          console.log(`[Places API] Venue confirmed PERMANENTLY CLOSED from details: ${venueName}`);
          return { isValid: false, isPermanentlyClosed: true };
        }
        
        // Use the name from details if available (most authoritative)
        if (detailsData.result.name) {
          confirmedName = detailsData.result.name;
        }
        
        websiteUrl = detailsData.result.website;
        phoneNumber = detailsData.result.formatted_phone_number;
        openingHours = detailsData.result.opening_hours?.weekday_text;
        // Build photo URL from first Google Business Profile photo (Place Photos API)
        const photos = detailsData.result.photos;
        if (Array.isArray(photos) && photos.length > 0 && photos[0].photo_reference) {
          const ref = encodeURIComponent(photos[0].photo_reference);
          imageUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${ref}&key=${apiKey}`;
          console.log(`[Places API] Photo URL set for "${confirmedName}"`);
        }
        console.log(`[Places API] Details for "${confirmedName}": website=${websiteUrl}, phone=${phoneNumber}, hours=${openingHours?.length || 0} entries, photo=${!!imageUrl}`);
      }
    } else {
      console.error("[Places API] Details fetch failed:", detailsResponse.status);
    }

    const reservationPlatforms = detectReservationPlatforms(websiteUrl);

    return {
      isValid: true,
      officialName: confirmedName,
      placeId: placeId,
      formattedAddress: place.formatted_address,
      latitude: place.geometry?.location?.lat,
      longitude: place.geometry?.location?.lng,
      websiteUrl,
      phoneNumber,
      openingHours,
      businessStatus,
      imageUrl,
      reservationPlatforms: reservationPlatforms.length > 0 ? reservationPlatforms : undefined,
    };
  } catch (error) {
    console.error("[Places API] Error validating venue:", error);
    return { isValid: false };
  }
}

// Fallback: Search for venue TYPE in the city when specific venue not found
async function searchVenueByType(
  venueType: string,
  city: string,
  apiKey: string,
  cityCenter?: CityCenter
): Promise<PlaceValidationResult> {
  try {
    // Search for the venue type in the city; bias to city area
    const query = encodeURIComponent(`${venueType} in ${city}`);
    let searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&key=${apiKey}`;
    if (cityCenter && Number.isFinite(cityCenter.latitude) && Number.isFinite(cityCenter.longitude)) {
      searchUrl += `&location=${cityCenter.latitude},${cityCenter.longitude}`;
      // textsearch uses location + radius (in meters)
      searchUrl += `&radius=50000`;
    }
    console.log(`[Places API] Fallback search: ${venueType} in ${city}`);
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
    
    let response;
    try {
      response = await fetch(searchUrl, { signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
    
    if (!response.ok) {
      console.error("[Places API] Text search error:", response.status);
      return { isValid: false };
    }
    
    const data = await response.json();
    
    if (data.status !== "OK" || !data.results?.length) {
      console.log(`[Places API] No results for venue type: ${venueType} in ${city}`);
      return { isValid: false };
    }
    
    // Find a place that's operational (not closed)
    const operationalPlace = data.results.find((p: any) => 
      p.business_status !== "CLOSED_PERMANENTLY" && 
      p.business_status !== "CLOSED_TEMPORARILY"
    ) || data.results[0];
    
    const place = operationalPlace;
    const placeId = place.place_id;
    
    if (place.business_status === "CLOSED_PERMANENTLY") {
      return { isValid: false, isPermanentlyClosed: true };
    }
    
    // Get details for the place (include photos for card images)
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,formatted_address,geometry,photos&key=${apiKey}`;
    const detailsResponse = await fetch(detailsUrl);
    
    let websiteUrl: string | undefined;
    let phoneNumber: string | undefined;
    let openingHours: string[] | undefined;
    let imageUrl: string | undefined;
    let officialName = place.name;
    let formattedAddress = place.formatted_address;
    let latitude = place.geometry?.location?.lat;
    let longitude = place.geometry?.location?.lng;
    
    if (detailsResponse.ok) {
      const detailsData = await detailsResponse.json();
      if (detailsData.status === "OK" && detailsData.result) {
        if (detailsData.result.business_status === "CLOSED_PERMANENTLY") {
          return { isValid: false, isPermanentlyClosed: true };
        }
        officialName = detailsData.result.name || officialName;
        formattedAddress = detailsData.result.formatted_address || formattedAddress;
        websiteUrl = detailsData.result.website;
        phoneNumber = detailsData.result.formatted_phone_number;
        openingHours = detailsData.result.opening_hours?.weekday_text;
        latitude = detailsData.result.geometry?.location?.lat || latitude;
        longitude = detailsData.result.geometry?.location?.lng || longitude;
        const photos = detailsData.result.photos;
        if (Array.isArray(photos) && photos.length > 0 && photos[0].photo_reference) {
          const ref = encodeURIComponent(photos[0].photo_reference);
          imageUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${ref}&key=${apiKey}`;
        }
      }
    }
    
    // Verify result is in the requested city (same as validateVenue)
    const inLocation = isAddressInLocation(
      formattedAddress || "",
      city,
      latitude,
      longitude,
      cityCenter?.latitude,
      cityCenter?.longitude,
      150
    );
    if (!inLocation) {
      console.log(`[Places API] Fallback WRONG LOCATION: "${officialName}" at "${formattedAddress}" not in "${city}"`);
      return { isValid: false };
    }
    console.log(`[Places API] Fallback found: "${officialName}" for type "${venueType}"`);
    
    return {
      isValid: true,
      officialName,
      placeId,
      formattedAddress,
      latitude,
      longitude,
      websiteUrl,
      phoneNumber,
      openingHours,
      imageUrl,
    };
  } catch (error) {
    console.error("[Places API] Fallback search error:", error);
    return { isValid: false };
  }
}

// Helper function to delay execution
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Validate venue with retry logic and fallback to type search
async function validateVenueWithRetry(
  venueName: string,
  venueType: string,
  city: string,
  apiKey: string,
  cityCenter?: CityCenter,
  maxRetries = 2
): Promise<PlaceValidationResult> {
  let lastError: Error | null = null;
  
  // First, try to find the specific venue
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      if (attempt > 0) {
        await delay(500 * attempt);
        console.log(`[Places API] Retry attempt ${attempt} for: ${venueName}`);
      }
      
      const result = await validateVenue(venueName, city, apiKey, cityCenter);
      if (result.isValid) {
        return result;
      }
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
      console.error(`[Places API] Attempt ${attempt + 1} failed for ${venueName}:`, lastError.message);
    }
  }
  
  // Fallback: Search by venue type if specific venue not found
  if (venueType) {
    console.log(`[Places API] Trying fallback search for type: ${venueType} in ${city}`);
    const fallbackResult = await searchVenueByType(venueType, city, apiKey, cityCenter);
    if (fallbackResult.isValid) {
      console.log(`[Places API] Fallback successful: found "${fallbackResult.officialName}" for type "${venueType}"`);
      return fallbackResult;
    }
  }
  
  console.error(`[Places API] All attempts exhausted for: ${venueName}`);
  return { isValid: false };
}

export async function validateAllStops(
  stops: Stop[],
  city: string,
  apiKey: string
): Promise<Stop[]> {
  // Input validation
  if (!Array.isArray(stops)) {
    console.error("[Validation] Invalid stops array");
    return [];
  }
  
  if (!city || !apiKey) {
    console.error("[Validation] Missing city or API key - returning stops as unverified");
    return stops.map((stop, index) => ({ ...stop, validated: false, order: index + 1 }));
  }

  // Geocode city once so we can bias and verify all venues are in the right place (avoid e.g. Dubai when user asked Chennai)
  let cityCenter: CityCenter | undefined;
  try {
    const geo = await geocodeAddress(city.trim().slice(0, 200), apiKey);
    if (geo) {
      cityCenter = { latitude: geo.latitude, longitude: geo.longitude };
      console.log(`[Validation] City center for "${city}": ${geo.latitude}, ${geo.longitude}`);
    }
  } catch (e) {
    console.warn("[Validation] Could not geocode city for location bias:", e);
  }

  const validatedStops: Stop[] = [];
  
  for (const stop of stops) {
    // Skip stops with missing name
    if (!stop || !stop.name || typeof stop.name !== 'string') {
      console.warn("[Validation] Skipping stop with invalid name");
      continue;
    }
    
    try {
      const result = await validateVenueWithRetry(stop.name, stop.venueType || "", city, apiKey, cityCenter);

      // Skip permanently closed venues, but keep unverified ones
      if (result.isPermanentlyClosed) {
        console.log(`[Validation] Excluding permanently closed venue: ${stop.name}`);
        continue;
      }
      
      // If venue couldn't be verified, include it as unverified (works for any location)
      if (!result.isValid) {
        console.log(`[Validation] Including unverified venue: ${stop.name}`);
        validatedStops.push({
          ...stop,
          validated: false,
        });
        continue;
      }

      // Use the official Google Maps name instead of AI-generated name
      const originalName = stop.name;
      const updatedName = result.officialName || stop.name;
      
      if (originalName !== updatedName) {
        console.log(`[Validation] Updated venue name: "${originalName}" → "${updatedName}"`);
      }

      // Merge platforms: prefer Places-detected (from real website), then fall back to AI hint
      const mergedPlatforms = (() => {
        const fromPlaces = result.reservationPlatforms ?? [];
        const fromAi = stop.reservationPlatforms ?? [];
        // Also check bookingUrl from AI for platform hints
        const fromBooking = detectReservationPlatforms(stop.bookingUrl);
        const combined = new Set([...fromPlaces, ...fromBooking, ...fromAi]);
        return combined.size > 0 ? Array.from(combined) : undefined;
      })();

      validatedStops.push({
        ...stop,
        name: updatedName, // Use official Google Maps name
        validated: true,
        placeId: result.placeId,
        address: result.formattedAddress,
        latitude: result.latitude,
        longitude: result.longitude,
        websiteUrl: result.websiteUrl ?? stop.websiteUrl,
        phoneNumber: result.phoneNumber ?? stop.phoneNumber,
        openingHours: result.openingHours ?? stop.openingHours,
        imageUrl: result.imageUrl ?? stop.imageUrl,
        reservationPlatforms: mergedPlatforms,
      });
    } catch (err) {
      console.error(`[Validation] Unexpected error validating ${stop.name}:`, err);
      // Include the venue as unverified rather than skipping
      validatedStops.push({
        ...stop,
        validated: false,
      });
    }
  }

  console.log(`[Validation] Kept ${validatedStops.length}/${stops.length} validated venues`);
  
  // Re-number the stops after filtering
  return validatedStops.map((stop, index) => ({
    ...stop,
    order: index + 1,
  }));
}