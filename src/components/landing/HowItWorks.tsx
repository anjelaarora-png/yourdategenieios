import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { ArrowRight, Clock, Sparkles, MapPin } from "lucide-react";

const steps = [
  {
    number: "1",
    icon: Clock,
    title: "Answer a few questions",
    description: "Tell us about your preferences, location, and dietary needs. Takes just 60 seconds.",
  },
  {
    number: "2",
    icon: Sparkles,
    title: "Get your personalized plan",
    description: "Our AI creates a complete multi-stop itinerary with verified venues and timing.",
  },
  {
    number: "3",
    icon: MapPin,
    title: "Show up and enjoy",
    description: "Everything is planned. Just follow the itinerary and focus on each other.",
  },
];

const HowItWorks = () => {
  return (
    <section className="py-16 sm:py-24">
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-12 sm:mb-16">
          <h2 className="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl mb-4 text-foreground">
            How It <span className="text-primary">Works</span>
          </h2>
          <p className="text-muted-foreground text-base sm:text-lg">
            From stressed to impressed in three simple steps
          </p>
        </div>

        {/* Steps */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 max-w-5xl mx-auto mb-12 sm:mb-16">
          {steps.map((step, index) => (
            <div key={step.number} className="relative text-center">
              {/* Connector line - hidden on mobile */}
              {index < steps.length - 1 && (
                <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-primary/50 to-transparent" />
              )}
              
              <div className="relative inline-flex items-center justify-center w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-primary/10 border-2 border-primary/30 mb-4 sm:mb-6">
                <step.icon className="w-8 h-8 sm:w-10 sm:h-10 text-primary" />
                <span className="absolute -top-2 -right-2 w-7 h-7 sm:w-8 sm:h-8 rounded-full gradient-gold text-primary-foreground text-sm sm:text-base font-bold flex items-center justify-center">
                  {step.number}
                </span>
              </div>
              <h3 className="font-display text-lg sm:text-xl mb-2 text-foreground">{step.title}</h3>
              <p className="text-muted-foreground text-sm sm:text-base max-w-xs mx-auto">{step.description}</p>
            </div>
          ))}
        </div>

        {/* Image gallery */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4 max-w-6xl mx-auto mb-10 sm:mb-12">
          <div className="aspect-[3/4] rounded-lg overflow-hidden">
            <img 
              src="https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=600&auto=format&fit=crop"
              alt="Fine dining restaurant"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
            />
          </div>
          <div className="aspect-[3/4] rounded-lg overflow-hidden">
            <img 
              src="https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=600&auto=format&fit=crop"
              alt="Restaurant with city view"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
            />
          </div>
          <div className="aspect-[3/4] rounded-lg overflow-hidden hidden sm:block">
            <img 
              src="https://images.unsplash.com/photo-1559329007-40df8a9345d8?q=80&w=600&auto=format&fit=crop"
              alt="Elegant bar interior"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
            />
          </div>
          <div className="aspect-[3/4] rounded-lg overflow-hidden hidden sm:block">
            <img 
              src="https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?q=80&w=600&auto=format&fit=crop"
              alt="Rooftop dining"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
            />
          </div>
        </div>

        <div className="text-center">
          <Button 
            asChild 
            size="lg" 
            className="gradient-gold text-primary-foreground font-bold px-8 sm:px-10 py-6 sm:py-7 text-base sm:text-lg glow-gold hover:opacity-90 transition-all hover:scale-105 group w-full sm:w-auto"
          >
            <Link to="/signup">
              Try It Free Now
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Link>
          </Button>
          <p className="mt-3 text-muted-foreground text-sm">No credit card required</p>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
