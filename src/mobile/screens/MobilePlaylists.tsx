import { useState } from "react";
import { ExternalLink, Heart, Clock, Trash2 } from "lucide-react";
import { usePlaylistStorage, SavedPlaylist, PlaylistSong } from "@/hooks/usePlaylistStorage";
import MusicRecordAnimation from "@/components/playlist/MusicRecordAnimation";

// ── Vibe → gradient / emoji maps (aligned with PlaylistCollection vibes) ──────
const VIBE_COLORS: Record<string, string> = {
  romantic:    "from-rose-500/20 to-pink-500/20",
  upbeat:      "from-amber-500/20 to-orange-500/20",
  chill:       "from-blue-500/20 to-cyan-500/20",
  adventurous: "from-green-500/20 to-emerald-500/20",
  jazzy:       "from-yellow-500/20 to-amber-500/20",
  indie:       "from-violet-500/20 to-purple-500/20",
  classic:     "from-stone-500/20 to-slate-500/20",
  rnb:         "from-pink-500/20 to-fuchsia-500/20",
  latin:       "from-lime-500/20 to-green-500/20",
  afrobeats:   "from-orange-500/20 to-red-500/20",
  kpop:        "from-purple-500/20 to-pink-500/20",
  reggae:      "from-teal-500/20 to-cyan-500/20",
  country:     "from-orange-400/20 to-amber-400/20",
  metal:       "from-zinc-500/20 to-slate-500/20",
  classical:   "from-sky-500/20 to-blue-500/20",
  folk:        "from-green-400/20 to-lime-400/20",
  hiphop:      "from-red-500/20 to-orange-500/20",
  electronic:  "from-cyan-500/20 to-violet-500/20",
};

const VIBE_EMOJIS: Record<string, string> = {
  romantic:    "💕",
  upbeat:      "🎉",
  chill:       "🌙",
  adventurous: "✨",
  jazzy:       "🎷",
  indie:       "🎸",
  classic:     "🎻",
  rnb:         "🎤",
  latin:       "🌴",
  afrobeats:   "🔥",
  kpop:        "💜",
  reggae:      "🎵",
  country:     "🤠",
  metal:       "🤘",
  classical:   "🎼",
  folk:        "🌾",
  hiphop:      "🎤",
  electronic:  "⚡",
};

const getVibeColor = (vibe: string) =>
  VIBE_COLORS[(vibe ?? "").toLowerCase()] ?? "from-primary/20 to-primary/10";

const getVibeEmoji = (vibe: string) =>
  VIBE_EMOJIS[(vibe ?? "").toLowerCase()] ?? "🎵";

// ── Component ─────────────────────────────────────────────────────────────────

const MobilePlaylists = () => {
  const { playlists, deletePlaylist } = usePlaylistStorage();
  const [selectedPlaylist, setSelectedPlaylist] = useState<SavedPlaylist | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<string | null>(null);

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
            <div className="flex justify-center mb-4">
              <MusicRecordAnimation size={80} showNotes />
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
                className={`rounded-2xl p-4 bg-gradient-to-br ${getVibeColor(playlist.vibe)} text-left haptic-button transition-transform active:scale-95`}
              >
                <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur flex items-center justify-center mb-3">
                  <span className="text-2xl">{getVibeEmoji(playlist.vibe)}</span>
                </div>
                <h3 className="font-semibold truncate mb-1">{playlist.name}</h3>
                <p className="text-xs text-muted-foreground capitalize">
                  {playlist.songs?.length || 0} songs • {playlist.vibe}
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
              <div
                className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${getVibeColor(selectedPlaylist.vibe)} flex items-center justify-center shrink-0`}
              >
                <span className="text-4xl">{getVibeEmoji(selectedPlaylist.vibe)}</span>
              </div>
              <div className="flex-1 min-w-0">
                <h2 className="text-xl font-bold truncate">{selectedPlaylist.name}</h2>
                <p className="text-sm text-muted-foreground mb-2 capitalize">
                  {selectedPlaylist.songs?.length || 0} songs • {selectedPlaylist.vibe} vibe
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
                  <SongRow key={song.id} song={song} index={index + 1} />
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

// ── Song row ──────────────────────────────────────────────────────────────────

interface SongRowProps {
  song: PlaylistSong;
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

      <button onClick={() => setLiked(!liked)} className="p-2 haptic-button">
        <Heart
          className={`w-4 h-4 ${liked ? "fill-rose-500 text-rose-500" : "text-muted-foreground"}`}
        />
      </button>
    </div>
  );
};

export default MobilePlaylists;
