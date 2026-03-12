import { useState, useMemo, useEffect, useCallback, useRef } from "react";
import { GiftSuggestion } from "@/types/datePlan";
import { SavedDatePlan } from "@/hooks/useDatePlans";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Gift, ExternalLink, Search, Filter, ChevronDown, ChevronUp, Sparkles, Loader2, Heart, RefreshCw, CheckCircle, ShoppingBag, ChevronLeft } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuCheckboxItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import OptionCard from "@/components/questionnaire/OptionCard";
import { PARTNER_INTERESTS, GIFT_BUDGETS, GIFT_RECIPIENTS } from "@/components/questionnaire/types";
import { useUserPreferences } from "@/hooks/useUserPreferences";
import { useSavedGifts } from "@/hooks/useSavedGifts";
import type { SavedGift } from "@/hooks/useSavedGifts";

interface GiftSuggestionsListProps {
  plans: SavedDatePlan[];
}

interface UniqueGift {
  gift: GiftSuggestion;
  planTitles: string[];
}

// Occasions matching the questionnaire style
const OCCASIONS = [
  { value: "anniversary", label: "Anniversary", emoji: "💕", desc: "Celebrate your time together" },
  { value: "birthday", label: "Birthday", emoji: "🎂", desc: "Make their day special" },
  { value: "valentines", label: "Valentine's Day", emoji: "❤️", desc: "Show your love" },
  { value: "just-because", label: "Just Because", emoji: "💝", desc: "A sweet surprise" },
  { value: "holiday", label: "Holiday", emoji: "🎄", desc: "Seasonal celebration" },
  { value: "date-night", label: "Date Night", emoji: "🌙", desc: "Perfect pairing" },
];

// Retailer configs: US and UK (and shared) with search URL templates
const RETAILER_CONFIGS: Record<string, { url: string; icon?: string; region?: "us" | "uk" }> = {
  amazon: { url: "https://www.amazon.com/s?k=", region: "us" },
  etsy: { url: "https://www.etsy.com/search?q=" },
  target: { url: "https://www.target.com/s?searchTerm=", region: "us" },
  walmart: { url: "https://www.walmart.com/search?q=", region: "us" },
  nordstrom: { url: "https://www.nordstrom.com/sr?keyword=", region: "us" },
  sephora: { url: "https://www.sephora.com/search?keyword=", region: "us" },
  "best buy": { url: "https://www.bestbuy.com/site/searchpage.jsp?st=", region: "us" },
  bestbuy: { url: "https://www.bestbuy.com/site/searchpage.jsp?st=", region: "us" },
  ebay: { url: "https://www.ebay.com/sch/i.html?_nkw=" },
  ulta: { url: "https://www.ulta.com/search?search=", region: "us" },
  macys: { url: "https://www.macys.com/shop/featured/", region: "us" },
  "macy's": { url: "https://www.macys.com/shop/featured/", region: "us" },
  "home depot": { url: "https://www.homedepot.com/s/", region: "us" },
  "lowe's": { url: "https://www.lowes.com/search?searchTerm=", region: "us" },
  lowes: { url: "https://www.lowes.com/search?searchTerm=", region: "us" },
  wayfair: { url: "https://www.wayfair.com/keyword.html?keyword=", region: "us" },
  overstock: { url: "https://www.overstock.com/search?keywords=", region: "us" },
  zappos: { url: "https://www.zappos.com/search?term=", region: "us" },
  chewy: { url: "https://www.chewy.com/s?query=", region: "us" },
  bookshop: { url: "https://bookshop.org/search?keywords=" },
  "barnes & noble": { url: "https://www.barnesandnoble.com/s/", region: "us" },
  "amazon.co.uk": { url: "https://www.amazon.co.uk/s?k=", region: "uk" },
  "john lewis": { url: "https://www.johnlewis.com/search?search-term=", region: "uk" },
  johnlewis: { url: "https://www.johnlewis.com/search?search-term=", region: "uk" },
  "argos": { url: "https://www.argos.co.uk/search/", region: "uk" },
  "boots": { url: "https://www.boots.com/search?search=", region: "uk" },
};

// Infer region from location string (city/country) for retailer links
function inferRegion(location: string): "us" | "uk" | undefined {
  if (!location) return undefined;
  const lower = location.toLowerCase();
  if (/\b(uk|united kingdom|england|scotland|wales|london|manchester|birmingham)\b/.test(lower)) return "uk";
  return "us";
}

