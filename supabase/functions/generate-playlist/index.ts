/**
 * Generate-playlist edge function: Last.fm only for the list — tag.getTopTracks plus,
 * when an era is selected, capped track.getInfo (toptags) and album.getInfo (releasedate).
 * Set LASTFM_API_KEY in Supabase project secrets (Dashboard → Edge Functions → Secrets).
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LASTFM_BASE = "https://ws.audioscrobbler.com/2.0";

interface PlaylistRequest {
  vibe: string;
  datePlanTitle: string;
  stops?: Array<{ name: string; venueType: string }>;
  era?: string | null;
  mood?: string | null;
  energy?: string | null;
  genres?: string[];
}

interface SongSuggestion {
  title: string;
  artist: string;
  year?: number;
  genre?: string;
  spotifyUri?: string;
}

/** Internal: union of Last.fm tag queries that returned this track (for scoring). */
interface TaggedSong extends SongSuggestion {
  matchedTags: string[];
  /** Optional boost/penalty from track.getInfo toptags + album.getInfo year (Last.fm only). */
  scoreAdjust?: number;
  /** Album title from track.getInfo for album.getInfo (not sent to client). */
  lastFmAlbum?: string;
}

// Map app vibe/genre/mood/energy raw values to Last.fm tag names (lowercase). Use tags Last.fm has plenty of tracks for.
function toLastFmTag(value: string): string {
  if (!value || value === "any" || value === "none") return "";
  const v = value.toLowerCase().trim();
  const map: Record<string, string> = {
    rnb: "r-n-b",
    "70s-80s": "80s",
    "2010s-now": "2010s",
    "2020s-now": "2020s",
    romantic_dinner: "love",
    road_trip: "road trip",
    chill: "chill",
    balanced: "chill",
    energetic: "dance",
    // Mood: map to tags that match intent and have good coverage
    party: "dance",
    focus: "chill",
    // Vibes: synonyms so Last.fm returns more tracks
    romantic: "love",
    upbeat: "dance",
    adventurous: "experimental",
    indie: "indie",
    classic: "oldies",
    jazzy: "jazz",
    pop: "pop",
    rock: "rock",
    electronic: "electronic",
    country: "country",
    latin: "latin",
    reggae: "reggae",
    blues: "blues",
    kpop: "k-pop",
    jpop: "j-pop",
    afrobeats: "afrobeats",
    // Last.fm's generic "bollywood" tag is often noisy; prefer the more specific Hindi cinema tag.
    bollywood: "hindi film music",
    arabic: "arabic",
  };
  return map[v] ?? v.replace(/_/g, " ");
}

// Era → Last.fm tags for tag.getTopTracks (crowdsourced; not exact release years).
// Extra tags (e.g. "2010s pop") improve recall on Last.fm without leaving the API.
// iOS "2010s–2019" still sends 2010s-now — we map to Last.fm "2010s" (not 2020s).
function eraToTags(era: string | null | undefined): string[] {
  if (!era || era === "any") return [];
  const v = era.toLowerCase();
  if (v === "70s-80s") return ["70s", "80s", "1970s", "1980s"];
  if (v === "90s") return ["90s", "1990s"];
  if (v === "2000s") return ["2000s", "2000s pop"];
  if (v === "2010s-now" || v === "2010s") return ["2010s", "2010s pop"];
  if (v === "2020s-now" || v === "2020s") return ["2020s", "2020s pop"];
  return [v];
}

/** Toptag / wiki text matching: decade strings users tag tracks with on Last.fm. */
function eraTopTagSynonyms(era: string | null | undefined): Set<string> {
  const base = eraToTags(era);
  const s = new Set(base.map((t) => t.toLowerCase()));
  const v = (era ?? "").toLowerCase();
  if (v === "70s-80s") {
    ["seventies", "eighties", "70's", "80's"].forEach((x) => s.add(x));
  } else if (v === "90s") {
    s.add("nineties");
    s.add("90's");
  } else if (v === "2000s") {
    s.add("noughties");
    s.add("00s");
  } else if (v === "2010s-now" || v === "2010s") {
    s.add("10s");
    s.add("twenty-tens");
  } else if (v === "2020s-now" || v === "2020s") {
    s.add("20s");
    s.add("twenty-twenties");
  }
  return s;
}

