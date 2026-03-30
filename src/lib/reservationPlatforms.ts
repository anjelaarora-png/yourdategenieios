/**
 * Reservation platform connections by country/region.
 * Top platforms per region: USA = OpenTable, Resy; UK = OpenTable, TheFork; etc.
 */

export type Region =
  | "us"
  | "uk"
  | "ca"
  | "au"
  | "fr"
  | "de"
  | "it"
  | "es"
  | "jp"
  | "india"
  | "ae"
  | "sa"
  | "sg"
  | "th"
  | "my"
  | "br"
  | "mx"
  | "za"
  | "nz"
  | "eu"
  | "latam"
  | "other";

export interface ReservationPlatformConfig {
  id: string;
  name: string;
  /** Preferred label for CTA, e.g. "Reserve on OpenTable" */
  ctaLabel: string;
  regions: Region[];
  getUrl: (params: {
    venueName: string;
    date: string;
    time: string;
    partySize: string;
    address?: string;
  }) => string;
}

/** Top 2 reservation platforms per country — matches product list. */
export const PRIMARY_PLATFORMS_BY_REGION: Record<Region, [string, string]> = {
  us: ["opentable", "resy"],
  uk: ["opentable", "thefork"],
  ca: ["opentable", "resy"],
  au: ["opentable", "quandoo"],
  fr: ["thefork", "opentable"],
  de: ["thefork", "quandoo"],
  it: ["thefork", "opentable"],
  es: ["thefork", "opentable"],
  jp: ["tabelog", "opentable"],
  india: ["swiggy", "district"],
  ae: ["eatapp", "zomato"],
  sa: ["eatapp", "thechefz"],
  sg: ["chope", "eatigo"],
  th: ["eatigo", "opentable"],
  my: ["eatigo", "opentable"],
  br: ["opentable", "tripadvisor"],
  mx: ["opentable", "tripadvisor"],
  za: ["zomato", "opentable"],
  nz: ["opentable", "firsttable"],
  eu: ["thefork", "quandoo"],
  latam: ["opentable", "thefork"],
  other: ["opentable", "quandoo"],
};

/**
 * Build search string to send to reservation platforms: restaurant name plus city when available.
 * Use this so the platform pre-fills the search with the right venue (we usually don't have a direct booking URL).
 */
export function restaurantSearchTerm(venueName: string, address?: string): string {
  const name = (venueName || "").trim();
  const effectiveName = name || "Restaurant";
  if (!address) return effectiveName;
  const parts = address.split(",").map((p) => p.trim()).filter(Boolean);
  const city = parts.length >= 2 ? parts[parts.length - 2] : "";
  if (!city) return effectiveName;
  return `${effectiveName} ${city}`;
}

function getCitySlugFromAddress(addr?: string): string {
  if (!addr) return "ny";
  const parts = addr.split(",");
  if (parts.length >= 2) {
    const city = parts[parts.length - 2]?.trim().toLowerCase();
    const cityMap: Record<string, string> = {
      "new york": "ny",
      nyc: "ny",
      manhattan: "ny",
      brooklyn: "ny",
      "los angeles": "la",
      la: "la",
      "san francisco": "sf",
      sf: "sf",
      chicago: "chi",
      miami: "mia",
      austin: "atx",
      denver: "den",
      seattle: "sea",
      boston: "bos",
      washington: "dc",
      dc: "dc",
      atlanta: "atl",
      nashville: "nash",
      houston: "hou",
      dallas: "dal",
      philadelphia: "phl",
    };
    for (const [key, value] of Object.entries(cityMap)) {
      if (city?.includes(key)) return value;
    }
  }
  return "ny";
}

/** Chope city slug for URL (chope.co/{slug}-restaurants). */
function getChopeCitySlug(addr?: string): string {
  if (!addr) return "singapore";
  const city = addr.split(",").slice(-2, -1)[0]?.trim().toLowerCase() ?? "";
  const map: Record<string, string> = {
    singapore: "singapore",
    "hong kong": "hong-kong",
    hong kong: "hong-kong",
    bangkok: "bangkok",
    phuket: "phuket",
    bali: "bali",
    jakarta: "jakarta",
    shanghai: "shanghai",
  };
  for (const [key, value] of Object.entries(map)) {
    if (city.includes(key)) return value;
  }
  return "singapore";
}

