import { MapPin, Clock, Utensils, Sparkles, Shield, MessageSquare, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

const features = [
  {
    icon: MapPin,
    title: "Location-Aware",
    description: "Plans anchored to your exact starting point with accurate walk times and transport options."
  },
  {
    icon: Utensils,
    title: "Allergy-Safe",
    description: "Your dietary restrictions and allergies are absolute. We never suggest risky venues."
  },
  {
    icon: Clock,
    title: "Timed Perfectly",
    description: "Concrete timelines with arrival windows, duration per stop, and natural transitions."
  },
  {
    icon: Sparkles,
    title: "AI-Curated",
    description: "Real venues, verified details. No hallucinations, no guesswork — just precision."
  },
  {
    icon: Shield,
    title: "Hard No's Respected",
    description: "Tell us what you hate. We eliminate tourist traps, long waits, and deal-breakers."
  },
  {
    icon: MessageSquare,
    title: "Conversation Ready",
    description: "Non-cringe conversation starters tailored to your venue's vibe and noise level."
  }
];

const Features = () => {
  return (
    <section id="features" className="py-16 sm:py-24 bg-secondary/30">
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-12 sm:mb-16">
          <h2 className="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl mb-4 text-foreground">
            Designed for <span className="text-primary">Confidence</span>
          </h2>
          <p className="text-muted-foreground text-base sm:text-lg">
            Every detail considered. Every concern addressed. You just show up.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 max-w-6xl mx-auto">
          {features.map((feature, index) => (
            <div
              key={feature.title}
              className="group p-5 sm:p-6 rounded-lg bg-card border border-border hover:border-primary/30 transition-all duration-300"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-3 sm:mb-4 group-hover:bg-primary/20 transition-colors">
                <feature.icon className="w-5 h-5 sm:w-6 sm:h-6 text-primary" />
              </div>
              <h3 className="font-display text-lg sm:text-xl mb-2 text-foreground">{feature.title}</h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        {/* CTA after features */}
        <div className="text-center mt-12 sm:mt-16">
          <p className="text-muted-foreground mb-4 text-sm sm:text-base">Ready to experience stress-free dating?</p>
          <Button 
            asChild 
            size="lg" 
            className="gradient-gold text-primary-foreground font-semibold px-8 py-6 text-base sm:text-lg glow-gold hover:opacity-90 transition-all hover:scale-105 group"
          >
            <Link to="/signup">
              Get Your First Plan Free
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Link>
          </Button>
        </div>
      </div>
    </section>
  );
};

export default Features;