/** Map UI era to inclusive calendar range when album.getInfo returns a year. */
function eraYearRange(era: string | null | undefined): { min: number; max: number } | null {
  if (!era || era === "any") return null;
  const v = era.toLowerCase();
  const y = new Date().getUTCFullYear();
  if (v === "70s-80s") return { min: 1970, max: 1989 };
  if (v === "90s") return { min: 1990, max: 1999 };
  if (v === "2000s") return { min: 2000, max: 2009 };
  if (v === "2010s-now" || v === "2010s") return { min: 2010, max: 2019 };
  if (v === "2020s-now" || v === "2020s") return { min: 2020, max: y };
  return null;
}

function parseLastFmReleaseYear(releasedate: unknown): number | null {
  if (releasedate == null || releasedate === false) return null;
  const str = String(releasedate).trim();
  if (!str || str.toLowerCase() === "false") return null;
  const m = str.match(/\b(19|20)\d{2}\b/);
  return m ? parseInt(m[0], 10) : null;
}

function trackKey(title: string, artist: string): string {
  return `${title.toLowerCase()}|${artist.toLowerCase()}`;
}

function hasEraInMatchedTags(s: TaggedSong, eraTagSet: Set<string>): boolean {
  return s.matchedTags.some((t) => eraTagSet.has(t));
}

/** Several Last.fm tags per app vibe — tracks matching more of them rank higher (reduces one noisy tag). */
function primaryTagsForVibe(vibe: string): string[] {
  const v = vibe.toLowerCase().trim();
  const main = (toLastFmTag(vibe) || "").trim();
  const bundles: Record<string, string[]> = {
    bollywood: ["hindi film music", "bollywood soundtracks", "hindi soundtrack"],
    kpop: ["k-pop", "korean pop"],
    jpop: ["j-pop", "japanese pop"],
    rnb: ["r-n-b", "neo soul", "soul"],
    /* romantic: "love songs" skews heavily to chart pop; ballad + romantic keep mood without only Top 40 */
    romantic: ["love", "ballad", "romantic"],
    chill: ["chill", "chillout", "downtempo", "lo-fi"],
    upbeat: ["dance", "dance pop", "party"],
    pop: ["pop", "dance pop"],
    electronic: ["electronic", "edm", "house", "techno"],
    /* rock: add hard/classic rock so results are not only pop-alt crossover */
    rock: ["rock", "hard rock", "classic rock"],
    indie: ["indie", "indie rock", "indie folk"],
    /* latin: drop latin pop (US chart skew); salsa/cumbia stay regional */
    latin: ["latin", "reggaeton", "salsa", "cumbia"],
    /* country: country pop is Nashville radio pop; outlaw/classic country tilts traditional */
    country: ["country", "outlaw country", "classic country"],
    reggae: ["reggae", "dancehall"],
    /* blues: soul bleeds R&B/pop vocal charts */
    blues: ["blues", "electric blues", "delta blues"],
    afrobeats: ["afrobeats", "amapiano", "highlife"],
    arabic: ["arabic", "middle eastern"],
    /* jazzy: avoid smooth jazz skew (chart pop); bebop/cool jazz/swing stay closer to jazz */
    jazzy: ["jazz", "bebop", "cool jazz", "swing"],
    /* classic: soul pulls R&B/pop crossovers; standards/swing fit timeless without chart pop */
    classic: ["oldies", "standards", "classic rock", "swing"],
    /* adventurous: "alternative" is broad alt-radio pop; psychedelic/post-punk/art rock are more genre-faithful */
    adventurous: ["experimental", "psychedelic rock", "post-punk", "art rock"],
  };
  const extra = bundles[v] ?? [];
  const combined = [main, ...extra].filter((t) => t.length > 0);
  return [...new Set(combined)];
}

