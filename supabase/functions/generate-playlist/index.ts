import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GATEWAY_URL = "https://ai.gateway.lovable.dev/v1/chat/completions";

interface PlaylistRequest {
  vibe: "romantic" | "upbeat" | "chill" | "adventurous" | "jazzy" | "indie" | "classic" | "rnb";
  datePlanTitle: string;
  stops: Array<{ name: string; venueType: string }>;
}

interface SongSuggestion {
  title: string;
  artist: string;
  year?: number;
  genre?: string;
  spotifyUri?: string;
}

// Genre-specific song recommendations with modern tracks (2020-2025)
const vibeConfig: Record<string, { description: string; artists: string[]; subgenres: string[] }> = {
  romantic: {
    description: "intimate, sensual, slow love songs perfect for close moments",
    artists: ["SZA", "Daniel Caesar", "H.E.R.", "Giveon", "Sabrina Claudio", "Lucky Daye", "Snoh Aalegra", "Summer Walker", "Brent Faiyaz", "Frank Ocean"],
    subgenres: ["R&B ballads", "neo-soul", "slow jams", "romantic pop"],
  },
  upbeat: {
    description: "energetic, danceable, feel-good party hits",
    artists: ["Doja Cat", "Dua Lipa", "The Weeknd", "Bruno Mars", "Lizzo", "Harry Styles", "Bad Bunny", "Beyoncé", "Silk Sonic", "Jack Harlow"],
    subgenres: ["pop hits", "dance pop", "funk", "disco revival"],
  },
  chill: {
    description: "relaxed, lo-fi, acoustic, mellow background vibes",
    artists: ["Mac DeMarco", "Clairo", "Boy Pablo", "Khruangbin", "Still Woozy", "Men I Trust", "Surfaces", "Omar Apollo", "Raveena", "beabadoobee"],
    subgenres: ["indie chill", "bedroom pop", "lo-fi", "soft rock"],
  },
  adventurous: {
    description: "eclectic, world music, unique sounds, genre-bending",
    artists: ["Rosalía", "Rina Sawayama", "FKA twigs", "Kaytranada", "Tame Impala", "Tyler, the Creator", "Disclosure", "Parcels", "Jungle", "Yves Tumor"],
    subgenres: ["art pop", "experimental", "world fusion", "electronic"],
  },
  jazzy: {
    description: "smooth jazz, neo-soul, sophisticated dinner vibes",
    artists: ["Robert Glasper", "Masego", "Tom Misch", "Norah Jones", "Kamasi Washington", "Jorja Smith", "Cleo Sol", "Leon Bridges", "Samara Joy", "Yussef Dayes"],
    subgenres: ["neo-soul", "contemporary jazz", "jazz fusion", "soul"],
  },
  indie: {
    description: "alternative, indie rock, thoughtful singer-songwriter",
    artists: ["Phoebe Bridgers", "Hozier", "Bon Iver", "Japanese Breakfast", "Big Thief", "Mitski", "Adrianne Lenker", "Fleet Foxes", "Weyes Blood", "Father John Misty"],
    subgenres: ["indie folk", "dream pop", "shoegaze", "alternative"],
  },
  classic: {
    description: "timeless classics, oldies, romantic standards",
    artists: ["Frank Sinatra", "Nat King Cole", "Etta James", "Sam Cooke", "Stevie Wonder", "Marvin Gaye", "Aretha Franklin", "Al Green", "Nina Simone", "Otis Redding"],
    subgenres: ["classic soul", "standards", "motown", "vintage R&B"],
  },
  rnb: {
    description: "modern R&B, smooth contemporary soul",
    artists: ["SZA", "Brent Faiyaz", "Steve Lacy", "Ravyn Lenae", "Chlöe", "Kehlani", "6LACK", "Victoria Monét", "Kali Uchis", "Ari Lennox"],
    subgenres: ["contemporary R&B", "alternative R&B", "neo-soul", "trap soul"],
  },
};

async function generateSongSuggestions(
  apiKey: string,
  request: PlaylistRequest
): Promise<SongSuggestion[]> {
  const venueContext = request.stops
    .map((s) => `${s.name} (${s.venueType})`)
    .join(", ");

  const config = vibeConfig[request.vibe] || vibeConfig.romantic;
  const currentYear = new Date().getFullYear();

  const prompt = `You are an expert music curator creating a perfect date night playlist.

DATE CONTEXT:
- Event: "${request.datePlanTitle}"
- Venues: ${venueContext}
- Desired vibe: ${config.description}

REQUIREMENTS:
1. Generate exactly 15 songs
2. Mix of time periods: 60% from ${currentYear - 5}-${currentYear}, 30% from 2010-${currentYear - 6}, 10% classics
3. Include songs from or similar to these artists: ${config.artists.slice(0, 5).join(", ")}
4. Genres to focus on: ${config.subgenres.join(", ")}
5. Songs must be REAL and available on major streaming platforms
6. Include a good flow - start mellow, build energy in middle, end romantically

Return ONLY a valid JSON array (no markdown, no explanation) with this exact structure:
[
  {
    "title": "exact song title",
    "artist": "exact artist name", 
    "year": release year as number,
    "genre": "specific genre"
  }
]

Focus on songs that are:
- Actually popular and well-known
- Have clear, romantic or mood-appropriate lyrics
- Perfect for a date setting`;

  const response = await fetch(GATEWAY_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "google/gemini-2.5-flash",
      messages: [
        {
          role: "system",
          content: "You are a professional music curator. Return ONLY valid JSON arrays, never markdown or explanations. Every song must be a real, verifiable track.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
    }),
  });

  if (!response.ok) {
    throw new Error(`AI request failed: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content || "[]";
  
  // Clean up potential markdown formatting
  const cleanContent = content
    .replace(/```json\n?/gi, "")
    .replace(/```\n?/g, "")
    .trim();

  try {
    const songs = JSON.parse(cleanContent);
    // Ensure we have valid song objects
    return songs.filter((song: any) => song.title && song.artist).map((song: any) => ({
      title: song.title,
      artist: song.artist,
      year: song.year || null,
      genre: song.genre || config.subgenres[0],
    }));
  } catch {
    console.error("Failed to parse AI response:", cleanContent);
    return [];
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("LOVABLE_API_KEY");
    if (!apiKey) {
      throw new Error("LOVABLE_API_KEY not configured");
    }

    const { vibe, datePlanTitle, stops } = (await req.json()) as PlaylistRequest;

    if (!vibe || !datePlanTitle || !stops?.length) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const songs = await generateSongSuggestions(apiKey, {
      vibe,
      datePlanTitle,
      stops,
    });

    const playlistName = `Date Night: ${datePlanTitle}`;
    const config = vibeConfig[vibe] || vibeConfig.romantic;

    return new Response(
      JSON.stringify({
        songs,
        playlistName,
        vibe,
        vibeDescription: config.description,
        suggestedArtists: config.artists.slice(0, 5),
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: unknown) {
    console.error("Playlist generation error:", error);
    const message = error instanceof Error ? error.message : "Failed to generate playlist";
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
