import { Sparkles, Heart, MapPin, UtensilsCrossed, Zap } from "lucide-react";

interface MobilePlanDateWelcomeProps {
  onContinue: () => void;
}

const MobilePlanDateWelcome = ({ onContinue }: MobilePlanDateWelcomeProps) => {
  return (
    <div className="min-h-screen flex flex-col bg-background px-6">
      <div className="flex-1 flex flex-col justify-center">
        <div className="text-center mb-10">
          <div className="w-20 h-20 rounded-2xl gradient-gold flex items-center justify-center mx-auto mb-6 shadow-lg">
            <Sparkles className="w-10 h-10 text-primary-foreground" />
          </div>
          <h1 className="text-3xl font-bold mb-4 font-display">
            Your Perfect Date Awaits ✨
          </h1>
          <p className="text-lg text-muted-foreground mb-8 max-w-sm mx-auto">
            We're so excited to help you plan something special. To create a personalized itinerary that feels <em>just right</em>, we need to learn a bit about your preferences.
          </p>
        </div>

        <div className="space-y-4 mb-10">
          <div className="ios-card flex items-start gap-4">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
              <MapPin className="w-5 h-5 text-primary" />
            </div>
            <div>
              <p className="font-semibold mb-1">Where you love to go</p>
              <p className="text-sm text-muted-foreground">Your favorite neighborhoods and travel style</p>
            </div>
          </div>
          <div className="ios-card flex items-start gap-4">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
              <UtensilsCrossed className="w-5 h-5 text-primary" />
            </div>
            <div>
              <p className="font-semibold mb-1">Food & vibe preferences</p>
              <p className="text-sm text-muted-foreground">Cuisines, budget, and the energy you're after</p>
            </div>
          </div>
          <div className="ios-card flex items-start gap-4">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
              <Zap className="w-5 h-5 text-primary" />
            </div>
            <div>
              <p className="font-semibold mb-1">Your personal touch</p>
              <p className="text-sm text-muted-foreground">Deal-breakers, extras, and what makes it magical</p>
            </div>
          </div>
        </div>

        <p className="text-center text-sm text-muted-foreground mb-6">
          It only takes a few minutes — and we'll remember your answers for next time.
        </p>
      </div>

      <div className="pb-12">
        <button
          onClick={onContinue}
          className="ios-button ios-button-primary w-full flex items-center justify-center gap-2"
        >
          <Heart className="w-5 h-5" />
          Let's Get Started
        </button>
      </div>
    </div>
  );
};

export default MobilePlanDateWelcome;