/** User-chosen modifiers (era, mood, energy, extra genres). Excludes every primary tag so dance ≠ genre. */
function buildModifierTags(req: PlaylistRequest, primaryTags: string[]): string[] {
  const primarySet = new Set(primaryTags);
  const tags: string[] = [];
  if (req.genres?.length) {
    for (const g of req.genres) {
      const t = toLastFmTag(g);
      if (t && !primarySet.has(t) && !tags.includes(t)) tags.push(t);
    }
  }
  for (const t of eraToTags(req.era ?? undefined)) {
    if (t && !primarySet.has(t) && !tags.includes(t)) tags.push(t);
  }
  if (req.mood) {
    const t = toLastFmTag(req.mood);
    if (t && !primarySet.has(t) && !tags.includes(t)) tags.push(t);
  }
  if (req.energy) {
    const t = toLastFmTag(req.energy);
    if (t && !primarySet.has(t) && !tags.includes(t)) tags.push(t);
  }
  return tags.filter(Boolean);
}

function mergeTaggedByTrack(songs: TaggedSong[]): TaggedSong[] {
  const m = new Map<string, TaggedSong>();
  for (const s of songs) {
    const key = `${s.title.toLowerCase()}|${s.artist.toLowerCase()}`;
    const prev = m.get(key);
    if (!prev) {
      m.set(key, { ...s, matchedTags: [...s.matchedTags] });
    } else {
      prev.matchedTags = [...new Set([...prev.matchedTags, ...s.matchedTags])];
    }
  }
  return [...m.values()];
}

function scoreTaggedSong(
  s: TaggedSong,
  primarySet: Set<string>,
  modifierSet: Set<string>,
  eraTagSet: Set<string>,
): number {
  let score = 0;
  let hitPrimary = false;
  let hitEra = false;
  let hitOtherMod = false;
  for (const t of s.matchedTags) {
    if (primarySet.has(t)) {
      hitPrimary = true;
      score += 12;
    } else if (eraTagSet.has(t)) {
      hitEra = true;
      score += 26;
    } else if (modifierSet.has(t)) {
      hitOtherMod = true;
      score += 5;
    }
  }
  if (hitPrimary && hitEra) score += 22;
  else if (hitPrimary && hitOtherMod) score += 10;
  return score + (s.scoreAdjust ?? 0);
}


/** When we need extra tracks, never default to generic "pop" for non-pop vibes — that caused jazz/classic to fill with chart pop. */
function fallbackTagForVibe(vibe: string): string {
  const v = vibe.toLowerCase().trim();
  const map: Record<string, string> = {
    romantic: "love",
    pop: "pop",
    upbeat: "dance",
    chill: "chill",
    jazzy: "jazz",
    indie: "indie",
    classic: "oldies",
    rnb: "r-n-b",
    adventurous: "experimental",
    latin: "latin",
    afrobeats: "afrobeats",
    kpop: "k-pop",
    reggae: "reggae",
    country: "country",
    bollywood: "hindi film music",
    arabic: "arabic",
    jpop: "j-pop",
    rock: "rock",
    electronic: "electronic",
    blues: "blues",
  };
  if (map[v]) return map[v];
  const mapped = (toLastFmTag(vibe) || "").trim();
  return mapped || "pop";
}

function shuffle<T>(arr: T[]): T[] {
  return arr.slice().sort(() => Math.random() - 0.5);
}

function sortByScoreWithTieShuffle(
  songs: TaggedSong[],
  primarySet: Set<string>,
  modifierSet: Set<string>,
  eraTagSet: Set<string>,
): TaggedSong[] {
  const scored = songs.map((s) => ({ s, score: scoreTaggedSong(s, primarySet, modifierSet, eraTagSet) }));
  scored.sort((a, b) => b.score - a.score);
  const out: TaggedSong[] = [];
  let i = 0;
  while (i < scored.length) {
    const sc = scored[i].score;
    const group: TaggedSong[] = [];
    while (i < scored.length && scored[i].score === sc) {
      group.push(scored[i].s);
      i++;
    }
    out.push(...shuffle(group));
  }
  return out;
}

