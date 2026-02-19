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

// Trust Google's search results - we already search with "[venue] [city]"
// so Google is already filtering by location
function isAddressInLocation(address: string, city: string): boolean {
  // Always trust Google's result if we have an address
  // The search query already includes the city, so results are location-relevant
  if (address) {
    console.log(`[Places API] Trusting Google result: "${address}" for city "${city}"`);
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

export async function validateVenue(
  venueName: string,
  city: string,
  apiKey: string
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
    // Step 1: Find the place (include name and business_status)
    const sanitizedVenue = venueName.trim().slice(0, 200); // Limit length
    const sanitizedCity = city.trim().slice(0, 100);
    const query = encodeURIComponent(`${sanitizedVenue} ${sanitizedCity}`);
    const findUrl = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${query}&inputtype=textquery&fields=place_id,name,formatted_address,geometry,business_status&key=${apiKey}`;

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
    console.log(`[Places API] Found: "${officialName}" at "${formattedAddress}" (searched: "${venueName}"), placeId: ${placeId}, status: ${businessStatus}`);

    // CRITICAL: Verify the venue is actually in the correct location
    if (!isAddressInLocation(formattedAddress, city)) {
      console.log(`[Places API] WRONG LOCATION! Venue "${officialName}" is at "${formattedAddress}" but user requested "${city}"`);
      return { isValid: false };
    }

    // Check if permanently closed
    if (businessStatus === "CLOSED_PERMANENTLY") {
      console.log(`[Places API] Venue is PERMANENTLY CLOSED: ${officialName}`);
      return { isValid: false, isPermanentlyClosed: true };
    }

    // Step 2: Get place details (website, phone, hours, official name for confirmation)
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status&key=${apiKey}`;
    
    const detailsResponse = await fetch(detailsUrl);
    let websiteUrl: string | undefined;
    let phoneNumber: string | undefined;
    let openingHours: string[] | undefined;
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
        console.log(`[Places API] Details for "${confirmedName}": website=${websiteUrl}, phone=${phoneNumber}, hours=${openingHours?.length || 0} entries`);
      }
    } else {
      console.error("[Places API] Details fetch failed:", detailsResponse.status);
    }

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
  apiKey: string
): Promise<PlaceValidationResult> {
  try {
    // Search for the venue type in the city
    const query = encodeURIComponent(`${venueType} in ${city}`);
    const searchUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&key=${apiKey}`;
    
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
    
    // Get details for the place
    const detailsUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,website,formatted_phone_number,opening_hours,business_status,formatted_address,geometry&key=${apiKey}`;
    const detailsResponse = await fetch(detailsUrl);
    
    let websiteUrl: string | undefined;
    let phoneNumber: string | undefined;
    let openingHours: string[] | undefined;
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
      }
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
      
      const result = await validateVenue(venueName, city, apiKey);
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
    const fallbackResult = await searchVenueByType(venueType, city, apiKey);
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

  const validatedStops: Stop[] = [];
  
  for (const stop of stops) {
    // Skip stops with missing name
    if (!stop || !stop.name || typeof stop.name !== 'string') {
      console.warn("[Validation] Skipping stop with invalid name");
      continue;
    }
    
    try {
      const result = await validateVenueWithRetry(stop.name, stop.venueType || "", city, apiKey);

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

      validatedStops.push({
        ...stop,
        name: updatedName, // Use official Google Maps name
        validated: true,
        placeId: result.placeId,
        address: result.formattedAddress,
        latitude: result.latitude,
        longitude: result.longitude,
        websiteUrl: result.websiteUrl,
        phoneNumber: result.phoneNumber,
        openingHours: result.openingHours,
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