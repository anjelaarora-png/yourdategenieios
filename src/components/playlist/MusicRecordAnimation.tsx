import { cn } from "@/lib/utils";

interface MusicRecordAnimationProps {
  /** Size of the main record circle (px). Default 80. */
  size?: number;
  /** Optional extra class for the wrapper */
  className?: string;
  /** Show floating notes around the record. Default true. */
  showNotes?: boolean;
}

/**
 * Spinning vinyl record with optional floating musical notes.
 * Used in Music tab empty state and playlist generation loading.
 */
const MusicRecordAnimation = ({
  size = 80,
  className,
  showNotes = true,
}: MusicRecordAnimationProps) => {
  const r = size / 2;
  const center = r;

  return (
    <div className={cn("relative inline-flex items-center justify-center", className)} style={{ width: size * 1.8, height: size * 1.8 }}>
      {/* Floating notes (behind record) */}
      {showNotes && (
        <>
          <span
            className="absolute text-primary/70 animate-note-float text-xl sm:text-2xl"
            style={{ left: "0%", top: "20%", animationDelay: "0s" }}
            aria-hidden
          >
            ♪
          </span>
          <span
            className="absolute text-primary/60 animate-note-float text-lg sm:text-xl"
            style={{ right: "5%", top: "15%", animationDelay: "0.4s" }}
            aria-hidden
          >
            ♫
          </span>
          <span
            className="absolute text-primary/50 animate-note-float text-base sm:text-lg"
            style={{ left: "10%", bottom: "25%", animationDelay: "0.8s" }}
            aria-hidden
          >
            ♪
          </span>
          <span
            className="absolute text-primary/60 animate-note-float text-lg sm:text-xl"
            style={{ right: "0%", bottom: "20%", animationDelay: "0.2s" }}
            aria-hidden
          >
            ♫
          </span>
        </>
      )}

      {/* Vinyl record */}
      <div
        className="relative rounded-full bg-gradient-to-br from-muted-foreground/40 to-foreground/50 border-2 border-border shadow-lg animate-record-spin"
        style={{ width: size, height: size }}
        aria-hidden
      >
        {/* Groove rings */}
        <div className="absolute inset-0 rounded-full flex items-center justify-center">
          <div className="rounded-full border border-foreground/15" style={{ width: size * 0.92, height: size * 0.92 }} />
          <div className="absolute rounded-full border border-foreground/10" style={{ width: size * 0.78, height: size * 0.78 }} />
          <div className="absolute rounded-full border border-foreground/10" style={{ width: size * 0.64, height: size * 0.64 }} />
        </div>
        {/* Center label */}
        <div
          className="absolute rounded-full bg-primary/90 border-2 border-primary flex items-center justify-center"
          style={{
            width: size * 0.32,
            height: size * 0.32,
            left: center - (size * 0.32) / 2,
            top: center - (size * 0.32) / 2,
          }}
        >
          <div className="rounded-full bg-background/80 w-4 h-4 sm:w-5 sm:h-5" />
        </div>
      </div>
    </div>
  );
};

export default MusicRecordAnimation;
