import { Button } from "@/components/ui/button";
import { Check, Sparkles, Zap, Gift, ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";

const tiers = [
  {
    name: "Starter",
    price: "Free",
    priceNote: "to try",
    icon: Gift,
    description: "Perfect for your first date plan",
    features: [
      "1 complete date plan",
      "3 venue recommendations",
      "Timed itinerary",
      "Conversation starters",
      "Basic transport tips"
    ],
    popular: false,
    cta: "Start Free",
    highlight: false
  },
  {
    name: "Date Pro",
    price: 19,
    priceNote: "/ plan",
    icon: Sparkles,
    description: "Everything you need for the perfect date",
    features: [
      "3 unique plan options",
      "Verified venues with details",
      "Gift suggestions",
      "Dietary accommodations",
      "Weather-aware planning",
      "Export & share options"
    ],
    popular: true,
    cta: "Get Started",
    highlight: true
  },
  {
    name: "VIP Date",
    price: 39,
    priceNote: "/ plan",
    icon: Zap,
    description: "Premium experience for special occasions",
    features: [
      "Everything in Date Pro",
      "Hidden gem venues",
      "Backup options included",
      "Priority support",
      "Real-time venue updates",
      "Concierge assistance"
    ],
    popular: false,
    cta: "Go Premium",
    highlight: false
  }
];

const Pricing = () => {
  return (
    <section id="pricing" className="py-16 sm:py-24 bg-secondary/30">
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-16">
          <h2 className="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl mb-4 text-foreground">
            Start <span className="text-primary">Free</span>, Upgrade Anytime
          </h2>
          <p className="text-muted-foreground text-base sm:text-lg">
            No subscriptions. Pay only when you need more. First plan is on us.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6 max-w-5xl mx-auto">
          {tiers.map((tier) => (
            <div
              key={tier.name}
              className={`relative p-5 sm:p-6 rounded-xl bg-card border transition-all duration-300 ${
                tier.popular 
                  ? "border-primary glow-gold scale-[1.02] md:scale-105" 
                  : "border-border hover:border-primary/30"
              }`}
            >
              {tier.popular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1.5 gradient-gold rounded-full text-xs font-bold text-primary-foreground whitespace-nowrap">
                  ⭐ Best Value
                </div>
              )}

              <div className="flex items-center gap-3 mb-4">
                <div className={`w-10 h-10 sm:w-12 sm:h-12 rounded-lg flex items-center justify-center ${
                  tier.popular ? "gradient-gold" : "bg-primary/10"
                }`}>
                  <tier.icon className={`w-5 h-5 sm:w-6 sm:h-6 ${tier.popular ? "text-primary-foreground" : "text-primary"}`} />
                </div>
                <div>
                  <h3 className="font-display text-lg sm:text-xl text-foreground">{tier.name}</h3>
                  <p className="text-xs text-muted-foreground">{tier.description}</p>
                </div>
              </div>

              <div className="mb-5 sm:mb-6">
                <span className="font-display text-3xl sm:text-4xl text-foreground">
                  {typeof tier.price === "number" ? `$${tier.price}` : tier.price}
                </span>
                <span className="text-muted-foreground text-sm ml-1">{tier.priceNote}</span>
              </div>

              <ul className="space-y-2.5 sm:space-y-3 mb-6">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-2 text-sm">
                    <Check className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                    <span className="text-muted-foreground">{feature}</span>
                  </li>
                ))}
              </ul>

              <Button 
                asChild 
                size="lg"
                className={`w-full group ${
                  tier.popular 
                    ? "gradient-gold text-primary-foreground font-bold hover:opacity-90 glow-gold" 
                    : tier.highlight === false && tier.price === "Free"
                    ? "bg-primary text-primary-foreground font-semibold hover:bg-primary/90"
                    : "bg-secondary hover:bg-secondary/80 text-foreground"
                }`}
              >
                <Link to="/signup">
                  {tier.cta}
                  <ArrowRight className="ml-2 w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </Link>
              </Button>
            </div>
          ))}
        </div>

        {/* Trust elements */}
        <div className="mt-10 sm:mt-12 text-center">
          <p className="text-muted-foreground text-sm">
            ✓ No credit card for free plan &nbsp;&nbsp; ✓ Cancel anytime &nbsp;&nbsp; ✓ Instant access
          </p>
        </div>
      </div>
    </section>
  );
};

export default Pricing;
