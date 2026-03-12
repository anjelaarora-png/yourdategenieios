export interface QuestionnaireData {
  city: string;
  neighborhood: string;
  startingAddress?: string;
  dateType: string;
  occasion: string;
  dateScheduled?: string;
  startTime?: string;
  transportationMode: string;
  travelRadius: string;
  energyLevel: string;
  activityPreferences: string[];
  timeOfDay: string;
  duration: string;
  cuisinePreferences: string[];
  dietaryRestrictions: string[];
  drinkPreferences: string;
  budgetRange: string;
  allergies: string[];
  hardNos: string[];
  accessibilityNeeds?: string[];
  smokingPreference?: string;
  smokingActivities?: string[];
  additionalNotes: string;
  // Relationship enhancers
  userIdentity?: string;
  partnerIdentity?: string;
  userLoveLanguages?: string[];
  partnerLoveLanguages?: string[];
  wantGiftSuggestions?: boolean;
  giftRecipient?: string;
  giftRecipientNotes?: string;
  partnerInterests?: string[];
  giftBudget?: string;
  wantConversationStarters?: boolean;
  relationshipStage?: string;
  conversationTopics?: string[];
}

const getTransportLabel = (mode: string): string => {
  const labels: Record<string, string> = {
    walking: "Walking",
    rideshare: "Rideshare/Taxi",
    driving: "Personal Car",
    "public-transit": "Public Transit",
    biking: "Biking",
  };
  return labels[mode] || mode;
};

const getRadiusLabel = (radius: string): string => {
  const labels: Record<string, string> = {
    walkable: "Walkable (< 1 mile between stops)",
    neighborhood: "Same neighborhood (1-5 miles)",
    "city-wide": "City-wide (5-15 miles)",
    metro: "Metro area (15-30 miles)",
    regional: "Regional (30-50 miles)",
    "road-trip": "Road trip (50+ miles)",
  };
  return labels[radius] || radius;
};

const formatTime = (time: string): string => {
  if (!time) return "";
  const [hours, minutes] = time.split(":");
  const hour = parseInt(hours, 10);
  const ampm = hour >= 12 ? "PM" : "AM";
  const hour12 = hour % 12 || 12;
  return `${hour12}:${minutes} ${ampm}`;
};

const formatDate = (dateStr: string): string => {
  if (!dateStr) return "";
  const date = new Date(dateStr + "T00:00:00");
  return date.toLocaleDateString("en-US", { 
    weekday: "long", 
    year: "numeric", 
    month: "long", 
    day: "numeric" 
  });
};

const getRelationshipLabel = (stage: string): string => {
  const labels: Record<string, string> = {
    new: "New relationship - still getting to know each other",
    dating: "Dating for 1-2 years - building something special",
    established: "Established relationship of 3+ years - deep connection",
    rekindling: "Rekindling the spark after time together",
    "long-distance": "Long distance - making moments count",
  };
  return labels[stage] || stage;
};

const getInterestLabels = (interests: string[]): string => {
  const labels: Record<string, string> = {
    tech: "Technology",
    fashion: "Fashion",
    sports: "Sports",
    books: "Books/Reading",
    music: "Music",
    art: "Art & Design",
    cooking: "Cooking/Food",
    travel: "Travel",
    fitness: "Fitness/Wellness",
    gaming: "Gaming",
    nature: "Nature/Outdoors",
    movies: "Movies/TV",
  };
  return interests.map(i => labels[i] || i).join(", ");
};

const getTopicLabels = (topics: string[]): string => {
  const labels: Record<string, string> = {
    dreams: "Dreams & Future Goals",
    memories: "Shared Memories & Past",
    values: "Values & Beliefs",
    fun: "Fun & Playful Topics",
    deep: "Deep Emotional Connection",
    adventure: "Adventures & Bucket List",
  };
  return topics.map(t => labels[t] || t).join(", ");
};

const getIdentityLabel = (identity: string): string => {
  const labels: Record<string, string> = {
    man: "a man",
    woman: "a woman",
    "non-binary": "non-binary",
    "prefer-not-to-say": "not specified",
  };
  return labels[identity] || identity;
};

const getGiftRecipientLabel = (recipient: string): string => {
  const labels: Record<string, string> = {
    partner: "their partner",
    date: "their date",
    myself: "themselves (self-care gift)",
    both: "both people in the couple",
  };
  return labels[recipient] || recipient;
};

const getLoveLanguageLabels = (languages: string[]): string => {
  const labels: Record<string, string> = {
    words: "Words of Affirmation",
    acts: "Acts of Service",
    gifts: "Receiving Gifts",
    time: "Quality Time",
    touch: "Physical Touch",
  };
  return languages.map(l => labels[l] || l).join(", ");
};

