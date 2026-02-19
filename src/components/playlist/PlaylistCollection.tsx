import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Music,
  Plus,
  Trash2,
  X,
  Calendar,
  ListMusic,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { SavedPlaylist, PlaylistSong, usePlaylistStorage } from "@/hooks/usePlaylistStorage";
import SongSearchInput from "./SongSearchInput";

// Platform URL generators (works with or without artist - YouTube style)
const platformUrls = {
  spotify: (title: string, artist?: string) =>
    `https://open.spotify.com/search/${encodeURIComponent(artist ? `${title} ${artist}` : title)}`,
  apple: (title: string, artist?: string) =>
    `https://music.apple.com/search?term=${encodeURIComponent(artist ? `${title} ${artist}` : title)}`,
  youtube: (title: string, artist?: string) =>
    `https://music.youtube.com/search?q=${encodeURIComponent(artist ? `${title} ${artist}` : title)}`,
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

const vibeEmojis: Record<string, string> = {
  romantic: "💕",
  upbeat: "🎉",
  chill: "🌙",
  adventurous: "✨",
  jazzy: "🎷",
  indie: "🎸",
  classic: "🎻",
  rnb: "🎤",
};

interface PlaylistCollectionProps {
  onCreateNew?: () => void;
}

const PlaylistCollection = ({ onCreateNew }: PlaylistCollectionProps) => {
  const { playlists, deletePlaylist, addSongToPlaylist, removeSongFromPlaylist } = usePlaylistStorage();
  const { toast } = useToast();
  
  const [selectedPlaylist, setSelectedPlaylist] = useState<SavedPlaylist | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [showAddSong, setShowAddSong] = useState(false);

  const handleDeletePlaylist = (id: string) => {
    deletePlaylist(id);
    setDeleteConfirmId(null);
    if (selectedPlaylist?.id === id) {
      setSelectedPlaylist(null);
    }
    toast({ title: "Playlist deleted" });
  };

  const handleAddSong = (song: { title: string; artist: string }) => {
    if (!selectedPlaylist) return;

    addSongToPlaylist(selectedPlaylist.id, {
      title: song.title,
      artist: song.artist || "",
      isCustom: true,
    });

    // Update local state
    setSelectedPlaylist(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        songs: [
          ...prev.songs,
          {
            id: `temp-${Date.now()}`,
            title: song.title,
            artist: song.artist || "",
            isCustom: true,
            addedAt: new Date().toISOString(),
          },
        ],
      };
    });

    setShowAddSong(false);
    toast({ title: "Song added! 🎵" });
  };

  const handleRemoveSong = (songId: string) => {
    if (!selectedPlaylist) return;
    
    removeSongFromPlaylist(selectedPlaylist.id, songId);
    setSelectedPlaylist(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        songs: prev.songs.filter(s => s.id !== songId),
      };
    });
    toast({ title: "Song removed" });
  };

  const openSong = (song: PlaylistSong, platform: "spotify" | "apple" | "youtube") => {
    window.open(platformUrls[platform](song.title, song.artist || undefined), "_blank");
  };

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  };

  // Empty state
  if (playlists.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center bg-muted/50 rounded-lg p-8 sm:p-12 gap-4 min-h-[300px]">
        <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center">
          <Music className="w-8 h-8 text-primary" />
        </div>
        <div className="text-center">
          <h3 className="font-display text-xl mb-2">No Playlists Yet</h3>
          <p className="text-muted-foreground text-sm max-w-sm">
            Create a playlist from your date plans to save and listen to your perfect date night music.
          </p>
        </div>
        {onCreateNew && (
          <Button onClick={onCreateNew} className="gradient-gold text-primary-foreground mt-2">
            <Plus className="w-4 h-4 mr-2" />
            Create First Playlist
          </Button>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-display text-xl sm:text-2xl">Your Playlists</h2>
          <p className="text-sm text-muted-foreground">
            {playlists.length} playlist{playlists.length !== 1 ? "s" : ""} saved
          </p>
        </div>
      </div>

      {/* Playlist grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {playlists.map((playlist) => (
          <Card
            key={playlist.id}
            className="cursor-pointer hover:border-primary/50 transition-colors group"
            onClick={() => setSelectedPlaylist(playlist)}
          >
            <CardHeader className="pb-2">
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <CardTitle className="text-base truncate flex items-center gap-2">
                    <span>{vibeEmojis[playlist.vibe] || "🎵"}</span>
                    {playlist.name}
                  </CardTitle>
                  <CardDescription className="text-xs truncate mt-1">
                    From: {playlist.datePlanTitle}
                  </CardDescription>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
                  onClick={(e) => {
                    e.stopPropagation();
                    setDeleteConfirmId(playlist.id);
                  }}
                >
                  <Trash2 className="w-4 h-4 text-destructive" />
                </Button>
              </div>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span className="flex items-center gap-1">
                  <ListMusic className="w-3 h-3" />
                  {playlist.songs.length} songs
                </span>
                <span className="flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  {formatDate(playlist.createdAt)}
                </span>
              </div>
              <Badge variant="secondary" className="mt-2 text-xs capitalize">
                {playlist.vibe}
              </Badge>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Playlist detail dialog */}
      <Dialog open={!!selectedPlaylist} onOpenChange={(open) => !open && setSelectedPlaylist(null)}>
        <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-hidden flex flex-col p-0">
          <DialogHeader className="px-4 sm:px-6 pt-4 sm:pt-6 pb-2">
            <DialogTitle className="font-display text-xl flex items-center gap-2">
              <span>{vibeEmojis[selectedPlaylist?.vibe || ""] || "🎵"}</span>
              {selectedPlaylist?.name}
            </DialogTitle>
            <DialogDescription>
              {selectedPlaylist?.songs.length} songs • {selectedPlaylist?.vibe} vibe
            </DialogDescription>
          </DialogHeader>

          <div className="flex-1 overflow-y-auto px-4 sm:px-6 pb-4">
            {/* Add song section */}
            <div className="mb-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowAddSong(!showAddSong)}
                className="gap-2"
              >
                {showAddSong ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
                {showAddSong ? "Cancel" : "Add Song"}
              </Button>
              
              {showAddSong && (
                <div className="mt-3 bg-muted/50 rounded-lg p-3 border border-border">
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
            </div>

            {/* Song list */}
            <div className="space-y-2">
              {selectedPlaylist?.songs.map((song, index) => (
                <div
                  key={song.id}
                  className="flex items-center justify-between p-2.5 rounded-lg bg-muted/50 hover:bg-muted transition-colors group"
                >
                  <div className="flex items-center gap-3 flex-1 min-w-0">
                    <span className="text-xs text-muted-foreground w-5 text-right shrink-0">
                      {index + 1}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-sm truncate flex items-center gap-2">
                        {song.title}
                        {song.isCustom && (
                          <Badge variant="outline" className="text-[10px] px-1 py-0">
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
                      onClick={() => handleRemoveSong(song.id)}
                      title="Remove song"
                    >
                      <X className="w-3.5 h-3.5" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <DialogFooter className="px-4 sm:px-6 pb-4 sm:pb-6 pt-2 border-t">
            <Button variant="outline" onClick={() => setSelectedPlaylist(null)}>
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <AlertDialog open={!!deleteConfirmId} onOpenChange={(open) => !open && setDeleteConfirmId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Playlist?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. The playlist will be permanently deleted.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleteConfirmId && handleDeletePlaylist(deleteConfirmId)}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default PlaylistCollection;
