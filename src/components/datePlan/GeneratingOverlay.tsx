import { Sparkles } from "lucide-react";

const GeneratingOverlay = () => {
  return (
    <div className="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center">
      <div className="text-center space-y-6 p-8">
        <div className="relative">
          <div className="w-24 h-24 rounded-full gradient-gold flex items-center justify-center mx-auto animate-pulse">
            <Sparkles className="w-12 h-12 text-primary-foreground" />
          </div>
          <div className="absolute inset-0 w-24 h-24 mx-auto rounded-full border-4 border-primary/30 animate-ping" />
        </div>
        
        <div className="space-y-2">
          <h2 className="font-display text-2xl sm:text-3xl">Your Genie is Working Magic...</h2>
          <p className="text-muted-foreground max-w-md">
            We're crafting the perfect date plan based on your preferences. This takes about 10-15 seconds.
          </p>
        </div>
        
        <div className="flex items-center justify-center gap-2">
          <div className="w-2 h-2 rounded-full bg-primary animate-bounce" style={{ animationDelay: "0ms" }} />
          <div className="w-2 h-2 rounded-full bg-primary animate-bounce" style={{ animationDelay: "150ms" }} />
          <div className="w-2 h-2 rounded-full bg-primary animate-bounce" style={{ animationDelay: "300ms" }} />
        </div>
      </div>
    </div>
  );
};

export default GeneratingOverlay;
