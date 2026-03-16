import { useState, useEffect, useCallback, useRef } from "react";

export interface SongResult {
  id: number;
  title: string;
  artist: string;
  album?: string;
  albumArt?: string;
  previewUrl?: string;
}

// iTunes Search API - free, no auth required
const ITUNES_SEARCH_URL = "https://itunes.apple.com/search";

export function useSongSearch(debounceMs = 300) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SongResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  const searchSongs = useCallback(async (searchQuery: string) => {
    if (!searchQuery.trim() || searchQuery.length < 2) {
      setResults([]);
      setIsSearching(false);
      return;
    }

    // Cancel previous request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    abortControllerRef.current = new AbortController();
    setIsSearching(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        term: searchQuery,
        media: "music",
        entity: "song",
        limit: "15",
      });

      const response = await fetch(`${ITUNES_SEARCH_URL}?${params}`, {
        signal: abortControllerRef.current.signal,
      });

      if (!response.ok) {
        throw new Error("Search failed");
      }

      const data = await response.json();

      const songs: SongResult[] = (data.results || []).map((item: any) => ({
        id: item.trackId,
        title: item.trackName,
        artist: item.artistName,
        album: item.collectionName,
        albumArt: item.artworkUrl60?.replace("60x60", "100x100"),
        previewUrl: item.previewUrl,
      }));

      setResults(songs);
    } catch (err: any) {
      if (err.name !== "AbortError") {
        console.error("Song search error:", err);
        setError("Search failed. Try again.");
        setResults([]);
      }
    } finally {
      setIsSearching(false);
    }
  }, []);

  // Debounced search effect
  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    if (!query.trim()) {
      setResults([]);
      return;
    }

    debounceTimerRef.current = setTimeout(() => {
      searchSongs(query);
    }, debounceMs);

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, [query, debounceMs, searchSongs]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, []);

  const clearResults = useCallback(() => {
    setResults([]);
    setQuery("");
  }, []);

  return {
    query,
    setQuery,
    results,
    isSearching,
    error,
    clearResults,
  };
}
