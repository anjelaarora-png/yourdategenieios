// Google Places API validation

interface PlaceValidationResult {
  isValid: boolean;
  isPermanentlyClosed?: boolean;
  isTemporarilyClosed?: boolean;
  rejectReason?: string;
  officialName?: string; // The verified name from Google Maps
  placeId?: string;
  formattedAddress?: string;
  latitude?: number;
  longitude?: number;
  websiteUrl?: string;
  phoneNumber?: string;
  openingHours?: string[];
  businessStatus?: string;
  googleTypes?: string[];
  /** Photo URL from Google Business Profile (Place Details photos) for cards and lists. */
  imageUrl?: string;
  /** Reservation platforms detected from the venue's website URL (e.g. ["opentable", "resy"]). */
  reservationPlatforms?: string[];
}

/** Google place types that must never appear on a date itinerary. */
const DISALLOWED_PLACE_TYPES = new Set([
  "storage",
  "moving_company",
  "car_dealer",
  "car_repair",
  "car_wash",
  "electrician",
  "general_contractor",
  "insurance_agency",
  "lawyer",
  "local_government_office",
  "locksmith",
  "plumber",
  "real_estate_agency",
  "roofing_contractor",
  "accounting",
  "post_office",
  "fire_station",
  "police",
  "funeral_home",
  "cemetery",
  "hospital",
  "doctor",
  "dentist",
  "veterinary_care",
  "gas_station",
  "parking",
  "warehouse",
  "storage",
]);

const SUSPICIOUS_VENUE_NAME =
  /\b(storage|warehouse|u-?haul|self[\s-]?storage|industrial|wholesale|distribution|fulfillment|logistics|freight|depot|mini[\s-]?storage)\b/i;

const VENUE_TYPE_KEYWORDS: Record<string, string[]> = {
  restaurant: ["restaurant", "food", "cafe", "bar", "bakery", "meal_takeaway", "meal_delivery", "night_club"],
  dining: ["restaurant", "food", "cafe", "bar", "bakery", "meal_takeaway"],
  dinner: ["restaurant", "food", "cafe", "bar", "bakery"],
  bar: ["bar", "night_club", "restaurant", "food", "cafe"],
  cafe: ["cafe", "bakery", "restaurant", "food"],
  coffee: ["cafe", "bakery", "restaurant", "food"],
  park: ["park", "natural_feature", "campground", "tourist_attraction"],
  museum: ["museum", "art_gallery", "tourist_attraction", "point_of_interest"],
  gallery: ["art_gallery", "museum", "tourist_attraction", "point_of_interest"],
  theater: ["movie_theater", "performing_arts_theater", "tourist_attraction", "point_of_interest"],
  theatre: ["movie_theater", "performing_arts_theater", "tourist_attraction", "point_of_interest"],
  rooftop: ["bar", "restaurant", "night_club", "tourist_attraction", "point_of_interest"],
  shop: ["store", "shopping_mall", "clothing_store", "book_store", "jewelry_store", "home_goods_store", "tourist_attraction"],
  market: ["store", "shopping_mall", "supermarket", "tourist_attraction", "point_of_interest"],
};

const GENERIC_DATE_TYPES = new Set([
  "point_of_interest",
  "establishment",
  "tourist_attraction",
  "premise",
  "food",
]);

function normalizeVenueTypeKey(venueType: string): string {
  return venueType.trim().toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ");
}

function expectedGoogleTypes(venueType: string): string[] | null {
  const key = normalizeVenueTypeKey(venueType);
  if (!key) return null;
  for (const [needle, types] of Object.entries(VENUE_TYPE_KEYWORDS)) {
    if (key.includes(needle)) return types;
  }
  return null;
}

function hasDisallowedPlaceType(types: string[] | undefined): boolean {
  if (!types?.length) return false;
  return types.some((t) => DISALLOWED_PLACE_TYPES.has(t));
}

function placeTypesMatchVenue(googleTypes: string[] | undefined, venueType: string): boolean {
  if (!googleTypes?.length) return true; // Can't verify — allow if nothing else failed
  if (hasDisallowedPlaceType(googleTypes)) return false;

  const expected = expectedGoogleTypes(venueType);
  if (!expected) return true;

  const typeSet = new Set(googleTypes);
  if (expected.some((t) => typeSet.has(t))) return true;

  // Allow generic POI only when no disallowed types and venue type is broad (e.g. "Experience")
  if (googleTypes.some((t) => GENERIC_DATE_TYPES.has(t)) && !hasDisallowedPlaceType(googleTypes)) {
    return true;
  }

  return false;
}

function tokenizeName(name: string): Set<string> {
  const stopWords = new Set(["the", "and", "bar", "restaurant", "cafe", "grill", "kitchen", "house"]);
  return new Set(
    name
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter((w) => w.length > 2 && !stopWords.has(w)),
  );
}