const getAccessibilityLabels = (needs: string[]): string => {
  const labels: Record<string, string> = {
    wheelchair: "Wheelchair accessible venues required",
    "mobility-aid": "Space for mobility aids (walkers, canes, scooters)",
    "limited-walking": "Minimize walking distances between venues",
    seating: "Venues with frequent seating/rest areas",
    "quiet-environment": "Quiet, sensory-friendly environments",
    "low-light": "Avoid bright or flashing lights",
    "service-animal": "Service animal accommodations required",
    "asl-friendly": "ASL/Deaf-friendly venues (visual menus, good lighting)",
  };
  return needs.map(n => labels[n] || n).join("; ");
};

const getSmokingPreferenceLabel = (pref: string): string => {
  const labels: Record<string, string> = {
    "smoke-free": "Prefer completely smoke-free venues and patios",
    "outdoor-ok": "Outdoor areas with designated smoking sections are acceptable",
    "flexible": "No strong preference regarding smoking areas",
  };
  return labels[pref] || pref;
};

const getSmokingActivitiesLabel = (activities: string[]): string => {
  const labels: Record<string, string> = {
    "hookah": "hookah/shisha lounge",
    "cigar": "upscale cigar bar or lounge",
    "cannabis": "cannabis-friendly venue or 420 lounge",
    "vape": "vape-friendly venue",
    "pipe": "classic tobacco pipe bar",
  };
  return activities
    .filter(a => a !== "none")
    .map(a => labels[a] || a)
    .join(", ");
};

