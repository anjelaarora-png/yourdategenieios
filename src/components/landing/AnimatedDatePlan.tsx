import { useState, useEffect } from "react";
import { 
  Sparkles, MapPin, Wine, Utensils, Music, Clock, Check, 
  MessageCircle, Shirt, Gift, Sun, Star, AlertCircle, Accessibility,
  Leaf, ChefHat
} from "lucide-react";

interface Stop {
  icon: typeof Wine;
  name: string;
  time: string;
  address: string;
  detail?: string;
  detailIcon?: typeof Leaf;
}

interface DatePlanExample {
  title: string;
  tagline: string;
  stops: Stop[];
  duration: string;
  budget: string;
  weatherNote: string;
  conversationStarter: string;
  packingItem: string;
  giftIdea: string;
  specialDetail: string;
  specialIcon: typeof Leaf;
}

const datePlanExamples: DatePlanExample[] = [
  {
    title: "Sunset & Sips",
    tagline: "A golden hour adventure through Brooklyn",
    stops: [
      { icon: Wine, name: "Rooftop Wine Bar", time: "6:00 PM", address: "The High Line Hotel", detail: "Gluten-free menu available", detailIcon: Leaf },
      { icon: Utensils, name: "Farm-to-Table Dinner", time: "7:30 PM", address: "Blue Hill NYC", detail: "Confirmed nut-free options", detailIcon: ChefHat },
      { icon: Music, name: "Live Jazz Lounge", time: "9:30 PM", address: "Village Vanguard", detail: "Intimate seating reserved", detailIcon: Star },
    ],
    duration: "4 hours",
    budget: "$$$",
    weatherNote: "Clear skies, 72°F — perfect for rooftop dining",
    conversationStarter: "If we could live anywhere for a year, where would you pick?",
    packingItem: "Light jacket for evening breeze",
    giftIdea: "Personalized wine glasses",
    specialDetail: "Allergy-safe venues confirmed",
    specialIcon: AlertCircle,
  },
  {
    title: "Art & Appetite",
    tagline: "Culture meets cuisine in Chelsea",
    stops: [
      { icon: MapPin, name: "Gallery District Walk", time: "3:00 PM", address: "Chelsea Galleries", detail: "Wheelchair accessible route", detailIcon: Accessibility },
      { icon: Utensils, name: "Hidden Gem Café", time: "5:00 PM", address: "Café Cluny", detail: "Vegan tasting menu", detailIcon: Leaf },
      { icon: Wine, name: "Speakeasy Cocktails", time: "7:00 PM", address: "Please Don't Tell", detail: "Reservation secured", detailIcon: Check },
    ],
    duration: "5 hours",
    budget: "$$",
    weatherNote: "Partly cloudy, 68°F — galleries are climate controlled",
    conversationStarter: "Which piece of art would you steal if you could?",
    packingItem: "Comfortable walking shoes",
    giftIdea: "Art book from favorite gallery",
    specialDetail: "Full accessibility verified",
    specialIcon: Accessibility,
  },
  {
    title: "Moonlit Romance",
    tagline: "An evening for whispered conversations",
    stops: [
      { icon: Utensils, name: "Candlelit Italian", time: "7:00 PM", address: "L'Artusi", detail: "Quiet corner table reserved", detailIcon: Star },
      { icon: MapPin, name: "Waterfront Stroll", time: "9:00 PM", address: "Hudson River Park", detail: "Well-lit walking path", detailIcon: Sun },
      { icon: Wine, name: "Dessert & Champagne", time: "10:00 PM", address: "Ladurée SoHo", detail: "Dairy-free desserts available", detailIcon: Leaf },
    ],
    duration: "4 hours",
    budget: "$$$",
    weatherNote: "Clear night, 65°F — ideal for stargazing walk",
    conversationStarter: "What's a dream you've never told anyone?",
    packingItem: "Cozy scarf for the evening walk",
    giftIdea: "Macarons box to take home",
    specialDetail: "Quiet, intimate venues only",
    specialIcon: MessageCircle,
  },
];

