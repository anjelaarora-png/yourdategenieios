import { useState } from "react";
import { DateMemory } from "@/hooks/useDateMemories";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Trash2, X } from "lucide-react";
import { format } from "date-fns";

interface MemoryGalleryProps {
  memories: DateMemory[];
  onDelete?: (memoryId: string) => void;
}

const MemoryGallery = ({ memories, onDelete }: MemoryGalleryProps) => {
  const [selectedMemory, setSelectedMemory] = useState<DateMemory | null>(null);

  if (memories.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <p>No memories yet. Start capturing moments during your dates!</p>
      </div>
    );
  }

  return (
    <>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        {memories.map((memory) => (
          <div
            key={memory.id}
            className="aspect-square rounded-lg overflow-hidden cursor-pointer hover:opacity-90 transition-opacity relative group"
            onClick={() => setSelectedMemory(memory)}
          >
            <img
              src={memory.image_url}
              alt={memory.caption || "Date memory"}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-3">
              <span className="text-white text-sm truncate">
                {format(new Date(memory.taken_at), "MMM d, yyyy")}
              </span>
            </div>
          </div>
        ))}
      </div>

      <Dialog open={!!selectedMemory} onOpenChange={() => setSelectedMemory(null)}>
        <DialogContent className="sm:max-w-3xl p-0 overflow-hidden">
          {selectedMemory && (
            <div className="relative">
              <img
                src={selectedMemory.image_url}
                alt={selectedMemory.caption || "Date memory"}
                className="w-full h-auto max-h-[80vh] object-contain bg-black"
              />
              <div className="absolute top-4 right-4 flex gap-2">
                {onDelete && (
                  <Button
                    variant="destructive"
                    size="icon"
                    onClick={() => {
                      onDelete(selectedMemory.id);
                      setSelectedMemory(null);
                    }}
                  >
                    <Trash2 className="w-4 h-4" />
                  </Button>
                )}
                <Button
                  variant="secondary"
                  size="icon"
                  onClick={() => setSelectedMemory(null)}
                >
                  <X className="w-4 h-4" />
                </Button>
              </div>
              {selectedMemory.caption && (
                <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
                  <p className="text-white text-lg">{selectedMemory.caption}</p>
                  <p className="text-white/70 text-sm mt-1">
                    {format(new Date(selectedMemory.taken_at), "MMMM d, yyyy")}
                  </p>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
};

export default MemoryGallery;