export const buildPrompt = (data: QuestionnaireData): string => {
  const isSoloDate = data.dateType === "solo";
  
  const activities = data.activityPreferences && data.activityPreferences.length > 0
    ? data.activityPreferences.join(", ")
    : "any activities";

  const cuisines = data.cuisinePreferences && data.cuisinePreferences.length > 0
    ? data.cuisinePreferences.join(", ")
    : "any cuisine";

  const dietary = data.dietaryRestrictions && data.dietaryRestrictions.length > 0 &&
      !data.dietaryRestrictions.includes("none")
    ? `Dietary restrictions: ${data.dietaryRestrictions.join(", ")}.`
    : "";

  const allergies = data.allergies && data.allergies.length > 0 && !data.allergies.includes("none")
    ? `Food allergies: ${data.allergies.join(", ")}.`
    : "";

  const hardNos = data.hardNos && data.hardNos.length > 0
    ? `Absolutely avoid: ${data.hardNos.join(", ")}.`
    : "";

  const accessibilityNeeds = data.accessibilityNeeds && data.accessibilityNeeds.length > 0 && 
      !data.accessibilityNeeds.includes("none")
    ? `ACCESSIBILITY REQUIREMENTS (CRITICAL): ${getAccessibilityLabels(data.accessibilityNeeds)}`
    : "";

  const smokingPref = data.smokingPreference && data.smokingPreference !== "flexible"
    ? `Venue atmosphere: ${getSmokingPreferenceLabel(data.smokingPreference)}`
    : "";

  const smokingActivities = data.smokingActivities && data.smokingActivities.length > 0 && 
      !data.smokingActivities.includes("none")
    ? `INCLUDE smoking/vibe experiences: ${getSmokingActivitiesLabel(data.smokingActivities)}. Find venues that offer these experiences as part of the date.`
    : "";

  const additionalNotes = data.additionalNotes
    ? `Additional notes: ${data.additionalNotes}`
    : "";

  const transportMode = getTransportLabel(data.transportationMode || "walking");
  const travelRadius = getRadiusLabel(data.travelRadius || "neighborhood");

  // Date/time scheduling
  const scheduledDate = data.dateScheduled ? formatDate(data.dateScheduled) : "";
  const scheduledTime = data.startTime ? formatTime(data.startTime) : "";
  const dateTimeInfo = scheduledDate 
    ? `SCHEDULED DATE: ${scheduledDate}${scheduledTime ? ` starting at ${scheduledTime}` : ""}`
    : "";

  // Identity and self-care/love languages info
  let identitySection = "";
  
  if (isSoloDate) {
    // Solo date: focus on the individual
    const hasUserInfo = data.userIdentity || (data.userLoveLanguages && data.userLoveLanguages.length > 0);
    if (hasUserInfo) {
      const userPart = data.userIdentity && data.userIdentity !== "prefer-not-to-say" 
        ? `This person identifies as ${getIdentityLabel(data.userIdentity)}.` 
        : "";
      const selfCarePart = data.userLoveLanguages && data.userLoveLanguages.length > 0
        ? `Their self-care preferences: ${getLoveLanguageLabels(data.userLoveLanguages)}.`
        : "";
      
      identitySection = `
SOLO DATE - SELF-CARE INFO:
${userPart}
${selfCarePart}
Use their self-care preferences to suggest activities and experiences that will help them feel relaxed, recharged, and fulfilled.`.trim();
    }
  } else {
    // Couple date: include partner info
    const hasIdentity = data.userIdentity || data.partnerIdentity;
    const hasLoveLanguages = (data.userLoveLanguages && data.userLoveLanguages.length > 0) || 
                             (data.partnerLoveLanguages && data.partnerLoveLanguages.length > 0);
    
    if (hasIdentity || hasLoveLanguages) {
      const userPart = data.userIdentity && data.userIdentity !== "prefer-not-to-say" 
        ? `The person planning this date identifies as ${getIdentityLabel(data.userIdentity)}.` 
        : "";
      const partnerPart = data.partnerIdentity && data.partnerIdentity !== "prefer-not-to-say"
        ? `Their partner identifies as ${getIdentityLabel(data.partnerIdentity)}.`
        : "";
      const userLoveLangPart = data.userLoveLanguages && data.userLoveLanguages.length > 0
        ? `Their love languages: ${getLoveLanguageLabels(data.userLoveLanguages)}.`
        : "";
      const partnerLoveLangPart = data.partnerLoveLanguages && data.partnerLoveLanguages.length > 0
        ? `Partner's love languages: ${getLoveLanguageLabels(data.partnerLoveLanguages)}.`
        : "";
      
      identitySection = `
COUPLE INFO:
${userPart}
${partnerPart}
${userLoveLangPart}
${partnerLoveLangPart}
Use their love languages to suggest activities, gestures, and date elements that will resonate most deeply with each person.`.trim();
    }
  }

  // Gift/self-care treats suggestions section
  let giftSection = "";
  if (data.wantGiftSuggestions) {
    const recipient = isSoloDate ? "themselves (self-care treat)" : (data.giftRecipient ? getGiftRecipientLabel(data.giftRecipient) : "their partner");
    const interests = data.partnerInterests && data.partnerInterests.length > 0
      ? getInterestLabels(data.partnerInterests)
      : "not specified";
    const notes = data.giftRecipientNotes ? `\n- Special notes: ${data.giftRecipientNotes}` : "";
    const userLocation = data.city ? `${data.city}${data.neighborhood ? `, ${data.neighborhood}` : ""}` : "user's area";
    
    if (isSoloDate) {
      giftSection = `
SELF-CARE TREAT SUGGESTIONS REQUIRED (ALWAYS INCLUDE):
- Shopping for: ${recipient}
- Their interests: ${interests}
- Budget: ${data.giftBudget || "moderate"}
- Occasion: ${data.occasion || "Self-care day"}${notes}
- User location (for where to buy): ${userLocation}
IMPORTANT: You MUST include at least 3 thoughtful self-care treat suggestions (ideally 5). Each must have: name, description, priceRange, whereToBuy (1-2 retailers easy to find in ${userLocation}), purchaseUrl (REQUIRED - use a search link that works in the user's region, e.g. Amazon or Target search for the product), and whyItFits. Prefer retailers that are widely accessible (e.g. Amazon, Target, Walmart in US; Amazon UK, John Lewis in UK).`;
    } else {
      giftSection = `
GIFT SUGGESTIONS REQUIRED (ALWAYS INCLUDE):
- Shopping for: ${recipient}
- Their interests: ${interests}
- Gift budget: ${data.giftBudget || "moderate"}
- Occasion: ${data.occasion || "Just because"}${notes}
- User location (for where to buy): ${userLocation}
IMPORTANT: You MUST include at least 3 thoughtful gift suggestions (ideally 5). Each must have: name, description, priceRange, whereToBuy (1-2 retailers easy to find in ${userLocation}), purchaseUrl (REQUIRED - direct search or product URL where they can buy, e.g. Amazon or Target search link for the product in the user's region), and whyItFits. Match gifts to their stated interests and notes. Prefer retailers that are widely accessible in the user's location.`;
    }
  }

  // Conversation starters / self-reflection prompts section
  let conversationSection = "";
  if (data.wantConversationStarters) {
    const topics = data.conversationTopics && data.conversationTopics.length > 0
      ? getTopicLabels(data.conversationTopics)
      : "general self-discovery topics";
    
    if (isSoloDate) {
      conversationSection = `
SELF-REFLECTION PROMPTS REQUESTED:
- Preferred topics: ${topics}
Please include 10-15 thoughtful self-reflection prompts for journaling or contemplation. Focus on questions that encourage self-discovery, gratitude, personal growth, and mindfulness.`;
    } else if (data.relationshipStage) {
      conversationSection = `
CONVERSATION STARTERS REQUESTED:
- Relationship stage: ${getRelationshipLabel(data.relationshipStage)}
- Preferred topics: ${topics}
Please include 10-15 thoughtful conversation starters tailored to deepen their connection.`;
    }
  }

  const dateTypeLabel = isSoloDate ? "Solo Date (self-care experience for one person)" : data.dateType;
  const planDescription = isSoloDate 
    ? "Create a self-care solo date plan" 
    : "Create a romantic date plan";

  return `${planDescription} with these preferences:

LOCATION: ${data.city}${data.neighborhood ? `, ${data.neighborhood}` : ""}
STARTING POINT (departure address): ${data.startingAddress?.trim() || "Not specified"}
DATE TYPE: ${dateTypeLabel}
OCCASION: ${data.occasion || (isSoloDate ? "Self-care day" : "Just because")}
${dateTimeInfo}

TRANSPORTATION: ${transportMode}
TRAVEL RADIUS: ${travelRadius}

ENERGY: ${data.energyLevel}
ACTIVITIES: ${activities}
TIME: ${data.timeOfDay}
DURATION: ${data.duration}
CUISINE: ${cuisines}
DRINKS: ${data.drinkPreferences || "any"}
BUDGET: ${data.budgetRange}
${dietary}
${allergies}
${hardNos}
${accessibilityNeeds}
${smokingPref}
${smokingActivities}
${additionalNotes}
${identitySection}
${giftSection}
${conversationSection}

CRITICAL REQUIREMENTS:

⚠️ LOCATION RESTRICTION - ABSOLUTELY CRITICAL ⚠️
ALL venues MUST be located in or very near: ${data.city}${data.neighborhood ? `, specifically in/near ${data.neighborhood}` : ""}
- DO NOT suggest venues in other cities or states
- DO NOT suggest venues outside the specified travel radius of ${travelRadius}
- Every single venue must be a REAL, VERIFIED location that exists in ${data.city}
- If the user is in New Jersey, suggest ONLY New Jersey venues (not Texas, not New York unless within radius)
- If the user is in a specific neighborhood, prioritize venues in that exact area first

${isSoloDate ? `1. Generate 3 COMPLETELY DIFFERENT solo date plan options:
   - Option A - Relaxation & Rejuvenation focus
   - Option B - Adventure & Exploration focus  
   - Option C - Creative & Cultural focus
   
IMPORTANT: This is a SOLO DATE for ONE PERSON. All activities should be enjoyable alone - no couple-focused activities. Focus on self-care, personal growth, and individual enjoyment. Use "you" language, not "you two" or "together".` : `1. Generate 3 COMPLETELY DIFFERENT date plan options:
   - Option A - Classic/Traditional approach
   - Option B - Adventurous/Unique experience  
   - Option C - Cozy/Intimate setting`}

2. TRAVEL TIME REQUIREMENTS (VERY IMPORTANT):
   - For each stop after the first, include realistic travel time from the previous stop
   - Use the specified transportation mode (${transportMode}) for travel estimates
   - Keep ALL stops within the specified travel radius (${travelRadius}) from ${data.city}
   - Factor travel time into the overall schedule
   - Format: "travelTimeFromPrevious": "X mins by ${transportMode.toLowerCase()}"
   - Format: "travelDistanceFromPrevious": "X.X miles" or "X blocks"

3. VENUE INFORMATION (VERY IMPORTANT):
   - For each stop, include the estimated cost PER PERSON (e.g., "$25-40" or "Free")
   - Include website URL if the venue has one (real, valid URLs only)
   - Include phone number in format (XXX) XXX-XXXX
   - For restaurants, include booking URL if available on OpenTable or Resy
   - Include FULL ADDRESS with city and state for each venue

4. Each option should have 3-4 stops with ${isSoloDate ? "self-care tips" : "romantic tips"} and travel logistics.
5. Use ONLY real, well-known venues that actually exist in ${data.city} or within the travel radius.
6. Be specific with venue names - use actual restaurant names, park names, etc.
7. Double-check that every venue's address is in ${data.city} or within ${travelRadius} of it.
${scheduledDate ? `8. The date is scheduled for ${scheduledDate}${scheduledTime ? ` starting at ${scheduledTime}` : ""}. Make sure all venues will be OPEN at the specified times and plan the time slots accordingly starting from the scheduled start time.` : ""}`;
};
