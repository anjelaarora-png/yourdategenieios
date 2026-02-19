import { useState, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { Music, Play, Loader2, Check, Copy, RefreshCw, Clock, Plus, Save, X } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { DatePlan } from "@/types/datePlan";
import { usePlaylistStorage } from "@/hooks/usePlaylistStorage";
import SongSearchInput from "./SongSearchInput";

interface PlaylistWidgetProps {
  datePlan: DatePlan;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

interface SongSuggestion {
  id?: string;
  title: string;
  artist: string;
  year?: number;
  genre?: string;
  isCustom?: boolean;
}

type VibeOption = "romantic" | "upbeat" | "chill" | "adventurous" | "jazzy" | "indie" | "classic" | "rnb";

const vibeOptions: { value: VibeOption; label: string; emoji: string; description: string }[] = [
  { value: "romantic", label: "Romantic", emoji: "💕", description: "Intimate love songs" },
  { value: "upbeat", label: "Upbeat", emoji: "🎉", description: "Dance & party hits" },
  { value: "chill", label: "Chill", emoji: "🌙", description: "Lo-fi & relaxed" },
  { value: "adventurous", label: "Eclectic", emoji: "✨", description: "Genre-bending" },
  { value: "jazzy", label: "Jazzy", emoji: "🎷", description: "Smooth jazz & soul" },
  { value: "indie", label: "Indie", emoji: "🎸", description: "Alternative vibes" },
  { value: "classic", label: "Classic", emoji: "🎻", description: "Timeless standards" },
  { value: "rnb", label: "R&B", emoji: "🎤", description: "Modern R&B" },
];

type Platform = "spotify" | "apple" | "youtube";

const platformConfig: Record<Platform, { name: string; color: string; searchUrl: (query: string) => string }> = {
  spotify: {
    name: "Spotify",
    color: "bg-[#1DB954]",
    searchUrl: (q) => `https://open.spotify.com/search/${encodeURIComponent(q)}`,
  },
  apple: {
    name: "Apple Music",
    color: "bg-[#FC3C44]",
    searchUrl: (q) => `https://music.apple.com/search?term=${encodeURIComponent(q)}`,
  },
  youtube: {
    name: "YouTube Music",
    color: "bg-[#FF0000]",
    searchUrl: (q) => `https://music.youtube.com/search?q=${encodeURIComponent(q)}`,
  },
};

const GENERATE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/generate-playlist`;

const PlaylistWidget = ({ datePlan, open, onOpenChange }: PlaylistWidgetProps) => {
  const [vibe, setVibe] = useState<VibeOption>("romantic");
  const [isGenerating, setIsGenerating] = useState(false);
  const [songs, setSongs] = useState<SongSuggestion[]>([]);
  const [generated, setGenerated] = useState(false);
  const [isOpeningAll, setIsOpeningAll] = useState(false);
  const [openingProgress, setOpeningProgress] = useState(0);
  const [isSaved, setIsSaved] = useState(false);
  const [showAddSong, setShowAddSong] = useState(false);
  const { toast } = useToast();
  const { savePlaylist } = usePlaylistStorage();

  const handleGenerate = async () => {
    setIsGenerating(true);
    setIsSaved(false); // Reset saved state on new generation
    try {
      const response = await fetch(GENERATE_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY}`,
        },
        body: JSON.stringify({
          vibe,
          datePlanTitle: datePlan.title,
          stops: (datePlan.stops ?? []).map((s) => ({
            name: s.name,
            venueType: s.venueType,
          })),
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to generate playlist");
      }

      const data = await response.json();
      // Add unique IDs to songs
      const songsWithIds = (data.songs || []).map((song: SongSuggestion, i: number) => ({
        ...song,
        id: `gen-${Date.now()}-${i}`,
      }));
      setSongs(songsWithIds);
      setGenerated(true);
      toast({
        title: "Playlist created! 🎵",
        description: `${songsWithIds.length} songs curated for your ${vibe} date.`,
      });
    } catch (error) {
      toast({
        title: "Oops!",
        description: "Couldn't generate playlist. Try again.",
        variant: "destructive",
      });
    } finally {
      setIsGenerating(false);
    }
  };

  // Regenerate with same vibe
  const handleRegenerate = async () => {
    setIsSaved(false);
    await handleGenerate();
  };

  // Save playlist to storage
  const handleSavePlaylist = () => {
    const vibeLabel = vibeOptions.find(v => v.value === vibe)?.label || vibe;
    const playlistName = `${vibeLabel} Playlist`;
    
    savePlaylist(playlistName, datePlan.title, vibe, songs);
    setIsSaved(true);
    toast({
      title: "Playlist saved! 💾",
      description: "Find it in your Music tab on the dashboard.",
    });
  };

  // Add custom song from search
  const handleAddSong = (song: { title: string; artist: string }) => {
    const newSong: SongSuggestion = {
      id: `custom-${Date.now()}`,
      title: song.title,
      artist: song.artist || "",
      isCustom: true,
    };

    setSongs(prev => [...prev, newSong]);
    setShowAddSong(false);
    setIsSaved(false); // Mark as unsaved since we added a new song
    toast({ title: "Song added! 🎵" });
  };

  // Remove a song
  const handleRemoveSong = (songId: string) => {
    setSongs(prev => prev.filter(s => s.id !== songId));
    setIsSaved(false); // Mark as unsaved
  };

  // Open a single song on a platform (works with or without artist)
  const openSong = (song: SongSuggestion, platform: Platform) => {
    // If no artist, just search by title (YouTube style)
    const query = song.artist ? `${song.title} ${song.artist}` : song.title;
    window.open(platformConfig[platform].searchUrl(query), "_blank");
  };

  // Open all songs on a platform with proper delays to avoid popup blockers
  const openAllOnPlatform = useCallback(async (platform: Platform) => {
    if (songs.length === 0) return;
    
    setIsOpeningAll(true);
    setOpeningProgress(0);
    
    const config = platformConfig[platform];
    
    // Strategy: Open songs in batches with delays
    // Browsers typically allow the first popup from a user action
    // Subsequent popups may be blocked, so we open in batches
    
    const batchSize = 3;
    const delayBetweenBatches = 800; // ms
    
    for (let i = 0; i < songs.length; i += batchSize) {
      const batch = songs.slice(i, Math.min(i + batchSize, songs.length));
      
      // Open each song in the batch
      batch.forEach((song, index) => {
        setTimeout(() => {
          // Handle songs with or without artist (YouTube style)
          const query = song.artist ? `${song.title} ${song.artist}` : song.title;
          window.open(config.searchUrl(query), "_blank");
          setOpeningProgress(Math.min(i + index + 1, songs.length));
        }, index * 200); // Small delay between items in batch
      });
      
      // Wait before opening next batch
      if (i + batchSize < songs.length) {
        await new Promise(resolve => setTimeout(resolve, delayBetweenBatches + (batchSize * 200)));
      }
    }
    
    // Final delay and toast
    setTimeout(() => {
      setIsOpeningAll(false);
      toast({
        title: `Opened on ${config.name}! 🎵`,
        description: `${songs.length} songs opened. Add them to your playlist!`,
      });
    }, 500);
  }, [songs, toast]);

  // Copy playlist as text
  const copyPlaylist = useCallback(() => {
    const text = songs
      .map((s, i) => `${i + 1}. ${s.title} - ${s.artist}${s.year ? ` (${s.year})` : ""}`)
      .join("\n");
    
    navigator.clipboard.writeText(`Date Night Playlist: ${datePlan.title}\n\n${text}`);
    toast({
      title: "Copied! 📋",
      description: "Playlist copied to clipboard.",
    });
  }, [songs, datePlan.title, toast]);

  const handleClose = () => {
    onOpenChange(false);
    setSongs([]);
    setGenerated(false);
    setIsOpeningAll(false);
  };

  // Platform icons
  const SpotifyIcon = () => (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z"/>
    </svg>
  );

  const AppleMusicIcon = () => (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
      <path d="M23.994 6.124a9.23 9.23 0 00-.24-2.19c-.317-1.31-1.062-2.31-2.18-3.043a5.022 5.022 0 00-1.877-.726 10.496 10.496 0 00-1.564-.15c-.04-.003-.083-.01-.124-.013H5.986c-.152.01-.303.017-.455.026-.747.043-1.49.123-2.193.4-1.336.53-2.3 1.452-2.865 2.78-.192.448-.292.925-.363 1.408-.056.392-.088.785-.1 1.18 0 .032-.007.062-.01.093v12.223c.01.14.017.283.027.424.05.815.154 1.624.497 2.373.65 1.42 1.738 2.353 3.234 2.801.42.127.856.187 1.293.228.555.053 1.11.06 1.667.06h11.03c.525 0 1.048-.034 1.57-.1.823-.106 1.597-.35 2.296-.81.84-.553 1.472-1.287 1.88-2.208.186-.42.293-.87.37-1.324.113-.675.138-1.358.137-2.04-.002-3.8 0-7.595-.003-11.393zm-6.423 3.99v5.712c0 .417-.058.827-.244 1.206-.29.59-.763.962-1.388 1.14-.35.1-.706.157-1.07.173-.95.042-1.785-.36-2.155-1.247-.267-.64-.263-1.318.045-1.94.327-.66.882-1.057 1.58-1.208.35-.076.708-.116 1.062-.152.36-.038.716-.096 1.056-.213.232-.08.378-.238.395-.5.01-.156.018-.313.018-.47V6.48c0-.393-.12-.523-.507-.453-.39.07-.778.154-1.168.228-1.336.255-2.67.508-4.006.764-.09.018-.177.045-.262.082-.12.052-.167.15-.17.277-.01.3-.012.603-.012.904v6.785c0 .263-.01.527-.062.787-.118.565-.396 1.024-.884 1.343-.354.232-.75.364-1.17.408-.728.077-1.418.017-2.02-.45-.457-.354-.71-.82-.774-1.382-.094-.83.12-1.573.817-2.117.42-.328.91-.493 1.44-.565.396-.054.795-.083 1.185-.16.312-.06.563-.203.668-.536.05-.155.07-.322.07-.487V5.672c0-.395.124-.57.51-.654 1.254-.27 2.507-.534 3.76-.8l3.043-.643c.246-.052.495-.095.746-.127.374-.047.557.1.574.492.01.24.006.48.006.72v5.454l-.001-.001z"/>
    </svg>
  );

  const YouTubeMusicIcon = () => (
    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0C5.376 0 0 5.376 0 12s5.376 12 12 12 12-5.376 12-12S18.624 0 12 0zm0 19.104c-3.924 0-7.104-3.18-7.104-7.104S8.076 4.896 12 4.896s7.104 3.18 7.104 7.104-3.18 7.104-7.104 7.104zm0-13.332c-3.432 0-6.228 2.796-6.228 6.228S8.568 18.228 12 18.228s6.228-2.796 6.228-6.228S15.432 5.772 12 5.772zM9.684 15.54V8.46L15.816 12l-6.132 3.54z"/>
    </svg>
  );

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-hidden flex flex-col p-0">
        <DialogHeader className="px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
          <DialogTitle className="font-display text-xl sm:text-2xl flex items-center gap-2">
            <Music className="w-5 h-5 sm:w-6 sm:h-6 text-primary" />
            Date Night Playlist
          </DialogTitle>
          <DialogDescription className="text-sm">
            Create a perfect playlist for "{datePlan.title}"
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto px-4 sm:px-6 pb-4 sm:pb-6">
          {!generated ? (
            <div className="space-y-5 py-2">
              <div className="space-y-3">
                <label className="text-sm font-medium">Choose your vibe:</label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {vibeOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => setVibe(option.value)}
                      className={`p-3 sm:p-4 rounded-lg border text-left transition-all ${
                        vibe === option.value
                          ? "border-primary bg-primary/10 ring-1 ring-primary"
                          : "border-border hover:border-primary/50"
                      }`}
                    >
                      <div className="text-xl sm:text-2xl mb-1">{option.emoji}</div>
                      <div className="font-medium text-sm">{option.label}</div>
                      <div className="text-xs text-muted-foreground hidden sm:block">{option.description}</div>
                    </button>
                  ))}
                </div>
              </div>

              <Button
                onClick={handleGenerate}
                disabled={isGenerating}
                className="w-full gradient-gold text-primary-foreground py-6 text-base"
              >
                {isGenerating ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Curating {vibeOptions.find(v => v.value === vibe)?.label} songs...
                  </>
                ) : (
                  <>
                    <Play className="w-5 h-5 mr-2" />
                    Generate Playlist
                  </>
                )}
              </Button>
            </div>
          ) : (
            <div className="space-y-4 py-2">
              {/* Header with song count and actions */}
              <div className="flex items-center justify-between flex-wrap gap-2">
                <div className="flex items-center gap-2">
                  <Check className="w-4 h-4 text-green-500" />
                  <span className="text-sm font-medium">{songs.length} songs</span>
                  <Badge variant="secondary" className="text-xs">
                    {vibeOptions.find(v => v.value === vibe)?.emoji} {vibeOptions.find(v => v.value === vibe)?.label}
                  </Badge>
                  {isSaved && (
                    <Badge variant="outline" className="text-xs text-green-600 border-green-300">
                      Saved
                    </Badge>
                  )}
                </div>
                <div className="flex gap-1">
                  <Button variant="ghost" size="sm" onClick={() => setShowAddSong(!showAddSong)} className="gap-1.5 h-8" title="Add custom song">
                    {showAddSong ? <X className="w-3.5 h-3.5" /> : <Plus className="w-3.5 h-3.5" />}
                    <span className="hidden sm:inline">{showAddSong ? "Cancel" : "Add"}</span>
                  </Button>
                  <Button variant="ghost" size="sm" onClick={copyPlaylist} className="gap-1.5 h-8">
                    <Copy className="w-3.5 h-3.5" />
                    <span className="hidden sm:inline">Copy</span>
                  </Button>
                </div>
              </div>

              {/* Inline song search */}
              {showAddSong && (
                <div className="bg-muted/50 rounded-lg p-3 border border-border">
                  <SongSearchInput
                    onSelectSong={handleAddSong}
                    placeholder="Search for a song to add..."
                    autoFocus
                  />
                  <p className="text-xs text-muted-foreground mt-2 text-center">
                    Type to search • Use ↑↓ to navigate • Press Enter to select
                  </p>
                </div>
              )}

              {/* Song list */}
              <div className="space-y-1.5 max-h-[250px] overflow-y-auto pr-1">
                {songs.map((song, index) => (
                  <div
                    key={song.id || index}
                    className="flex items-center justify-between p-2.5 sm:p-3 rounded-lg bg-muted/50 hover:bg-muted transition-colors group"
                  >
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <span className="text-xs text-muted-foreground w-5 text-right shrink-0">
                        {index + 1}
                      </span>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-sm truncate flex items-center gap-2">
                          {song.title}
                          {song.isCustom && (
                            <Badge variant="outline" className="text-[10px] px-1 py-0 shrink-0">
                              Custom
                            </Badge>
                          )}
                        </p>
                        <p className="text-xs text-muted-foreground truncate">
                          {song.artist || <span className="italic">Search by title</span>}
                          {song.year && <span className="ml-1">({song.year})</span>}
                        </p>
                      </div>
                    </div>
                    <div className="flex gap-0.5 shrink-0 items-center">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 hover:bg-[#1DB954]/10 hover:text-[#1DB954]"
                        onClick={() => openSong(song, "spotify")}
                        title="Open in Spotify"
                      >
                        <SpotifyIcon />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 hover:bg-[#FC3C44]/10 hover:text-[#FC3C44]"
                        onClick={() => openSong(song, "apple")}
                        title="Open in Apple Music"
                      >
                        <AppleMusicIcon />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 hover:bg-[#FF0000]/10 hover:text-[#FF0000]"
                        onClick={() => openSong(song, "youtube")}
                        title="Open in YouTube Music"
                      >
                        <YouTubeMusicIcon />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 opacity-0 group-hover:opacity-100 transition-opacity text-muted-foreground hover:text-destructive"
                        onClick={() => song.id && handleRemoveSong(song.id)}
                        title="Remove song"
                      >
                        <X className="w-3.5 h-3.5" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>

              {/* Open all on platform */}
              <div className="border-t border-border pt-4 space-y-3">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium">Open all songs on:</p>
                  {isOpeningAll && (
                    <span className="text-xs text-muted-foreground flex items-center gap-1.5">
                      <Clock className="w-3 h-3 animate-pulse" />
                      Opening {openingProgress}/{songs.length}...
                    </span>
                  )}
                </div>
                
                <div className="grid grid-cols-3 gap-2">
                  <Button 
                    variant="outline" 
                    className="gap-1.5 text-xs sm:text-sm h-10 sm:h-11 hover:bg-[#1DB954]/10 hover:border-[#1DB954]/50 hover:text-[#1DB954]" 
                    onClick={() => openAllOnPlatform("spotify")}
                    disabled={isOpeningAll}
                  >
                    <SpotifyIcon />
                    <span className="hidden xs:inline">Spotify</span>
                  </Button>
                  <Button 
                    variant="outline" 
                    className="gap-1.5 text-xs sm:text-sm h-10 sm:h-11 hover:bg-[#FC3C44]/10 hover:border-[#FC3C44]/50 hover:text-[#FC3C44]" 
                    onClick={() => openAllOnPlatform("apple")}
                    disabled={isOpeningAll}
                  >
                    <AppleMusicIcon />
                    <span className="hidden xs:inline">Apple</span>
                  </Button>
                  <Button 
                    variant="outline" 
                    className="gap-1.5 text-xs sm:text-sm h-10 sm:h-11 hover:bg-[#FF0000]/10 hover:border-[#FF0000]/50 hover:text-[#FF0000]" 
                    onClick={() => openAllOnPlatform("youtube")}
                    disabled={isOpeningAll}
                  >
                    <YouTubeMusicIcon />
                    <span className="hidden xs:inline">YouTube</span>
                  </Button>
                </div>

                <p className="text-xs text-muted-foreground text-center">
                  Songs will open one by one. Add them to a playlist on your chosen platform.
                </p>
              </div>

              {/* Action buttons */}
              <div className="flex flex-col gap-2 pt-2">
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    className="flex-1 gap-2"
                    onClick={handleRegenerate}
                    disabled={isGenerating}
                  >
                    <RefreshCw className={`w-4 h-4 ${isGenerating ? "animate-spin" : ""}`} />
                    Regenerate
                  </Button>
                  <Button
                    variant="outline"
                    className="flex-1 gap-2"
                    onClick={() => {
                      setGenerated(false);
                      setSongs([]);
                      setIsSaved(false);
                    }}
                  >
                    Change Vibe
                  </Button>
                </div>
                <div className="flex gap-2">
                  {!isSaved && (
                    <Button
                      variant="outline"
                      className="flex-1 gap-2 border-primary/50 text-primary hover:bg-primary/10"
                      onClick={handleSavePlaylist}
                      disabled={songs.length === 0}
                    >
                      <Save className="w-4 h-4" />
                      Save Playlist
                    </Button>
                  )}
                  <Button
                    className={`${isSaved ? "w-full" : "flex-1"} gradient-gold text-primary-foreground`}
                    onClick={handleClose}
                  >
                    Done
                  </Button>
                </div>
              </div>
            </div>
          )}

        </div>
      </DialogContent>
    </Dialog>
  );
};

export default PlaylistWidget;
