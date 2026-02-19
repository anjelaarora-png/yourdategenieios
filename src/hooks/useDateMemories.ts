import { useState, useEffect } from "react";
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

export function useDateMemories() {
  const [memories, setMemories] = useState<DateMemory[]>([]);
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { user } = useAuth();

  const fetchMemories = async () => {
    if (!user) {
      setMemories([]);
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from("date_memories")
        .select("*")
        .eq("user_id", user.id)
        .order("taken_at", { ascending: false });

      if (error) throw error;
      
      // Generate signed URLs for each memory since bucket is now private
      const memoriesWithSignedUrls = await Promise.all(
        (data || []).map(async (memory) => {
          // Extract the file path from the full URL
          const urlParts = memory.image_url.split("/date-memories/");
          if (urlParts.length > 1) {
            const filePath = urlParts[1];
            const { data: signedUrlData } = await supabase.storage
              .from("date-memories")
              .createSignedUrl(filePath, 3600); // 1 hour expiry
            
            if (signedUrlData?.signedUrl) {
              return { ...memory, image_url: signedUrlData.signedUrl };
            }
          }
          return memory;
        })
      );
      
      setMemories(memoriesWithSignedUrls);
    } catch (error) {
      console.error("Error fetching memories:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMemories();
  }, [user]);

  const uploadMemory = async (
    file: File,
    datePlanId?: string,
    caption?: string
  ): Promise<DateMemory | null> => {
    if (!user) {
      toast({
        title: "Not signed in",
        description: "Please sign in to upload photos.",
        variant: "destructive",
      });
      return null;
    }

    try {
      const fileExt = file.name.split(".").pop();
      const fileName = `${user.id}/${Date.now()}.${fileExt}`;

      const { error: uploadError } = await supabase.storage
        .from("date-memories")
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Use signed URL since bucket is now private
      const { data: signedUrlData } = await supabase.storage
        .from("date-memories")
        .createSignedUrl(fileName, 3600); // 1 hour expiry

      if (!signedUrlData?.signedUrl) {
        throw new Error("Failed to generate signed URL");
      }

      // Store the original path reference for the database (without signature)
      const { data: publicUrlData } = supabase.storage
        .from("date-memories")
        .getPublicUrl(fileName);

      const { data, error } = await supabase
        .from("date_memories")
        .insert({
          user_id: user.id,
          date_plan_id: datePlanId || null,
          image_url: publicUrlData.publicUrl, // Store the base URL for reference
          caption,
          taken_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw error;

      // Return the memory with signed URL for immediate display
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
    try {
      const { error } = await supabase
        .from("date_memories")
        .delete()
        .eq("id", memoryId);

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