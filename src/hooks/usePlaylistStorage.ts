import { useState, useEffect, useCallback } from "react";

export interface PlaylistSong {
  id: string;
  title: string;
  artist: string;
  year?: number;
  genre?: string;
  isCustom?: boolean; // User-added song
  addedAt?: string;
}

export interface SavedPlaylist {
  id: string;
  name: string;
  datePlanTitle: string;
  vibe: string;
  songs: PlaylistSong[];
  createdAt: string;
  updatedAt: string;
}

const STORAGE_KEY = "date_genie_playlists";

// Generate unique ID
const generateId = () => `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

// Get playlists from localStorage
const getStoredPlaylists = (): SavedPlaylist[] => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  } catch (e) {
    console.error("Error loading playlists:", e);
    return [];
  }
};

// Save playlists to localStorage
const saveToStorage = (playlists: SavedPlaylist[]) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(playlists));
  } catch (e) {
    console.error("Error saving playlists:", e);
  }
};

export function usePlaylistStorage() {
  const [playlists, setPlaylists] = useState<SavedPlaylist[]>([]);
  const [loading, setLoading] = useState(true);

  // Load playlists on mount
  useEffect(() => {
    setPlaylists(getStoredPlaylists());
    setLoading(false);
  }, []);

  // Sync across tabs
  useEffect(() => {
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY && e.newValue) {
        try {
          setPlaylists(JSON.parse(e.newValue));
        } catch (err) {
          console.error("Error syncing playlists:", err);
        }
      }
    };

    window.addEventListener("storage", handleStorageChange);
    return () => window.removeEventListener("storage", handleStorageChange);
  }, []);

  // Save a new playlist
  const savePlaylist = useCallback((
    name: string,
    datePlanTitle: string,
    vibe: string,
    songs: Omit<PlaylistSong, "id">[]
  ): SavedPlaylist => {
    const now = new Date().toISOString();
    const newPlaylist: SavedPlaylist = {
      id: generateId(),
      name,
      datePlanTitle,
      vibe,
      songs: songs.map(song => ({
        ...song,
        id: generateId(),
        addedAt: now,
      })),
      createdAt: now,
      updatedAt: now,
    };

    const updated = [newPlaylist, ...playlists];
    setPlaylists(updated);
    saveToStorage(updated);
    return newPlaylist;
  }, [playlists]);

  // Update an existing playlist
  const updatePlaylist = useCallback((
    playlistId: string,
    updates: Partial<Omit<SavedPlaylist, "id" | "createdAt">>
  ) => {
    const updated = playlists.map(p => {
      if (p.id === playlistId) {
        return {
          ...p,
          ...updates,
          updatedAt: new Date().toISOString(),
        };
      }
      return p;
    });
    setPlaylists(updated);
    saveToStorage(updated);
  }, [playlists]);

  // Delete a playlist
  const deletePlaylist = useCallback((playlistId: string) => {
    const updated = playlists.filter(p => p.id !== playlistId);
    setPlaylists(updated);
    saveToStorage(updated);
  }, [playlists]);

  // Add a song to a playlist
  const addSongToPlaylist = useCallback((
    playlistId: string,
    song: Omit<PlaylistSong, "id" | "addedAt">
  ) => {
    const updated = playlists.map(p => {
      if (p.id === playlistId) {
        const newSong: PlaylistSong = {
          ...song,
          id: generateId(),
          addedAt: new Date().toISOString(),
        };
        return {
          ...p,
          songs: [...p.songs, newSong],
          updatedAt: new Date().toISOString(),
        };
      }
      return p;
    });
    setPlaylists(updated);
    saveToStorage(updated);
  }, [playlists]);

  // Remove a song from a playlist
  const removeSongFromPlaylist = useCallback((
    playlistId: string,
    songId: string
  ) => {
    const updated = playlists.map(p => {
      if (p.id === playlistId) {
        return {
          ...p,
          songs: p.songs.filter(s => s.id !== songId),
          updatedAt: new Date().toISOString(),
        };
      }
      return p;
    });
    setPlaylists(updated);
    saveToStorage(updated);
  }, [playlists]);

  // Get a single playlist by ID
  const getPlaylist = useCallback((playlistId: string) => {
    return playlists.find(p => p.id === playlistId) || null;
  }, [playlists]);

  return {
    playlists,
    loading,
    savePlaylist,
    updatePlaylist,
    deletePlaylist,
    addSongToPlaylist,
    removeSongFromPlaylist,
    getPlaylist,
  };
}
