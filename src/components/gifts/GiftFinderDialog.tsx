import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Loader2, Gift, Sparkles, ExternalLink, Search } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { GiftSuggestion } from "@/types/datePlan";

interface GiftFinderDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const OCCASIONS = [
  { value: "anniversary", label: "Anniversary", emoji: "💕" },
  { value: "birthday", label: "Birthday", emoji: "🎂" },
  { value: "valentines", label: "Valentine's Day", emoji: "❤️" },
  { value: "just-because", label: "Just Because", emoji: "💝" },
  { value: "holiday", label: "Holiday", emoji: "🎄" },
  { value: "date-night", label: "Date Night", emoji: "🌙" },
];

const PRICE_RANGES = [
  { value: "under-25", label: "Under $25" },
  { value: "25-50", label: "$25 - $50" },
  { value: "50-100", label: "$50 - $100" },
  { value: "100-200", label: "$100 - $200" },
  { value: "200-plus", label: "$200+" },
];

const RETAILER_CONFIGS: Record<string, string> = {
  amazon: "https://www.amazon.com/s?k=",
  etsy: "https://www.etsy.com/search?q=",
  target: "https://www.target.com/s?searchTerm=",
  walmart: "https://www.walmart.com/search?q=",
  nordstrom: "https://www.nordstrom.com/sr?keyword=",
  sephora: "https://www.sephora.com/search?keyword=",
};

const generateSearchUrl = (giftName: string, whereToBuy: string): string => {
  const whereToBuyLower = whereToBuy.toLowerCase();
  const searchQuery = encodeURIComponent(giftName);

  for (const [retailer, baseUrl] of Object.entries(RETAILER_CONFIGS)) {
    if (whereToBuyLower.includes(retailer)) {
      return `${baseUrl}${searchQuery}`;
    }
  }

  return `https://www.google.com/search?tbm=shop&q=${searchQuery}`;
};

