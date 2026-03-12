import { useState, useEffect, useCallback } from "react";
import { GiftSuggestion } from "@/types/datePlan";

const STORAGE_KEY = "date_genie_favorite_gifts";
const VERSION_KEY = "date_genie_favorites_version";

/** Saved gift with optional purchased flag so we don't recommend again */
export type SavedGift = GiftSuggestion & { purchased?: boolean };

function normalizeKey(gift: GiftSuggestion): string {
  return gift.name.toLowerCase().trim();
}

function loadSavedGifts(): SavedGift[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return [];
    const parsed = JSON.parse(stored);
    if (!Array.isArray(parsed)) {
      localStorage.removeItem(STORAGE_KEY);
      return [];
    }
    return parsed.filter(
      (g: unknown): g is SavedGift =>
        g != null &&
        typeof g === "object" &&
        typeof (g as GiftSuggestion).name === "string" &&
        (g as GiftSuggestion).name.trim() !== ""
    );
  } catch {
    return [];
  }
}

function persistSavedGifts(gifts: SavedGift[]): boolean {
  try {
    if (!Array.isArray(gifts)) return false;
    const clean = gifts.filter((g) => g && typeof g.name === "string");
    localStorage.setItem(STORAGE_KEY, JSON.stringify(clean));
    localStorage.setItem(VERSION_KEY, Date.now().toString());
    return true;
  } catch {
    return false;
  }
}

/**
 * Shared hook for saved gifts. Use from the Gifts tab and from date plan cards
 * so saving on a plan adds to the same list you see under the Gifts tab.
 */
export function useSavedGifts() {
  const [savedGifts, setSavedGifts] = useState<SavedGift[]>([]);

  const refresh = useCallback(() => {
    setSavedGifts(loadSavedGifts());
  }, []);

  useEffect(() => {
    refresh();
    const onStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY && e.newValue != null) {
        try {
          const next = JSON.parse(e.newValue);
          if (Array.isArray(next)) setSavedGifts(next);
        } catch {
          // ignore
        }
      }
    };
    const onVisibility = () => {
      if (document.visibilityState === "visible") setSavedGifts(loadSavedGifts());
    };
    window.addEventListener("storage", onStorage);
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      window.removeEventListener("storage", onStorage);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [refresh]);

  const addSavedGift = useCallback((gift: GiftSuggestion) => {
    const key = normalizeKey(gift);
    setSavedGifts((prev) => {
      if (prev.some((g) => normalizeKey(g) === key)) return prev;
      const next: SavedGift[] = [...prev, { ...gift, purchased: false }];
      persistSavedGifts(next);
      return next;
    });
  }, []);

  const removeSavedGift = useCallback((gift: GiftSuggestion) => {
    const key = normalizeKey(gift);
    setSavedGifts((prev) => {
      const next = prev.filter((g) => normalizeKey(g) !== key);
      persistSavedGifts(next);
      return next;
    });
  }, []);

  const toggleSavedGift = useCallback((gift: GiftSuggestion) => {
    const key = normalizeKey(gift);
    setSavedGifts((prev) => {
      const has = prev.some((g) => normalizeKey(g) === key);
      const next: SavedGift[] = has
        ? prev.filter((g) => normalizeKey(g) !== key)
        : [...prev, { ...gift, purchased: false }];
      persistSavedGifts(next);
      return next;
    });
  }, []);

  /** Mark a gift as purchased so it won't be recommended again. Saves the gift if not already saved. */
  const markAsPurchased = useCallback((gift: GiftSuggestion) => {
    const key = normalizeKey(gift);
    setSavedGifts((prev) => {
      const existing = prev.find((g) => normalizeKey(g) === key);
      const next: SavedGift[] = existing
        ? prev.map((g) => (normalizeKey(g) === key ? { ...g, purchased: true } : g))
        : [...prev, { ...gift, purchased: true }];
      persistSavedGifts(next);
      return next;
    });
  }, []);

  /** Clear purchased status so the gift can be recommended again. */
  const unmarkAsPurchased = useCallback((gift: GiftSuggestion) => {
    const key = normalizeKey(gift);
    setSavedGifts((prev) => {
      const next: SavedGift[] = prev.map((g) =>
        normalizeKey(g) === key ? { ...g, purchased: false } : g
      );
      persistSavedGifts(next);
      return next;
    });
  }, []);

  const isSaved = useCallback(
    (gift: GiftSuggestion) => savedGifts.some((g) => normalizeKey(g) === normalizeKey(gift)),
    [savedGifts]
  );

  const isPurchased = useCallback(
    (gift: GiftSuggestion) =>
      savedGifts.some((g) => normalizeKey(g) === normalizeKey(gift) && (g as SavedGift).purchased),
    [savedGifts]
  );

  /** Names of purchased gifts to send to the API so they are not recommended again. */
  const purchasedGiftNames = savedGifts
    .filter((g) => (g as SavedGift).purchased)
    .map((g) => g.name);

  return {
    savedGifts,
    addSavedGift,
    removeSavedGift,
    toggleSavedGift,
    markAsPurchased,
    unmarkAsPurchased,
    isSaved,
    isPurchased,
    purchasedGiftNames,
    refresh,
  };
}