/** Tabelog Japan area slug (tabelog.com/en/{area}/). */
function getTabelogAreaSlug(addr?: string): string {
  if (!addr) return "tokyo";
  const city = addr.split(",").slice(-2, -1)[0]?.trim().toLowerCase() ?? "";
  const map: Record<string, string> = {
    tokyo: "tokyo",
    osaka: "osaka",
    kyoto: "kyoto",
    yokohama: "kanagawa",
    fukuoka: "fukuoka",
    sapporo: "hokkaido",
    nagoya: "aichi",
    hiroshima: "hiroshima",
  };
  for (const [key, value] of Object.entries(map)) {
    if (city.includes(key)) return value;
  }
  return "tokyo";
}

/** Eatigo country path (eatigo.com/{cc}/{city}/en). */
function getEatigoPath(addr?: string): string {
  if (!addr) return "sg/singapore";
  const lower = addr.toLowerCase();
  if (lower.includes("thailand") || lower.includes("bangkok") || lower.includes("phuket")) return "th/bangkok";
  if (lower.includes("malaysia") || lower.includes("kuala lumpur") || lower.includes("penang")) return "my/kuala-lumpur";
  return "sg/singapore";
}

export const RESERVATION_PLATFORMS: ReservationPlatformConfig[] = [
  {
    id: "opentable",
    name: "OpenTable",
    ctaLabel: "Reserve on OpenTable",
    regions: ["us", "uk", "au", "ca", "mx", "nz", "fr", "de", "it", "es", "jp", "th", "my", "br", "za", "eu", "latam", "other"],
    getUrl: ({ venueName, date, time, partySize, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      const locationQuery = address
        ? encodeURIComponent(address.split(",")[0]?.trim() || "")
        : "";
      return `https://www.opentable.com/s?covers=${partySize}&dateTime=${date}T${time}&term=${searchQuery}${locationQuery ? `&metroId=&regionId=&neighborhood=${locationQuery}` : ""}`;
    },
  },
  {
    id: "resy",
    name: "Resy",
    ctaLabel: "Reserve on Resy",
    regions: ["us", "ca"],
    getUrl: ({ venueName, date, partySize, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      const city = getCitySlugFromAddress(address);
      return `https://resy.com/cities/${city}?query=${searchQuery}&date=${date}&seats=${partySize}`;
    },
  },
  {
    id: "thefork",
    name: "TheFork",
    ctaLabel: "Reserve on TheFork",
    regions: ["uk", "fr", "de", "it", "es", "eu", "latam", "sa"],
    getUrl: ({ venueName, date, time, partySize, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      return `https://www.thefork.com/search?cityId=&queryText=${searchQuery}&date=${date}&time=${time}&partySize=${partySize}`;
    },
  },
  {
    id: "quandoo",
    name: "Quandoo",
    ctaLabel: "Reserve on Quandoo",
    regions: ["au", "de", "eu", "other"],
    getUrl: ({ venueName, date, time, partySize, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      return `https://www.quandoo.com/en/search?query=${searchQuery}&date=${date}&time=${time}&pax=${partySize}`;
    },
  },
  {
    id: "tabelog",
    name: "Tabelog",
    ctaLabel: "Reserve on Tabelog",
    regions: ["jp"],
    getUrl: ({ venueName, address }) => {
      const area = getTabelogAreaSlug(address);
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      return `https://tabelog.com/en/${area}/rstLst/?vs=1&sk=${query}`;
    },
  },
  {
    id: "swiggy",
    name: "Swiggy",
    ctaLabel: "Dineout on Swiggy",
    regions: ["india"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      return `https://www.swiggy.com/dineout?query=${encodeURIComponent(term)}`;
    },
  },
  {
    id: "district",
    name: "District",
    ctaLabel: "Reserve on District",
    regions: ["india"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      return `https://www.district.in/dine?q=${query}`;
    },
  },
  {
    id: "eatapp",
    name: "Eat App",
    ctaLabel: "Reserve on Eat App",
    regions: ["ae", "sa"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      return `https://eat.app/search?q=${searchQuery}`;
    },
  },
  {
    id: "thechefz",
    name: "The Chefz",
    ctaLabel: "Order & reserve on The Chefz",
    regions: ["sa"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      return `https://thechefz.co/en/search?q=${query}`;
    },
  },
  {
    id: "chope",
    name: "Chope",
    ctaLabel: "Reserve on Chope",
    regions: ["sg"],
    getUrl: ({ venueName, address }) => {
      const slug = getChopeCitySlug(address);
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      return `https://www.chope.co/${slug}-restaurants?query=${query}`;
    },
  },
  {
    id: "eatigo",
    name: "Eatigo",
    ctaLabel: "Reserve on Eatigo",
    regions: ["sg", "th", "my"],
    getUrl: ({ venueName, address }) => {
      const path = getEatigoPath(address);
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      return `https://eatigo.com/${path}/en?search=${query}`;
    },
  },
  {
    id: "tripadvisor",
    name: "TripAdvisor",
    ctaLabel: "Find on TripAdvisor",
    regions: ["br", "mx"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(`${term} restaurant`);
      return `https://www.tripadvisor.com/Search?q=${query}`;
    },
  },
  {
    id: "zomato",
    name: "Zomato",
    ctaLabel: "Find on Zomato",
    regions: ["india", "ae", "za"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      const city =
        address?.split(",").slice(-2, -1)[0]?.trim().toLowerCase() || "mumbai";
      const safeCity = city.replace(/\s+/g, "-");
      return `https://www.zomato.com/${safeCity}/restaurants?q=${searchQuery}`;
    },
  },
  {
    id: "firsttable",
    name: "First Table",
    ctaLabel: "Reserve on First Table",
    regions: ["nz", "au"],
    getUrl: ({ venueName, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const query = encodeURIComponent(term);
      const isNz = !address || address.toLowerCase().includes("zealand") || address.toLowerCase().includes("auckland") || address.toLowerCase().includes("wellington");
      const base = isNz ? "https://www.firsttable.co.nz" : "https://www.firsttable.com.au";
      return `${base}/search?q=${query}`;
    },
  },
  {
    id: "tablecheck",
    name: "TableCheck",
    ctaLabel: "Reserve on TableCheck",
    regions: ["jp"],
    getUrl: ({ venueName, date, time, partySize, address }) => {
      const term = restaurantSearchTerm(venueName, address);
      const searchQuery = encodeURIComponent(term);
      return `https://www.tablecheck.com/en/search?query=${searchQuery}&date=${date}&time=${time}&pax=${partySize}`;
    },
  },
];

/**
 * Detect region from address string (e.g. "123 Main St, New York, NY 10001, USA").
 * Defaults to "us" when unknown or missing.
 */
export function detectRegionFromAddress(address?: string): Region {
  if (!address) return "us";

  const lowerAddr = address.toLowerCase();
  // Order matters: country-specific first, then fallbacks
  const patterns: Array<{ pattern: RegExp; region: Region }> = [
    { pattern: /\b(usa|united states|u\.s\.a?\.|, [a-z]{2} \d{5})/i, region: "us" },
    { pattern: /\b(canada|ontario|quebec|british columbia|toronto|vancouver|montreal|calgary|ottawa|, bc\b|, ab\b|, qc\b|, on\b)/i, region: "ca" },
    { pattern: /\b(mexico|méxico|cdmx|guadalajara|monterrey|cancun|oaxaca|quintana roo)\b/i, region: "mx" },
    { pattern: /\b(new zealand|nz|auckland|wellington|christchurch|queenstown|dunedin)\b/i, region: "nz" },
    { pattern: /\b(uae|u\.a\.e\.|dubai|abu dhabi|emirates)\b/i, region: "ae" },
    { pattern: /\b(saudi arabia|saudi|riyadh|jeddah|mecca|dammam)\b/i, region: "sa" },
    { pattern: /\b(south africa|johannesburg|cape town|durban|pretoria)\b/i, region: "za" },
    { pattern: /\b(brazil|brasil|são paulo|sao paulo|rio de janeiro|brasília|brasilia)\b/i, region: "br" },
    { pattern: /\b(uk|united kingdom|england|scotland|wales|london|manchester|birmingham|liverpool|leeds|glasgow|edinburgh)\b/i, region: "uk" },
    { pattern: /\b[a-z]{1,2}\d{1,2}[a-z]?\s?\d[a-z]{2}\b/i, region: "uk" },
    { pattern: /\b(france|paris|lyon|marseille)\b/i, region: "fr" },
    { pattern: /\b(germany|deutschland|berlin|munich|hamburg|frankfurt|cologne)\b/i, region: "de" },
    { pattern: /\b(italy|italia|rome|roma|milan|milano|naples|florence|venice)\b/i, region: "it" },
    { pattern: /\b(spain|españa|espana|madrid|barcelona|valencia|seville)\b/i, region: "es" },
    { pattern: /\b(japan|tokyo|osaka|kyoto|yokohama|nagoya|fukuoka|sapporo|hiroshima)\b/i, region: "jp" },
    { pattern: /\b(india|mumbai|delhi|bangalore|bengaluru|chennai|hyderabad|kolkata|pune|ahmedabad|jaipur)\b/i, region: "india" },
    { pattern: /\b(singapore|sg)\b/i, region: "sg" },
    { pattern: /\b(thailand|bangkok|phuket|chiang mai)\b/i, region: "th" },
    { pattern: /\b(malaysia|kuala lumpur|penang|george town|johor)\b/i, region: "my" },
    { pattern: /\b(argentina|chile|colombia|peru|lima|buenos aires|bogotá|bogota|santiago)\b/i, region: "latam" },
    {
      pattern:
        /\b(ny|nyc|ca|tx|fl|wa|il|pa|oh|ga|nc|mi|nj|va|az|ma|tn|in|mo|md|wi|mn|co|al|sc|la|ky|or|ok|ct|ut|ia|nv|ar|ms|ks|nm|ne|wv|id|hi|nh|me|mt|ri|de|sd|nd|ak|vt|dc|wy)\b/i,
      region: "us",
    },
    {
      pattern:
        /\b(australia|sydney|melbourne|brisbane|perth|adelaide|canberra|nsw|vic|qld|wa|sa\b|tas|nt|act)\b/i,
      region: "au",
    },
    {
      pattern:
        /\b(netherlands|belgium|austria|switzerland|portugal|ireland|denmark|sweden|norway|finland|greece|poland|czech|hungary|amsterdam|brussels|vienna|zurich|lisbon|dublin|copenhagen|stockholm)\b/i,
      region: "eu",
    },
  ];

  for (const { pattern, region } of patterns) {
    if (pattern.test(lowerAddr)) return region;
  }
  return "us";
}

/**
 * Get the top two reservation platforms for a region, in display order.
 * Used so each country sees its two leading dining reservation platforms.
 */
export function getTopTwoPlatformsForRegion(
  region: Region
): ReservationPlatformConfig[] {
  const [firstId, secondId] = PRIMARY_PLATFORMS_BY_REGION[region];
  const all = RESERVATION_PLATFORMS.filter((p) => p.regions.includes(region));
  const first = all.find((p) => p.id === firstId);
  const second = all.find((p) => p.id === secondId);
  const result: ReservationPlatformConfig[] = [];
  if (first) result.push(first);
  if (second && second.id !== first?.id) result.push(second);
  return result.slice(0, 2);
}

/**
 * Get reservation platforms for a region, ordered with primary (top two) first.
 * @param maxPlatforms - max count to return; default 2 for "top two" display.
 */
export function getPlatformsForRegion(
  region: Region,
  maxPlatforms = 2
): ReservationPlatformConfig[] {
  const primaryIds = PRIMARY_PLATFORMS_BY_REGION[region];
  const available = RESERVATION_PLATFORMS.filter((p) => p.regions.includes(region));
  const byPrimary = [...available].sort((a, b) => {
    const aIdx = primaryIds.indexOf(a.id);
    const bIdx = primaryIds.indexOf(b.id);
    if (aIdx === -1 && bIdx === -1) return 0;
    if (aIdx === -1) return 1;
    if (bIdx === -1) return -1;
    return aIdx - bIdx;
  });
  return byPrimary.slice(0, maxPlatforms);
}

/**
 * Brand icon for reservation platforms.
 * slug: Simple Icons CDN slug (cdn.simpleicons.org/{slug}) — only set when icon exists in Simple Icons.
 * color: hex without # for CDN or fallback initial circle.
 */
export const PLATFORM_ICONS: Record<
  string,
  { slug?: string; color: string }
> = {
  opentable: { slug: "opentable", color: "DA3741" },
  resy: { slug: "resy", color: "2D2D2D" },
  thefork: { slug: "thefork", color: "F05537" },
  quandoo: { slug: "quandoo", color: "00A0DC" },
  tabelog: { slug: "tabelog", color: "E60012" },
  swiggy: { slug: "swiggy", color: "FC8019" },
  district: { slug: "district", color: "334155" },
  eatapp: { slug: "eatapp", color: "212121" },
  thechefz: { slug: "thechefz", color: "E31937" },
  chope: { slug: "chope", color: "E31937" },
  eatigo: { slug: "eatigo", color: "EE2E24" },
  tripadvisor: { slug: "tripadvisor", color: "34E0A1" },
  zomato: { slug: "zomato", color: "E23744" },
  firsttable: { slug: "firsttable", color: "E31937" },
  tablecheck: { slug: "tablecheck", color: "0D9488" },
};

/** Human-readable label for region/country. */
export const REGION_LABELS: Record<Region, string> = {
  us: "USA",
  uk: "UK",
  ca: "Canada",
  au: "Australia",
  fr: "France",
  de: "Germany",
  it: "Italy",
  es: "Spain",
  jp: "Japan",
  india: "India",
  ae: "UAE / Dubai",
  sa: "Saudi Arabia",
  sg: "Singapore",
  th: "Thailand",
  my: "Malaysia",
  br: "Brazil",
  mx: "Mexico",
  za: "South Africa",
  nz: "New Zealand",
  eu: "Europe",
  latam: "Latin America",
  other: "International",
};
