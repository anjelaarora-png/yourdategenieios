import { useState, useEffect, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "./useAuth";

export interface DateMemory {
  id: string;
  date_plan_id: string | null;
  venue_id: string | null;
  image_url: string;
  caption: string | null;
  taken_at: string;
  is_public: boolean;
  created_at: string;
}

/** Path prefix for current user's files in storage (user_id/filename) */
function pathBelongsToUser(filePath: string, userId: string): boolean {
  const firstSegment = filePath.split("/")[0];
  return firstSegment === userId;
}

/** Storage object path for signing: supports legacy full public URL or raw `userId/file` path (iOS + new web rows). */
function storagePathFromImageUrl(imageUrl: string | null | undefined): string | null {
  if (!imageUrl?.trim()) return null;
  const raw = imageUrl.trim();
  const marker = "/date-memories/";
  const idx = raw.indexOf(marker);
  if (idx !== -1) {
    return raw.slice(idx + marker.length).split("?")[0] ?? null;
  }
  if (!raw.startsWith("http")) {
    return raw;
  }
  return null;
}

export function useDateMemories() {
  const [memories, setMemories] = useState<DateMemory[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { user } = useAuth();
  const userIdRef = useRef<string | null>(null);
  userIdRef.current = user?.id ?? null;

  const fetchMemories = async () => {
    const currentUserId = userIdRef.current;
    if (!currentUserId) {
      setMemories([]);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from("date_memories")
        .select("*")
        .eq("user_id", currentUserId)
        .order("taken_at", { ascending: false });

      if (error) throw error;

      // Only generate signed URLs for paths under the current user (prevents cross-account exposure)
      const memoriesWithSignedUrls = await Promise.all(
        (data || []).map(async (memory) => {
          const filePath = storagePathFromImageUrl(memory.image_url);
          if (!filePath) {
            return memory;
          }
          if (!pathBelongsToUser(filePath, currentUserId)) {
            return null;
          }
          const { data: signedUrlData } = await supabase.storage
            .from("date-memories")
            .createSignedUrl(filePath, 3600);

          if (signedUrlData?.signedUrl) {
            return { ...memory, image_url: signedUrlData.signedUrl };
          }
          return memory;
        })
      );

      setMemories(memoriesWithSignedUrls.filter(Boolean) as DateMemory[]);
    } catch (error) {
      console.error("Error fetching memories:", error);
      setMemories([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!user) {
      setMemories([]);
      setLoading(false);
      return;
    }
    fetchMemories();
  }, [user?.id]);

  const uploadMemory = async (
    file: File,
    datePlanId?: string,
    caption?: string
  ): Promise<DateMemory | null> => {
    const currentUserId = userIdRef.current;
    if (!currentUserId) {
      toast({
        title: "Not signed in",
        description: "Please sign in to upload photos.",
        variant: "destructive",
      });
      return null;
    }

    try {
      const fileExt = file.name.split(".").pop();
      const fileName = `${currentUserId}/${Date.now()}.${fileExt}`;

      const { error: uploadError } = await supabase.storage
        .from("date-memories")
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      const { data: signedUrlData } = await supabase.storage
        .from("date-memories")
        .createSignedUrl(fileName, 3600);

      if (!signedUrlData?.signedUrl) {
        throw new Error("Failed to generate signed URL");
      }

      const { data, error } = await supabase
        .from("date_memories")
        .insert({
          user_id: currentUserId,
          date_plan_id: datePlanId || null,
          image_url: fileName,
          caption,
          taken_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw error;

      // Only update state if the same user is still logged in
      if (userIdRef.current !== currentUserId) return null;

      const memoryWithSignedUrl = { ...data, image_url: signedUrlData.signedUrl };
      setMemories((prev) => [memoryWithSignedUrl, ...prev]);
      toast({
        title: "Memory saved! 📸",
        description: "Your photo has been added to your date memories.",
      });
      return memoryWithSignedUrl;
    } catch (error) {
      console.error("Error uploading memory:", error);
      toast({
        title: "Upload failed",
        description: "Failed to upload your photo. Please try again.",
        variant: "destructive",
      });
      return null;
    }
  };

  const deleteMemory = async (memoryId: string) => {
    const currentUserId = userIdRef.current;
    if (!currentUserId) return;

    try {
      const { error } = await supabase
        .from("date_memories")
        .delete()
        .eq("id", memoryId)
        .eq("user_id", currentUserId);

      if (error) throw error;

      setMemories((prev) => prev.filter((m) => m.id !== memoryId));
      toast({
        title: "Memory deleted",
        description: "Your photo has been removed.",
      });
    } catch (error) {
      console.error("Error deleting memory:", error);
      toast({
        title: "Error",
        description: "Failed to delete the memory.",
        variant: "destructive",
      });
    }
  };

  return {
    memories,
    loading,
    uploadMemory,
    deleteMemory,
    refetch: fetchMemories,
  };
}