const AnimatedDatePlan = () => {
  const [phase, setPhase] = useState<"idle" | "generating" | "typing" | "details" | "complete">("idle");
  const [currentPlanIndex, setCurrentPlanIndex] = useState(0);
  const [typedTitle, setTypedTitle] = useState("");
  const [showTagline, setShowTagline] = useState(false);
  const [visibleStops, setVisibleStops] = useState<number[]>([]);
  const [showDetails, setShowDetails] = useState<string[]>([]);
  const [showDuration, setShowDuration] = useState(false);

  const currentPlan = datePlanExamples[currentPlanIndex];

  // Auto-start animation loop
  useEffect(() => {
    const startAnimation = () => {
      setPhase("generating");
      setTypedTitle("");
      setShowTagline(false);
      setVisibleStops([]);
      setShowDetails([]);
      setShowDuration(false);
    };

    const initialTimer = setTimeout(startAnimation, 1000);
    return () => clearTimeout(initialTimer);
  }, [currentPlanIndex]);

  // Handle generating phase
  useEffect(() => {
    if (phase === "generating") {
      const timer = setTimeout(() => setPhase("typing"), 1500);
      return () => clearTimeout(timer);
    }
  }, [phase]);

  // Handle typing animation
  useEffect(() => {
    if (phase === "typing" && typedTitle.length < currentPlan.title.length) {
      const timer = setTimeout(() => {
        setTypedTitle(currentPlan.title.slice(0, typedTitle.length + 1));
      }, 70);
      return () => clearTimeout(timer);
    } else if (phase === "typing" && typedTitle.length === currentPlan.title.length) {
      const timer = setTimeout(() => {
        setShowTagline(true);
        setTimeout(() => revealStops(), 400);
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [phase, typedTitle, currentPlan.title]);

  const revealStops = () => {
    currentPlan.stops.forEach((_, index) => {
      setTimeout(() => {
        setVisibleStops(prev => [...prev, index]);
        if (index === currentPlan.stops.length - 1) {
          setTimeout(() => {
            setPhase("details");
            revealDetails();
          }, 500);
        }
      }, index * 600);
    });
  };

  const revealDetails = () => {
    const detailKeys = ["duration", "weather", "conversation", "packing", "gift"];
    detailKeys.forEach((key, index) => {
      setTimeout(() => {
        setShowDetails(prev => [...prev, key]);
        if (index === detailKeys.length - 1) {
          setTimeout(() => {
            setPhase("complete");
            // Move to next plan
            setTimeout(() => {
              setPhase("idle");
              setTimeout(() => {
                setCurrentPlanIndex((prev) => (prev + 1) % datePlanExamples.length);
              }, 500);
            }, 5000);
          }, 800);
        }
      }, index * 400);
    });
  };

  return (
    <div className="relative w-full max-w-md mx-auto">
      {/* Glow effect */}
      <div className={`absolute inset-0 bg-primary/20 rounded-2xl blur-xl transition-opacity duration-1000 ${phase !== "idle" ? "opacity-100" : "opacity-0"}`} />
      
      {/* Main card */}
      <div className="relative bg-card border border-border rounded-2xl overflow-hidden shadow-2xl">
        {/* Header */}
        <div className="bg-gradient-to-r from-primary/10 to-primary/5 p-4 border-b border-border">
          <div className="flex items-center gap-2">
            <div className={`transition-all duration-500 ${phase === "generating" ? "animate-pulse" : ""}`}>
              <Sparkles className={`w-5 h-5 text-primary ${phase === "generating" ? "animate-spin" : ""}`} />
            </div>
            <span className="text-sm font-medium text-primary">
              {phase === "idle" && "Ready to plan..."}
              {phase === "generating" && "Crafting your perfect date..."}
              {(phase === "typing" || phase === "details" || phase === "complete") && "Your Date Plan"}
            </span>
            {phase === "complete" && (
              <Check className="w-4 h-4 text-green-500 ml-auto animate-scale-in" />
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-5 min-h-[420px]">
          {phase === "idle" && (
            <div className="flex items-center justify-center h-full">
              <div className="text-center text-muted-foreground">
                <MapPin className="w-12 h-12 mx-auto mb-3 opacity-30" />
                <p>Waiting for magic...</p>
              </div>
            </div>
          )}

          {phase === "generating" && (
            <div className="flex flex-col items-center justify-center h-full gap-4">
              <div className="flex gap-2">
                {[0, 1, 2].map((i) => (
                  <div
                    key={i}
                    className="w-3 h-3 rounded-full bg-primary animate-bounce"
                    style={{ animationDelay: `${i * 0.15}s` }}
                  />
                ))}
              </div>
              <p className="text-muted-foreground text-sm">Checking allergies & preferences...</p>
            </div>
          )}

          {(phase === "typing" || phase === "details" || phase === "complete") && (
            <div className="space-y-4">
              {/* Title */}
              <div>
                <h3 className="font-display text-2xl text-foreground">
                  {typedTitle}
                  {phase === "typing" && typedTitle.length < currentPlan.title.length && (
                    <span className="inline-block w-0.5 h-6 bg-primary ml-1 animate-pulse" />
                  )}
                </h3>
                <p className={`text-primary text-sm mt-1 transition-all duration-500 ${showTagline ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-2"}`}>
                  {currentPlan.tagline}
                </p>
              </div>

              {/* Stops */}
              <div className="space-y-3">
                {currentPlan.stops.map((stop, index) => (
                  <div
                    key={stop.name}
                    className={`transition-all duration-500 ${
                      visibleStops.includes(index) ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-4"
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <div className="relative flex-shrink-0">
                        <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center">
                          <stop.icon className="w-4 h-4 text-primary" />
                        </div>
                        {index < currentPlan.stops.length - 1 && (
                          <div className={`absolute top-9 left-1/2 -translate-x-1/2 w-0.5 h-6 transition-all duration-300 ${
                            visibleStops.includes(index + 1) ? "bg-primary/30" : "bg-border"
                          }`} />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-foreground font-medium text-sm">{stop.name}</p>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                          <Clock className="w-3 h-3 flex-shrink-0" />
                          <span>{stop.time}</span>
                          <span className="text-border">•</span>
                          <span className="truncate">{stop.address}</span>
                        </div>
                        {/* Venue-specific detail */}
                        {stop.detail && visibleStops.includes(index) && (
                          <div className="flex items-center gap-1.5 mt-1 text-xs text-primary/80">
                            {stop.detailIcon && <stop.detailIcon className="w-3 h-3" />}
                            <span>{stop.detail}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Duration & Budget */}
              <div className={`flex items-center gap-3 pt-3 border-t border-border text-sm transition-all duration-500 ${
                showDetails.includes("duration") ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
              }`}>
                <div className="flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-primary" />
                  <span className="text-foreground font-medium">{currentPlan.duration}</span>
                </div>
                <span className="text-border">•</span>
                <span className="text-foreground font-medium">{currentPlan.budget}</span>
                <div className="ml-auto flex items-center gap-1 text-xs text-primary/80">
                  <currentPlan.specialIcon className="w-3 h-3" />
                  <span>{currentPlan.specialDetail}</span>
                </div>
              </div>

              {/* Weather Note */}
              <div className={`flex items-start gap-2 p-2.5 rounded-lg bg-secondary/50 text-xs transition-all duration-500 ${
                showDetails.includes("weather") ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
              }`}>
                <Sun className="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
                <span className="text-muted-foreground">{currentPlan.weatherNote}</span>
              </div>

              {/* Extra Details Grid */}
              <div className="grid grid-cols-1 gap-2">
                {/* Conversation Starter */}
                <div className={`flex items-start gap-2 p-2.5 rounded-lg bg-primary/5 border border-primary/10 text-xs transition-all duration-500 ${
                  showDetails.includes("conversation") ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
                }`}>
                  <MessageCircle className="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
                  <div>
                    <span className="text-primary font-medium">Conversation Starter</span>
                    <p className="text-muted-foreground mt-0.5 italic">"{currentPlan.conversationStarter}"</p>
                  </div>
                </div>

                {/* Packing & Gift */}
                <div className="grid grid-cols-2 gap-2">
                  <div className={`flex items-center gap-2 p-2 rounded-lg bg-secondary/30 text-xs transition-all duration-500 ${
                    showDetails.includes("packing") ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-4"
                  }`}>
                    <Shirt className="w-3.5 h-3.5 text-primary flex-shrink-0" />
                    <span className="text-muted-foreground truncate">{currentPlan.packingItem}</span>
                  </div>
                  <div className={`flex items-center gap-2 p-2 rounded-lg bg-secondary/30 text-xs transition-all duration-500 ${
                    showDetails.includes("gift") ? "opacity-100 translate-x-0" : "opacity-0 translate-x-4"
                  }`}>
                    <Gift className="w-3.5 h-3.5 text-primary flex-shrink-0" />
                    <span className="text-muted-foreground truncate">{currentPlan.giftIdea}</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Plan indicator dots */}
        <div className="flex justify-center gap-2 pb-4">
          {datePlanExamples.map((_, index) => (
            <div
              key={index}
              className={`w-2 h-2 rounded-full transition-all duration-300 ${
                index === currentPlanIndex ? "bg-primary w-6" : "bg-border"
              }`}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default AnimatedDatePlan;
