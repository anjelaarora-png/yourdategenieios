import { useState, useEffect, useCallback, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "./useAuth";

export interface PlaylistSong {
  id: string;
  title: string;
  artist: string;
  year?: number;
  genre?: string;
  isCustom?: boolean;
  addedAt?: string;
}

export interface PlaylistStop {
  name: string;
  venueType: string;
}

export interface SavedPlaylist {
  id: string;
  name: string;
  datePlanTitle: string;
  vibe: string;
  songs: PlaylistSong[];
  /** Stored so a playlist can be regenerated from the saved view. */
  stops?: PlaylistStop[];
  createdAt: string;
  updatedAt: string;
}

// ── Local storage ─────────────────────────────────────────────────────────────

const STORAGE_KEY = "date_genie_playlists";

const getStoredPlaylists = (): SavedPlaylist[] => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as SavedPlaylist[]) : [];
  } catch {
    return [];
  }
};

const saveToStorage = (list: SavedPlaylist[]) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
  } catch (e) {
    console.error("[Playlists] localStorage write failed:", e);
  }
};

// ── Supabase row ↔ domain model ───────────────────────────────────────────────

interface DbPlaylistRow {
  playlist_id: string;
  user_id: string;
  title: string | null;
  date_plan_title: string | null;
  vibe: string | null;
  tracks: PlaylistSong[] | null;
  stops: PlaylistStop[] | null;
  generated_at: string;
  updated_at: string | null;
}

const rowToPlaylist = (row: DbPlaylistRow): SavedPlaylist => ({
  id: row.playlist_id,
  name: row.title ?? "",
  datePlanTitle: row.date_plan_title ?? "",
  vibe: row.vibe ?? "",
  songs: Array.isArray(row.tracks) ? row.tracks : [],
  stops: Array.isArray(row.stops) && row.stops.length > 0 ? row.stops : undefined,
  createdAt: row.generated_at,
  updatedAt: row.updated_at ?? row.generated_at,
});

const playlistToRow = (p: SavedPlaylist, userId: string): DbPlaylistRow => ({
  playlist_id: p.id,
  user_id: userId,
  title: p.name,
  date_plan_title: p.datePlanTitle,
  vibe: p.vibe,
  tracks: p.songs,
  stops: p.stops ?? null,
  generated_at: p.createdAt,
  updated_at: p.updatedAt,
});

// ── Hook ──────────────────────────────────────────────────────────────────────

