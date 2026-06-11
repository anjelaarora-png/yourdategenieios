import { Sparkles, Heart } from "lucide-react";
import { Link } from "react-router-dom";
import { PrimaryCTA } from "@/components/PrimaryCTA";

const Footer = () => {
  return (
    <footer className="border-t border-border">
      {/* Final CTA Section */}
      <div className="py-16 sm:py-20 bg-gradient-to-b from-background to-secondary/30">
        <div className="container px-4 sm:px-6 lg:px-8 text-center">
          <div className="max-w-2xl mx-auto">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 mb-6">
              <Heart className="w-4 h-4 text-primary fill-primary animate-pulse" />
              <span className="text-primary text-sm font-medium">Stop stressing about date night</span>
            </div>
            <h2 className="font-display text-2xl sm:text-3xl md:text-4xl mb-4 text-foreground">
              Your perfect date is <span className="text-gradient-gold">60 seconds away</span>
            </h2>
            <p className="text-muted-foreground mb-8 text-base sm:text-lg max-w-lg mx-auto">
              Join hundreds of couples who've transformed their relationship with thoughtful, personalized date plans.
            </p>
            <div className="max-w-md mx-auto w-full">
              <PrimaryCTA source="landing_footer" appStorePlacement="footer" />
            </div>
            <p className="mt-4 text-muted-foreground text-sm">
              ✓ Free early access &nbsp;&nbsp; ✓ No credit card required
            </p>
          </div>
        </div>
      </div>

      {/* Bottom bar */}
      <div className="py-8 border-t border-border">
        <div className="container px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            {/* Logo */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full border-2 border-gold-subtle flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-primary" />
              </div>
              <div className="flex flex-col">
                <span className="text-xs text-muted-foreground tracking-widest uppercase">Your Date</span>
                <span className="font-display text-xl text-foreground tracking-wide">GENIE</span>
              </div>
            </div>

            {/* Links */}
            <nav className="flex items-center gap-6 text-sm text-muted-foreground flex-wrap justify-center">
              <Link to="/login" className="hover:text-foreground transition-colors">
                Sign In
              </Link>
              <Link to="/signup" className="text-primary hover:text-primary/80 transition-colors font-medium">
                Sign Up Free
              </Link>
              <Link to="/privacy" className="hover:text-foreground transition-colors">
                Privacy Policy
              </Link>
              <Link to="/terms" className="hover:text-foreground transition-colors">
                Terms of Service
              </Link>
            </nav>

            {/* Copyright */}
            <p className="text-sm text-muted-foreground">
              © {new Date().getFullYear()} Your Date Genie
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
