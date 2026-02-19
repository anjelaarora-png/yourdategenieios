import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { Sparkles, X } from "lucide-react";

const FloatingCTA = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [isDismissed, setIsDismissed] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      // Show after scrolling 400px and hide near footer (last 300px)
      const scrollY = window.scrollY;
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      const nearBottom = scrollY + windowHeight > documentHeight - 300;
      
      setIsVisible(scrollY > 400 && !nearBottom && !isDismissed);
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, [isDismissed]);

  if (!isVisible) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 md:hidden safe-area-bottom animate-slide-up">
      <div className="bg-background/95 backdrop-blur-lg border-t border-border px-4 py-3 shadow-lg">
        <div className="flex items-center justify-between gap-3">
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-foreground truncate">Ready to plan the perfect date?</p>
            <p className="text-xs text-muted-foreground">Free • Takes 60 seconds</p>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0">
            <Button 
              asChild 
              size="sm"
              className="gradient-gold text-primary-foreground font-semibold px-4 glow-gold"
            >
              <Link to="/signup">
                <Sparkles className="w-4 h-4 mr-1.5" />
                Start Free
              </Link>
            </Button>
            <Button 
              variant="ghost" 
              size="icon" 
              className="h-8 w-8 text-muted-foreground"
              onClick={() => setIsDismissed(true)}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FloatingCTA;