export function usePlaylistStorage() {
  const { user } = useAuth();
  const [playlists, setPlaylists] = useState<SavedPlaylist[]>([]);
  const [loading, setLoading] = useState(true);
  const isMounted = useRef(true);
  const synced = useRef(false);

  useEffect(() => {
    isMounted.current = true;
    return () => {
      isMounted.current = false;
    };
  }, []);

  // ── Initial load: merge Supabase + localStorage ───────────────────────────
  useEffect(() => {
    synced.current = false;

    const load = async () => {
      const local = getStoredPlaylists();

      if (!user) {
        if (isMounted.current) {
          setPlaylists(local);
          setLoading(false);
        }
        return;
      }

      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const { data, error } = await (supabase as any)
          .from("playlists")
          .select(
            "playlist_id, user_id, title, date_plan_title, vibe, tracks, stops, generated_at, updated_at"
          )
          .eq("user_id", user.id)
          .order("generated_at", { ascending: false });

        if (!isMounted.current) return;
        if (error) throw error;

        const remote: SavedPlaylist[] = ((data ?? []) as DbPlaylistRow[]).map(rowToPlaylist);
        const remoteIds = new Set(remote.map((p) => p.id));

        // Push local-only playlists (created while logged out) up to Supabase.
        const localOnly = local.filter((p) => !remoteIds.has(p.id));
        if (localOnly.length > 0) {
          const rows = localOnly.map((p) => playlistToRow(p, user.id));
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          await (supabase as any)
            .from("playlists")
            .upsert(rows, { onConflict: "playlist_id" });
        }

        const merged = [...remote, ...localOnly].sort(
          (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );

        if (isMounted.current) {
          setPlaylists(merged);
          saveToStorage(merged);
          synced.current = true;
        }
      } catch (err) {
        console.error("[Playlists] Supabase load failed, falling back to localStorage:", err);
        if (isMounted.current) {
          setPlaylists(local);
        }
      } finally {
        if (isMounted.current) setLoading(false);
      }
    };

    void load();
  }, [user?.id]); // re-run whenever the logged-in user changes

  // ── Cross-tab sync via storage event ─────────────────────────────────────
  useEffect(() => {
    const handle = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY && e.newValue) {
        try {
          setPlaylists(JSON.parse(e.newValue) as SavedPlaylist[]);
        } catch {
          /* ignore parse errors */
        }
      }
    };
    window.addEventListener("storage", handle);
    return () => window.removeEventListener("storage", handle);
  }, []);

  // ── Write-through helper ──────────────────────────────────────────────────
  // Applies state + localStorage, then optionally syncs to Supabase in the background.
  const applyAndSync = useCallback(
    (next: SavedPlaylist[], supabaseOp?: () => Promise<void>) => {
      setPlaylists(next);
      saveToStorage(next);
      if (user && supabaseOp) {
        void supabaseOp().catch((err) =>
          console.error("[Playlists] Supabase write failed:", err)
        );
      }
    },
    [user]
  );

  // ── Save new playlist ─────────────────────────────────────────────────────
  const savePlaylist = useCallback(
    (
      name: string,
      datePlanTitle: string,
      vibe: string,
      songs: Omit<PlaylistSong, "id">[],
      stops?: PlaylistStop[]
    ): SavedPlaylist => {
      const now = new Date().toISOString();
      const newPlaylist: SavedPlaylist = {
        id: crypto.randomUUID(),
        name,
        datePlanTitle,
        vibe,
        songs: songs.map((s) => ({ ...s, id: crypto.randomUUID(), addedAt: now })),
        stops,
        createdAt: now,
        updatedAt: now,
      };

      const next = [newPlaylist, ...playlists];
      applyAndSync(next, async () => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await (supabase as any)
          .from("playlists")
          .upsert(playlistToRow(newPlaylist, user!.id), { onConflict: "playlist_id" });
      });

      return newPlaylist;
    },
    [playlists, applyAndSync, user]
  );

  // ── Update existing playlist ──────────────────────────────────────────────
  const updatePlaylist = useCallback(
    (
      playlistId: string,
      updates: Partial<Omit<SavedPlaylist, "id" | "createdAt">>
    ) => {
      const now = new Date().toISOString();
      const next = playlists.map((p) =>
        p.id === playlistId ? { ...p, ...updates, updatedAt: now } : p
      );
      const updated = next.find((p) => p.id === playlistId);

      applyAndSync(next, async () => {
        if (!updated) return;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await (supabase as any)
          .from("playlists")
          .update({
            title: updated.name,
            date_plan_title: updated.datePlanTitle,
            vibe: updated.vibe,
            tracks: updated.songs,
            stops: updated.stops ?? null,
            updated_at: now,
          })
          .eq("playlist_id", playlistId)
          .eq("user_id", user!.id);
      });
    },
    [playlists, applyAndSync, user]
  );

  // ── Delete playlist ───────────────────────────────────────────────────────
  const deletePlaylist = useCallback(
    (playlistId: string) => {
      const next = playlists.filter((p) => p.id !== playlistId);
      applyAndSync(next, async () => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await (supabase as any)
          .from("playlists")
          .delete()
          .eq("playlist_id", playlistId)
          .eq("user_id", user!.id);
      });
    },
    [playlists, applyAndSync, user]
  );

  // ── Song mutations (delegate to updatePlaylist for Supabase sync) ─────────
  const addSongToPlaylist = useCallback(
    (playlistId: string, song: Omit<PlaylistSong, "id" | "addedAt">) => {
      const found = playlists.find((p) => p.id === playlistId);
      if (!found) return;
      const newSong: PlaylistSong = {
        ...song,
        id: crypto.randomUUID(),
        addedAt: new Date().toISOString(),
      };
      updatePlaylist(playlistId, { songs: [...found.songs, newSong] });
    },
    [playlists, updatePlaylist]
  );

  const removeSongFromPlaylist = useCallback(
    (playlistId: string, songId: string) => {
      const found = playlists.find((p) => p.id === playlistId);
      if (!found) return;
      updatePlaylist(playlistId, { songs: found.songs.filter((s) => s.id !== songId) });
    },
    [playlists, updatePlaylist]
  );

  const replaceSongInPlaylist = useCallback(
    (
      playlistId: string,
      songId: string,
      newSong: Omit<PlaylistSong, "id" | "addedAt">
    ) => {
      const found = playlists.find((p) => p.id === playlistId);
      if (!found) return;
      const songIndex = found.songs.findIndex((s) => s.id === songId);
      if (songIndex === -1) return;
      const replacement: PlaylistSong = {
        ...newSong,
        id: crypto.randomUUID(),
        addedAt: new Date().toISOString(),
      };
      const newSongs = [...found.songs];
      newSongs[songIndex] = replacement;
      updatePlaylist(playlistId, { songs: newSongs });
    },
    [playlists, updatePlaylist]
  );

  const getPlaylist = useCallback(
    (playlistId: string): SavedPlaylist | null =>
      playlists.find((p) => p.id === playlistId) ?? null,
    [playlists]
  );

  return {
    playlists,
    loading,
    savePlaylist,
    updatePlaylist,
    deletePlaylist,
    addSongToPlaylist,
    removeSongFromPlaylist,
    replaceSongInPlaylist,
    getPlaylist,
  };
}