/**
 * When user chose an era, keep score order from `ordered` but swap in deeper era-tagged rows
 * so at least `minEraSlots` results carry an era modifier tag (up to availability).
 */
function selectTaggedPlaylist(
  ordered: TaggedSong[],
  eraTagSet: Set<string>,
  targetCount: number,
  eraRequested: boolean,
): TaggedSong[] {
  if (!eraRequested || eraTagSet.size === 0) {
    return ordered.slice(0, targetCount);
  }
  const minEraSlots = Math.min(10, targetCount);
  const n = Math.min(targetCount, ordered.length);
  const sel = ordered.slice(0, n).map((s) => ({ ...s, matchedTags: [...s.matchedTags] }));
  let eraCount = sel.filter((s) => hasEraInMatchedTags(s, eraTagSet)).length;
  if (eraCount >= minEraSlots) return sel;

  const selKeys = new Set(sel.map((s) => trackKey(s.title, s.artist)));
  const extras = ordered.filter((s) => !selKeys.has(trackKey(s.title, s.artist)) && hasEraInMatchedTags(s, eraTagSet));

  let xi = 0;
  for (let i = sel.length - 1; i >= 0 && eraCount < minEraSlots && xi < extras.length; i--) {
    if (!hasEraInMatchedTags(sel[i], eraTagSet)) {
      const oldK = trackKey(sel[i].title, sel[i].artist);
      selKeys.delete(oldK);
      const repSrc = extras[xi++];
      const rep: TaggedSong = { ...repSrc, matchedTags: [...repSrc.matchedTags] };
      sel[i] = rep;
      selKeys.add(trackKey(rep.title, rep.artist));
      eraCount++;
    }
  }
  return sel;
}

function normalizeLastFmTagArray(tagField: unknown): string[] {
  if (!tagField) return [];
  const raw = Array.isArray(tagField) ? tagField : [tagField];
  const names: string[] = [];
  for (const item of raw) {
    if (item && typeof item === "object" && "name" in item) {
      const n = (item as { name?: string }).name;
      if (typeof n === "string" && n.trim()) names.push(n.toLowerCase().trim());
    }
  }
  return names;
}

async function fetchLastFmJson(
  apiKey: string,
  params: Record<string, string>,
): Promise<Record<string, unknown> | null> {
  const search = new URLSearchParams({ ...params, api_key: apiKey, format: "json" });
  const url = `${LASTFM_BASE}/?${search.toString()}`;
  try {
    const opts: RequestInit = typeof AbortSignal?.timeout === "function" ? { signal: AbortSignal.timeout(12000) } : {};
    const res = await fetch(url, opts);
    const text = await res.text();
    if (!res.ok) return null;
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return null;
  }
}

const TRACK_GETINFO_CAP = 28;
const ALBUM_GETINFO_CAP = 16;
const LASTFM_REFINE_CONCURRENCY = 4;

async function runWithConcurrency<T>(items: T[], limit: number, fn: (item: T) => Promise<void>): Promise<void> {
  const queue = items.slice();
  const workers: Promise<void>[] = [];
  for (let i = 0; i < Math.min(limit, queue.length); i++) {
    workers.push(
      (async () => {
        while (queue.length > 0) {
          const item = queue.shift();
          if (item !== undefined) await fn(item);
        }
      })(),
    );
  }
  await Promise.all(workers);
}

/**
 * Last.fm-only refinement: track.getInfo toptags vs era synonyms; album.getInfo releasedate vs UI era range.
 * Mutates `scoreAdjust` / `lastFmAlbum` on visited tracks. Does not use wiki.published as release year.
 */
