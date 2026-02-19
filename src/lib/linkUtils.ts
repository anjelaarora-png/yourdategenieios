// Deep link utilities for social media and venue links

/**
 * Generate a smart link that opens in native app if available
 */
export const generateSmartLink = (url: string): string => {
  if (!url) return "";
  
  try {
    const urlObj = new URL(url);
    const hostname = urlObj.hostname.toLowerCase();
    
    // Instagram deep linking
    if (hostname.includes("instagram.com")) {
      const path = urlObj.pathname;
      // Handle profile URLs like instagram.com/username
      const usernameMatch = path.match(/^\/([^/]+)\/?$/);
      if (usernameMatch && usernameMatch[1] !== "p" && usernameMatch[1] !== "reel") {
        const username = usernameMatch[1];
        // iOS/Android deep link format
        return `instagram://user?username=${username}`;
      }
      // Handle post URLs
      const postMatch = path.match(/^\/p\/([^/]+)/);
      if (postMatch) {
        return `instagram://media?id=${postMatch[1]}`;
      }
    }
    
    // TikTok deep linking
    if (hostname.includes("tiktok.com")) {
      const usernameMatch = urlObj.pathname.match(/^\/@([^/]+)/);
      if (usernameMatch) {
        return `snssdk1128://user/profile/${usernameMatch[1]}`;
      }
    }
    
    // Twitter/X deep linking
    if (hostname.includes("twitter.com") || hostname.includes("x.com")) {
      const usernameMatch = urlObj.pathname.match(/^\/([^/]+)\/?$/);
      if (usernameMatch && !["home", "explore", "notifications", "messages"].includes(usernameMatch[1])) {
        return `twitter://user?screen_name=${usernameMatch[1]}`;
      }
    }
    
    // Facebook deep linking
    if (hostname.includes("facebook.com") || hostname.includes("fb.com")) {
      const pageMatch = urlObj.pathname.match(/^\/([^/]+)\/?$/);
      if (pageMatch) {
        return `fb://page/${pageMatch[1]}`;
      }
    }
    
    // Yelp deep linking
    if (hostname.includes("yelp.com")) {
      const bizMatch = urlObj.pathname.match(/^\/biz\/([^/]+)/);
      if (bizMatch) {
        return `yelp:///biz/${bizMatch[1]}`;
      }
    }
    
    // Google Maps deep linking
    if (hostname.includes("google.com/maps") || hostname.includes("maps.google.com")) {
      // Keep as-is, mobile browsers handle this well
      return url;
    }
    
    return url;
  } catch {
    return url;
  }
};

/**
 * Generate a venue search URL based on venue name and city
 */
export const generateVenueSearchUrl = (venueName: string, city?: string): string => {
  const query = encodeURIComponent(city ? `${venueName} ${city}` : venueName);
  return `https://www.google.com/maps/search/${query}`;
};

/**
 * Generate a Yelp search URL for a venue
 */
export const generateYelpUrl = (venueName: string, city?: string): string => {
  const query = encodeURIComponent(venueName);
  const location = city ? encodeURIComponent(city) : "";
  return `https://www.yelp.com/search?find_desc=${query}&find_loc=${location}`;
};

/**
 * Generate an OpenTable search URL for a restaurant
 */
export const generateOpenTableUrl = (restaurantName: string, city?: string): string => {
  const query = encodeURIComponent(restaurantName);
  return `https://www.opentable.com/s?term=${query}${city ? `&metroId=&covers=2&dateTime=2024-01-01T19:00` : ""}`;
};

/**
 * Check if URL is a social media link
 */
export const isSocialMediaUrl = (url: string): boolean => {
  if (!url) return false;
  try {
    const hostname = new URL(url).hostname.toLowerCase();
    return (
      hostname.includes("instagram.com") ||
      hostname.includes("tiktok.com") ||
      hostname.includes("twitter.com") ||
      hostname.includes("x.com") ||
      hostname.includes("facebook.com") ||
      hostname.includes("fb.com")
    );
  } catch {
    return false;
  }
};

/**
 * Get the appropriate link with fallback to web URL
 * Opens in app if supported, otherwise opens web URL
 */
export const getClickableLink = (url: string): { href: string; fallbackHref: string } => {
  const smartLink = generateSmartLink(url);
  return {
    href: smartLink,
    fallbackHref: url,
  };
};