const generateSearchUrl = (giftName: string, whereToBuy: string, region?: "us" | "uk"): string => {
  const whereToBuyLower = whereToBuy.toLowerCase();
  const searchQuery = encodeURIComponent(giftName);
  const preferUK = region === "uk";

  for (const [retailer, config] of Object.entries(RETAILER_CONFIGS)) {
    if (!whereToBuyLower.includes(retailer)) continue;
    if (config.region && config.region !== region && (region === "uk" || region === "us")) continue;
    if (preferUK && retailer === "amazon") return `https://www.amazon.co.uk/s?k=${searchQuery}`;
    if (preferUK && config.region === "us") continue;
    return `${config.url}${searchQuery}`;
  }
  if (preferUK) return `https://www.amazon.co.uk/s?k=${searchQuery}`;
  return `https://www.google.com/search?tbm=shop&q=${searchQuery}`;
};

// Build multiple shop links for a gift (primary + alternates by location)
function getShopLinks(gift: GiftSuggestion, locationHint: string): { label: string; url: string }[] {
  const region = inferRegion(locationHint);
  const primaryUrl = gift.purchaseUrl || generateSearchUrl(gift.name, gift.whereToBuy, region);
  const links: { label: string; url: string }[] = [{ label: "Shop now", url: primaryUrl }];
  const seenUrls = new Set<string>([primaryUrl]);
  const stores = gift.whereToBuy.split(/[,&]|\band\b/).map((s) => s.trim().toLowerCase()).filter(Boolean);
  const seenRetailers = new Set<string>();
  for (const store of stores) {
    for (const [retailer, config] of Object.entries(RETAILER_CONFIGS)) {
      if (!store.includes(retailer) || seenRetailers.has(retailer)) continue;
      if (config.region && region && config.region !== region) continue;
      const url = retailer === "amazon" && region === "uk"
        ? `https://www.amazon.co.uk/s?k=${encodeURIComponent(gift.name)}`
        : `${config.url}${encodeURIComponent(gift.name)}`;
      const label = retailer === "amazon" && region === "uk" ? "Amazon UK" : retailer.replace(/\b\w/g, (c) => c.toUpperCase());
      if (!seenUrls.has(url)) {
        links.push({ label, url });
        seenUrls.add(url);
        seenRetailers.add(retailer);
      }
      break;
    }
  }
  return links.length > 1 ? links : [{ label: "Shop now", url: primaryUrl }];
}