async function applyLastFmEraRefinements(
  apiKey: string,
  ordered: TaggedSong[],
  era: string | null | undefined,
  eraSynonyms: Set<string>,
  yearRange: { min: number; max: number } | null,
): Promise<void> {
  const head = ordered.slice(0, TRACK_GETINFO_CAP);
  await runWithConcurrency(head, LASTFM_REFINE_CONCURRENCY, async (s) => {
    const data = await fetchLastFmJson(apiKey, {
      method: "track.getInfo",
      artist: s.artist,
      track: s.title,
    });
    const track = data?.track as Record<string, unknown> | undefined;
    if (!track) return;
    const topwrap = track.toptags as Record<string, unknown> | undefined;
    const tagNames = normalizeLastFmTagArray(topwrap?.tag);
    const hitEraTag = tagNames.some((n) => eraSynonyms.has(n));
    let adj = s.scoreAdjust ?? 0;
    if (hitEraTag) adj += 10;
    else adj -= 5;

    const album = track.album as Record<string, unknown> | undefined;
    let albumTitle = "";
    if (album) {
      albumTitle = String((album as { title?: string; "#text"?: string }).title ??
        (album as { "#text"?: string })["#text"] ?? "").trim();
    }
    s.scoreAdjust = adj;
    if (albumTitle) s.lastFmAlbum = albumTitle;
  });

  if (!yearRange) return;

  const forAlbum = ordered
    .slice(0, ALBUM_GETINFO_CAP)
    .filter((s) => s.lastFmAlbum && s.lastFmAlbum.length > 0);
  await runWithConcurrency(forAlbum, LASTFM_REFINE_CONCURRENCY, async (s) => {
    const albumName = s.lastFmAlbum!;
    const data = await fetchLastFmJson(apiKey, {
      method: "album.getInfo",
      artist: s.artist,
      album: albumName,
    });
    const album = data?.album as Record<string, unknown> | undefined;
    if (!album) return;
    const year = parseLastFmReleaseYear(album.releasedate);
    if (year == null) return;
    let adj = s.scoreAdjust ?? 0;
    if (year >= yearRange.min && year <= yearRange.max) adj += 6;
    else adj -= 22;
    s.scoreAdjust = adj;
  });
}

interface LastFmTrack {
  name?: string;
  artist?: { "#text"?: string; name?: string };
  duration?: string | number;
}

interface LastFmTracksResponse {
  toptracks?: {
    track?: LastFmTrack[] | LastFmTrack;
    tracks?: LastFmTrack[] | LastFmTrack;
  };
  /** Last.fm actually returns "tracks" (plural), not "toptracks" */
  tracks?: {
    track?: LastFmTrack[] | LastFmTrack;
  };
  error?: number;
  message?: string;
}

function getArtistName(t: LastFmTrack): string {
  const a = t?.artist;
  if (!a) return "";
  const name = (a as { "#text"?: string }).["#text"] ?? (a as { name?: string }).name;
  return typeof name === "string" ? name.trim() : "";
}