const GiftFinderDialog = ({ open, onOpenChange }: GiftFinderDialogProps) => {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [gifts, setGifts] = useState<GiftSuggestion[]>([]);
  const [hasSearched, setHasSearched] = useState(false);

  const [occasion, setOccasion] = useState("");
  const [priceRange, setPriceRange] = useState("");
  const [interests, setInterests] = useState("");
  const [partnerDescription, setPartnerDescription] = useState("");

  const handleSearch = async () => {
    if (!occasion) {
      toast({
        title: "Please select an occasion",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);
    setHasSearched(true);

    try {
      const { data, error } = await supabase.functions.invoke("generate-more-gifts", {
        body: {
          planTitle: `Gift Ideas for ${OCCASIONS.find((o) => o.value === occasion)?.label || occasion}`,
          occasion: occasion,
          priceRange: priceRange || "any",
          interests: interests,
          partnerDescription: partnerDescription,
          existingGifts: [],
          count: 3,
        },
      });

      if (error) throw error;

      if (data?.gifts && Array.isArray(data.gifts)) {
        setGifts(data.gifts);
      }
    } catch (error) {
      console.error("Error finding gifts:", error);
      toast({
        title: "Couldn't find gifts",
        description: "Please try again in a moment.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleReset = () => {
    setGifts([]);
    setHasSearched(false);
    setOccasion("");
    setPriceRange("");
    setInterests("");
    setPartnerDescription("");
  };

  const handleClose = () => {
    onOpenChange(false);
    // Reset after closing animation
    setTimeout(handleReset, 300);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="font-display text-2xl flex items-center gap-2">
            <Gift className="w-6 h-6" />
            Find the Perfect Gift
          </DialogTitle>
          <DialogDescription>
            Get personalized gift suggestions based on the occasion and your partner's interests
          </DialogDescription>
        </DialogHeader>

        {!hasSearched || gifts.length === 0 ? (
          <div className="space-y-5 py-4">
            {/* Occasion */}
            <div className="space-y-2">
              <Label className="text-sm font-medium">What's the occasion? *</Label>
              <div className="grid grid-cols-3 gap-2">
                {OCCASIONS.map((occ) => (
                  <button
                    key={occ.value}
                    onClick={() => setOccasion(occ.value)}
                    className={`p-3 rounded-lg border text-left transition-all ${
                      occasion === occ.value
                        ? "border-primary bg-primary/10"
                        : "border-border hover:border-primary/50"
                    }`}
                  >
                    <div className="text-xl mb-1">{occ.emoji}</div>
                    <div className="text-sm font-medium">{occ.label}</div>
                  </button>
                ))}
              </div>
            </div>

            {/* Price Range */}
            <div className="space-y-2">
              <Label className="text-sm font-medium">Budget</Label>
              <Select value={priceRange} onValueChange={setPriceRange}>
                <SelectTrigger>
                  <SelectValue placeholder="Any price range" />
                </SelectTrigger>
                <SelectContent>
                  {PRICE_RANGES.map((range) => (
                    <SelectItem key={range.value} value={range.value}>
                      {range.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Interests */}
            <div className="space-y-2">
              <Label className="text-sm font-medium">Their interests (optional)</Label>
              <Input
                placeholder="e.g., cooking, travel, photography, books..."
                value={interests}
                onChange={(e) => setInterests(e.target.value)}
              />
            </div>

            {/* Partner Description */}
            <div className="space-y-2">
              <Label className="text-sm font-medium">Tell us about them (optional)</Label>
              <Input
                placeholder="e.g., loves surprises, prefers experiences over things..."
                value={partnerDescription}
                onChange={(e) => setPartnerDescription(e.target.value)}
              />
            </div>

            <Button
              onClick={handleSearch}
              disabled={isLoading || !occasion}
              className="w-full gradient-gold text-primary-foreground"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Finding gifts...
                </>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 mr-2" />
                  Find Gift Ideas
                </>
              )}
            </Button>
          </div>
        ) : (
          <div className="space-y-4 py-4">
            <div className="flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                {gifts.length} gift ideas for {OCCASIONS.find((o) => o.value === occasion)?.label}
              </p>
              <Button variant="outline" size="sm" onClick={handleReset}>
                <Search className="w-4 h-4 mr-2" />
                New Search
              </Button>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              {gifts.map((gift, i) => {
                const purchaseUrl = gift.purchaseUrl || generateSearchUrl(gift.name, gift.whereToBuy);

                return (
                  <Card key={i} className="border-border hover:shadow-md transition-shadow">
                    <CardContent className="pt-4">
                      <div className="flex items-start justify-between gap-2 mb-2">
                        <h4 className="font-medium flex items-center gap-2">
                          <span className="text-xl">{gift.emoji}</span>
                          {gift.name}
                        </h4>
                        <Badge variant="outline" className="text-xs shrink-0">
                          {gift.priceRange}
                        </Badge>
                      </div>

                      <p className="text-sm text-muted-foreground mb-3">{gift.description}</p>

                      <p className="text-xs text-muted-foreground mb-2">
                        <span className="text-primary font-medium">Where to buy:</span>{" "}
                        {gift.whereToBuy}
                      </p>

                      <p className="text-xs text-muted-foreground italic mb-3">{gift.whyItFits}</p>

                      <Button
                        variant="default"
                        size="sm"
                        className="w-full text-xs gap-1.5 gradient-gold text-primary-foreground hover:opacity-90"
                        asChild
                      >
                        <a href={purchaseUrl} target="_blank" rel="noopener noreferrer">
                          <ExternalLink className="w-3 h-3" />
                          Shop Now
                        </a>
                      </Button>
                    </CardContent>
                  </Card>
                );
              })}
            </div>

            <Button
              variant="outline"
              onClick={handleSearch}
              disabled={isLoading}
              className="w-full"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Finding more...
                </>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 mr-2" />
                  Get More Ideas
                </>
              )}
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default GiftFinderDialog;
