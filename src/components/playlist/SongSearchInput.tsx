import { useState, useRef, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Loader2, Music, Search, X } from "lucide-react";
import { useSongSearch, SongResult } from "@/hooks/useSongSearch";
import { cn } from "@/lib/utils";

interface SongSearchInputProps {
  onSelectSong: (song: { title: string; artist: string }) => void;
  placeholder?: string;
  autoFocus?: boolean;
}

const SongSearchInput = ({ 
  onSelectSong, 
  placeholder = "Search for a song...",
  autoFocus = false,
}: SongSearchInputProps) => {
  const { query, setQuery, results, isSearching, clearResults } = useSongSearch(250);
  const [showResults, setShowResults] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const resultsRef = useRef<HTMLDivElement>(null);

  // Handle clicking outside to close results
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (
        resultsRef.current && 
        !resultsRef.current.contains(e.target as Node) &&
        inputRef.current &&
        !inputRef.current.contains(e.target as Node)
      ) {
        setShowResults(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Show results when we have them
  useEffect(() => {
    if (results.length > 0) {
      setShowResults(true);
      setSelectedIndex(-1);
    }
  }, [results]);

  const handleSelect = (song: SongResult) => {
    onSelectSong({ title: song.title, artist: song.artist });
    setQuery("");
    clearResults();
    setShowResults(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!showResults || results.length === 0) {
      if (e.key === "Enter" && query.trim()) {
        // If no results but user pressed enter, submit as manual entry
        onSelectSong({ title: query.trim(), artist: "" });
        setQuery("");
        clearResults();
      }
      return;
    }

    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        setSelectedIndex(prev => Math.min(prev + 1, results.length - 1));
        break;
      case "ArrowUp":
        e.preventDefault();
        setSelectedIndex(prev => Math.max(prev - 1, -1));
        break;
      case "Enter":
        e.preventDefault();
        if (selectedIndex >= 0 && results[selectedIndex]) {
          handleSelect(results[selectedIndex]);
        } else if (query.trim()) {
          // Submit as manual entry if nothing selected
          onSelectSong({ title: query.trim(), artist: "" });
          setQuery("");
          clearResults();
        }
        break;
      case "Escape":
        setShowResults(false);
        setSelectedIndex(-1);
        break;
    }
  };

  const handleClear = () => {
    setQuery("");
    clearResults();
    setShowResults(false);
    inputRef.current?.focus();
  };

  return (
    <div className="relative">
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <Input
          ref={inputRef}
          type="text"
          placeholder={placeholder}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => results.length > 0 && setShowResults(true)}
          onKeyDown={handleKeyDown}
          autoFocus={autoFocus}
          className="pl-10 pr-10"
        />
        {isSearching ? (
          <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground animate-spin" />
        ) : query && (
          <Button
            variant="ghost"
            size="icon"
            className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7"
            onClick={handleClear}
          >
            <X className="w-3.5 h-3.5" />
          </Button>
        )}
      </div>

      {/* Results dropdown */}
      {showResults && results.length > 0 && (
        <div 
          ref={resultsRef}
          className="absolute z-50 w-full mt-1 bg-popover border border-border rounded-lg shadow-lg overflow-hidden max-h-[280px] overflow-y-auto"
        >
          {results.map((song, index) => (
            <button
              key={song.id}
              onClick={() => handleSelect(song)}
              className={cn(
                "w-full flex items-center gap-3 p-2.5 text-left hover:bg-muted transition-colors",
                selectedIndex === index && "bg-muted"
              )}
            >
              {song.albumArt ? (
                <img 
                  src={song.albumArt} 
                  alt={song.album || song.title}
                  className="w-10 h-10 rounded object-cover shrink-0"
                />
              ) : (
                <div className="w-10 h-10 rounded bg-muted flex items-center justify-center shrink-0">
                  <Music className="w-5 h-5 text-muted-foreground" />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <p className="font-medium text-sm truncate">{song.title}</p>
                <p className="text-xs text-muted-foreground truncate">{song.artist}</p>
              </div>
            </button>
          ))}
          
          {/* Manual entry option */}
          {query.trim() && (
            <button
              onClick={() => {
                onSelectSong({ title: query.trim(), artist: "" });
                setQuery("");
                clearResults();
                setShowResults(false);
              }}
              className={cn(
                "w-full flex items-center gap-3 p-2.5 text-left hover:bg-muted transition-colors border-t border-border",
                selectedIndex === results.length && "bg-muted"
              )}
            >
              <div className="w-10 h-10 rounded bg-primary/10 flex items-center justify-center shrink-0">
                <Search className="w-5 h-5 text-primary" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-medium text-sm truncate">Search for "{query}"</p>
                <p className="text-xs text-muted-foreground">Add without selecting a result</p>
              </div>
            </button>
          )}
        </div>
      )}

      {/* Empty state when searching */}
      {showResults && query.length >= 2 && results.length === 0 && !isSearching && (
        <div className="absolute z-50 w-full mt-1 bg-popover border border-border rounded-lg shadow-lg p-4 text-center">
          <p className="text-sm text-muted-foreground mb-2">No songs found for "{query}"</p>
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => {
              onSelectSong({ title: query.trim(), artist: "" });
              setQuery("");
              clearResults();
              setShowResults(false);
            }}
          >
            Add "{query}" anyway
          </Button>
        </div>
      )}
    </div>
  );
};

export default SongSearchInput;
