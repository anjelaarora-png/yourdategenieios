import { useState, useMemo, useEffect } from "react";
import { ChevronLeft, Shuffle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
  type CarouselApi,
} from "@/components/ui/carousel";
import {
  PLAYBOOK_CATEGORIES,
  getPlaybookComboKey,
  getPlaybookTips,
  type PlaybookCategory,
} from "@/data/playbookContent";
import { useUserPreferences } from "@/hooks/useUserPreferences";

function shuffleArray<T>(arr: T[]): T[] {
  const out = [...arr];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

interface PlaybookViewProps {
  onClose?: () => void;
  /** If true, show a back/close control in the header (e.g. when used in a sheet). */
  showClose?: boolean;
}

const TIPS_PER_BATCH = 10;

export default function PlaybookView({ onClose, showClose = true }: PlaybookViewProps) {
  const { preferences } = useUserPreferences();
  const [selectedCategory, setSelectedCategory] = useState<PlaybookCategory | null>(null);
  const [shuffledTips, setShuffledTips] = useState<string[]>([]);
  const [carouselApi, setCarouselApi] = useState<CarouselApi | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);

  const comboKey = getPlaybookComboKey(preferences?.gender ?? null, preferences?.partner_gender ?? null);

  const tipsForCategory = useMemo(() => {
    if (!selectedCategory) return [];
    return getPlaybookTips(selectedCategory.id, comboKey);
  }, [selectedCategory, comboKey]);

  const displayedTips = useMemo(() => {
    if (shuffledTips.length > 0) return shuffledTips;
    return tipsForCategory;
  }, [tipsForCategory, shuffledTips]);

  useEffect(() => {
    if (!carouselApi) return;
    setCurrentIndex(carouselApi.selectedScrollSnap());
    carouselApi.on("select", () => setCurrentIndex(carouselApi.selectedScrollSnap()));
  }, [carouselApi]);

  useEffect(() => {
    if (carouselApi && displayedTips.length) carouselApi.scrollTo(0, true);
  }, [displayedTips, carouselApi]);

  const handleSelectCategory = (cat: PlaybookCategory) => {
    setSelectedCategory(cat);
    setShuffledTips([]);
    setCurrentIndex(0);
  };

  const handleBackToGrid = () => {
    setSelectedCategory(null);
    setShuffledTips([]);
  };

  const handleShuffle = () => {
    setShuffledTips(shuffleArray(tipsForCategory));
    setCurrentIndex(0);
  };

  const totalTips = displayedTips.length;
  const currentBatch = Math.floor(currentIndex / TIPS_PER_BATCH) + 1;
  const totalBatches = Math.ceil(totalTips / TIPS_PER_BATCH) || 1;

  return (
    <div className="flex flex-col h-full min-h-0">
      <div className="flex items-center justify-between gap-2 shrink-0 pb-4 border-b border-border">
        <div className="flex items-center gap-2">
          {selectedCategory ? (
            <Button variant="ghost" size="icon" onClick={handleBackToGrid} aria-label="Back to categories">
              <ChevronLeft className="h-5 w-5" />
            </Button>
          ) : null}
          <h2 className="font-display text-xl sm:text-2xl text-foreground">
            {selectedCategory ? selectedCategory.title : "The Playbook"}
          </h2>
        </div>
        {showClose && onClose ? (
          <Button variant="ghost" size="sm" onClick={onClose}>
            Close
          </Button>
        ) : null}
      </div>

      <div className="flex-1 overflow-auto py-4">
        {!selectedCategory ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {PLAYBOOK_CATEGORIES.map((cat) => (
              <Card
                key={cat.id}
                className="cursor-pointer transition-colors hover:bg-accent/50 hover:border-primary/30"
                onClick={() => handleSelectCategory(cat)}
              >
                <CardContent className="p-4 flex flex-col items-center text-center gap-2">
                  <span className="text-2xl" aria-hidden>{cat.emoji}</span>
                  <span className="font-medium text-sm text-foreground">{cat.title}</span>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <div className="flex flex-col flex-1 min-h-0">
            <div className="flex items-center justify-between gap-2 shrink-0 mb-3">
              <p className="text-sm text-muted-foreground">
                Tip {currentIndex + 1} of {totalTips}
                {totalBatches > 1 && (
                  <span className="ml-2 text-muted-foreground/80">
                    · Set {currentBatch} of {totalBatches}
                  </span>
                )}
              </p>
              <Button variant="outline" size="sm" onClick={handleShuffle} className="gap-2">
                <Shuffle className="h-4 w-4" />
                Shuffle
              </Button>
            </div>
            <p className="text-xs text-muted-foreground mb-2 shrink-0">
              Swipe left or right — or use the arrows — to see the next tip
            </p>
            <div className="flex-1 min-h-0 relative flex items-stretch">
              <Carousel
                setApi={setCarouselApi}
                opts={{ align: "center", loop: false, skipSnaps: false }}
                className="w-full flex-1"
              >
                <CarouselContent className="ml-0">
                  {displayedTips.map((tip, i) => (
                    <CarouselItem key={`${tip.slice(0, 30)}-${i}`} className="pl-0 pr-2">
                      <Card className="h-full min-h-[140px] flex flex-col border-primary/20 bg-card">
                        <CardContent className="p-5 flex flex-col flex-1 justify-center">
                          <span className="shrink-0 w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center text-sm font-semibold mb-3">
                            {i + 1}
                          </span>
                          <p className="text-sm sm:text-base text-foreground leading-relaxed">
                            {tip}
                          </p>
                        </CardContent>
                      </Card>
                    </CarouselItem>
                  ))}
                </CarouselContent>
                <CarouselPrevious className="left-1 sm:-left-4 top-1/2 -translate-y-1/2" />
                <CarouselNext className="right-1 sm:-right-4 top-1/2 -translate-y-1/2" />
              </Carousel>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