function namesLikelyMatch(aiName: string, googleName: string): boolean {
  const ai = aiName.trim();
  const google = googleName.trim();
  if (!ai || !google) return true;

  const aiLower = ai.toLowerCase();
  const googleLower = google.toLowerCase();
  if (googleLower.includes(aiLower) || aiLower.includes(googleLower)) return true;

  const aiTokens = tokenizeName(ai);
  const googleTokens = tokenizeName(google);
  if (aiTokens.size === 0 || googleTokens.size === 0) return true;

  let overlap = 0;
  for (const token of aiTokens) {
    if (googleTokens.has(token)) overlap++;
  }
  return overlap / Math.min(aiTokens.size, googleTokens.size) >= 0.34;
}

function hasSuspiciousVenueName(...names: string[]): boolean {
  return names.some((n) => n && SUSPICIOUS_VENUE_NAME.test(n));
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
  cityCenter?: CityCenter,
  venueType?: string,
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
    let findUrl = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${query}&inputtype=textquery&fields=place_id,name,formatted_address,geometry,business_status,types&key=${apiKey}`;
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
      return { isValid: false, rejectReason: "not_found" };
    }

    for (const candidate of findData.candidates.slice(0, 3)) {
      const place = candidate;
      const placeId = place.place_id;
      const officialName = place.name;
      const formattedAddress = place.formatted_address;
      const businessStatus = place.business_status;
      const candidateTypes: string[] = Array.isArray(place.types) ? place.types : [];
      const placeLat = place.geometry?.location?.lat;
      const placeLon = place.geometry?.location?.lng;
      console.log(`[Places API] Candidate: "${officialName}" at "${formattedAddress}" (searched: "${venueName}"), types: ${candidateTypes.join(",")}`);

      if (hasSuspiciousVenueName(venueName, officialName)) {
        console.log(`[Places API] Rejected suspicious name: "${officialName}"`);
        continue;
      }

      if (businessStatus === "CLOSED_PERMANENTLY") {
        console.log(`[Places API] Venue is PERMANENTLY CLOSED: ${officialName}`);
        continue;
      }
      if (businessStatus === "CLOSED_TEMPORARILY") {
        console.log(`[Places API] Venue is TEMPORARILY CLOSED: ${officialName}`);
        continue;
      }

      if (hasDisallowedPlaceType(candidateTypes)) {
        console.log(`[Places API] Rejected disallowed types for "${officialName}": ${candidateTypes.join(",")}`);
        continue;
      }

      if (venueType && !placeTypesMatchVenue(candidateTypes, venueType)) {
        console.log(`[Places API] Types mismatch for "${officialName}" vs venueType "${venueType}"`);
        continue;
      }

      if (!namesLikelyMatch(venueName, officialName)) {
        console.log(`[Places API] Name mismatch: searched "${venueName}" vs Google "${officialName}"`);
        continue;
      }

      const inLocation = isAddressInLocation(
        formattedAddress,
        city,
        placeLat,
        placeLon,
        cityCenter?.latitude,
        cityCenter?.longitude,
        150,
      );
      if (!inLocation) {
        console.log(`[Places API] WRONG LOCATION! Venue "${officialName}" at "${formattedAddress}" is not in "${city}"`);
        continue;
      }

      const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,photos,types,formatted_address,geometry&key=${apiKey}`;

      const detailsResponse = await fetch(detailsUrl);
      let websiteUrl: string | undefined;
      let phoneNumber: string | undefined;
      let openingHours: string[] | undefined;
      let imageUrl: string | undefined;
      let confirmedName = officialName;
      let googleTypes = candidateTypes;

      if (detailsResponse.ok) {
        const detailsData = await detailsResponse.json();
        console.log(`[Places API] Details response status: ${detailsData.status}`);
        if (detailsData.status === "OK" && detailsData.result) {
          if (detailsData.result.business_status === "CLOSED_PERMANENTLY") {
            console.log(`[Places API] Venue confirmed PERMANENTLY CLOSED from details: ${venueName}`);
            continue;
          }
          if (detailsData.result.business_status === "CLOSED_TEMPORARILY") {
            console.log(`[Places API] Venue confirmed TEMPORARILY CLOSED from details: ${venueName}`);
            continue;
          }

          if (detailsData.result.name) {
            confirmedName = detailsData.result.name;
          }

          googleTypes = Array.isArray(detailsData.result.types) ? detailsData.result.types : googleTypes;
          if (hasDisallowedPlaceType(googleTypes)) {
            console.log(`[Places API] Details rejected disallowed types for "${confirmedName}"`);
            continue;
          }
          if (venueType && !placeTypesMatchVenue(googleTypes, venueType)) {
            console.log(`[Places API] Details types mismatch for "${confirmedName}" vs "${venueType}"`);
            continue;
          }
          if (hasSuspiciousVenueName(confirmedName)) {
            console.log(`[Places API] Details rejected suspicious name: "${confirmedName}"`);
            continue;
          }
          if (!namesLikelyMatch(venueName, confirmedName)) {
            console.log(`[Places API] Details name mismatch: "${venueName}" vs "${confirmedName}"`);
            continue;
          }

          websiteUrl = detailsData.result.website;
          phoneNumber = detailsData.result.formatted_phone_number;
          openingHours = detailsData.result.opening_hours?.weekday_text;
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
        googleTypes,
        imageUrl,
        reservationPlatforms: reservationPlatforms.length > 0 ? reservationPlatforms : undefined,
      };
    }

    console.log(`[Places API] All candidates rejected for: ${venueName}`);
    return { isValid: false, rejectReason: "failed_validation" };
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
    
    // Find operational places that match the expected venue category
    const operationalPlace = data.results.find((p: any) => {
      if (p.business_status === "CLOSED_PERMANENTLY" || p.business_status === "CLOSED_TEMPORARILY") {
        return false;
      }
      if (hasSuspiciousVenueName(p.name || "")) return false;
      const types: string[] = Array.isArray(p.types) ? p.types : [];
      if (hasDisallowedPlaceType(types)) return false;
      if (venueType && !placeTypesMatchVenue(types, venueType)) return false;
      return true;
    });
    
    if (!operationalPlace) {
      console.log(`[Places API] No suitable results for venue type: ${venueType} in ${city}`);
      return { isValid: false };
    }
    
    const place = operationalPlace;
    const placeId = place.place_id;
    
    if (place.business_status === "CLOSED_PERMANENTLY") {
      return { isValid: false, isPermanentlyClosed: true };
    }
    
    // Get details for the place (include photos for card images)
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,formatted_address,geometry,photos,types&key=${apiKey}`;
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
        if (detailsData.result.business_status === "CLOSED_TEMPORARILY") {
          return { isValid: false, isTemporarilyClosed: true };
        }
        officialName = detailsData.result.name || officialName;
        if (hasSuspiciousVenueName(officialName)) {
          return { isValid: false, rejectReason: "suspicious_name" };
        }
        const detailTypes: string[] = Array.isArray(detailsData.result.types) ? detailsData.result.types : [];
        if (hasDisallowedPlaceType(detailTypes)) {
          return { isValid: false, rejectReason: "disallowed_type" };
        }
        if (venueType && !placeTypesMatchVenue(detailTypes, venueType)) {
          return { isValid: false, rejectReason: "type_mismatch" };
        }
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
      googleTypes: Array.isArray(place.types) ? place.types : undefined,
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
      
      const result = await validateVenue(venueName, city, apiKey, cityCenter, venueType);
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

  // Validate all stops concurrently with a cap of 4 in-flight Google Places requests.
  const CONCURRENCY = 4;
  const validStops = stops.filter(
    (s) => s && s.name && typeof s.name === "string"
  );
  const skipped = stops.length - validStops.length;
  if (skipped > 0) console.warn(`[Validation] Skipped ${skipped} stops with invalid names`);

  async function validateOne(stop: Stop): Promise<Stop | null> {
    const { imageUrl: _aiImageUrl, ...stopWithoutAiImage } = stop;
    try {
      const result = await validateVenueWithRetry(
        stop.name,
        stop.venueType || "",
        city,
        apiKey,
        cityCenter,
      );

      if (result.isPermanentlyClosed || result.isTemporarilyClosed) {
        console.log(`[Validation] Excluding closed venue: ${stop.name}`);
        return null;
      }
      if (!result.isValid) {
        console.log(`[Validation] Excluding unverified venue (failed triple-check): ${stop.name}`);
        return null;
      }

      const originalName = stop.name;
      const updatedName = result.officialName || stop.name;
      if (originalName !== updatedName) {
        console.log(`[Validation] Updated venue name: "${originalName}" → "${updatedName}"`);
      }

      const mergedPlatforms = (() => {
        const fromPlaces = result.reservationPlatforms ?? [];
        const fromAi = stop.reservationPlatforms ?? [];
        const fromBooking = detectReservationPlatforms(stop.bookingUrl);
        const combined = new Set([...fromPlaces, ...fromBooking, ...fromAi]);
        return combined.size > 0 ? Array.from(combined) : undefined;
      })();

      return {
        ...stopWithoutAiImage,
        name: updatedName,
        validated: true,
        placeId: result.placeId,
        address: result.formattedAddress,
        latitude: result.latitude,
        longitude: result.longitude,
        websiteUrl: result.websiteUrl ?? stop.websiteUrl,
        phoneNumber: result.phoneNumber ?? stop.phoneNumber,
        openingHours: result.openingHours ?? stop.openingHours,
        imageUrl: result.imageUrl,
        reservationPlatforms: mergedPlatforms,
      };
    } catch (err) {
      console.error(`[Validation] Unexpected error validating ${stop.name}:`, err);
      return null;
    }
  }

  // Process in batches to respect CONCURRENCY limit without losing ordering context.
  const resultSlots: (Stop | null)[] = [];
  for (let i = 0; i < validStops.length; i += CONCURRENCY) {
    const batch = validStops.slice(i, i + CONCURRENCY);
    const batchResults = await Promise.all(batch.map(validateOne));
    resultSlots.push(...batchResults);
  }

  const validatedStops: Stop[] = resultSlots.filter((s): s is Stop => s !== null);

  console.log(`[Validation] Kept ${validatedStops.length}/${stops.length} validated venues`);
  
  // Re-number the stops after filtering
  return validatedStops.map((stop, index) => ({
    ...stop,
    order: index + 1,
  }));
}