async function fetchTopTracksForTag(
  apiKey: string,
  tag: string,
  limit: number,
  page: number
): Promise<SongSuggestion[]> {
  const params = new URLSearchParams({
    method: "tag.gettoptracks",
    tag,
    api_key: apiKey,
    limit: String(limit),
    page: String(page),
    format: "json",
  });
  const url = `${LASTFM_BASE}/?${params.toString()}`;
  let res: Response;
  try {
    const opts: RequestInit = typeof AbortSignal?.timeout === "function" ? { signal: AbortSignal.timeout(15000) } : {};
    res = await fetch(url, opts);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`Last.fm fetch failed for tag=${tag}: ${msg}`);
    throw new Error("Could not reach Last.fm. Check your network and try again.");
  }
  const text = await res.text();
  if (!res.ok) {
    console.error(`Last.fm HTTP ${res.status} for tag=${tag}: ${text.slice(0, 300)}`);
    if (res.status === 401 || res.status === 403) {
      throw new Error("Last.fm rejected the request. Check that LASTFM_API_KEY is correct in Supabase → Edge Functions → Secrets.");
    }
    return [];
  }
  let data: LastFmTracksResponse;
  try {
    data = JSON.parse(text) as LastFmTracksResponse;
  } catch {
    console.error(`Last.fm invalid JSON for tag=${tag}: ${text.slice(0, 200)}`);
    throw new Error("Last.fm returned invalid response. Check your API key.");
  }
  if (data.error) {
    if (data.error === 29) throw new Error("Rate limit exceeded. Try again in a moment.");
    if (data.error === 10) throw new Error("Invalid Last.fm API key. Add LASTFM_API_KEY in Supabase Edge Function secrets.");
    console.error(`Last.fm API error ${data.error}: ${data.message}`);
    return [];
  }
  // Last.fm returns top-level "tracks" (plural), not "toptracks"
  const d = data as Record<string, unknown>;
  const tracksWrapper = d.tracks ?? d.toptracks;
  const rawTrack = tracksWrapper && typeof tracksWrapper === "object" ? (tracksWrapper as Record<string, unknown>).track : undefined;
  const list: LastFmTrack[] = Array.isArray(rawTrack) ? rawTrack as LastFmTrack[] : rawTrack && typeof rawTrack === "object" ? [rawTrack as LastFmTrack] : [];
  if (list.length === 0) {
    console.error(`Last.fm tag=${tag}: no track array. Top-level keys: ${JSON.stringify(Object.keys(d))}. Has tracks: ${!!d.tracks}, has toptracks: ${!!d.toptracks}. Body sample: ${text.slice(0, 400)}`);
  }
  const out = list
    .filter((t) => t && (t.name || (t as { title?: string }).title))
    .map((t) => {
      const title = String((t.name ?? (t as { title?: string }).title) ?? "").trim();
      const artist = getArtistName(t as LastFmTrack);
      return { title, artist, duration: t.duration ? String(Math.round(Number(t.duration) / 60)) + " min" : undefined as string | undefined };
    })
    .filter((s) => s.title && s.artist);
  if (out.length === 0 && list.length > 0) {
    console.error(`Last.fm tag=${tag}: got ${list.length} raw tracks but none had name+artist. Sample keys: ${JSON.stringify(Object.keys(list[0] || {}))}`);
  } else if (out.length === 0) {
    console.error(`Last.fm tag=${tag}: toptracks.track length=${list.length}. Response keys: ${JSON.stringify(Object.keys(data))}`);
  }
  return out;
}

