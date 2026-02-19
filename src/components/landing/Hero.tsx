import { Button } from "@/components/ui/button";
import { ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";

const Hero = () => {
  return (
    <section className="relative min-h-screen flex items-center overflow-hidden pt-16">
      {/* Two-column layout */}
      <div className="container px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left: Image placeholder */}
          <div className="relative order-2 lg:order-1">
            <div className="aspect-[4/5] rounded-lg overflow-hidden bg-secondary/50">
              <img 
                src="https://images.unsplash.com/photo-1529634806980-85c3dd6d34ac?q=80&w=1000&auto=format&fit=crop"
                alt="Romantic couple walking on beach"
                className="w-full h-full object-cover"
              />
            </div>
          </div>

          {/* Right: Content */}
          <div className="order-1 lg:order-2 text-center lg:text-left">
            <h2 className="font-display text-3xl sm:text-4xl mb-2 text-foreground animate-fade-in">
              About <span className="font-script text-primary">Us</span>
            </h2>

            <p className="text-muted-foreground text-lg leading-relaxed mb-6 animate-fade-in" style={{ animationDelay: "0.1s" }}>
              Your Date Genie was created for people who love with intention but juggle full-demanding 
              lives. For those who care deeply, yet often find themselves thinking, "I want to plan 
              something special... I just don't know where to begin." When days get crowded and 
              routines take over, romance can slip into the background without anyone meaning to let it.
            </p>

            <p className="text-muted-foreground text-lg leading-relaxed mb-8 animate-fade-in" style={{ animationDelay: "0.2s" }}>
              That's where your Genie steps in. We take the details that define you, your pace, your 
              preferences, your partner's little quirks, the rhythm of your week and shape them into 
              moments that feel thoughtful, easy, and beautifully personal.
            </p>

            <div className="animate-fade-in" style={{ animationDelay: "0.3s" }}>
              <Button asChild size="lg" className="gradient-gold text-primary-foreground font-semibold px-8 py-6 text-lg glow-gold hover:opacity-90 transition-opacity">
                <Link to="/signup">
                  Plan Your Date
                  <ArrowRight className="ml-2 w-5 h-5" />
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
