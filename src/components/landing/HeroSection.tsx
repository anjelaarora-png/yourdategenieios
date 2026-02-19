import { Button } from "@/components/ui/button";
import { ArrowRight, Sparkles, Heart, Clock } from "lucide-react";
import { Link } from "react-router-dom";
import AnimatedDatePlan from "./AnimatedDatePlan";

const HeroSection = () => {
  return (
    <section className="relative min-h-[100dvh] flex items-center overflow-hidden pt-20 sm:pt-24 pb-8 sm:pb-12">
      {/* Background effects - smaller on mobile */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-[250px] sm:w-[500px] h-[250px] sm:h-[500px] bg-primary/10 rounded-full blur-3xl animate-pulse" />
        <div className="absolute bottom-1/4 right-1/4 w-[200px] sm:w-[400px] h-[200px] sm:h-[400px] bg-primary/5 rounded-full blur-3xl animate-pulse" style={{ animationDelay: "1s" }} />
      </div>

      <div className="container px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid lg:grid-cols-2 gap-8 lg:gap-16 items-center">
          {/* Left side - Content */}
          <div className="text-center lg:text-left order-2 lg:order-1">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full bg-primary/10 border border-primary/20 mb-6 sm:mb-8 animate-fade-in">
              <Sparkles className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-primary" />
              <span className="text-primary text-xs sm:text-sm font-medium">AI-Powered Date Planning</span>
            </div>

            {/* Main headline */}
            <h1 className="font-display text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl mb-4 sm:mb-6 text-foreground leading-tight animate-fade-in" style={{ animationDelay: "0.1s" }}>
              Stop Planning.<br />
              <span className="text-gradient-gold">Start Dating.</span>
            </h1>

            {/* Subheadline */}
            <p className="text-base sm:text-lg md:text-xl text-muted-foreground mb-6 sm:mb-8 max-w-xl mx-auto lg:mx-0 animate-fade-in leading-relaxed" style={{ animationDelay: "0.2s" }}>
              Get personalized, multi-stop date plans tailored to your preferences, location, and dietary needs in <span className="text-primary font-semibold">60 seconds</span>.
            </p>

            {/* Value props - vertical on mobile */}
            <div className="flex flex-col xs:flex-row xs:flex-wrap justify-center lg:justify-start gap-3 sm:gap-4 md:gap-6 mb-6 sm:mb-8 animate-fade-in" style={{ animationDelay: "0.3s" }}>
              <div className="flex items-center justify-center xs:justify-start gap-2 text-foreground text-sm sm:text-base">
                <Heart className="w-4 h-4 sm:w-5 sm:h-5 text-primary flex-shrink-0" />
                <span>Personalized to you</span>
              </div>
              <div className="flex items-center justify-center xs:justify-start gap-2 text-foreground text-sm sm:text-base">
                <Clock className="w-4 h-4 sm:w-5 sm:h-5 text-primary flex-shrink-0" />
                <span>Ready in 60 seconds</span>
              </div>
              <div className="flex items-center justify-center xs:justify-start gap-2 text-foreground text-sm sm:text-base">
                <Sparkles className="w-4 h-4 sm:w-5 sm:h-5 text-primary flex-shrink-0" />
                <span>Real venues, not guesses</span>
              </div>
            </div>

            {/* CTA */}
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center lg:justify-start items-center animate-fade-in" style={{ animationDelay: "0.4s" }}>
              <Button 
                asChild 
                size="lg" 
                className="gradient-gold text-primary-foreground font-bold w-full sm:w-auto px-6 sm:px-10 py-5 sm:py-7 text-base sm:text-xl glow-gold hover:opacity-90 transition-all hover:scale-105 animate-pulse-glow group"
              >
                <Link to="/signup">
                  Start Planning Free
                  <ArrowRight className="ml-2 w-5 h-5 sm:w-6 sm:h-6 group-hover:translate-x-1 transition-transform" />
                </Link>
              </Button>
              <p className="text-muted-foreground text-sm">Free • No credit card required</p>
            </div>

            {/* Social proof */}
            <div className="mt-8 sm:mt-10 flex flex-col items-center lg:items-start gap-3 sm:gap-4 animate-fade-in" style={{ animationDelay: "0.5s" }}>
              <div className="flex -space-x-2 sm:-space-x-3">
                <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=60&h=60&fit=crop&crop=faces" alt="User" className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-background" />
                <img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=60&h=60&fit=crop&crop=faces" alt="User" className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-background" />
                <img src="https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=60&h=60&fit=crop&crop=faces" alt="User" className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-background" />
                <img src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=60&h=60&fit=crop&crop=faces" alt="User" className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-background" />
                <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=60&h=60&fit=crop&crop=faces" alt="User" className="w-8 h-8 sm:w-10 sm:h-10 rounded-full border-2 border-background" />
              </div>
              <p className="text-muted-foreground text-sm sm:text-base">
                Join <span className="text-primary font-semibold">500+ couples</span> already planning better dates
              </p>
            </div>
          </div>

          {/* Right side - Animated Date Plan (hidden on very small screens) */}
          <div className="order-1 lg:order-2 animate-fade-in hidden xs:block" style={{ animationDelay: "0.3s" }}>
            <AnimatedDatePlan />
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;