async function generateWithLastFm(apiKey: string, request: PlaylistRequest): Promise<SongSuggestion[]> {
  const targetCount = 15;
  const eraPoolMin = 4;
  const timeSeed = Math.floor(Date.now() / 1000);
  const pageForTag = (tag: string, i: number) =>
    ((timeSeed + i * 17 + Math.floor(Math.random() * 100)) % 20) + 1;

  const limitPerPrimary = 50;
  const limitModifier = 36;

  let primaryTags = primaryTagsForVibe(request.vibe);
  if (primaryTags.length === 0) primaryTags = ["pop"];

  const modifierTags = buildModifierTags(request, primaryTags);
  const primarySet = new Set(primaryTags);
  const modifierSet = new Set(modifierTags);

  const tagToTagged = (tag: string, tracks: SongSuggestion[]): TaggedSong[] =>
    tracks.map((t) => ({
      ...t,
      genre: tag,
      matchedTags: [tag],
    }));

  let flatTagged: TaggedSong[] = [];

  const primaryResults = await Promise.all(
    primaryTags.map((tag, i) =>
      fetchTopTracksForTag(apiKey, tag, limitPerPrimary, pageForTag(tag, i)).then((tracks) => tagToTagged(tag, tracks)),
    ),
  );
  flatTagged.push(...primaryResults.flat());

  if (modifierTags.length > 0) {
    const modResults = await Promise.all(
      modifierTags.map((tag, i) =>
        fetchTopTracksForTag(apiKey, tag, limitModifier, pageForTag(tag, i + primaryTags.length)).then((tracks) =>
          tagToTagged(tag, tracks),
        ),
      ),
    );
    flatTagged.push(...modResults.flat());
  }

  let merged = mergeTaggedByTrack(flatTagged);

  const eraTagsList = eraToTags(request.era ?? undefined);
  const eraTagSet = new Set(eraTagsList);

  if (merged.length < targetCount) {
    if (eraTagsList.length > 0) {
      let bump = 0;
      for (const eraTag of eraTagsList) {
        if (merged.length >= targetCount) break;
        const ep = ((timeSeed + 200 + bump) % 18) + 1;
        bump += 3;
        const extra = await fetchTopTracksForTag(apiKey, eraTag, limitModifier, ep);
        flatTagged.push(...tagToTagged(eraTag, extra));
      }
      merged = mergeTaggedByTrack(flatTagged);
    }
    if (merged.length < targetCount) {
      const fallbackPage = ((timeSeed + 99) % 15) + 1;
      const extra = await fetchTopTracksForTag(apiKey, primaryTags[0], limitPerPrimary, fallbackPage);
      flatTagged.push(...tagToTagged(primaryTags[0], extra));
      merged = mergeTaggedByTrack(flatTagged);
    }
  }

  const withPrimary = merged.filter((s) => s.matchedTags.some((t) => primarySet.has(t)));
  let pool = withPrimary.length > 0 ? withPrimary : merged;

  if (eraTagSet.size > 0) {
    const withEra = pool.filter((s) => s.matchedTags.some((t) => eraTagSet.has(t)));
    if (withEra.length >= targetCount || withEra.length >= eraPoolMin) {
      pool = withEra;
    }
  }

  let ordered = sortByScoreWithTieShuffle(pool, primarySet, modifierSet, eraTagSet);

  if (eraTagSet.size > 0) {
    await applyLastFmEraRefinements(
      apiKey,
      ordered,
      request.era,
      eraTopTagSynonyms(request.era),
      eraYearRange(request.era),
    );
    ordered = sortByScoreWithTieShuffle(pool, primarySet, modifierSet, eraTagSet);
  }

  const toSuggestion = (s: TaggedSong): SongSuggestion => ({
    title: s.title,
    artist: s.artist,
    genre: request.vibe,
  });

  const eraRequested = eraTagSet.size > 0;
  const pickedTagged = selectTaggedPlaylist(ordered, eraTagSet, targetCount, eraRequested);
  let out: SongSuggestion[] = pickedTagged.map(toSuggestion);

  if (out.length === 0 && merged.length === 0) {
    const rescueTag = fallbackTagForVibe(request.vibe);
    const lastResort = await fetchTopTracksForTag(apiKey, rescueTag, limitPerPrimary, 1);
    out = tagToTagged(rescueTag, lastResort).slice(0, targetCount).map(toSuggestion);
  }

  if (out.length < targetCount && eraTagsList.length > 0) {
    const haveEraFill = new Set(out.map((x) => trackKey(x.title, x.artist)));
    let eraPageBump = 0;
    for (let round = 0; round < 3 && out.length < targetCount; round++) {
      for (const eraTag of eraTagsList) {
        if (out.length >= targetCount) break;
        const ep = ((timeSeed + 61 + eraPageBump + round * 7) % 12) + 1;
        eraPageBump += 4;
        const eraFill = await fetchTopTracksForTag(apiKey, eraTag, limitModifier, ep);
        for (const t of eraFill) {
          if (out.length >= targetCount) break;
          const k = trackKey(t.title, t.artist);
          if (haveEraFill.has(k)) continue;
          haveEraFill.add(k);
          out.push({ title: t.title, artist: t.artist, genre: request.vibe });
        }
      }
    }
  }

  if (out.length < targetCount) {
    const fillTag = fallbackTagForVibe(request.vibe);
    const have = new Set(out.map((x) => trackKey(x.title, x.artist)));
    let fillPageBump = 0;
    for (let round = 0; round < (eraTagSet.size > 0 ? 2 : 1) && out.length < targetCount; round++) {
      const fillPage = ((timeSeed + 50 + fillPageBump) % 10) + 1;
      fillPageBump += 5;
      const fillExtra = await fetchTopTracksForTag(apiKey, fillTag, limitModifier, fillPage);
      for (const t of fillExtra) {
        if (out.length >= targetCount) break;
        const k = trackKey(t.title, t.artist);
        if (have.has(k)) continue;
        have.add(k);
        out.push({ title: t.title, artist: t.artist, genre: request.vibe });
      }
    }
  }

  if (out.length === 0) {
    console.error(
      "Last.fm returned no tracks. Primary tags:",
      primaryTags,
      "modifiers:",
      modifierTags,
      "| Check Edge Function logs and LASTFM_API_KEY.",
    );
    throw new Error(
      "Last.fm returned no tracks. In Supabase: set LASTFM_API_KEY in Project Settings → Edge Functions → Secrets (get a key at last.fm/api/account/create). Then check the function logs for this invocation to see why each tag returned 0 tracks.",
    );
  }
  return out.slice(0, targetCount);
}

