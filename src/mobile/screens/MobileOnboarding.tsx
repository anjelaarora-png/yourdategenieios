import { useState, useEffect } from "react";
import { Sparkles, MapPin, Check, ArrowRight, Star, Wine, Coffee, Utensils } from "lucide-react";
import logo from "@/assets/logo.png";

interface MobileOnboardingProps {
  onComplete: () => void;
}

// High-quality Unsplash images
const IMAGES = {
  heroCouple: "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=800&h=600&fit=crop",
  stressedCouple: "https://images.unsplash.com/photo-1516589091380-5d8e87df6999?w=600&h=400&fit=crop",
  happyDate: "https://images.unsplash.com/photo-1559620192-032c4bc4674e?w=600&h=400&fit=crop",
  wineBar: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400&h=300&fit=crop",
  italianDinner: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop",
  rooftopView: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=400&h=300&fit=crop",
  user1: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&crop=faces",
  user2: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&crop=faces",
  user3: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=faces",
  user4: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop&crop=faces",
};

const MobileOnboarding = ({ onComplete }: MobileOnboardingProps) => {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [showContent, setShowContent] = useState(false);

  useEffect(() => {
    setShowContent(false);
    const timer = setTimeout(() => setShowContent(true), 100);
    return () => clearTimeout(timer);
  }, [currentSlide]);

  const totalSlides = 4;

  const handleNext = () => {
    if (currentSlide < totalSlides - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      onComplete();
    }
  };

  return (
    <div className="h-screen flex flex-col bg-background overflow-hidden">
      {/* Progress dots */}
      <div className="pt-12 px-6 flex justify-center gap-2 shrink-0">
        {Array.from({ length: totalSlides }).map((_, i) => (
          <div
            key={i}
            className={`h-1.5 rounded-full transition-all duration-500 ${
              i === currentSlide ? "w-5 gradient-gold" : "w-1.5 bg-muted"
            }`}
          />
        ))}
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
        {currentSlide === 0 && <SlideWelcome show={showContent} />}
        {currentSlide === 1 && <SlideChaos show={showContent} />}
        {currentSlide === 2 && <SlideItinerary show={showContent} />}
        {currentSlide === 3 && <SlideGetStarted show={showContent} />}
      </div>

      {/* Bottom actions - compact */}
      <div className="pb-8 px-5 pt-2 shrink-0">
        <button
          onClick={handleNext}
          className="w-full py-3.5 rounded-xl font-medium text-sm flex items-center justify-center gap-2 gradient-gold text-primary-foreground transition-all active:scale-[0.98]"
        >
          {currentSlide === totalSlides - 1 ? (
            "Get Started Free"
          ) : (
            <>
              Next
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
        {currentSlide < totalSlides - 1 && (
          <button 
            onClick={onComplete} 
            className="w-full text-center text-muted-foreground/60 text-xs py-2"
          >
            Skip
          </button>
        )}
      </div>
    </div>
  );
};

// ============ SLIDE 1: WELCOME ============
const SlideWelcome = ({ show }: { show: boolean }) => (
  <div className="flex-1 flex flex-col min-h-0">
    {/* Hero image - constrained height */}
    <div className={`relative h-[42%] shrink-0 overflow-hidden transition-all duration-700 ${show ? "opacity-100" : "opacity-0"}`}>
      <img 
        src={IMAGES.heroCouple} 
        alt="Couple on a date"
        className="w-full h-full object-cover"
      />
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-background" />
    </div>

    {/* Content */}
    <div className="px-6 -mt-8 relative z-10 flex-1 flex flex-col justify-center">
      <div className={`transition-all duration-700 delay-200 ${show ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
        <div className="flex items-center gap-2 mb-2">
          <img src={logo} alt="" className="h-7 w-auto" />
          <span className="text-[10px] text-primary font-medium uppercase tracking-wider">Your Date Genie</span>
        </div>
        
        <h1 className="font-display text-3xl text-foreground leading-tight mb-2">
          Date nights,<br />
          <span className="text-gradient-gold">planned for you.</span>
        </h1>
        
        <p className="text-muted-foreground text-sm leading-relaxed">
          Tell us what you love. We'll create a complete evening — venues, timing, and all the details.
        </p>
      </div>
    </div>
  </div>
);

// ============ SLIDE 2: THE CHAOS OF PLANNING ============
const SlideChaos = ({ show }: { show: boolean }) => (
  <div className="flex-1 flex flex-col px-5 pt-2 min-h-0">
    {/* Header - compact */}
    <div className={`mb-2 transition-all duration-500 ${show ? "opacity-100" : "opacity-0"}`}>
      <p className="text-muted-foreground text-xs mb-0.5">Sound familiar?</p>
      <h2 className="font-display text-xl text-foreground leading-tight">
        Friday night. No plan.
      </h2>
    </div>

    {/* Phone mockup - scaled down */}
    <div className={`flex-1 flex items-center justify-center min-h-0 transition-all duration-700 delay-100 ${show ? "opacity-100" : "opacity-0"}`}>
      <div className="relative scale-[0.85] origin-center">
        {/* Phone frame */}
        <div className="relative w-[240px] bg-black rounded-[36px] p-1.5 shadow-2xl">
          {/* Phone screen */}
          <div className="bg-[#1c1c1e] rounded-[30px] overflow-hidden">
            {/* Status bar */}
            <div className="flex items-center justify-between px-5 py-1.5 text-white text-[10px]">
              <span>9:41</span>
              <div className="w-16 h-5 bg-black rounded-full" />
              <div className="flex items-center gap-1">
                <SignalIcon />
                <WifiIcon />
                <BatteryIcon />
              </div>
            </div>

            {/* Browser with tabs */}
            <div className="bg-[#2c2c2e] mx-1.5 rounded-t-lg">
              <div className="flex items-center gap-1 px-1.5 py-1 overflow-hidden">
                <div className="flex items-center gap-1 bg-[#3a3a3c] rounded px-1.5 py-0.5 text-[8px] text-white/80 shrink-0">
                  <YelpIcon />
                  <span>Yelp</span>
                </div>
                <div className="flex items-center gap-1 bg-[#3a3a3c] rounded px-1.5 py-0.5 text-[8px] text-white/60 shrink-0">
                  <GoogleIcon />
                  <span>Google</span>
                </div>
                <div className="flex items-center gap-1 bg-[#3a3a3c] rounded px-1.5 py-0.5 text-[8px] text-white/60 shrink-0">
                  <span>+8</span>
                </div>
              </div>
              <div className="px-1.5 pb-1.5">
                <div className="bg-[#1c1c1e] rounded px-2 py-1.5 text-[9px] text-white/40">
                  romantic restaurants near me...
                </div>
              </div>
            </div>

            {/* Search results - compact */}
            <div className="px-1.5 pb-1 space-y-1">
              <div className="bg-white rounded-lg p-1.5">
                <div className="flex gap-1.5">
                  <div className="w-9 h-9 bg-gray-200 rounded shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-[9px] font-medium text-gray-900 truncate">Italian Place Downtown</p>
                    <div className="flex items-center gap-0.5">
                      <div className="flex">{[1,2,3,4].map(i => <span key={i} className="text-[7px] text-red-500">★</span>)}<span className="text-[7px] text-gray-300">★</span></div>
                      <span className="text-[7px] text-gray-500">(234)</span>
                    </div>
                    <p className="text-[7px] text-gray-400">$$$ · 2.3 mi</p>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg p-1.5">
                <div className="flex gap-1.5">
                  <div className="w-9 h-9 bg-gray-200 rounded shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-[9px] font-medium text-gray-900 truncate">Wine Bar & Bistro</p>
                    <div className="flex items-center gap-0.5">
                      <div className="flex">{[1,2,3,4,5].map(i => <span key={i} className="text-[7px] text-red-500">★</span>)}</div>
                      <span className="text-[7px] text-gray-500">(89)</span>
                    </div>
                    <p className="text-[7px] text-gray-400">$$$$ · 4.1 mi</p>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg p-1.5 opacity-50">
                <div className="flex gap-1.5">
                  <div className="w-9 h-9 bg-gray-200 rounded shrink-0" />
                  <div className="flex-1">
                    <p className="text-[9px] font-medium text-gray-900">The Rooftop...</p>
                    <p className="text-[7px] text-gray-400">Loading...</p>
                  </div>
                </div>
              </div>
            </div>

            {/* App dock - compact */}
            <div className="px-3 py-2 bg-[#1c1c1e]">
              <div className="flex justify-around">
                <AppIconMini icon={<OpenTableIcon />} label="OpenTable" />
                <AppIconMini icon={<MapsIcon />} label="Maps" />
                <AppIconMini icon={<ResyIcon />} label="Resy" />
                <AppIconMini icon={<TripAdvisorIcon />} label="TripAdv" />
              </div>
            </div>

            <div className="flex justify-center py-1.5">
              <div className="w-24 h-1 bg-white/30 rounded-full" />
            </div>
          </div>
        </div>

        {/* Notification badge */}
        <div className={`absolute -top-1 -right-1 transition-all duration-500 delay-300 ${show ? "opacity-100 scale-100" : "opacity-0 scale-50"}`}>
          <div className="bg-red-500 text-white text-[8px] font-bold w-4 h-4 rounded-full flex items-center justify-center shadow-lg">
            12
          </div>
        </div>

        {/* Time indicator */}
        <div className={`absolute -bottom-2 left-1/2 -translate-x-1/2 transition-all duration-500 delay-500 ${show ? "opacity-100" : "opacity-0"}`}>
          <div className="bg-card border border-border rounded-full px-2 py-1 shadow-lg flex items-center gap-1.5">
            <div className="w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse" />
            <span className="text-[10px] text-foreground font-medium">45 min searching...</span>
          </div>
        </div>
      </div>
    </div>

    {/* Pain points - compact */}
    <div className={`py-2 transition-all duration-500 delay-600 ${show ? "opacity-100" : "opacity-0"}`}>
      <p className="text-center text-muted-foreground text-xs leading-relaxed">
        Too many apps. Too many reviews.<br />
        After work, who has time for this?
      </p>
    </div>
  </div>
);

// Mini app icon for dock
const AppIconMini = ({ icon, label }: { icon: React.ReactNode; label: string }) => (
  <div className="flex flex-col items-center gap-0.5">
    <div className="w-8 h-8 rounded-lg flex items-center justify-center overflow-hidden">
      {icon}
    </div>
    <span className="text-[7px] text-white/60">{label}</span>
  </div>
);

// Realistic app icons
const YelpIcon = () => (
  <svg className="w-4 h-4" viewBox="0 0 24 24">
    <rect width="24" height="24" rx="6" fill="#d32323"/>
    <path d="M12 6c-1.5 0-2.5 1-2.5 2.5v4c0 .5.5 1 1 1h3c.5 0 1-.5 1-1v-4C14.5 7 13.5 6 12 6z" fill="white"/>
  </svg>
);

const GoogleIcon = () => (
  <svg className="w-4 h-4" viewBox="0 0 24 24">
    <rect width="24" height="24" rx="6" fill="white"/>
    <circle cx="12" cy="12" r="5" fill="none" stroke="#4285f4" strokeWidth="2"/>
    <path d="M16 12h-4v-4" fill="none" stroke="#ea4335" strokeWidth="2"/>
  </svg>
);

const OpenTableIcon = () => (
  <div className="w-full h-full bg-[#da3743] rounded-xl flex items-center justify-center">
    <svg className="w-6 h-6" viewBox="0 0 24 24" fill="white">
      <circle cx="12" cy="12" r="8" fill="none" stroke="white" strokeWidth="2"/>
      <circle cx="12" cy="12" r="3" fill="white"/>
    </svg>
  </div>
);

const MapsIcon = () => (
  <div className="w-full h-full rounded-xl overflow-hidden">
    <svg className="w-full h-full" viewBox="0 0 24 24">
      <rect width="24" height="24" fill="#4caf50"/>
      <path d="M6 4l6 3 6-3v16l-6-3-6 3V4z" fill="#81c784"/>
      <circle cx="12" cy="10" r="3" fill="#f44336"/>
    </svg>
  </div>
);

const ResyIcon = () => (
  <div className="w-full h-full bg-[#1a1a1a] rounded-xl flex items-center justify-center">
    <span className="text-[#c7a547] font-bold text-sm">R</span>
  </div>
);

const TripAdvisorIcon = () => (
  <div className="w-full h-full bg-white rounded-xl flex items-center justify-center">
    <svg className="w-6 h-6" viewBox="0 0 24 24">
      <circle cx="8" cy="12" r="4" fill="none" stroke="#00af87" strokeWidth="1.5"/>
      <circle cx="16" cy="12" r="4" fill="none" stroke="#00af87" strokeWidth="1.5"/>
      <circle cx="8" cy="12" r="1.5" fill="#00af87"/>
      <circle cx="16" cy="12" r="1.5" fill="#00af87"/>
    </svg>
  </div>
);

// Phone status bar icons
const SignalIcon = () => (
  <svg className="w-4 h-3" viewBox="0 0 16 12" fill="white">
    <rect x="0" y="8" width="3" height="4" rx="0.5"/>
    <rect x="4" y="5" width="3" height="7" rx="0.5"/>
    <rect x="8" y="2" width="3" height="10" rx="0.5"/>
    <rect x="12" y="0" width="3" height="12" rx="0.5"/>
  </svg>
);

const WifiIcon = () => (
  <svg className="w-4 h-3" viewBox="0 0 16 12" fill="white">
    <path d="M8 10a1.5 1.5 0 100 3 1.5 1.5 0 000-3zM4 7.5a5.5 5.5 0 018 0M1 4.5a9.5 9.5 0 0114 0" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
  </svg>
);

const BatteryIcon = () => (
  <svg className="w-6 h-3" viewBox="0 0 24 12" fill="white">
    <rect x="0" y="1" width="20" height="10" rx="2" fill="none" stroke="white" strokeWidth="1"/>
    <rect x="2" y="3" width="14" height="6" rx="1" fill="white"/>
    <rect x="21" y="4" width="2" height="4" rx="0.5" fill="white"/>
  </svg>
);

// ============ SLIDE 3: THE ITINERARY PREVIEW ============
const SlideItinerary = ({ show }: { show: boolean }) => (
  <div className="flex-1 flex flex-col px-5 pt-2 min-h-0">
    {/* Header - compact */}
    <div className={`mb-2 transition-all duration-500 ${show ? "opacity-100" : "opacity-0"}`}>
      <p className="text-muted-foreground text-xs mb-0.5">What you get</p>
      <h2 className="font-display text-xl text-foreground leading-tight">
        A complete date plan
      </h2>
    </div>

    {/* Itinerary card - compact */}
    <div className={`flex-1 min-h-0 transition-all duration-700 delay-100 ${show ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
      <div className="bg-card rounded-xl border border-border overflow-hidden h-full flex flex-col">
        {/* Header banner - smaller */}
        <div className="relative h-16 shrink-0 overflow-hidden">
          <img src={IMAGES.happyDate} alt="" className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-r from-primary/80 to-primary/40" />
          <div className="absolute inset-0 flex items-center px-4">
            <div>
              <p className="text-white font-display text-base">Romantic Italian Night</p>
              <p className="text-white/70 text-[10px]">Saturday · 3 stops · ~$150</p>
            </div>
          </div>
        </div>

        {/* Timeline - compact */}
        <div className="p-3 flex-1 min-h-0">
          <div className="space-y-2">
            <ItineraryStopCompact 
              time="7:00 PM"
              name="The Cellar Wine Bar"
              tip="Start with Italian reds"
              image={IMAGES.wineBar}
              icon={Wine}
              delay={200}
              show={show}
            />
            <ItineraryStopCompact 
              time="8:30 PM"
              name="Trattoria Milano"
              tip="Try the truffle pasta"
              image={IMAGES.italianDinner}
              icon={Utensils}
              delay={350}
              show={show}
            />
            <ItineraryStopCompact 
              time="10:30 PM"
              name="Skyview Rooftop"
              tip="Nightcap under the stars"
              image={IMAGES.rooftopView}
              icon={Coffee}
              delay={500}
              show={show}
              isLast
            />
          </div>
        </div>

        {/* Included badges - compact */}
        <div className={`px-3 pb-3 transition-all duration-500 delay-600 ${show ? "opacity-100" : "opacity-0"}`}>
          <div className="flex flex-wrap gap-1.5">
            <IncludedBadge text="Directions" />
            <IncludedBadge text="Tips" />
            <IncludedBadge text="Conversation starters" />
            <IncludedBadge text="Gift ideas" />
          </div>
        </div>
      </div>
    </div>
  </div>
);

const ItineraryStopCompact = ({ 
  time, name, tip, image, icon: Icon, delay, show, isLast 
}: { 
  time: string; name: string; tip: string; image: string; icon: any; delay: number; show: boolean; isLast?: boolean 
}) => (
  <div 
    className={`flex gap-2 transition-all duration-500 ${show ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-4"}`}
    style={{ transitionDelay: `${delay}ms` }}
  >
    {/* Timeline */}
    <div className="flex flex-col items-center w-6 shrink-0">
      <div className="w-6 h-6 rounded-full gradient-gold flex items-center justify-center">
        <Icon className="w-3 h-3 text-primary-foreground" />
      </div>
      {!isLast && <div className="w-0.5 flex-1 bg-border mt-1" />}
    </div>
    
    {/* Content */}
    <div className="flex-1 flex gap-2 pb-1">
      <img src={image} alt="" className="w-14 h-14 rounded-lg object-cover shrink-0" />
      <div className="flex-1 min-w-0">
        <p className="text-[10px] text-muted-foreground">{time}</p>
        <p className="font-medium text-foreground text-sm truncate">{name}</p>
        <p className="text-[10px] text-primary italic truncate">{tip}</p>
      </div>
    </div>
  </div>
);

const IncludedBadge = ({ text }: { text: string }) => (
  <span className="text-[10px] bg-muted text-muted-foreground px-2 py-0.5 rounded-full">
    {text}
  </span>
);

// ============ SLIDE 4: GET STARTED ============
const SlideGetStarted = ({ show }: { show: boolean }) => (
  <div className="flex-1 flex flex-col px-5 pt-2 min-h-0">
    {/* Image - compact */}
    <div className={`relative rounded-xl overflow-hidden mb-4 shrink-0 transition-all duration-700 ${show ? "opacity-100 scale-100" : "opacity-0 scale-95"}`}>
      <img 
        src={IMAGES.happyDate}
        alt="Couple enjoying date"
        className="w-full h-36 object-cover"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-background via-background/20 to-transparent" />
      <div className="absolute bottom-3 left-3 right-3">
        <div className="flex items-center gap-1">
          {[1,2,3,4,5].map(i => (
            <Star key={i} className="w-3 h-3 text-primary fill-primary" />
          ))}
          <span className="text-white text-xs ml-1">"Stress-free date nights"</span>
        </div>
      </div>
    </div>

    {/* Content - compact */}
    <div className={`text-center mb-4 transition-all duration-500 delay-200 ${show ? "opacity-100" : "opacity-0"}`}>
      <h1 className="font-display text-2xl text-foreground mb-1">
        Ready for better dates?
      </h1>
      <p className="text-muted-foreground text-sm">
        Answer a few questions. Get a plan in seconds.
      </p>
    </div>

    {/* Benefits - compact */}
    <div className={`space-y-2 transition-all duration-500 delay-300 ${show ? "opacity-100" : "opacity-0"}`}>
      {[
        "Takes less than 2 minutes",
        "Tailored to your vibe & budget",
        "Real venues, verified details",
      ].map((text, i) => (
        <div key={i} className="flex items-center gap-2">
          <Check className="w-4 h-4 text-green-500 shrink-0" />
          <span className="text-foreground text-sm">{text}</span>
        </div>
      ))}
    </div>

    {/* Social proof - compact */}
    <div className={`mt-auto py-3 transition-all duration-500 delay-500 ${show ? "opacity-100" : "opacity-0"}`}>
      <div className="flex items-center justify-center gap-2">
        <div className="flex -space-x-1.5">
          {[IMAGES.user1, IMAGES.user2, IMAGES.user3, IMAGES.user4].map((img, i) => (
            <img key={i} src={img} alt="" className="w-6 h-6 rounded-full border-2 border-background object-cover" />
          ))}
        </div>
        <p className="text-xs text-muted-foreground">
          <span className="text-foreground font-medium">500+</span> couples joined
        </p>
      </div>
      <p className="text-center text-[10px] text-muted-foreground/60 mt-2">
        Free to start · No credit card
      </p>
    </div>
  </div>
);

export default MobileOnboarding;
