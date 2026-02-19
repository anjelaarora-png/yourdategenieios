import { useState } from "react";
import { Music, Plus, Play, Pause, ExternalLink, Heart, MoreHorizontal, Clock, Trash2 } from "lucide-react";
import { usePlaylistStorage } from "@/hooks/usePlaylistStorage";

interface Playlist {
  id: string;
  name: string;
  mood: string;
  songs: {
    title: string;
    artist: string;
    spotifyUrl?: string;
    duration?: string;
  }[];
  createdAt: string;
  coverEmoji?: string;
}

const MobilePlaylists = () => {
  const { playlists, deletePlaylist } = usePlaylistStorage();
  const [selectedPlaylist, setSelectedPlaylist] = useState<Playlist | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<string | null>(null);

  const getMoodColor = (mood: string) => {
    const colors: Record<string, string> = {
      romantic: "from-rose-500/20 to-pink-500/20",
      chill: "from-blue-500/20 to-cyan-500/20",
      energetic: "from-amber-500/20 to-orange-500/20",
      adventure: "from-green-500/20 to-emerald-500/20",
      cozy: "from-purple-500/20 to-violet-500/20",
    };
    return colors[mood.toLowerCase()] || "from-primary/20 to-primary/10";
  };

  const getMoodEmoji = (mood: string) => {
    const emojis: Record<string, string> = {
      romantic: "💕",
      chill: "🌊",
      energetic: "⚡",
      adventure: "🚀",
      cozy: "☕",
    };
    return emojis[mood.toLowerCase()] || "🎵";
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="px-5 pt-14 pb-4">
        <h1 className="large-title mb-1">Your Playlists</h1>
        <p className="text-muted-foreground">Music for every date mood</p>
      </div>

      {/* Playlists grid */}
      <div className="px-5">
        {playlists.length === 0 ? (
          <div className="ios-card text-center py-12">
            <div className="w-16 h-16 rounded-full bg-muted mx-auto mb-4 flex items-center justify-center">
              <Music className="w-8 h-8 text-muted-foreground" />
            </div>
            <p className="text-muted-foreground mb-2">No playlists yet</p>
            <p className="text-sm text-muted-foreground">
              Generate a date plan to get a curated playlist
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            {playlists.map((playlist) => (
              <button
                key={playlist.id}
                onClick={() => setSelectedPlaylist(playlist)}
                className={`rounded-2xl p-4 bg-gradient-to-br ${getMoodColor(playlist.mood)} text-left haptic-button transition-transform active:scale-95`}
              >
                <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur flex items-center justify-center mb-3">
                  <span className="text-2xl">{playlist.coverEmoji || getMoodEmoji(playlist.mood)}</span>
                </div>
                <h3 className="font-semibold truncate mb-1">{playlist.name}</h3>
                <p className="text-xs text-muted-foreground">
                  {playlist.songs?.length || 0} songs • {playlist.mood}
                </p>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Playlist detail sheet */}
      {selectedPlaylist && (
        <>
          <div className="ios-sheet-backdrop" onClick={() => setSelectedPlaylist(null)} />
          <div className="ios-sheet max-h-[85vh] overflow-hidden flex flex-col">
            <div className="swipe-indicator" />

            {/* Playlist header */}
            <div className="flex items-start gap-4 mb-4">
              <div className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${getMoodColor(selectedPlaylist.mood)} flex items-center justify-center shrink-0`}>
                <span className="text-4xl">
                  {selectedPlaylist.coverEmoji || getMoodEmoji(selectedPlaylist.mood)}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <h2 className="text-xl font-bold truncate">{selectedPlaylist.name}</h2>
                <p className="text-sm text-muted-foreground mb-2">
                  {selectedPlaylist.songs?.length || 0} songs • {selectedPlaylist.mood} vibe
                </p>
                <div className="flex items-center gap-2">
                  <a
                    href={`https://open.spotify.com/search/${encodeURIComponent(selectedPlaylist.name)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1.5 text-xs bg-[#1DB954] text-white px-3 py-1.5 rounded-full font-medium"
                  >
                    <ExternalLink className="w-3 h-3" />
                    Open in Spotify
                  </a>
                  <button
                    onClick={() => setShowDeleteConfirm(selectedPlaylist.id)}
                    className="p-2 text-muted-foreground hover:text-red-500 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>

            {/* Songs list */}
            <div className="overflow-y-auto flex-1 -mx-4 px-4">
              <div className="space-y-1">
                {selectedPlaylist.songs?.map((song, index) => (
                  <SongRow key={index} song={song} index={index + 1} />
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      {/* Delete confirmation */}
      {showDeleteConfirm && (
        <>
          <div className="ios-sheet-backdrop" onClick={() => setShowDeleteConfirm(null)} />
          <div className="ios-sheet text-center">
            <div className="swipe-indicator" />
            <h3 className="text-lg font-semibold mb-2">Delete Playlist?</h3>
            <p className="text-muted-foreground text-sm mb-6">
              This action cannot be undone.
            </p>
            <div className="space-y-3">
              <button
                onClick={() => {
                  deletePlaylist(showDeleteConfirm);
                  setShowDeleteConfirm(null);
                  setSelectedPlaylist(null);
                }}
                className="ios-button w-full bg-red-500 text-white"
              >
                Delete Playlist
              </button>
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="ios-button ios-button-secondary w-full"
              >
                Cancel
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

interface SongRowProps {
  song: {
    title: string;
    artist: string;
    spotifyUrl?: string;
    duration?: string;
  };
  index: number;
}

const SongRow = ({ song, index }: SongRowProps) => {
  const [liked, setLiked] = useState(false);

  return (
    <div className="flex items-center gap-3 p-3 rounded-xl hover:bg-muted/50 transition-colors">
      <span className="w-6 text-center text-sm text-muted-foreground">{index}</span>

      <div className="flex-1 min-w-0">
        <p className="font-medium truncate">{song.title}</p>
        <p className="text-sm text-muted-foreground truncate">{song.artist}</p>
      </div>

      {song.duration && (
        <span className="text-xs text-muted-foreground flex items-center gap-1">
          <Clock className="w-3 h-3" />
          {song.duration}
        </span>
      )}

      <button
        onClick={() => setLiked(!liked)}
        className="p-2 haptic-button"
      >
        <Heart className={`w-4 h-4 ${liked ? "fill-rose-500 text-rose-500" : "text-muted-foreground"}`} />
      </button>

      {song.spotifyUrl && (
        <a
          href={song.spotifyUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="p-2 text-[#1DB954]"
        >
          <ExternalLink className="w-4 h-4" />
        </a>
      )}
    </div>
  );
};

export default MobilePlaylists;