// Fallback config for playlist name and description when Last.fm is used
const vibeConfig: Record<string, { description: string }> = {
  romantic: { description: "Intimate & Elegant" },
  pop: { description: "Pop Hits & Radio Favorites" },
  upbeat: { description: "Fun & Energetic" },
  chill: { description: "Relaxed & Cozy" },
  jazzy: { description: "Smooth & Sophisticated" },
  indie: { description: "Alternative & Artistic" },
  classic: { description: "Timeless & Elegant" },
  rnb: { description: "Smooth & Soulful" },
  adventurous: { description: "Eclectic & Genre-Bending" },
  latin: { description: "Latin & Reggaeton" },
  afrobeats: { description: "Afrobeats & Amapiano" },
  kpop: { description: "K-Pop & K-R&B" },
  reggae: { description: "Reggae & Dancehall" },
  country: { description: "Country & Americana" },
  bollywood: { description: "Bollywood & Indian" },
  arabic: { description: "Arabic & Middle Eastern" },
  jpop: { description: "J-Pop & Japanese" },
  rock: { description: "Rock & Alternative" },
  electronic: { description: "Electronic & EDM" },
  blues: { description: "Blues & Soul" },
};

/** Decodes a base64url JWT payload without verification (Supabase already verified via config.toml). */
function jwtRole(authHeader: string | null): string | null {
  if (!authHeader?.startsWith("Bearer ")) return null;
  try {
    const parts = authHeader.slice(7).split(".");
    if (parts.length !== 3) return null;
    const padded = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
    const payload = JSON.parse(atob(padded + pad));
    return typeof payload?.role === "string" ? payload.role : null;
  } catch {
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

  // Reject anonymous (anon-key-only) calls — a signed-in user is required.
  const role = jwtRole(req.headers.get("Authorization"));
  if (role !== "authenticated") {
    return new Response(JSON.stringify({ error: "Authenticated user required" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  try {
    const apiKey = Deno.env.get("LASTFM_API_KEY");
    if (!apiKey) {
      console.error("LASTFM_API_KEY not set in Supabase Edge Function secrets");
      return new Response(
        JSON.stringify({
          error: "LASTFM_API_KEY not configured. Add it in Supabase Dashboard → Project Settings → Edge Functions → Secrets.",
        }),
        { status: 503, headers: jsonHeaders }
      );
    }

    let body: PlaylistRequest;
    try {
      const raw = await req.json();
      body = (raw && typeof raw === "object" ? raw : {}) as PlaylistRequest;
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid request body. Send JSON with vibe and datePlanTitle." }),
        { status: 400, headers: jsonHeaders }
      );
    }
    const { vibe, datePlanTitle, stops, era, mood, energy, genres } = body;

    if (!vibe || !datePlanTitle) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: vibe, datePlanTitle" }),
        { status: 400, headers: jsonHeaders }
      );
    }

    const songs = await generateWithLastFm(apiKey, {
      vibe,
      datePlanTitle,
      stops: stops ?? [],
      era: era ?? undefined,
      mood: mood ?? undefined,
      energy: energy ?? undefined,
      genres,
    });

    const playlistName = `Date Night: ${datePlanTitle}`;
    const config = vibeConfig[vibe.toLowerCase()] ?? vibeConfig.romantic;

    return new Response(
      JSON.stringify({
        songs,
        playlistName,
        vibe,
        vibeDescription: config.description,
        suggestedArtists: [],
      }),
      { headers: jsonHeaders }
    );
  } catch (error: unknown) {
    console.error("Playlist generation error:", error);
    const message = error instanceof Error ? error.message : "Failed to generate playlist";
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: jsonHeaders }
    );
  }
});