const GiftSuggestionsList = ({ plans }: GiftSuggestionsListProps) => {
  const { toast } = useToast();
  const { getGiftPreferences, saveGiftPreferences, loading: prefsLoading, preferences } = useUserPreferences();
  const { savedGifts, toggleSavedGift, isSaved, markAsPurchased, unmarkAsPurchased, isPurchased, purchasedGiftNames } = useSavedGifts();
  const locationHint = preferences?.preferred_location || preferences?.default_city || "";
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedPriceRanges, setSelectedPriceRanges] = useState<string[]>([]);
  const [expandedCards, setExpandedCards] = useState<Set<string>>(new Set());
  const [prefsLoaded, setPrefsLoaded] = useState(false);
  
  // Gift finder state (questionnaire-style)
  const [showGiftFinder, setShowGiftFinder] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const [foundGifts, setFoundGifts] = useState<GiftSuggestion[]>([]);
  const [occasion, setOccasion] = useState("");
  const [giftRecipient, setGiftRecipient] = useState("");
  const [selectedInterests, setSelectedInterests] = useState<string[]>([]);
  const [giftBudget, setGiftBudget] = useState("");
  const [giftNotes, setGiftNotes] = useState("");
  const foundGiftsRef = useRef<GiftSuggestion[]>([]);
  const refillingRef = useRef(false);
  const swipeStartRef = useRef<{ x: number; y: number } | null>(null);

  useEffect(() => {
    foundGiftsRef.current = foundGifts;
  }, [foundGifts]); (questionnaire prefs carried over)
  useEffect(() => {
    if (showGiftFinder && !prefsLoading && !prefsLoaded) {
      const savedPrefs = getGiftPreferences();
      if (savedPrefs.gift_occasion) setOccasion(savedPrefs.gift_occasion);
      if (savedPrefs.gift_recipient) setGiftRecipient(savedPrefs.gift_recipient);
      if (savedPrefs.gift_interests?.length) setSelectedInterests(savedPrefs.gift_interests);
      if (savedPrefs.gift_budget) setGiftBudget(savedPrefs.gift_budget);
      if (savedPrefs.gift_notes) setGiftNotes(savedPrefs.gift_notes);
      setPrefsLoaded(true);
    }
  }, [showGiftFinder, prefsLoading, prefsLoaded, getGiftPreferences]);

  // Aggregate and deduplicate gifts
  const { uniqueGifts, priceRanges } = useMemo(() => {
    const giftMap = new Map<string, UniqueGift>();
    const priceSet = new Set<string>();
    
    plans.forEach((plan) => {
      if (plan.gift_suggestions && plan.gift_suggestions.length > 0) {
        plan.gift_suggestions.forEach((gift) => {
          // Create a unique key based on name (normalized)
          const key = gift.name.toLowerCase().trim();
          priceSet.add(gift.priceRange);
          
          if (giftMap.has(key)) {
            // Add plan title to existing gift
            const existing = giftMap.get(key)!;
            if (!existing.planTitles.includes(plan.title)) {
              existing.planTitles.push(plan.title);
            }
          } else {
            // Add new gift
            giftMap.set(key, {
              gift,
              planTitles: [plan.title],
            });
          }
        });
      }
    });
    
    return {
      uniqueGifts: Array.from(giftMap.values()),
      priceRanges: Array.from(priceSet).sort(),
    };
  }, [plans]);

  // Filter gifts based on search and price range
  const filteredGifts = useMemo(() => {
    return uniqueGifts.filter((item) => {
      const matchesSearch =
        searchQuery === "" ||
        item.gift.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.gift.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.gift.whereToBuy.toLowerCase().includes(searchQuery.toLowerCase());
      
      const matchesPrice =
        selectedPriceRanges.length === 0 ||
        selectedPriceRanges.includes(item.gift.priceRange);
      
      return matchesSearch && matchesPrice;
    });
  }, [uniqueGifts, searchQuery, selectedPriceRanges]);

  const toggleCardExpansion = (key: string) => {
    setExpandedCards((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(key)) {
        newSet.delete(key);
      } else {
        newSet.add(key);
      }
      return newSet;
    });
  };

  const togglePriceRange = (range: string) => {
    setSelectedPriceRanges((prev) =>
      prev.includes(range) ? prev.filter((r) => r !== range) : [...prev, range]
    );
  };

  const toggleInterest = (value: string) => {
    setSelectedInterests((prev) =>
      prev.includes(value) ? prev.filter((v) => v !== value) : [...prev, value]
    );
  };

  const toggleSavedGiftWithToast = (gift: GiftSuggestion) => {
    if (!gift?.name) return;
    const wasSaved = isSaved(gift);
    toggleSavedGift(gift);
    toast({
      title: wasSaved ? "Removed from saved gifts" : "Saved to My Gifts",
      description: wasSaved ? undefined : "Find it anytime under the Gifts tab.",
    });
  };

  const handleFindGifts = async (refreshCompletely = false) => {
    if (!occasion) {
      toast({
        title: "Please select an occasion",
        variant: "destructive",
      });
      return;
    }

    setIsSearching(true);

    // Save preferences for next time
    saveGiftPreferences({
      gift_occasion: occasion,
      gift_recipient: giftRecipient,
      gift_interests: selectedInterests,
      gift_budget: giftBudget,
      gift_notes: giftNotes,
    });

    try {
      const occasionLabel = OCCASIONS.find((o) => o.value === occasion)?.label || occasion;
      const budgetLabel = GIFT_BUDGETS.find((b) => b.value === giftBudget)?.desc || "any budget";
      const interestLabels = selectedInterests.map(
        (i) => PARTNER_INTERESTS.find((p) => p.value === i)?.label || i
      );

      // Get recipient context for better gift targeting
      const recipientLabel = GIFT_RECIPIENTS.find((r) => r.value === giftRecipient)?.label || "";
      const recipientContext = recipientLabel ? `Shopping for: ${recipientLabel}. ` : "";

      // Pass existing gifts to avoid duplicates (unless refreshing completely)
      const existingToExclude = refreshCompletely ? [] : foundGifts;

      const { data, error } = await supabase.functions.invoke("generate-more-gifts", {
        body: {
          planTitle: `Gift Ideas for ${occasionLabel}`,
          occasion: occasion,
          priceRange: giftBudget || "any",
          interests: interestLabels.join(", "),
          partnerDescription: `${recipientContext}${giftNotes}`.trim(),
          existingGifts: existingToExclude,
          count: 3,
          location: locationHint || undefined,
          city: preferences?.default_city || undefined,
          giftRecipient: giftRecipient || undefined,
          purchasedGiftNames: purchasedGiftNames.length > 0 ? purchasedGiftNames : undefined,
        },
      });

      if (error) throw error;

      if (data?.gifts && Array.isArray(data.gifts)) {
        if (refreshCompletely) {
          // Complete refresh - replace all results
          setFoundGifts(data.gifts);
        } else {
          // Add more - new results at top, old ones at bottom
          setFoundGifts((prev) => [...data.gifts, ...prev]);
        }
      }
    } catch (error) {
      console.error("Error finding gifts:", error);
      toast({
        title: "Couldn't find gifts",
        description: "Please try again in a moment.",
        variant: "destructive",
      });
    } finally {
      setIsSearching(false);
    }
  };

  const resetGiftFinder = () => {
    setFoundGifts([]);
    // Don't reset the form values - keep saved preferences
    // User can manually change if needed
  };

  /** Keep exactly 3 suggestions: fetch more when deck has fewer than 3 after skip/save. */
  const refillToThree = useCallback(async () => {
    if (refillingRef.current || isSearching || !occasion) return;
    const current = foundGiftsRef.current;
    if (current.length >= 3) return;
    const need = 3 - current.length;
    refillingRef.current = true;
    setIsSearching(true);
    try {
      const occasionLabel = OCCASIONS.find((o) => o.value === occasion)?.label || occasion;
      const interestLabels = selectedInterests.map((i) => PARTNER_INTERESTS.find((p) => p.value === i)?.label || i);
      const recipientLabel = GIFT_RECIPIENTS.find((r) => r.value === giftRecipient)?.label || "";
      const recipientContext = recipientLabel ? `Shopping for: ${recipientLabel}. ` : "";
      const { data, error } = await supabase.functions.invoke("generate-more-gifts", {
        body: {
          planTitle: `Gift Ideas for ${occasionLabel}`,
          occasion,
          priceRange: giftBudget || "any",
          interests: interestLabels.join(", "),
          partnerDescription: `${recipientContext}${giftNotes}`.trim(),
          existingGifts: foundGiftsRef.current,
          count: need,
          location: locationHint || undefined,
          city: preferences?.default_city || undefined,
          giftRecipient: giftRecipient || undefined,
          purchasedGiftNames: purchasedGiftNames.length > 0 ? purchasedGiftNames : undefined,
        },
      });
      if (error) throw error;
      if (data?.gifts && Array.isArray(data.gifts)) {
        setFoundGifts((prev) => [...prev, ...data.gifts]);
      }
    } catch (e) {
      console.error("Refill gifts error:", e);
      toast({ title: "Couldn't load another suggestion", variant: "destructive" });
    } finally {
      setIsSearching(false);
      refillingRef.current = false;
    }
  }, [occasion, selectedInterests, giftRecipient, giftBudget, giftNotes, locationHint, preferences?.default_city, purchasedGiftNames, isSearching]);

  const handleSkipTop = useCallback(() => {
    setFoundGifts((prev) => prev.slice(1));
    toast({ title: "Skipped", description: "Loading next suggestion..." });
  }, []);

  const handleSaveTop = useCallback((gift: GiftSuggestion) => {
    toggleSavedGiftWithToast(gift);
    setFoundGifts((prev) => prev.slice(1));
  }, [toggleSavedGiftWithToast]);

  // Refill to 3 when deck has fewer than 3 after skip/save
  useEffect(() => {
    if (foundGifts.length > 0 && foundGifts.length < 3 && !isSearching && occasion && !refillingRef.current) {
      refillToThree();
    }
  }, [foundGifts.length, occasion, isSearching, refillToThree]);

  const handleSwipeStart = (e: React.TouchEvent) => {
    swipeStartRef.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  };
  const handleSwipeMove = (e: React.TouchEvent) => {
    if (!swipeStartRef.current) return;
    const dx = e.touches[0].clientX - swipeStartRef.current.x;
    if (Math.abs(dx) > 60) {
      if (dx < 0) handleSkipTop();
      else if (foundGifts[0]) handleSaveTop(foundGifts[0]);
      swipeStartRef.current = null;
    }
  };
  const handleSwipeEnd = () => {
    swipeStartRef.current = null;
  };

  // Render the Gift Finder form (questionnaire-style)
  const renderGiftFinder = () => (
    <div className="space-y-6 p-5 rounded-lg border border-border bg-card">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
            <Gift className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 className="text-lg font-medium">Find the Perfect Gift</h3>
            <p className="text-sm text-muted-foreground">Tell us about who you're shopping for</p>
          </div>
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setShowGiftFinder(false);
            resetGiftFinder();
          }}
        >
          Cancel
        </Button>
      </div>

      {foundGifts.length === 0 ? (
        <div className="space-y-6">
          {/* Occasion */}
          <div>
            <Label className="text-sm font-medium mb-3 block">What's the occasion? *</Label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {OCCASIONS.map((occ) => (
                <OptionCard
                  key={occ.value}
                  emoji={occ.emoji}
                  label={occ.label}
                  description={occ.desc}
                  selected={occasion === occ.value}
                  onClick={() => setOccasion(occ.value)}
                />
              ))}
            </div>
          </div>

          {/* Who are you shopping for */}
          <div>
            <Label className="text-sm font-medium mb-3 block">Who are you shopping for?</Label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {GIFT_RECIPIENTS.map((recipient) => (
                <OptionCard
                  key={recipient.value}
                  emoji={recipient.emoji}
                  label={recipient.label}
                  description={recipient.desc}
                  selected={giftRecipient === recipient.value}
                  onClick={() => setGiftRecipient(recipient.value)}
                />
              ))}
            </div>
          </div>

          {/* Their interests */}
          <div>
            <Label className="text-sm font-medium mb-3 block">Their Interests (select all that apply)</Label>
            <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
              {PARTNER_INTERESTS.map((interest) => (
                <button
                  key={interest.value}
                  type="button"
                  onClick={() => toggleInterest(interest.value)}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm transition-all ${
                    selectedInterests.includes(interest.value)
                      ? "border-primary bg-primary/10 text-foreground"
                      : "border-border bg-background text-muted-foreground hover:border-primary/50"
                  }`}
                >
                  <span>{interest.emoji}</span>
                  <span className="truncate">{interest.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Gift budget */}
          <div>
            <Label className="text-sm font-medium mb-3 block">Gift Budget</Label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {GIFT_BUDGETS.map((budget) => (
                <OptionCard
                  key={budget.value}
                  label={budget.label}
                  description={budget.desc}
                  selected={giftBudget === budget.value}
                  onClick={() => setGiftBudget(budget.value)}
                />
              ))}
            </div>
          </div>

          {/* Notes about them */}
          <div>
            <Label htmlFor="gift-notes" className="text-sm font-medium mb-3 block">
              Any special notes about them? (Optional)
            </Label>
            <Textarea
              id="gift-notes"
              placeholder="E.g., They love vintage items, recently got into hiking, have a sweet tooth..."
              value={giftNotes}
              onChange={(e) => setGiftNotes(e.target.value)}
              className="min-h-[80px] resize-none"
            />
            <p className="text-xs text-muted-foreground mt-2">
              The more details you share, the better we can tailor gift suggestions!
            </p>
          </div>

          {/* Find button */}
          <Button
            onClick={() => handleFindGifts(true)}
            disabled={isSearching || !occasion}
            className="w-full gradient-gold text-primary-foreground"
          >
            {isSearching ? (
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
        <div className="space-y-4">
          {/* Saved Gifts section at top */}
          {savedGifts.length > 0 && (
            <div className="space-y-3 p-4 rounded-lg border-2 border-primary/20 bg-primary/5">
              <div className="flex items-center gap-2">
                <Heart className="w-4 h-4 text-primary fill-primary" />
                <h4 className="font-medium text-sm">Saved Gifts ({savedGifts.length})</h4>
              </div>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {savedGifts.map((gift, i) => {
                  const shopLinks = getShopLinks(gift, locationHint);
                  const primaryUrl = shopLinks[0].url;
                  const bought = (gift as SavedGift).purchased;
                  return (
                    <div key={`fav-${i}`} className={`flex items-center justify-between gap-2 p-2 rounded-md bg-background border ${bought ? "opacity-75" : ""}`}>
                      <div className="flex items-center gap-2 min-w-0">
                        <span>{gift.emoji}</span>
                        <span className="text-sm truncate">{gift.name}</span>
                        {bought && (
                          <Badge variant="secondary" className="text-xs shrink-0 gap-0.5">
                            <CheckCircle className="w-3 h-3" />
                            Bought
                          </Badge>
                        )}
                        {!bought && <Badge variant="outline" className="text-xs shrink-0">{gift.priceRange}</Badge>}
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        {bought ? (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 text-xs"
                            onClick={() => {
                              unmarkAsPurchased(gift);
                              toast({ title: "Marked as not bought", description: "It may be recommended again." });
                            }}
                          >
                            Undo
                          </Button>
                        ) : (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-7 text-xs gap-1"
                            onClick={() => {
                              markAsPurchased(gift);
                              toast({ title: "Marked as bought", description: "Won't be recommended again." });
                            }}
                          >
                            <ShoppingBag className="w-3.5 h-3.5" />
                            Bought
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7"
                          onClick={() => toggleSavedGiftWithToast(gift)}
                        >
                          <Heart className="w-3.5 h-3.5 text-primary fill-primary" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7"
                          asChild
                        >
                          <a href={primaryUrl} target="_blank" rel="noopener noreferrer">
                            <ExternalLink className="w-3.5 h-3.5" />
                          </a>
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              3 suggestions — swipe or use buttons to skip or save
            </p>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" onClick={() => handleFindGifts(true)} disabled={isSearching}>
                <RefreshCw className={`w-4 h-4 mr-2 ${isSearching ? 'animate-spin' : ''}`} />
                Refresh All
              </Button>
              <Button variant="outline" size="sm" onClick={resetGiftFinder}>
                <Search className="w-4 h-4 mr-2" />
                New Search
              </Button>
            </div>
          </div>

          {/* Swipeable 3-card stack: always show 3 suggestions; swipe left = skip, right = save */}
          <div className="relative min-h-[320px] flex items-center justify-center">
            {foundGifts.length === 0 && isSearching && (
              <div className="absolute inset-0 flex items-center justify-center">
                <Loader2 className="w-10 h-10 animate-spin text-primary" />
                <span className="ml-2 text-sm">Loading suggestions...</span>
              </div>
            )}
            {foundGifts.slice(0, 3).map((gift, stackIndex) => {
              const shopLinks = getShopLinks(gift, locationHint);
              const primaryUrl = shopLinks[0].url;
              const isTop = stackIndex === 0;
              return (
                <div
                  key={`stack-${stackIndex}-${gift.name}`}
                  className={`w-full max-w-md mx-auto transition-all duration-200 ${
                    isTop ? "relative z-10 scale-100 opacity-100" : "absolute inset-0 z-0 scale-95 opacity-60 pointer-events-none"
                  }`}
                  style={!isTop ? { top: stackIndex * 12, left: 0, right: 0 } : undefined}
                  {...(isTop && {
                    onTouchStart: handleSwipeStart,
                    onTouchMove: handleSwipeMove,
                    onTouchEnd: handleSwipeEnd,
                  })}
                >
                  <Card className="border-border shadow-lg overflow-hidden">
                    <CardContent className="pt-4 pb-4">
                      <div className="flex items-start justify-between gap-2 mb-2">
                        <h4 className="font-medium flex items-center gap-2">
                          <span className="text-2xl">{gift.emoji}</span>
                          {gift.name}
                        </h4>
                        <Badge variant="outline" className="text-xs shrink-0">{gift.priceRange}</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground mb-2">{gift.description}</p>
                      <p className="text-xs text-muted-foreground mb-1">
                        <span className="text-primary font-medium">Where to buy:</span> {gift.whereToBuy}
                      </p>
                      <p className="text-xs text-muted-foreground italic mb-4">{gift.whyItFits}</p>

                      {isTop && (
                        <>
                          <a
                            href={primaryUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center justify-center gap-2 w-full py-2.5 rounded-lg gradient-gold text-primary-foreground font-medium text-sm mb-4 hover:opacity-90"
                          >
                            <ExternalLink className="w-4 h-4" />
                            Shop at {shopLinks[0].label}
                          </a>
                          <div className="flex items-center justify-center gap-4">
                            <Button
                              variant="outline"
                              size="lg"
                              className="gap-2 px-6"
                              onClick={handleSkipTop}
                              disabled={isSearching}
                            >
                              <ChevronLeft className="w-5 h-5" />
                              Skip
                            </Button>
                            <Button
                              variant="default"
                              size="lg"
                              className="gap-2 px-6 gradient-gold text-primary-foreground"
                              onClick={() => handleSaveTop(gift)}
                              disabled={isSearching}
                            >
                              <Heart className="w-5 h-5 fill-current" />
                              Save
                            </Button>
                          </div>
                          {!isPurchased(gift) && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="w-full mt-2 gap-1.5 text-xs"
                              onClick={() => {
                                markAsPurchased(gift);
                                toast({ title: "Marked as bought", description: "Won't be recommended again." });
                              }}
                            >
                              <ShoppingBag className="w-3.5 h-3.5" />
                              Mark as bought
                            </Button>
                          )}
                        </>
                      )}

                      {!isTop && (
                        <a
                          href={primaryUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs text-primary hover:underline"
                        >
                          Shop at {gift.whereToBuy}
                        </a>
                      )}
                    </CardContent>
                  </Card>
                </div>
              );
            })}
          </div>

          <p className="text-center text-xs text-muted-foreground mt-2">
            Swipe left to skip • Swipe right to save • Each suggestion has a shop link
          </p>
        </div>
      )}
    </div>
  );

  // Empty state or gift finder shown
  if (uniqueGifts.length === 0 || showGiftFinder) {
    return (
      <>
        {showGiftFinder ? (
          renderGiftFinder()
        ) : (
          <div className="flex flex-col items-center justify-center bg-muted rounded-lg p-8 gap-4 h-[300px]">
            <Gift className="w-12 h-12 text-muted-foreground" />
            <p className="text-muted-foreground text-center">
              No gift suggestions yet. Generate date plans with gift suggestions enabled, or find gifts now!
            </p>
            <Button onClick={() => setShowGiftFinder(true)} className="gradient-gold text-primary-foreground">
              <Sparkles className="w-4 h-4 mr-2" />
              Find Gifts Now
            </Button>
          </div>
        )}
      </>
    );
  }

  return (
    <>
      {showGiftFinder ? (
        renderGiftFinder()
      ) : (
        <div className="space-y-4">
          {/* Saved Gifts section at top */}
          {savedGifts.length > 0 && (
            <div className="space-y-3 p-4 rounded-lg border-2 border-primary/20 bg-primary/5">
              <div className="flex items-center gap-2">
                <Heart className="w-4 h-4 text-primary fill-primary" />
                <h4 className="font-medium text-sm">Saved Gifts ({savedGifts.length})</h4>
              </div>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {savedGifts.map((gift, i) => {
                  const shopLinks = getShopLinks(gift, locationHint);
                  const primaryUrl = shopLinks[0].url;
                  const bought = (gift as SavedGift).purchased;
                  return (
                    <div key={`fav-main-${i}`} className={`flex items-center justify-between gap-2 p-2 rounded-md bg-background border ${bought ? "opacity-75" : ""}`}>
                      <div className="flex items-center gap-2 min-w-0">
                        <span>{gift.emoji}</span>
                        <span className="text-sm truncate">{gift.name}</span>
                        {bought && (
                          <Badge variant="secondary" className="text-xs shrink-0 gap-0.5">
                            <CheckCircle className="w-3 h-3" />
                            Bought
                          </Badge>
                        )}
                        {!bought && <Badge variant="outline" className="text-xs shrink-0">{gift.priceRange}</Badge>}
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        {bought ? (
                          <Button variant="ghost" size="sm" className="h-7 text-xs" onClick={() => { unmarkAsPurchased(gift); toast({ title: "Marked as not bought" }); }}>
                            Undo
                          </Button>
                        ) : (
                          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={() => { markAsPurchased(gift); toast({ title: "Marked as bought", description: "Won't be recommended again." }); }}>
                            <ShoppingBag className="w-3.5 h-3.5" />
                            Bought
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7"
                          onClick={() => toggleSavedGiftWithToast(gift)}
                        >
                          <Heart className="w-3.5 h-3.5 text-primary fill-primary" />
                        </Button>
                        <Button variant="ghost" size="icon" className="h-7 w-7" asChild>
                          <a href={primaryUrl} target="_blank" rel="noopener noreferrer">
                            <ExternalLink className="w-3.5 h-3.5" />
                          </a>
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Header with stats */}
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div className="flex items-center gap-3">
              <p className="text-sm text-muted-foreground">
                {uniqueGifts.length} unique gift idea{uniqueGifts.length !== 1 ? "s" : ""} from {plans.length} plan{plans.length !== 1 ? "s" : ""}
              </p>
              <Button variant="outline" size="sm" onClick={() => setShowGiftFinder(true)} className="gap-1.5">
                <Sparkles className="w-3 h-3" />
                Find More
              </Button>
            </div>
            {/* Search and filter */}
            <div className="flex items-center gap-2">
              <div className="relative flex-1 sm:w-64">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <Input
                  placeholder="Search gifts..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-8 h-9"
                />
              </div>
              
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm" className="gap-1.5">
                    <Filter className="w-4 h-4" />
                    Price
                    {selectedPriceRanges.length > 0 && (
                      <Badge variant="secondary" className="ml-1 px-1.5 py-0 text-xs">
                        {selectedPriceRanges.length}
                      </Badge>
                    )}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {priceRanges.map((range) => (
                    <DropdownMenuCheckboxItem
                      key={range}
                      checked={selectedPriceRanges.includes(range)}
                      onCheckedChange={() => togglePriceRange(range)}
                    >
                      {range}
                    </DropdownMenuCheckboxItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          {/* Results count when filtered */}
          {(searchQuery || selectedPriceRanges.length > 0) && (
            <p className="text-xs text-muted-foreground">
              Showing {filteredGifts.length} of {uniqueGifts.length} gifts
              {selectedPriceRanges.length > 0 && (
                <Button
                  variant="link"
                  size="sm"
                  className="ml-2 h-auto p-0 text-xs"
                  onClick={() => setSelectedPriceRanges([])}
                >
                  Clear filters
                </Button>
              )}
            </p>
          )}

          {/* Gift cards grid */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {filteredGifts.map((item, i) => {
              const cardKey = item.gift.name.toLowerCase().trim();
              const isExpanded = expandedCards.has(cardKey);
              const shopLinks = getShopLinks(item.gift, locationHint);
              const primaryUrl = shopLinks[0].url;
              const favorited = isSaved(item.gift);
              
              return (
                <Card key={i} className="border-border hover:shadow-md transition-shadow flex flex-col">
                  <CardContent className="pt-4 flex flex-col flex-1">
                    {/* Header */}
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <h4 className="font-medium flex items-center gap-2">
                        <span className="text-xl">{item.gift.emoji}</span>
                        {item.gift.name}
                      </h4>
                      <div className="flex items-center gap-1.5 shrink-0">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7"
                          onClick={() => toggleSavedGiftWithToast(item.gift)}
                        >
                          <Heart className={`w-4 h-4 ${favorited ? 'text-primary fill-primary' : 'text-muted-foreground'}`} />
                        </Button>
                        <Badge variant="outline" className="text-xs">
                          {item.gift.priceRange}
                        </Badge>
                      </div>
                    </div>
                    
                    {/* Description */}
                    <p className="text-sm text-muted-foreground mb-3">{item.gift.description}</p>
                    
                    {/* Expandable section */}
                    <div className={`space-y-2 overflow-hidden transition-all ${isExpanded ? "max-h-96" : "max-h-0"}`}>
                      <p className="text-xs text-muted-foreground">
                        <span className="text-primary font-medium">Where to buy:</span> {item.gift.whereToBuy}
                      </p>
                      <p className="text-xs text-muted-foreground italic">{item.gift.whyItFits}</p>
                      
                      {item.planTitles.length > 1 && (
                        <div className="pt-2 border-t border-border">
                          <p className="text-xs text-muted-foreground">
                            Suggested in {item.planTitles.length} plans:
                          </p>
                          <div className="flex flex-wrap gap-1 mt-1">
                            {item.planTitles.map((title, j) => (
                              <Badge key={j} variant="secondary" className="text-xs">
                                {title}
                              </Badge>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                    
                    {/* Actions */}
                    <div className="flex items-center justify-between gap-2 mt-auto pt-3 border-t border-border">
                      <div className="flex items-center gap-1.5">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-xs h-8 px-2"
                          onClick={() => toggleCardExpansion(cardKey)}
                        >
                          {isExpanded ? (
                            <>
                              <ChevronUp className="w-3 h-3 mr-1" />
                              Less
                            </>
                          ) : (
                            <>
                              <ChevronDown className="w-3 h-3 mr-1" />
                              More
                            </>
                          )}
                        </Button>
                        {!isPurchased(item.gift) ? (
                          <Button
                            variant="ghost"
                            size="sm"
                            className="text-xs h-8 gap-1"
                            onClick={() => {
                              markAsPurchased(item.gift);
                              toast({ title: "Marked as bought", description: "Won't be recommended again." });
                            }}
                          >
                            <ShoppingBag className="w-3 h-3" />
                            Bought
                          </Button>
                        ) : (
                          <Badge variant="secondary" className="text-xs gap-0.5 h-8 px-2">
                            <CheckCircle className="w-3 h-3" />
                            Bought
                          </Badge>
                        )}
                      </div>

                      <div className="flex flex-wrap items-center gap-1.5">
                        <Button
                          variant="default"
                          size="sm"
                          className="text-xs h-8 gap-1.5 gradient-gold text-primary-foreground hover:opacity-90"
                          asChild
                        >
                          <a href={primaryUrl} target="_blank" rel="noopener noreferrer">
                            <ExternalLink className="w-3 h-3" />
                            {shopLinks[0].label}
                          </a>
                        </Button>
                        {shopLinks.slice(1, 3).map((link, j) => (
                          <Button
                            key={j}
                            variant="outline"
                            size="sm"
                            className="text-xs h-8 gap-1"
                            asChild
                          >
                            <a href={link.url} target="_blank" rel="noopener noreferrer">
                              <ExternalLink className="w-3 h-3" />
                              {link.label}
                            </a>
                          </Button>
                        ))}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {filteredGifts.length === 0 && (
            <div className="flex flex-col items-center justify-center bg-muted rounded-lg p-8 gap-3">
              <Search className="w-8 h-8 text-muted-foreground" />
              <p className="text-muted-foreground text-center">
                No gifts match your search. Try different keywords or clear filters.
              </p>
            </div>
          )}
        </div>
      )}
    </>
  );
};

export default GiftSuggestionsList;
